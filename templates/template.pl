## @file      template.pl
## @author    <your@email.com>
## @infofile  <short description>
## @license   GPL 3.0
## @version   1.0-SNAP
## @docs      </docs/path/>
## @since     2026-05-07

use strict;
use warnings;

use v5.35;

## @funcinfo <function description>
## @excode   < example />
sub 
function_name
{
  my     ($param) = @_;
  return $param;
}

## @secinfo <main>
my $result = function_name("test");
say $result;
