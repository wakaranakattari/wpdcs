## @file    <t/linter.t>
## @author  <wakaranakattari@gmail.com>
## @info    <tests for style linter>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-09-23>

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);

use WPDCS::Linter;

## @funcinfo <write tempfile with content>
## @param <content: str - file body>
## @return <str - temp path>
sub write_tmp {
  my ($content, $suffix) = @_;
  $suffix //= '.pl';
  my ($fh, $file) = tempfile(SUFFIX => $suffix, UNLINK => 1);
  print $fh $content;
  close $fh;
  return $file;
}

my $linter = WPDCS::Linter->new();
isa_ok($linter, 'WPDCS::Linter');

is($linter->lint(write_tmp("## \@file <a.pl>\n")), 0, 'clean file passes');

is($linter->lint(write_tmp("hello   \n")), 1, 'trailing whitespace fails');

is($linter->lint(write_tmp("a\tb\n")), 1, 'tab fails');

is($linter->lint(write_tmp("## \@file oops\n")), 1, 'unbracketed tag fails');

is($linter->lint(write_tmp("## \@frobnicate <x>\n")), 1, 'unknown tag fails');

is($linter->lint(write_tmp("## \@param <oops>\n")), 1, 'param without colon fails');

is($linter->lint(write_tmp("## \@param <x: int - ok>\n")), 0, 'good param passes');

{
  my $f = write_tmp("## \@frobnicate <x>  # wpdcs:nolint\n");
  is($linter->lint($f), 0, 'line nolint silences tag errors');
}

{
  my $f = write_tmp("## \@nolint <all>\n## \@frobnicate <x>\n");
  is($linter->lint($f), 0, 'file nolint skips file');
}

{
  my $f = write_tmp("x\n", '.pl');
  ## @secinfo <strip final newline>
  open my $fh, '<', $f or die;
  my $c = do { local $/; <$fh> };
  close $fh;
  $c =~ s/\n$//;
  open my $out, '>', $f or die;
  print $out $c;
  close $out;
  is($linter->lint($f), 1, 'missing EOF newline fails');
}

{
  ## @secinfo <makefiles require tabs: never flag them there>
  my $mdir = tempdir(CLEANUP => 1);
  my $mf = "$mdir/Makefile";
  open my $fh, '>', $mf or die;
  print $fh "all:\n\t\@echo hi\n";
  close $fh;
  is($linter->lint($mf), 0, 'makefile tabs allowed');
}

{
  my $f = write_tmp("hello   \n\tworld\n");
  $linter->format($f);
  open my $fh, '<', $f or die;
  my @lines = <$fh>;
  close $fh;
  is($lines[0], "hello\n", 'trailing ws stripped');
  is($lines[1], "    world\n", 'tab expanded to 4 spaces');
}

done_testing();
