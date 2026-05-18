## @file      <calc.pl>
## @author    <wakaranakattari@gmail.com>
## @info      <Basic calculator implementation>
## @license   <GPL 3.0>
## @version   <1.0-SNAP>
## @docs      </example/path/>
## @since     <2026-05-07>

use strict;
use warnings;
use v5.35;

## @funcinfo <Addition of two numbers>
## @excode   < add (10, 5) => 15 />
sub
add
{
  my     ($num1, $num2) = @_;
  return $num1 + $num2;
}

## @funcinfo <Subtraction of two numbers>
## @excode   < subs (10, 5) => 5 />
sub
subs
{
  my     ($num1, $num2) = @_;
  return $num1 - $num2;
}

## @funcinfo <Multiplication of two numbers>
## @excode   < mul (10, 5) => 50 />
sub
mul
{
  my     ($num1, $num2) = @_;
  return $num1 * $num2;
}

## @funcinfo          <Division with zero protection>
## @excode-normalmode < div (10, 2) => 5 />
## @excode-exmode     < div (10, 0) => undef />
sub
div
{
  my              ($num1, $num2) = @_;

  return undef if $num2 == 0;
  return          $num1 / $num2;
}

## @secinfo <Test section>
say add  (10, 5);
say subs (10, 5);
say mul  (10, 5);

my $result = div (10, 0);
say defined $result ? $result : "Cannot divide by zero";
