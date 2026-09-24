package WPDCS::Checker;
## @file    <lib/WPDCS/Checker.pm>
## @author  <wakaranakattari@gmail.com>
## @info    <check required wpdcs tags in files>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-05-17>

use strict;
use warnings;
use v5.35;
use WPDCS::Parser;
use WPDCS::Config;
use WPDCS::Core;

## @funcinfo <constructor, optionally with required list or config file>
## @param <required: arrayref - optional required tag list>
## @param <config: str - optional .wpdcsrc path>
## @param <parser: parser - optional parser instance>
## @param <strict: bool - fail on unknown tags, default from config>
## @return <checker instance>
## @ex <new(required => [qw(file author info)]) => bless {}>
sub
new
{
  my ($class, %args) = @_;

  my $cfg;
  if (defined $args{config})
  {
    $cfg = WPDCS::Config->load($args{config});
  }
  else
  {
    my $found_cfg = WPDCS::Config->find_file('.');
    $cfg = WPDCS::Config->load($found_cfg) if defined $found_cfg;
  }

  my $required = $args{required} // $cfg->{required_tags} // [qw(file author info)];
  my $strict = exists $args{strict} ? $args{strict} : ($cfg->{strict} // 0);

  my $self = {
    required => $required,
    strict   => $strict,
    parser   => $args{parser} // WPDCS::Parser->new(),
  };
  return bless $self, $class;
}

## @funcinfo <check file for required tags>
## @param <file: str - path to source file>
## @return <hashref - {file, found, missing, malformed, duplicates, unknown, ok}>
## @throws <dies if file cannot be opened>
## @ex <check_file("calc.pl") => {ok => 1}>
sub
check_file
{
  my ($self, $file) = @_;

  my $tags = $self->{parser}->parse_file($file);
  my %found;
  my %seen;
  my @malformed;
  my @duplicates;

  ## @info <some tags repeat per file, the rest must be unique>
  my %repeatable = map { $_ => 1 } qw(
    funcinfo param return throws
    ex ex-fail excode excode-normalmode excode-exmode
    secinfo secstart secend info docs
    see deprecated todo test complexity nolint
  );

  my @unknown;
  for my $tag (@$tags)
  {
    push @unknown, "$tag->{tag} (line $tag->{line})"
      unless WPDCS::Parser->is_known($tag->{tag});
  }

  for my $tag (@$tags)
  {
    ## @info <first occurrence wins for required check>
    if (exists $seen{$tag->{tag}})
    {
      push @duplicates, "$tag->{tag} (line $tag->{line})"
        unless $repeatable{$tag->{tag}};
      next;
    }
    $seen{$tag->{tag}} = 1;
    $found{$tag->{tag}} = $tag->{value};

    if (!$tag->{bracketed} || $tag->{value} eq '')
    {
      push @malformed, "$tag->{tag} (line $tag->{line})";
    }
  }

  my @missing;
  for my $required (@{$self->{required}})
  {
    push @missing, $required unless exists $found{$required} && $found{$required} ne '';
  }

  my $ok = (@missing == 0 && @malformed == 0) ? 1 : 0;
  $ok = 0 if $self->{strict} && @unknown;

  return {
    file      => $file,
    found     => \%found,
    missing   => \@missing,
    malformed => \@malformed,
    duplicates => \@duplicates,
    unknown   => \@unknown,
    ok        => $ok,
  };
}

## @funcinfo <print check result, return exit code instead of exiting>
## @param <result: hashref - from check_file>
## @return <int - 0 ok, 1 fail>
sub
print_result
{
  my ($self, $result) = @_;

  my $failed = 0;

  if (@{$result->{missing}})
  {
    for my $tag (@{$result->{missing}})
    {
      say "missing: $tag";
    }
    $failed = 1;
  }

  if (@{$result->{malformed}})
  {
    for my $tag (@{$result->{malformed}})
    {
      say "malformed (expected \@tag <value>): $tag";
    }
    $failed = 1;
  }

  if (@{$result->{duplicates}})
  {
    for my $tag (@{$result->{duplicates}})
    {
      say "duplicate: $tag";
    }
  }

  if ($result->{unknown} && @{$result->{unknown}})
  {
    for my $tag (@{$result->{unknown}})
    {
      say "unknown tag: $tag";
    }
    if ($self->{strict})
    {
      $failed = 1;
    }
  }

  if ($failed)
  {
    return 1;
  }

  for my $tag (@{$self->{required}})
  {
    say "$tag: $result->{found}{$tag}";
  }
  return 0;
}

## @funcinfo <documentation coverage: share of funcs with funcinfo>
## @param <file: str - source path>
## @return <hashref - {total, documented, undocumented, pct}>
## @ex <coverage("calc.pl") => {total => 4, documented => 4}>
sub
check_coverage
{
  my ($self, $file) = @_;
  require WPDCS::Generator;
  my @lines = WPDCS::Core->read_file($file);
  my $gen = WPDCS::Generator->new();
  my @funcs = $gen->_collect_funcs(\@lines, $file);
  my $total = scalar @funcs;
  return { total => 0, documented => 0, undocumented => [], pct => 100 } unless $total;

  my @undoc;
  for my $f (@funcs)
  {
    my $documented = 0;
    my $j = $f->{idx} - 1;
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
      last if $lines[$j] !~ /^\s*(##|;;)/;
      $j--;
    }
    push @undoc, $f->{name} unless $documented;
  }
  my $doc = $total - scalar(@undoc);
  return {
    total        => $total,
    documented   => $doc,
    undocumented => \@undoc,
    pct          => int(100 * $doc / $total),
  };
}

1;
