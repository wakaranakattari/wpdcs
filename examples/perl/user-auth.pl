## @file    <user-auth.pl>
## @author  <wakaranakattari@gmail.com>
## @info    <user authentication module>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-05-07>
## @see     <examples/perl/calc.pl>

use strict;
use warnings;
use v5.34;

## @info <demo credentials only, dont use in production>
my $VALID_USER     = "wakaranakattari";
my $VALID_PASSWORD = "123456789";

## @funcinfo <validate user credentials>
## @param <username: str - login name>
## @param <password: str - plaintext password, demo only>
## @return <bool - 1 on match, 0 otherwise>
## @ex <check_auth("wakaranakattari", "123456789") => 1>
## @ex-fail <check_auth("wrong", "pass") => 0>
sub check_auth {
  my ($username, $password) = @_;

  return 1 if $username eq $VALID_USER && $password eq $VALID_PASSWORD;
  return 0;
}

## @funcinfo <get welcome message for user>
## @param <username: str - user to greet>
## @return <str - welcome message>
## @ex <get_welcome("wakaranakattari") => "Welcome, wakaranakattari!">
sub get_welcome {
  my ($username) = @_;
  return "Welcome, $username!";
}

## @secinfo <test authentication>
if (check_auth("wakaranakattari", "123456789")) {
  say get_welcome("wakaranakattari");
}
else {
  say "Access denied";
}
