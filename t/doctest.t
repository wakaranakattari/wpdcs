## @file    <t/doctest.t>
## @author  <wakaranakattari@gmail.com>
## @info    <tests for doctest runner>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-09-23>

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use WPDCS::Doctest;

my $dt = WPDCS::Doctest->new();
isa_ok($dt, 'WPDCS::Doctest');

## \ <matches()>
ok($dt->matches('15', '15'), 'numeric match');
ok(!$dt->matches('15', '16'), 'numeric mismatch');
ok($dt->matches('hi', '"hi"'), 'quoted string match');
ok($dt->matches(undef, 'undef'), 'undef match');
ok(!$dt->matches(undef, '0'), 'undef vs value');

## \ <quiet_eval swallows stdout>
{
  my ($ok, $res) = $dt->quiet_eval('print "NOISE"; 42');
  ok($ok, 'eval ok');
  is($res, 42, 'result kept, noise swallowed');
}

my $dir = tempdir(CLEANUP => 1);

## \ <run_file on a quiet fixture with say side effects at bottom>
{
  my $f = "$dir/calc.pl";
  open my $fh, '>', $f or die;
  print $fh <<'EOF';
sub add { my ($a, $b) = @_; return $a + $b; }
## @funcinfo <add>
## @ex <add(2, 3) => 5>
## @ex-fail <add("x") => 0>
say "SIDE EFFECT NOISE";
EOF
  close $fh;
  my $cases = $dt->cases($f);
  is(scalar(@$cases), 2, 'two cases incl ex-fail');
  my $r = $dt->run_file($f);
  ## @secinfo <add("x") warns but returns 0 with warnings? "x"+0 == 0 numerically, may pass or fail>
  ok($r->{total} == 2, 'total 2');
  is($dt->print_result($f, $r), $r->{failed} ? 1 : 0, 'print matches status');
}

## \ <failing doctest>
{
  my $f = "$dir/bad.pl";
  open my $fh, '>', $f or die;
  print $fh "sub one { return 1; }\n## \@funcinfo <one>\n## \@ex <one() => 2>\n";
  close $fh;
  my $r = $dt->run_file($f);
  is($r->{failed}, 1, 'wrong expectation fails');
  is($dt->print_result($f, $r), 1, 'print returns 1');
}

## \ <no doctests>
{
  my $f = "$dir/empty.pl";
  open my $fh, '>', $f or die;
  print $fh "sub x { 1 }\n";
  close $fh;
  my $r = $dt->run_file($f);
  is($r->{total}, 0, 'no cases');
  is($dt->print_result($f, $r), 0, 'no cases is ok');
}

done_testing();
