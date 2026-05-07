## @file      user-auth.pl
## @author    <wakaranakattari@gmail.com>
## @infofile  <User authentication module>
## @license   GPL 3.0
## @version   1.0-SNAP
## @since     2026-05-07

use strict;
use warnings;

use v5.35;

my $VALID_USER     = "wakaranakattari";
my $VALID_PASSWORD = "123456789";

## @funcinfo          <Validate user credentials>
## @excode-normalmode < check_auth("wakaranakattari", "123456789") => 1 />
## @excode-exmode     < check_auth("wrong", "pass") => 0 />
sub 
check_auth
{
  my     ($username, $password) = @_;
  
  return 1 if $username eq $VALID_USER && $password eq $VALID_PASSWORD;
  return 0;
}

## @funcinfo <Get welcome message for user>
## @excode   < get_welcome("wakaranakattari") => "Welcome, wakaranakattari!" />
sub 
get_welcome
{
  my     ($username) = @_;
  return "Welcome, $username!";
}

## @secinfo <Test authentication>
if (check_auth("wakaranakattari", "123456789")) {
  say get_welcome("wakaranakattari");
} else {
  say "Access denied";
}
