## @file    <t/cli.t>
## @author  <wakaranakattari@gmail.com>
## @info    <tests for cli commands>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-09-23>

##     <tuse strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

my $BIN = 'bin/wpdcs';

## @funcinfo <run cli and capture output>
## @param <args: array - cli arguments>
## @return <array - (exit code, output)>
sub run {
  my (@args) = @_;
  my $cmd = join(' ', 'perl', '-Ilib', $BIN, map { "'$_'" } @args);
  my $out = `$cmd 2>&1`;
  return ($? >> 8, $out);
}

{
  my ($code, $out) = run('version');
  is($code, 0, 'version exits 0');
  like($out, qr/wpdcs \d+\.\d+/, 'version printed');
}

{
  my ($code, $out) = run('help');
  is($code, 0, 'help exits 0');
  like($out, qr/usage/, 'help text');
}

{
  my ($code, $out) = run('parse', 'examples/perl/calc.pl');
  is($code, 0, 'parse exits 0');
  like($out, qr/funcinfo/, 'parse shows tags');
}

{
  my ($code) = run('check', 'examples/perl/calc.pl');
  is($code, 0, 'check good file exits 0');
}

{
  my ($code) = run('lint', 'examples/perl/calc.pl');
  is($code, 0, 'lint clean exits 0');
}

{
  my ($code, $out) = run('test', 'examples/perl/calc.pl');
  is($code, 0, 'doctest exits 0');
  like($out, qr/doctests ok/, 'doctest ok');
}

{
  my ($code, $out) = run('--json', 'stats', 'examples/perl/calc.pl');
  is($code, 0, 'json stats exits 0');
  like($out, qr/"funcs"/, 'json has funcs');
}

{
  ## @secinfo <recursive dir argument>
  my ($code, $out) = run('check', 'examples/perl');
  is($code, 0, 'dir recursion works');
}

{
  my ($code) = run('bogus-cmd');
  isnt($code, 0, 'unknown command fails');
}

{
  my ($code, $out) = run('help', 'check');
  is($code, 0, 'help topic exits 0');
  like($out, qr/check/, 'help topic text');
}

{
  my ($code, $out) = run('completion', 'bash');
  is($code, 0, 'bash completion exits 0');
  like($out, qr/complete/, 'bash completion script');
  ($code, $out) = run('completion', 'zsh');
  is($code, 0, 'zsh completion exits 0');
}

{
  my ($code, $out) = run('check', '--strict', 'examples/perl/calc.pl');
  is($code, 0, 'strict passes on clean file');
}

{
  ## @secinfo <docs --out collects plus index>
  use File::Temp qw(tempdir);
  my $dir = tempdir(CLEANUP => 1);
  my ($code) = run('docs', 'examples/perl/calc.pl', '--out', "$dir/out");
  is($code, 0, 'docs --out exits 0');
  ok(-f "$dir/out/calc.md", 'doc collected in out dir');
  ok(-f "$dir/out/index.md", 'index generated');
}

{
  my ($code, $out) = run('changelog', 'examples/perl/calc.pl');
  is($code, 0, 'changelog exits 0');
  like($out, qr/# Changelog/, 'changelog header');
}

done_testing();
