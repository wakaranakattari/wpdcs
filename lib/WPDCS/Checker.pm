package WPDCS::Checker;
## @file    <lib/WPDCS/Checker.pm>
## @author  <wakaranakattari@gmail.com>
## @info    <check required WPDCS tags in files>

use strict;
use warnings;
use v5.35;
use WPDCS::Parser;

## @funcinfo <constructor>
sub 
new
{
  my     ($class) = @_;
  my $self = {
    required => [qw(file author info)],
    parser   => WPDCS::Parser->new(),
  };
  return bless $self, $class;
}

## @funcinfo <check file for required tags>
## @excode   <my $result = $checker->check_file("calc.pl")>
sub 
check_file
{
  my     ($self, $file) = @_;

  my $tags = $self->{parser}->parse_file($file);
  my %found;

  for my $tag (@$tags)
  {
    $found{$tag->{tag}} = $tag->{value};
  }

  my @missing;
  for my $required (@{$self->{required}})
  {
    push @missing, $required unless $found{$required};
  }

  return {
    file    => $file,
    found   => \%found,
    missing => \@missing,
  };
}

## @funcinfo <print check result>
sub 
print_result
{
  my     ($self, $result) = @_;

  if (@{$result->{missing}})
  {
    for my $tag (@{$result->{missing}})
    {
      say "MISSING: $tag";
    }
    exit 1;
  }

  for my $tag (qw(file author info))
  {
    say "$tag: $result->{found}{$tag}";
  }
  exit 0;
}

1;
