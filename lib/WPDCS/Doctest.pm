package WPDCS::Doctest;
## @file    <lib/WPDCS/Doctest.pm>
## @author  <wakaranakattari@gmail.com>
## @info    <run @ex examples as executable doctests>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-09-23>

use strict;
use warnings;
use v5.34;
use WPDCS::Parser;
use WPDCS::Core;

## @funcinfo <constructor>
## @return <doctest instance>
## @ex <new() => bless {}>
sub
new
{
  my ($class) = @_;
  return bless { parser => WPDCS::Parser->new() }, $class;
}

## @funcinfo <extract runnable cases from tags>
## @param <file: str - source path>
## @param <tags: arrayref - optional pre-parsed tags>
## @return <arrayref of {expr, expected, fail_expected, line}>
## @ex <cases("calc.pl") => [{expr => add(1,2), expected => 3}]>
sub
cases
{
  my ($self, $file, $preparsed) = @_;
  my $tags = $preparsed // $self->{parser}->parse_file($file);
  my @cases;

  for my $t (@$tags)
  {
    my $kind = $t->{tag};
    my $is_ok   = ($kind eq 'ex' || $kind eq 'excode' || $kind eq 'excode-normalmode');
    my $is_fail = ($kind eq 'ex-fail' || $kind eq 'excode-exmode');
    next unless $is_ok || $is_fail;

    my $v = $t->{value};
    $v =~ s{/\s*$}{};
    $v =~ s{^\s+}{};
    $v =~ s{\s+$}{};
    ## @info <split on last arrow so inner arrows survive>
    next unless $v =~ /^(.*)=>(.*)$/s;
    my ($expr, $expected) = ($1, $2);
    $expr     =~ s/^\s+//;
    $expr     =~ s/\s+$//;
    $expected =~ s/^\s+//;
    $expected =~ s/\s+$//;
    next if $expr eq '' || $expected eq '';
    push @cases, {
      expr          => $expr,
      expected      => $expected,
      fail_expected => $is_fail ? 1 : 0,
      line          => $t->{line},
    };
  }
  return \@cases;
}

## @funcinfo <compare got vs expected with smart semantics>
## @param <got: str - actual value>
## @param <expected: str - spec from tag>
## @return <bool - 1 on match>
## @ex <matches("15", "15") => 1>
sub
matches
{
  my ($self_or_class, $got, $expected) = @_;
  ## @info <undef expected means nothing may be returned>
  if (!defined $got)
  {
    return $expected =~ /^\s*undef\s*$/i ? 1 : 0;
  }
  my $g = "$got";
  my $e = "$expected";
  ## @info <quoted strings: compare inner content>
  if ($e =~ /^"(.*)"$/s)
  {
    return $g eq $1 ? 1 : 0;
  }
  if ($e =~ /^'(.*)'$/s)
  {
    return $g eq $1 ? 1 : 0;
  }
  ## @info <numeric compare when both sides look numeric>
  if ($g =~ /^-?\d+(?:\.\d+)?$/ && $e =~ /^-?\d+(?:\.\d+)?$/)
  {
    return $g == $e ? 1 : 0;
  }
  return $g eq $e ? 1 : 0;
}

## @funcinfo <eval code with stdout/stderr swallowed>
## @param <code: str - perl code to eval>
## @return <array - (ok, result_or_error)>
## @ex <quiet_eval("1+1") => (1, 2)>
sub
quiet_eval
{
  my ($self_or_class, $code) = @_;
  my $out = '';
  my $result;
  my $ok;
  {
    local *STDOUT;
    local *STDERR;
    open STDOUT, '>', \$out or die "Cannot capture STDOUT: $!";
    open STDERR, '>', \$out or die "Cannot capture STDERR: $!";
    $result = eval $code; ## no critic
    $ok = $@ ? 0 : 1;
    $result = $@ if !$ok;
  }
  return ($ok, $result);
}

## @funcinfo <run doctests for one perl file>
## @param <file: str - .pl/.pm/.t path>
## @return <hashref - {total, passed, failed, failures}>
## @ex <run_file("calc.pl") => {total => 5, failed => 0}>
## @throws <dies if file is missing or has no package context>
sub
run_file
{
  my ($self, $file) = @_;
  my $cases = $self->cases($file);
  my $total = scalar @$cases;
  return { total => 0, passed => 0, failed => 0, failures => [] } unless $total;

  ## @info <load target file in an isolated package for callable subs>
  ## @info <stdout stays swallowed so demo output never leaks>
  my $pkg = 'WPDCS::Doctest::Sandbox';
  my $code = do {
    my @lines = WPDCS::Core->read_file($file);
    join '', @lines;
  };
  $code =~ s/^#!.*\n//;
  ## @info <strip shebang, then wrap everything into sandbox package>
  $code =~ s/^#!.*\n//;
  my $wrapped = "package $pkg;\nuse strict;\nuse warnings;\nno warnings 'redefine';\n$code\n1;\n";
  my ($load_ok, $load_err) = $self->quiet_eval($wrapped);
  if (!$load_ok)
  {
    my $msg = "$load_err";
    $msg =~ s/\s+/ /g;
    return {
      total    => $total,
      passed   => 0,
      failed   => $total,
      failures => [{ line => 0, expr => '<load>', expected => 'load ok', got => "load error: $msg" }],
    };
  }

  my @failures;
  my $passed = 0;
  for my $c (@$cases)
  {
    my $expr = $c->{expr};
    my ($ok, $res) = $self->quiet_eval("package $pkg; $expr");
    my $died = !$ok;
    my $got = $ok ? $res : undef;
    ## @info <fail case passes when code dies or value matches>
    my $pass;
    if ($c->{fail_expected} && $died)
    {
      $pass = 1;
    }
    elsif ($died)
    {
      $pass = 0;
      $got = "died: $res";
      $got =~ s/\s+at\s+\(eval.*//s;
    }
    else
    {
      $pass = $self->matches(defined $got ? "$got" : undef, $c->{expected});
    }
    if ($pass)
    {
      $passed++;
    }
    else
    {
      push @failures, {
        line     => $c->{line},
        expr     => $expr,
        expected => $c->{expected},
        got      => $died && !$c->{fail_expected} ? $got : (defined $got ? "$got" : 'undef'),
      };
    }
  }
  return { total => $total, passed => $passed, failed => scalar(@failures), failures => \@failures };
}

## @funcinfo <print doctest result, return exit code>
## @param <file: str - source path>
## @param <result: hashref - from run_file>
## @return <int - 0 pass, 1 fail>
sub
print_result
{
  my ($self, $file, $result) = @_;
  if ($result->{total} == 0)
  {
    say "no doctests in $file";
    return 0;
  }
  if ($result->{failed} == 0)
  {
    say "doctests ok in $file: $result->{passed}/$result->{total} passed";
    return 0;
  }
  say "doctests failed in $file: $result->{passed}/$result->{total} passed";
  for my $f (@{$result->{failures}})
  {
    say "  line $f->{line}: $f->{expr} => got [$f->{got}], expected [$f->{expected}]";
  }
  return 1;
}

1;
