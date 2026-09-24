package WPDCS::Config;
## @file    <lib/WPDCS/Config.pm>
## @author  <wakaranakattari@gmail.com>
## @info    <configuration manager for .wpdcsrc files>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-05-17>

use strict;
use warnings;
use v5.35;

## @funcinfo <constructor with defaults>
## @param <overrides: hash - optional config overrides>
## @return <config instance>
## @ex <new(language => "clojure") => bless {}>
sub
new
{
  my ($class, %args) = @_;
  my $defaults = $class->defaults();
  for my $k (keys %args)
  {
    $defaults->{$k} = $args{$k};
  }
  return bless $defaults, $class;
}

## @funcinfo <default configuration hash>
## @return <hashref - {language, required_tags, exclude_dirs, max_length, strict}>
## @ex <defaults() => {language => perl}>
sub
defaults
{
  return {
    language      => 'Perl',
    required_tags => [qw(file author info license version since)],
    exclude_dirs  => [qw(.git t docs)],
    max_length    => 120,
    strict        => 0,
  };
}

## @funcinfo <render default .wpdcsrc content>
## @return <str - config file content>
## @ex <default_content() => config text>
sub
default_content
{
  my ($class_or_self) = @_;
  return <<'EOF';
## @info <wpdcs configuration>
language: perl
required_tags:
  - file
  - author
  - info
  - license
  - version
  - since
exclude_dirs:
  - .git
  - t
  - docs
max_length: 120
strict: 0
EOF
}

## @funcinfo <load configuration from file>
## @param <file: str - .wpdcsrc path, defaults when missing>
## @return <config instance>
## @throws <dies if file exists but unreadable>
## @ex <load(".wpdcsrc") => bless {language => perl}>
sub
load
{
  my ($self_or_class, $file) = @_;
  my $class = ref($self_or_class) || $self_or_class || __PACKAGE__;
  my $cfg = $class->defaults();

  return bless {%$cfg}, $class unless defined $file && -f $file;

  open my $fh, '<:encoding(UTF-8)', $file or die "Cannot open $file: $!";
  my @lines = <$fh>;
  close $fh;

  my $section = '';
  my @required;
  my @exclude;
  for my $raw (@lines)
  {
    my $line = $raw;
    $line =~ s/#.*$//;
    $line =~ s/^\s+//;
    $line =~ s/\s+$//;
    next if $line eq '';

    if ($line =~ /^language\s*:\s*(\S+)/)
    {
      $cfg->{language} = $1;
      $section = '';
    }
    elsif ($line =~ /^max_length\s*:\s*(\d+)/)
    {
      $cfg->{max_length} = $1;
      $section = '';
    }
    elsif ($line =~ /^strict\s*:\s*(\S+)/)
    {
      $cfg->{strict} = ($1 =~ /^(1|yes|true|on)$/i) ? 1 : 0;
      $section = '';
    }
    elsif ($line =~ /^required_tags\s*:/)
    {
      $section = 'required';
      @required = ();
    }
    elsif ($line =~ /^exclude_dirs\s*:/)
    {
      $section = 'exclude';
      @exclude = ();
    }
    elsif ($line =~ /^-\s*(\S+)/ && $section eq 'required')
    {
      push @required, $1;
    }
    elsif ($line =~ /^-\s*(\S+)/ && $section eq 'exclude')
    {
      push @exclude, $1;
    }
  }
  $cfg->{required_tags} = \@required if @required;
  $cfg->{exclude_dirs}  = \@exclude  if @exclude;

  return bless {%$cfg}, $class;
}

## @funcinfo <find .wpdcsrc walking up from dir>
## @param <start: str - file or dir to start from, default .>
## @return <str|undef - config path or undef>
## @ex <find_file("src") => "src/.wpdcsrc">
sub
find_file
{
  my ($self_or_class, $start) = @_;
  $start //= '.';
  my $dir = $start;
  $dir =~ s{/[^/]*$}{} if -f $dir;

  while (1)
  {
    my $candidate = "$dir/.wpdcsrc";
    return $candidate if -f $candidate;
    last if $dir eq '.' || $dir eq '/' || $dir eq '';
    if ($dir =~ m{/})
    {
      $dir =~ s{/[^/]+$}{};
      $dir = '.' if $dir eq '';
    }
    else
    {
      last;
    }
  }
  return undef;
}

1;
