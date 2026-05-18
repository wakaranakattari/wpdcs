package WPDCS::Generator;
## @file    <lib/WPDCS/Generator.pm>
## @author  <wakaranakattari@gmail.com>
## @info    <generate templates and boilerplate>

use strict;
use warnings;
use v5.35;

## @funcinfo <constructor>
sub 
new
{
  my     ($class) = @_;
  return bless {}, $class;
}

## @funcinfo <initialize new WPDCS project>
## @excode <WPDCS::Generator->init(.)>
sub 
init
{
  my     ($self, $dir) = @_;
  $dir //= '.';

  my $config = '# WPDCS Configuration
language: Perl
required_tags:
  - file
  - author
  - info
exclude_dirs:
  - .git
  - t
  - docs
';

  my $config_file = "$dir/.wpdcsrc";
  if (-e $config_file)
  {
    say "Config already exists: $config_file";
  }
  else
  {
    open my $fh, '>', $config_file or die "Cannot create $config_file";
    print $fh $config;
    close $fh;
    say "Created: $config_file";
  }

  my $examples_dir = "$dir/examples";
  unless (-d $examples_dir)
  {
    mkdir $examples_dir or die "Cannot create $examples_dir";
    say "Created: $examples_dir";
  }

  say "WPDCS project initialized in $dir";
}

## @funcinfo <generate WPDCS header for a file>
## @excode <WPDCS::Generator->generate_header(script.pl)>
sub 
generate_header
{
  my     ($self, $file) = @_;

  if (-e $file && open my $fh, '<', $file)
  {
    my $first_line = <$fh>;
    close $fh;

    if ($first_line && $first_line =~ /^##\s+\@file/)
    {
      say "Header already exists in $file";
      return;
    }
  }

  my $comment = ($file =~ /\.(pl|pm)$/) ? '##' : ';;';
  my $basename = $file;
  $basename =~ s/.*\///;

  my $header = '';
  $header .= $comment . ' @file    <' . $basename . '>' . "\n";
  $header .= $comment . ' @author  <your@email.com>' . "\n";
  $header .= $comment . ' @info    <description>' . "\n";
  $header .= $comment . ' @license <GPL 3.0>' . "\n";
  $header .= $comment . ' @version <1.0-SNAP>' . "\n";
  $header .= $comment . ' @since   <2026-05-17>' . "\n\n";

  unless (-e $file)
  {
    open my $fh, '>', $file or die "Cannot create $file: $!";
    print $fh $header;
    close $fh;
    say "Created $file with header";
    return;
  }

  open my $fh_read, '<', $file or die "Cannot read $file: $!";
  my @old_content = <$fh_read>;
  close $fh_read;

  open my $fh_write, '>', $file or die "Cannot write $file: $!";
  print $fh_write $header;
  print $fh_write @old_content;
  close $fh_write;

  say "Added header to $file";
}

## @funcinfo <add @funcinfo before functions that miss it>
sub 
generate_funcinfo
{
  my     ($self, $file) = @_;

  open my $fh, '<', $file or die "Cannot open $file: $!";
  my @lines = <$fh>;
  close $fh;

  my @new_lines;
  my $changes = 0;

  for my $i (0 .. $#lines)
  {
    push @new_lines, $lines[$i];

    if ($lines[$i] =~ /^sub\s+(\w+)/ && $i > 0)
    {
      my $prev_line = $lines[$i-1];

      if ($prev_line !~ /\@funcinfo/)
      {
        my $func_name = $1;
        my $indent = '';
        $indent = $1 if $lines[$i] =~ /^(\s+)/;

        pop @new_lines;
        push @new_lines, $indent . '## @funcinfo <TODO: describe ' . $func_name . '>' . "\n";
        push @new_lines, $lines[$i];
        $changes++;
      }
    }
  }

  if ($changes)
  {
    open my $fh_out, '>', $file or die "Cannot write $file: $!";
    print $fh_out @new_lines;
    close $fh_out;
    say "Added $changes \@funcinfo tags to $file";
  }
  else
  {
    say "No missing \@funcinfo tags in $file";
  }
}

## @funcinfo <generate markdown documentation from tags>
sub 
generate_docs
{
  my     ($self, $file) = @_;

  my $parser = WPDCS::Parser->new();
  my $tags   = $parser->parse_file($file);

  my $output_file = $file;
  $output_file =~ s/\.pl$/.md/;
  $output_file =~ s/\.clj$/.md/;
  $output_file =~ s/\.cljs$/.md/;

  open my $fh, '>', $output_file or die "Cannot write $output_file: $!";

  print $fh "# Documentation for $file\n\n";

  for my $tag (@$tags)
  {
    if ($tag->{tag} eq 'funcinfo')
    {
      print $fh "## Function\n\n";
      print $fh "**Description:** $tag->{value}\n\n";
    }
    elsif ($tag->{tag} eq 'excode')
    {
      print $fh "**Example:**\n\n```perl\n$tag->{value}\n```\n\n";
    }
    elsif ($tag->{tag} eq 'excode-normalmode')
    {
      print $fh "**Example (normal):**\n\n```perl\n$tag->{value}\n```\n\n";
    }
    elsif ($tag->{tag} eq 'excode-exmode')
    {
      print $fh "**Example (exception):**\n\n```perl\n$tag->{value}\n```\n\n";
    }
    elsif ($tag->{tag} eq 'secinfo')
    {
      print $fh "## Section: $tag->{value}\n\n";
    }
  }

  close $fh;
  say "Generated documentation: $output_file";
}

## @funcinfo <create new WPDCS project structure>
sub 
create_project
{
  my     ($self, $name) = @_;

  die "Project $name already exists" if -d $name;

  mkdir $name or die "Cannot create $name: $!";
  mkdir "$name/src" or die "Cannot create $name/src: $!";
  mkdir "$name/examples" or die "Cannot create $name/examples: $!";
  mkdir "$name/t" or die "Cannot create $name/t: $!";

  my $config = <<'EOF';
# WPDCS Configuration
language: Perl
required_tags:
  - file
  - author
  - info
exclude_dirs:
  - .git
  - t
  - docs
EOF

  open my $fh, '>', "$name/.wpdcsrc" or die "Cannot create .wpdcsrc: $!";
  print $fh $config;
  close $fh;

  my $main = <<'EOF';
## @file    <src/main.pl>
## @author  <your@email.com>
## @info    <main entry point>
## @license <GPL 3.0>
## @version <1.0-SNAP>
## @since   <2026-05-17>

use strict;
use warnings;
use v5.35;

## @funcinfo <main function>
sub 
main
{
  say "Hello, WPDCS!";
}

main();
EOF

  open my $fh2, '>', "$name/src/main.pl" or die "Cannot create src/main.pl: $!";
  print $fh2 $main;
  close $fh2;

  open my $fh3, '>', "$name/README.md" or die "Cannot create README.md: $!";
  print $fh3 "# $name\n\nWPDCS project\n";
  close $fh3;

  say "Created WPDCS project: $name";
  say "";
  say "  cd $name";
  say "  wpdcs check src/main.pl";
  say "  wpdcs gen header src/main.pl";
}

1;
