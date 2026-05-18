package WPDCS::Core;
## @file    <lib/WPDCS/Core.pm>
## @author  <wakaranakattari@gmail.com>
## @info    <core utilities for file operations>

use strict;
use warnings;
use v5.35;

## @funcinfo <read file and return array of lines>
## @excode   <my @lines = WPDCS::Core::read_file("file.txt")>
sub 
read_file
{
  my     ($class, $file) = @_;
  open my $fh, '<', $file or die "Cannot open $file: $!";
  my @lines = <$fh>;
  close $fh;
  return @lines;
}

## @funcinfo <write array of lines to file>
## @excode   <WPDCS::Core::write_file("out.txt", @lines)>
sub 
write_file
{
  my     ($class, $file, @lines) = @_;
  open my $fh, '>', $file or die "Cannot write $file: $!";
  print $fh @lines;
  close $fh;
}

1;
