package WPDCS::Core;
## @file    <lib/WPDCS/Core.pm>
## @author  <wakaranakattari@gmail.com>
## @info    <core utilities for file operations>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-05-17>

use strict;
use warnings;
use v5.35;

## @funcinfo <read file and return array of lines>
## @param <file: str - path to read>
## @return <array - lines including newlines>
## @throws <dies if file cannot be opened>
## @ex <read_file("file.txt") => @lines>
sub
read_file
{
  my ($class, $file) = @_;
  open my $fh, '<:encoding(UTF-8)', $file or die "Cannot open $file: $!";
  my @lines = <$fh>;
  close $fh or die "Cannot close $file: $!";
  return @lines;
}

## @funcinfo <write array of lines to file>
## @param <file: str - output path>
## @param <lines: array - lines to write>
## @return <void>
## @ex <write_file("out.txt", @lines) => creates file>
sub
write_file
{
  my ($class, $file, @lines) = @_;
  open my $fh, '>:encoding(UTF-8)', $file or die "Cannot write $file: $!";
  print $fh @lines or die "Cannot write $file: $!";
  close $fh or die "Cannot close $file: $!";
}

## @funcinfo <collect source files from files/dirs, recursively>
## @param <paths: array - files or directories>
## @param <exclude: arrayref - dir names to skip>
## @return <array of file paths>
## @ex <collect_files(["src"]) => ["src/main.pl"]>
sub
collect_files
{
  my ($class, $paths, $exclude) = @_;
  $paths   //= ['.'];
  $paths     = [$paths] unless ref $paths;
  $exclude //= [qw(.git t docs node_modules target)];
  my %skip = map { $_ => 1 } @$exclude;

  my @out;
  my @stack = @$paths;
  my %seen_dir;
  while (@stack)
  {
    my $p = shift @stack;
    if (-l $p)
    {
      ## @info <never follow symlinks: take symlinked files, skip dirs>
      if (-f $p && $p =~ /\.(pl|pm|t|clj|cljs|cljc)$/)
      {
        push @out, $p;
      }
      next;
    }
    if (-f $p)
    {
      push @out, $p;
    }
    elsif (-d $p)
    {
      ## @info <guard against hardlink cycles: visit each dir inode once>
      my @st = stat($p);
      if (@st)
      {
        my $key = "$st[0]:$st[1]";
        next if $seen_dir{$key}++;
      }
      opendir my $dh, $p or die "Cannot open dir $p: $!";
      my @entries = sort readdir $dh;
      closedir $dh;
      for my $e (@entries)
      {
        next if $e eq '.' || $e eq '..';
        next if $skip{$e};
        my $full = "$p/$e";
        $full =~ s{^\./}{};
        if (-l $full)
        {
          next if -d $full;
          if (-f $full && $full =~ /\.(pl|pm|t|clj|cljs|cljc)$/)
          {
            push @out, $full;
          }
          next;
        }
        if (-d $full)
        {
          push @stack, $full;
        }
        elsif ($full =~ /\.(pl|pm|t|clj|cljs|cljc)$/ || $full =~ /(?:^|\/)(Makefile|GNUmakefile)$/)
        {
          push @out, $full;
        }
      }
    }
    else
    {
      die "no such file or directory: $p\n";
    }
  }
  return @out;
}

1;
