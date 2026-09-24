## @file    <t/checker.t>
## @author  <wakaranakattari@gmail.com>
## @info    <tests for tag checker>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-09-23>

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use WPDCS::Checker;

## @funcinfo <write tempfile with content>
## @param <content: str - file body>
## @return <str - temp path>
sub write_tmp {
  my ($content) = @_;
  my ($fh, $file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
  print $fh $content;
  close $fh;
  return $file;
}

my $good = <<'EOF';
## @file    <a.pl>
## @author  <me>
## @info    <demo>
EOF

{
  my $f = write_tmp($good);
  my $c = WPDCS::Checker->new(required => [qw(file author info)]);
  my $r = $c->check_file($f);
  ok($r->{ok}, 'good file ok');
  is($c->print_result($r), 0, 'print returns 0');
}

{
  my $f = write_tmp("## \@file <a.pl>\n");
  my $c = WPDCS::Checker->new(required => [qw(file author info)]);
  my $r = $c->check_file($f);
  ok(!$r->{ok}, 'missing tags fail');
  is_deeply($r->{missing}, [qw(author info)], 'missing listed');
  is($c->print_result($r), 1, 'print returns 1');
}

{
  my $f = write_tmp("## \@file bare.pl\n## \@author <me>\n## \@info <x>\n");
  my $c = WPDCS::Checker->new(required => [qw(file author info)]);
  my $r = $c->check_file($f);
  ok(!$r->{ok}, 'unbracketed fails');
  is(scalar(@{$r->{malformed}}), 1, 'one malformed');
}

{
  ## @secinfo <repeatable tags are not duplicates; header tags are>
  my $f = write_tmp(<<'EOF');
## @file <a.pl>
## @file <b.pl>
## @funcinfo <one>
## @funcinfo <two>
## @info <x>
EOF
  my $c = WPDCS::Checker->new(required => [qw(file info)]);
  my $r = $c->check_file($f);
  is(scalar(@{$r->{duplicates}}), 1, 'only file flagged duplicate');
  like($r->{duplicates}[0], qr/^file/, 'duplicate is file');
}

{
  my $f = write_tmp("## \@file <a.pl>\n## \@frobnicate <x>\n");
  my $c = WPDCS::Checker->new(required => [qw(file)]);
  my $r = $c->check_file($f);
  is(scalar(@{$r->{unknown}}), 1, 'unknown tag reported');
  ok($r->{ok}, 'unknown does not fail by default');
}

{
  my $f = write_tmp("## \@file <a.pl>\n## \@frobnicate <x>\n");
  my $c = WPDCS::Checker->new(required => [qw(file)], strict => 1);
  my $r = $c->check_file($f);
  ok(!$r->{ok}, 'strict fails on unknown');
  is($c->print_result($r), 1, 'strict print returns 1');
}

{
  my $f = write_tmp(<<'EOF');
## @funcinfo <documented>
sub foo {
}
sub bar {
}
EOF
  my $c = WPDCS::Checker->new();
  my $cov = $c->check_coverage($f);
  is($cov->{total}, 2, 'two funcs');
  is($cov->{documented}, 1, 'one documented');
  is_deeply($cov->{undocumented}, ['bar'], 'bar undocumented');
  is($cov->{pct}, 50, '50 percent');
}

done_testing();
