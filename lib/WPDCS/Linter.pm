package WPDCS::Linter;
## @file    <lib/WPDCS/Linter.pm>
## @author  <wakaranakattari@gmail.com>
## @info    <lint code style for wpdcs compliance>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-05-17>

use strict;
use warnings;
use v5.34;
use WPDCS::Core;
use WPDCS::Parser;

our $MAX_LINE_LENGTH = 120;
our $TAB_WIDTH       = 4;

## @funcinfo <constructor>
## @param <max_length: int - max line length, default 120>
## @param <tab_width: int - spaces per tab, default 4>
## @return <linter instance>
## @ex <new(max_length => 100) => bless {}>
sub
new
{
  my ($class, %args) = @_;
  return bless {
    max_length => $args{max_length} // $MAX_LINE_LENGTH,
    tab_width  => $args{tab_width}  // $TAB_WIDTH,
  }, $class;
}

## @funcinfo <lint file for wpdcs style violations, returns 1 on errors>
## @param <file: str - path to source file>
## @return <int - 0 clean, 1 errors>
## @throws <dies if file cannot be opened>
## @ex <lint("calc.pl") => 0>
sub
lint
{
  my ($self, $file) = @_;
  my @lines = WPDCS::Core->read_file($file);

  ## @info <whole-file opt-out: nolint tag in first 5 lines skips file>
  my $scope = @lines < 5 ? scalar(@lines) : 5;
  for my $i (0 .. $scope - 1)
  {
    if ($lines[$i] =~ /\@nolint\s*<\s*all\s*>/)
    {
      say "skipped (nolint): $file";
      return 0;
    }
  }

  my @errors;
  my $max = $self->{max_length};
  my $is_make = ($file =~ /(?:^|\/)(Makefile|GNUmakefile)$/ || $file =~ /\.(mk|mak)$/) ? 1 : 0;

  for my $i (0 .. $#lines)
  {
    my $line_num = $i + 1;
    my $raw = $lines[$i];
    my $line = $raw;
    $line =~ s/\r?\n$//;

    ## @info <trailing nolint marker silences tag checks on that line>
    my $tag_checks = ($line =~ /wpdcs:\s*nolint/) ? 0 : 1;

    if ($raw =~ /\r\n$/ || $raw =~ /\r$/)
    {
      push @errors, "line $line_num: crlf line ending (use lf)";
    }
    if ($line =~ /[ \t]+$/)
    {
      push @errors, "line $line_num: trailing whitespace";
    }
    if ($line =~ /\t/ && !$is_make)
    {
      push @errors, "line $line_num: tab character (use spaces)";
    }
    if (length($line) > $max)
    {
      push @errors, "line $line_num: exceeds $max chars (" . length($line) . ")";
    }
    ## @info <malformed tag: at-sign tag without angle value on comment line>
    ## @info <only double hash and double semicolon open a tag>
    if ($tag_checks && $line =~ /^\s*(##|;;)\s*\@([\w-]+)\s*$/)
    {
      push @errors, "line $line_num: tag without <value>";
    }
    elsif ($tag_checks && $line =~ /^\s*(##|;;)\s*\@([\w-]+)\s+[^\s<]/)
    {
      push @errors, "line $line_num: tag value not in <...>";
    }
    elsif ($tag_checks && $line =~ /^\s*(##|;;)\s*\@([\w-]+)\s*<(.*)>\s*$/)
    {
      my $tag = $2;
      if (!WPDCS::Parser->is_known($tag))
      {
        push @errors, "line $line_num: unknown tag \@$tag";
      }
      elsif ($tag eq 'param' && $3 !~ /^\s*\S+\s*:/)
      {
        push @errors, "line $line_num: \@param should be <name: type - desc>";
      }
    }
  }

  if (@lines && $lines[-1] !~ /\n$/)
  {
    push @errors, "line " . scalar(@lines) . ": missing newline at end of file";
  }

  if (@errors)
  {
    say "lint errors in $file:";
    say "  $_" for @errors;
    return 1;
  }
  else
  {
    say "no lint errors in $file";
    return 0;
  }
}

## @funcinfo <auto-format file: strip trailing ws, expand tabs, ensure eof newline>
## @param <file: str - path to format in place>
## @return <void>
## @throws <dies if file cannot be read or written>
## @ex <format("calc.pl") => rewrites file>
sub
format
{
  my ($self, $file) = @_;
  my @lines = WPDCS::Core->read_file($file);

  my $spaces = ' ' x $self->{tab_width};
  my @new_lines;

  for my $line (@lines)
  {
    $line =~ s/\r?\n$//;
    $line =~ s/\t/$spaces/g;
    $line =~ s/[ \t]+$//;
    push @new_lines, $line . "\n";
  }

  WPDCS::Core->write_file($file, @new_lines);

  say "formatted $file";
}

1;
