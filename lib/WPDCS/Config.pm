package WPDCS::Config;
## @file    <lib/WPDCS/Config.pm>
## @author  <wakaranakattari@gmail.com>
## @info    <configuration manager (placeholder)>

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

## @funcinfo <load configuration from file>
## @excode   <my $config = WPDCS::Config->load(".wpdcsrc")>
sub 
load
{
  my     ($self, $file) = @_;
  # TODO: implement config loading
  return {};
}

1;
