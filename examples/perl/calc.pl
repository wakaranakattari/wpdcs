## @file    <calc.pl>
## @author  <wakaranakattari@gmail.com>
## @info    <basic calculator implementation>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-05-07>
## @see     <examples/perl/user-auth.pl>

use strict;
use warnings;
use v5.34;

## @funcinfo <addition of two numbers>
## @param <num1: num - first operand>
## @param <num2: num - second operand>
## @return <num - sum of operands>
## @ex <add(10, 5) => 15>
## @complexity <o(1)>
sub add {
  my ($num1, $num2) = @_;
  return $num1 + $num2;
}

## @funcinfo <subtraction of two numbers>
## @param <num1: num - minuend>
## @param <num2: num - subtrahend>
## @return <num - difference of operands>
## @ex <subs(10, 5) => 5>
## @complexity <o(1)>
sub subs {
  my ($num1, $num2) = @_;
  return $num1 - $num2;
}

## @funcinfo <multiplication of two numbers>
## @param <num1: num - first factor>
## @param <num2: num - second factor>
## @return <num - product of operands>
## @ex <mul(10, 5) => 50>
## @complexity <o(1)>
sub mul {
  my ($num1, $num2) = @_;
  return $num1 * $num2;
}

## @funcinfo <division with zero protection>
## @param <num1: num - dividend>
## @param <num2: num - divisor, may be zero>
## @return <num|undef - quotient or undef on zero divisor>
## @ex <div(10, 2) => 5>
## @ex-fail <div(10, 0) => undef>
## @complexity <o(1)>
sub div {
  my ($num1, $num2) = @_;

  return undef if $num2 == 0;
  return $num1 / $num2;
}

## @secinfo <test section>
say add(10, 5);
say subs(10, 5);
say mul(10, 5);

my $result = div(10, 0);
say defined $result ? $result : "Cannot divide by zero";
