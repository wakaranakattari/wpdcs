package WPDCS::Parser;
## @file    <lib/WPDCS/Parser.pm>
## @author  <wakaranakattari@gmail.com>
## @info    <parse wpdcs tags from files>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-05-17>

use strict;
use warnings;
use v5.34;
use WPDCS::Core;

## @funcinfo <list of known wpdcs tags>
## @return <array of tag names>
## @ex <known_tags() => file, author, info, ...>
sub
known_tags
{
  return qw(
    file author info license version since
    funcinfo param return throws
    ex ex-fail excode excode-normalmode excode-exmode
    secinfo secstart secend
    see deprecated todo test complexity docs nolint
  );
}

## @funcinfo <check if a tag name is known>
## @param <name: str - tag name without @>
## @return <bool - 1 if known>
## @ex <is_known("param") => 1>
sub
is_known
{
  my ($invocant, $maybe_name) = @_;
  my $name = defined $maybe_name ? $maybe_name : $invocant;
  state %known;
  unless (%known)
  {
    %known = map { $_ => 1 } __PACKAGE__->known_tags();
  }
  return $known{$name} ? 1 : 0;
}

## @funcinfo <constructor>
## @return <parser instance>
## @ex <new() => bless {}>
sub
new
{
  my ($class) = @_;
  return bless {}, $class;
}

## @funcinfo <parse file and return arrayref of tags>
## @param <file: str - path to source file>
## @return <arrayref of {tag, value, line, type, bracketed, raw}>
## @throws <dies if file cannot be opened>
## @ex <parse_file("calc.pl") => [{tag => file, value => calc.pl}]>
sub
parse_file
{
  my ($self, $file) = @_;
  die "Usage: parse_file(<file>)\n" unless defined $file;
  my @lines = WPDCS::Core->read_file($file);

  my @tags;
  my $lineno = 0;

  for my $raw (@lines)
  {
    $lineno++;
    my $line = $raw;
    $line =~ s/\r?\n$//;

    ## @info <legacy section markers live on their own line>
    if ($line =~ m{(?<!\S)(##|;;)\s*\@(secstart|secend)\s*->\s*\@secname\s*<(.*)>\s*$})
    {
      my ($type, $tag, $value) = ($1, $2, $3);
      $value =~ s/^\s+//;
      $value =~ s/\s+$//;
      push @tags, {
        tag       => $tag,
        value     => $value,
        line      => $lineno,
        type      => $type,
        bracketed => 1,
        raw       => $raw,
      };
      next;
    }

    ## @info <match every tag tho inline ones after code count too>
    ## @info <tag names take letters, digits, underscore and dash>
    ## @info <values may hold arrows so lone bracket ends the value>
    ## @info <marker must open a comment, not sit inside quoted text>
    while ($line =~ m{(?<!\S)(##|;;)\s*\@([\w-]+)(?:\s*<((?:=>|[^>])*)>\s*)?}g)
    {
      my ($type, $tag, $bracketed) = ($1, $2, $3);
      my $value = $bracketed;

      ## @info <bare value without brackets: take rest of line after tag>
      my $bracketed_flag = defined $bracketed ? 1 : 0;
      if (!defined $value)
      {
        ## @info <match end offset marks where bare value starts>
        my $rest = substr($line, $+[0]);
        $rest =~ s/^\s+//;
        $rest =~ s/\s+$//;
        $value = $rest;
      }
      $value //= '';
      $value =~ s/^\s+//;
      $value =~ s/\s+$//;

      push @tags, {
        tag       => $tag,
        value     => $value,
        line      => $lineno,
        type      => $type,
        bracketed => $bracketed_flag,
        raw       => $raw,
      };
    }
  }

  return \@tags;
}

## @funcinfo <group tags into per-function blocks>
## @param <file: str - path to source file>
## @param <tags: arrayref - optional pre-parsed tags>
## @return <arrayref of blocks {func, line, tags}>
## @ex <blocks("calc.pl") => [{func => add, tags => [...]}]>
sub
parse_blocks
{
  my ($self, $file, $preparsed) = @_;
  my $tags = $preparsed // $self->parse_file($file);

  my @blocks;
  my $current;

  my $flush = sub {
    push @blocks, $current if defined $current;
    $current = undef;
  };

  my %is_block_tag = map { $_ => 1 } qw(
    param return throws ex ex-fail
    excode excode-normalmode excode-exmode
    see deprecated todo test complexity
  );

  for my $tag (@$tags)
  {
    if ($tag->{tag} eq 'funcinfo')
    {
      $flush->();
      $current = { func => undef, line => $tag->{line}, tags => [$tag] };
    }
    elsif ($is_block_tag{$tag->{tag}} && defined $current)
    {
      push @{$current->{tags}}, $tag;
    }
    elsif ($is_block_tag{$tag->{tag}})
    {
      ## @info <func tag before any funcinfo counts as file scope>
      push @blocks, { func => undef, line => $tag->{line}, tags => [$tag], header => 1 };
    }
    else
    {
      ## @info <header tags close any open function block>
      $flush->();
      push @blocks, { func => undef, line => $tag->{line}, tags => [$tag], header => 1 };
    }
  }
  $flush->();

  return \@blocks;
}

## @funcinfo <print tags in human-readable format>
## @param <tags: arrayref - parsed tags>
## @return <void>
## @ex <print_tags($tags) => prints lines>
sub
print_tags
{
  my ($self, $tags) = @_;
  $tags //= [];
  if (!@$tags)
  {
    say "no wpdcs tags found";
    return;
  }
  for my $tag (@$tags)
  {
    my $flag = $tag->{bracketed} ? '' : ' [unbracketed]';
    printf "line %-5d %-18s: %s%s\n", $tag->{line}, $tag->{tag}, $tag->{value}, $flag;
  }
}

1;
