package WPDCS::Linter;
## @file    <lib/WPDCS/Linter.pm>
## @author  <wakaranakattari@gmail.com>
## @info    <lint code style for WPDCS compliance>

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

## @funcinfo <lint file for WPDCS style violations>
sub 
lint
{
  my     ($self, $file) = @_;

  open my $fh, '<', $file or die "Cannot open $file: $!";
  my @lines = <$fh>;
  close $fh;

  my @errors;

  for my $i (0 .. $#lines)
  {
    my $line_num = $i + 1;
    my $line = $lines[$i];
    chomp $line;

    # trailing whitespace
    if ($line =~ /\s$/)
    {
      push @errors, "Line $line_num: trailing whitespace";
    }
  }

  if (@errors)
  {
    say "Lint errors in $file:";
    say "  $_" for @errors;
    return 1;
  }
  else
  {
    say "No lint errors in $file";
    return 0;
  }
}

## @funcinfo <auto-format file according to WPDCS>
sub 
format
{
  my     ($self, $file) = @_;

  open my $fh, '<', $file or die "Cannot open $file: $!";
  my @lines = <$fh>;
  close $fh;

  my @new_lines;

  for my $line (@lines)
  {
    my $new_line = $line;
    $new_line =~ s/\s+$/\n/;
    $new_line =~ s/\t/  /g;
    push @new_lines, $new_line;
  }

  open my $fh_out, '>', $file or die "Cannot write $file: $!";
  print $fh_out @new_lines;
  close $fh_out;

  say "Formatted $file";
}

1;
