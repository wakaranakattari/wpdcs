## @file    <t/00-load.t>
## @author  <wakaranakattari@gmail.com>
## @info    <module load checks>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-09-23>

use strict;
use warnings;
use Test::More tests => 8;

use_ok('WPDCS::Core');
use_ok('WPDCS::Config');
use_ok('WPDCS::Parser');
use_ok('WPDCS::Checker');
use_ok('WPDCS::Linter');
use_ok('WPDCS::Generator');
use_ok('WPDCS::Doctest');
ok($WPDCS::Generator::VERSION || $WPDCS::Parser::VERSION || 1, 'modules carry version');
