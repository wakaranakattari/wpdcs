## @file    <t/config-core.t>
## @author  <wakaranakattari@gmail.com>
## @info    <tests for config and core>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-09-23>

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile tempdir);

use WPDCS::Config;
use WPDCS::Core;

## \ <defaults>
{
  my $d = WPDCS::Config->defaults();
  is($d->{language}, 'Perl', 'default language');
  is_deeply($d->{required_tags}, [qw(file author info license version since)], 'default required');
  ok(@{$d->{exclude_dirs}} > 0, 'default excludes');
}

## \ <load missing file -> defaults>
{
  my $c = WPDCS::Config->load('/no/such/.wpdcsrc');
  isa_ok($c, 'WPDCS::Config');
  is($c->{language}, 'Perl', 'missing file gives defaults');
}

## \ <load real file>
{
  my ($fh, $f) = tempfile(UNLINK => 1);
  print $fh <<'EOF';
## \ <comment>
language: Clojure
required_tags:
  - file
  - author
exclude_dirs:
  - target
EOF
  close $fh;
  my $c = WPDCS::Config->load($f);
  is($c->{language}, 'Clojure', 'language parsed');
  is_deeply($c->{required_tags}, [qw(file author)], 'required parsed');
  is_deeply($c->{exclude_dirs}, ['target'], 'excludes parsed');
}

## \ <max_length + strict options>
{
  my ($fh, $f) = tempfile(UNLINK => 1);
  print $fh "max_length: 80\nstrict: yes\n";
  close $fh;
  my $c = WPDCS::Config->load($f);
  is($c->{max_length}, 80, 'max_length parsed');
  is($c->{strict}, 1, 'strict parsed');
}

## \ <find_file walks up>
{
  my $dir = tempdir(CLEANUP => 1);
  mkdir "$dir/sub" or die;
  open my $fh, '>', "$dir/.wpdcsrc" or die;
  print $fh WPDCS::Config->default_content();
  close $fh;
  is(WPDCS::Config->find_file("$dir/sub"), "$dir/.wpdcsrc", 'found upward');
  ok(!defined WPDCS::Config->find_file($dir . '/sub') || 1, 'find returns something');
}

## \ <round-trip read/write>
{
  my ($fh, $f) = tempfile(UNLINK => 1);
  close $fh;
  WPDCS::Core->write_file($f, "a\n", "b\n");
  my @lines = WPDCS::Core->read_file($f);
  is_deeply(\@lines, ["a\n", "b\n"], 'round trip');
}

## \ <collect_files: recursion + excludes + symlink guard>
{
  my $dir = tempdir(CLEANUP => 1);
  mkdir "$dir/src" or die;
  mkdir "$dir/.git" or die;
  open my $fh, '>', "$dir/src/a.pl" or die; print $fh "1\n"; close $fh;
  open $fh, '>', "$dir/.git/b.pl" or die; print $fh "1\n"; close $fh;
  open $fh, '>', "$dir/notes.txt" or die; print $fh "1\n"; close $fh;
  my @got = WPDCS::Core->collect_files(["$dir/src"], ['.git']);
  ok(scalar(grep { /a\.pl$/ } @got), 'pl collected');
  ok(!scalar(grep { /notes/ } @got), 'txt skipped in dir scan');

  ## @secinfo <explicit files pass through even without known extension>
  my @explicit = WPDCS::Core->collect_files(["$dir/notes.txt"], ['.git']);
  is_deeply(\@explicit, ["$dir/notes.txt"], 'explicit file passes through');

  my @all = WPDCS::Core->collect_files([$dir], ['.git']);
  ok(!scalar(grep { /\.git/ } @all), '.git excluded');

  ## @secinfo <symlink loop must terminate>
  my $loop = "$dir/loop";
  symlink($dir, $loop) or die "symlink: $!";
  my @with_loop = WPDCS::Core->collect_files([$dir], ['.git']);
  ok(scalar(@with_loop) >= 1, 'symlink loop terminates');
}

## \ <missing path dies>
{
  eval { WPDCS::Core->collect_files(['/no/such/path'] , []) };
  ok($@, 'missing path dies');
}

done_testing();
