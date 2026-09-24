package WPDCS::Generator;
## @file    <lib/WPDCS/Generator.pm>
## @author  <wakaranakattari@gmail.com>
## @info    <generate templates and boilerplate>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-05-17>

use strict;
use warnings;
use v5.35;
use POSIX qw(strftime);
use File::Path qw(make_path);
use WPDCS::Core;
use WPDCS::Config;
use WPDCS::Parser;

our $VERSION = '2.0.0';

## @funcinfo <constructor>
## @return <generator instance>
## @ex <new() => bless {}>
sub
new
{
  my ($class) = @_;
  return bless {}, $class;
}

## @funcinfo <comment prefix for a filename>
## @param <file: str - filename with extension>
## @return <str - comment marker for dialect>
## @ex <comment_for_file("a.clj") => ";;">
sub
comment_for_file
{
  my ($self_or_class, $file) = @_;
  return '##' if $file =~ /\.(pl|pm|t)$/;
  return ';;' if $file =~ /\.(clj|cljs|cljc|edn)$/;
  return '##' if $file =~ /(?:^|\/)(Makefile|GNUmakefile)$/ || $file =~ /\.(mk|mak)$/;
  return '##';
}

## @funcinfo <today in YYYY-MM-DD>
## @return <str - local date>
## @ex <today() => "2026-09-23">
sub
today
{
  return strftime('%Y-%m-%d', localtime);
}

## @funcinfo <initialize new wpdcs project>
## @param <dir: str - target dir, default .>
## @return <void>
## @throws <dies if dir does not exist>
## @ex <init(".") => creates .wpdcsrc>
sub
init
{
  my ($self, $dir) = @_;
  $dir //= '.';

  die "Directory $dir does not exist\n" unless -d $dir;

  my $config_file = "$dir/.wpdcsrc";
  if (-e $config_file)
  {
    say "config already exists: $config_file";
  }
  else
  {
    WPDCS::Core->write_file($config_file, WPDCS::Config->default_content());
    say "created: $config_file";
  }

  for my $subdir ("$dir/examples", "$dir/t", "$dir/docs")
  {
    unless (-d $subdir)
    {
      make_path($subdir) or die "Cannot create $subdir: $!";
      say "created: $subdir";
    }
  }

  say "wpdcs project initialized in $dir";
}

## @funcinfo <generate wpdcs header for a file>
## @param <file: str - target path, created if missing>
## @return <void>
## @throws <dies on io errors>
## @ex <generate_header("script.pl") => adds header>
sub
generate_header
{
  my ($self, $file) = @_;

  my $comment  = $self->comment_for_file($file);
  my $basename = $file;
  $basename =~ s{.*\/}{};
  my $date = $self->today();

  my $header = '';
  $header .= "$comment \@file    <$basename>\n";
  $header .= "$comment \@author  <your\@email.com>\n";
  $header .= "$comment \@info    <description>\n";
  $header .= "$comment \@license <gpl 3.0>\n";
  $header .= "$comment \@version <0.1.0>\n";
  $header .= "$comment \@since   <$date>\n\n";

  unless (-e $file)
  {
    WPDCS::Core->write_file($file, $header);
    say "created  with header";
    return;
  }

  my @old_content = WPDCS::Core->read_file($file);

  ## @info <skip when header already sits in first 10 lines>
  my $limit = @old_content < 10 ? scalar(@old_content) : 10;
  for my $i (0 .. $limit - 1)
  {
    if ($old_content[$i] =~ /^\s*(##|;;)\s*\@file\b/)
    {
      say "header already exists in $file";
      return;
    }
  }

  ## @info <keep shebang as the very first line of file>
  my $shebang = '';
  if (@old_content && $old_content[0] =~ /^#!/)
  {
    $shebang = shift @old_content;
  }

  my @out;
  push @out, $shebang if $shebang ne '';
  push @out, $header;
  push @out, @old_content;
  WPDCS::Core->write_file($file, @out);

  say "added header to $file";
}

## @funcinfo <detect function definitions in a line, returns (name, comment)>
## @param <line: str - single source line>
## @param <file: str - filename for dialect>
## @return <array - (name, comment) or empty>
## @ex <detect("sub foo {", "a.pl") => ("foo", "##")>
sub
_detect_func
{
  my ($self, $line, $file) = @_;
  ## @info <perl case: optional indent, then sub name>
  ## @info <same line may carry signature or attrs>
  if ($line =~ /^\s*sub\s+(\w+)\b/)
  {
    return ($1, $self->comment_for_file($file));
  }
  ## @info <clojure case: defn form with optional metadata>
  if ($line =~ /^\s*\(\s*defn-?\s+([\w\-\.\!\?]+)/)
  {
    return ($1, ';;');
  }
  return ();
}

## @funcinfo <extract parameter names from definition + body>
## @param <lines: arrayref - file lines>
## @param <idx: int - definition line index>
## @param <file: str - filename for dialect>
## @return <array of param names>
## @ex <params(\@lines, 12, "a.pl") => ["x", "y"]>
sub
_signature_params
{
  my ($self, $lines, $idx, $file) = @_;
  my @params;

  if ($file =~ /\.(clj|cljs|cljc|edn)$/)
  {
    ## @info <defn vector may span a few lines, join them first>
    my $joined = $lines->[$idx];
    $joined .= $lines->[$idx + 1] if defined $lines->[$idx + 1];
    $joined .= $lines->[$idx + 2] if defined $lines->[$idx + 2];
    if ($joined =~ /defn-?\s+[\w\-\.\!\?]+\s*\[[^\]]*\]/)
    {
      my ($vec) = $joined =~ /\[([^\]]*)\]/;
      for my $p (split /\s+/, ($vec // ''))
      {
        next if $p eq '' || $p eq '&';
        $p =~ s/^\{.*//;
        push @params, $p if $p =~ /^[\w\-\.\!\?]+$/;
      }
    }
    return @params;
  }

  ## @info <perl case: signature sits on definition line>
  if ($lines->[$idx] =~ /^\s*sub\s+\w+\s*\(([^)]*)\)/)
  {
    for my $p (split /,/, $1)
    {
      $p =~ s/^\s+//;
      $p =~ s/\s+$//;
      $p =~ s/^[\$\@\%]//;
      $p =~ s/\s*=.*$//;
      push @params, $p if $p =~ /^\w+$/;
    }
    return @params if @params;
  }
  ## @info <attrs may sit between name and signature>
  if ($lines->[$idx] =~ /^\s*sub\s+\w+\b.*\(([^)]*)\)\s*$/)
  {
    for my $p (split /,/, $1)
    {
      $p =~ s/^\s+//;
      $p =~ s/\s+$//;
      $p =~ s/^[\$\@\%]//;
      $p =~ s/\s*=.*$//;
      push @params, $p if $p =~ /^\w+$/;
    }
    return @params if @params;
  }

  ## @info <fallback: destructured args within next 5 lines>
  for my $k ($idx .. $idx + 5)
  {
    last if $k > $#$lines;
    if ($lines->[$k] =~ /my\s*\(\s*([^)]*?)\s*\)\s*=\s*\@_/)
    {
      for my $p (split /,/, $1)
      {
        $p =~ s/^\s+//;
        $p =~ s/\s+$//;
        $p =~ s/^[\$\@\%]//;
        push @params, $p if $p =~ /^\w+$/;
      }
      last;
    }
  }
  return @params;
}

## @funcinfo <collect all function defs, handles multiline "sub\nname" style>
## @param <lines: arrayref - file lines>
## @param <file: str - filename for dialect>
## @return <array of {name, idx}>
## @ex <collect(\@lines, "a.pl") => [{name => foo}]>
sub
_collect_funcs
{
  my ($self, $lines, $file) = @_;
  my @funcs;
  for (my $i = 0; $i < @$lines; $i++)
  {
    my ($name) = $self->_detect_func($lines->[$i], $file);
    if (defined $name)
    {
      push @funcs, { name => $name, idx => $i };
      next;
    }
    ## @info <legacy style: lone sub line, name sits on next line>
    ## @info <blank lines between them dont matter>
    if ($lines->[$i] =~ /^\s*sub\s*$/)
    {
      my $j = $i + 1;
      while ($j < @$lines && $lines->[$j] =~ /^\s*$/)
      {
        $j++;
      }
      if ($j < @$lines && $lines->[$j] =~ /^\s*(\w+)\b/ && $lines->[$j] !~ /^\s*\{/)
      {
        push @funcs, { name => $1, idx => $i };
      }
    }
  }
  return @funcs;
}

## @funcinfo <add @funcinfo before functions that miss it>
## @param <file: str - source path to rewrite in place>
## @return <void>
## @throws <dies if file cannot be read or written>
## @ex <generate_funcinfo("calc.pl") => adds skeletons>
sub
generate_funcinfo
{
  my ($self, $file) = @_;

  my @lines = WPDCS::Core->read_file($file);
  my $comment = $self->comment_for_file($file);
  my @funcs = $self->_collect_funcs(\@lines, $file);
  my %is_func = map { $_->{idx} => $_->{name} } @funcs;

  my @new_lines;
  my $changes = 0;

  for my $i (0 .. $#lines)
  {
    my $func_name = $is_func{$i};
    if (defined $func_name)
    {
      ## @info <doc skeleton spans a few lines so look back wider>
      ## @info <seen when any of previous 12 comment lines holds funcinfo>
      my $documented = 0;
      my $j = $i - 1;
      my $checked = 0;
      while ($j >= 0 && $checked < 12)
      {
        if ($lines[$j] =~ /^\s*$/)
        {
          $j--;
          next;
        }
        $checked++;
        if ($lines[$j] =~ /\@funcinfo/)
        {
          $documented = 1;
          last;
        }
        ## @info <stop at code lines that hold no comment>
        last if $lines[$j] !~ /^\s*(##|;;|#|;)/;
        $j--;
      }

      unless ($documented)
      {
        my $indent = '';
        $indent = $1 if $lines[$i] =~ /^(\s+)/;
        my @params = $self->_signature_params(\@lines, $i, $file);
        push @new_lines, "${indent}${comment} \@funcinfo <todo: describe $func_name>\n";
        for my $p (@params)
        {
          push @new_lines, "${indent}${comment} \@param <${p}: any - todo>\n";
        }
        push @new_lines, "${indent}${comment} \@return <any - todo>\n";
        $changes++;
      }
    }
    push @new_lines, $lines[$i];
  }

  if ($changes)
  {
    WPDCS::Core->write_file($file, @new_lines);
    say "added $changes \@funcinfo tags to $file";
  }
  else
  {
    say "no missing \@funcinfo tags in $file";
  }
}

## @funcinfo <generate markdown documentation from tags>
## @param <file: str - source path>
## @return <void>
## @throws <dies if source unreadable or output unwritable>
## @ex <generate_docs("calc.pl") => creates calc.md>
sub
generate_docs
{
  my ($self, $file) = @_;

  my $parser = WPDCS::Parser->new();
  my $tags   = $parser->parse_file($file);

  my %meta;
  for my $tag (@$tags)
  {
    $meta{$tag->{tag}} //= $tag->{value};
  }

  ## @info <collect function names in file order, multiline subs included>
  my @lines = WPDCS::Core->read_file($file);

  my $output_file = $file;
  $output_file =~ s/\.(pl|pm|clj|cljs|cljc|t)$/.md/;
  if ($output_file eq $file)
  {
    $output_file .= '.md';
  }

  my $lang = ($file =~ /\.(clj|cljs|cljc)$/) ? 'clojure' : 'perl';

  ## @info <group function tags keeping definition order>
  my @func_names = map { $_->{name} } $self->_collect_funcs(\@lines, $file);
  my @func_tag_names = qw(
    funcinfo param return throws ex ex-fail
    excode excode-normalmode excode-exmode
    see deprecated todo test complexity
  );
  my %is_func_tag = map { $_ => 1 } @func_tag_names;
  my @func_tags = grep { $is_func_tag{$_->{tag}} } @$tags;

  ## @info <cut tags into chunks, each opens with funcinfo>
  ## @info <tags before first funcinfo stay file-scope, never shift names>
  my @chunks;
  my @header_extras;
  my $cur;
  my $seen_funcinfo = 0;
  for my $t (@func_tags)
  {
    if ($t->{tag} eq 'funcinfo')
    {
      $seen_funcinfo = 1;
      push @chunks, $cur if defined $cur;
      $cur = [$t];
    }
    elsif (!$seen_funcinfo)
    {
      push @header_extras, $t;
    }
    else
    {
      $cur //= [];
      push @$cur, $t;
    }
  }
  push @chunks, $cur if defined $cur && @$cur;

  open my $fh, '>:encoding(UTF-8)', $output_file or die "Cannot write $output_file: $!";

  print $fh "# documentation for $file\n\n";
  for my $k (qw(file author info license version since))
  {
    print $fh "- **$k:** $meta{$k}\n" if defined $meta{$k} && $meta{$k} ne '';
  }

  for my $t (@header_extras)
  {
    if ($t->{tag} eq 'see')
    {
      print $fh "- **see:** $t->{value}\n";
    }
    elsif ($t->{tag} eq 'todo')
    {
      print $fh "- **todo:** $t->{value}\n";
    }
    elsif ($t->{tag} eq 'deprecated')
    {
      print $fh "> **deprecated:** $t->{value}\n";
    }
  }
  print $fh "\n" if %meta;

  ## @info <section markers render in file order before function docs>
  for my $tag (@$tags)
  {
    if ($tag->{tag} eq 'secinfo')
    {
      print $fh "## section: $tag->{value}\n\n";
    }
  }

  my $render_ex = sub {
    my ($label, $val) = @_;
    print $fh "**$label:**\n\n```$lang\n$val\n```\n\n";
  };

  my $render_chunk = sub {
    my ($chunk, $fname) = @_;
    $fname //= 'function';
    print $fh "## $fname\n\n";
    for my $t (@$chunk)
    {
      if ($t->{tag} eq 'funcinfo')
      {
        print $fh "$t->{value}\n\n";
      }
      elsif ($t->{tag} eq 'param')
      {
        print $fh "- **param:** $t->{value}\n";
      }
      elsif ($t->{tag} eq 'return')
      {
        print $fh "- **returns:** $t->{value}\n";
      }
      elsif ($t->{tag} eq 'throws')
      {
        print $fh "- **throws:** $t->{value}\n";
      }
      elsif ($t->{tag} eq 'complexity')
      {
        print $fh "- **complexity:** $t->{value}\n";
      }
      elsif ($t->{tag} eq 'see')
      {
        print $fh "- **see:** $t->{value}\n";
      }
      elsif ($t->{tag} eq 'deprecated')
      {
        print $fh "> **deprecated:** $t->{value}\n\n";
      }
      elsif ($t->{tag} eq 'todo')
      {
        print $fh "- **todo:** $t->{value}\n";
      }
      elsif ($t->{tag} eq 'test')
      {
        print $fh "- **test:** `$t->{value}`\n";
      }
      elsif ($t->{tag} eq 'ex' || $t->{tag} eq 'excode')
      {
        print $fh "\n";
        $render_ex->('example', $t->{value});
      }
      elsif ($t->{tag} eq 'ex-fail' || $t->{tag} eq 'excode-exmode')
      {
        print $fh "\n";
        $render_ex->('example (failure)', $t->{value});
      }
      elsif ($t->{tag} eq 'excode-normalmode')
      {
        print $fh "\n";
        $render_ex->('example', $t->{value});
      }
    }
    print $fh "\n";
  };

  if (@chunks)
  {
    for (my $ci = 0; $ci < @chunks; $ci++)
    {
      my $fname = $func_names[$ci] // "function-" . ($ci + 1);
      $render_chunk->($chunks[$ci], $fname);
    }
  }
  else
  {
    ## @info <with no funcinfo blocks render loose tags only>
    for my $tag (@$tags)
    {
      if ($tag->{tag} eq 'see')
      {
        print $fh "- **see:** $tag->{value}\n";
      }
      elsif ($tag->{tag} eq 'todo')
      {
        print $fh "- **todo:** $tag->{value}\n";
      }
    }
  }

  close $fh or die "Cannot close $output_file: $!";
  say "generated documentation: $output_file";
}

## @funcinfo <create new wpdcs project structure>
## @param <name: str - project dir name, letters/digits/dash>
## @return <void>
## @throws <dies on invalid name or existing path>
## @ex <create_project("my-app") => creates my-app/src/main.pl>
sub
create_project
{
  my ($self, $name) = @_;

  die "Usage: create_project(<name>)\n" unless defined $name && $name ne '';
  die "Invalid project name: $name (use [A-Za-z0-9_-]+)\n" unless $name =~ /^[A-Za-z0-9][A-Za-z0-9_-]*$/;
  die "Project $name already exists\n" if -e $name;

  make_path("$name/src", "$name/examples", "$name/t", "$name/docs")
    or die "Cannot create $name: $!";

  WPDCS::Core->write_file("$name/.wpdcsrc", WPDCS::Config->default_content());

  my $date = $self->today();
  my $main = <<"EOF";
## \@file    <main.pl>
## \@author  <your\@email.com>
## \@info    <main entry point>
## \@license <gpl 3.0>
## \@version <0.1.0>
## \@since   <$date>

use strict;
use warnings;
use v5.35;

## \@funcinfo <main function>
sub main {
  say "Hello, WPDCS!";
}

main();
EOF

  WPDCS::Core->write_file("$name/src/main.pl", $main);
  WPDCS::Core->write_file("$name/README.md", "# $name\n\nWPDCS project\n");
  WPDCS::Core->write_file("$name/t/basic.t", <<'EOF');
use strict;
use warnings;
use Test::More tests => 1;
ok(1, 'placeholder');
EOF

  say "created wpdcs project: $name";
  say "";
  say "  cd $name";
  say "  wpdcs check src/main.pl";
  say "  wpdcs lint src/main.pl";
}

1;
