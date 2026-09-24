## @file    <t/generator.t>
## @author  <wakaranakattari@gmail.com>
## @info    <tests for code generator>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-09-23>

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use WPDCS::Generator;

my $gen = WPDCS::Generator->new();
isa_ok($gen, 'WPDCS::Generator');

is($gen->comment_for_file('a.pl'), '##', 'pl prefix');
is($gen->comment_for_file('a.cljs'), ';;', 'cljs prefix');
is($gen->comment_for_file('Makefile'), '##', 'makefile prefix');

my $dir = tempdir(CLEANUP => 1);

## \ <header preserves shebang, uses 0.1.0 for new files>
{
  my $f = "$dir/s.pl";
  open my $fh, '>', $f or die;
  print $fh "#!/usr/bin/env perl\nuse strict;\n";
  close $fh;
  $gen->generate_header($f);
  open $fh, '<', $f or die;
  my @l = <$fh>;
  close $fh;
  like($l[0], qr/^#!/, 'shebang stays first');
  like($l[1], qr/\@file/, 'header follows shebang');
  like(join('', @l), qr/\@version <0\.1\.0>/, 'new-file version 0.1.0');
  ## @secinfo <idempotent>
  $gen->generate_header($f);
  open $fh, '<', $f or die;
  my $n = grep { /\@file/ } <$fh>;
  close $fh;
  is($n, 1, 'header not duplicated');
}

## \ <funcinfo skeleton infers params + return, multiline subs supported>
{
  my $f = "$dir/m.pl";
  open my $fh, '>', $f or die;
  print $fh "sub\nmyfunc\n{\n  my (\$a, \$b) = \@_;\n}\n";
  close $fh;
  $gen->generate_funcinfo($f);
  open $fh, '<', $f or die;
  my $c = do { local $/; <$fh> };
  close $fh;
  like($c, qr/\@funcinfo <todo: describe myfunc>/, 'funcinfo inserted');
  like($c, qr/\@param <a: any - todo>/, 'param a inferred');
  like($c, qr/\@param <b: any - todo>/, 'param b inferred');
  like($c, qr/\@return <any - todo>/, 'return skeleton');
  ## @secinfo <second run is a no-op>
  $gen->generate_funcinfo($f);
  open $fh, '<', $f or die;
  my $count = () = do { local $/; <$fh> } =~ /\@funcinfo/g;
  close $fh;
  is($count, 1, 'no duplicate skeleton');
}

## \ <signature params on one line>
{
  my $f = "$dir/sig.pl";
  open my $fh, '>', $f or die;
  print $fh "sub greet (\$name) {\n}\n";
  close $fh;
  $gen->generate_funcinfo($f);
  open $fh, '<', $f or die;
  my $c = do { local $/; <$fh> };
  close $fh;
  like($c, qr/\@param <name: any - todo>/, 'signature param inferred');
}

## \ <clojure defn>
{
  my $f = "$dir/a.clj";
  open my $fh, '>', $f or die;
  print $fh "(ns foo)\n(defn bar [x y]\n  x)\n";
  close $fh;
  $gen->generate_funcinfo($f);
  open $fh, '<', $f or die;
  my $c = do { local $/; <$fh> };
  close $fh;
  like($c, qr/;; \@funcinfo <todo: describe bar>/, 'defn documented with ;;');
  like($c, qr/\@param <x: any - todo>/, 'clj param inferred');
}

## \ <docs group correctly: no shifted descriptions>
{
  my $f = "$dir/d.pl";
  open my $fh, '>', $f or die;
  print $fh <<'EOF';
## @file <d.pl>
## @see <other.pl>
## @funcinfo <does foo>
## @param <x: int - input>
## @return <int - output>
## @ex <foo(1) => 2>
sub foo { my ($x) = @_; return $x + 1; }
EOF
  close $fh;
  $gen->generate_docs($f);
  open $fh, '<', "$dir/d.md" or die;
  my $md = do { local $/; <$fh> };
  close $fh;
  like($md, qr/## foo\n\n\Qdoes foo\E/, 'description under right heading');
  like($md, qr/- \*\*see:\*\* \[other\.pl\]\(other\.md\)/, 'header see rendered as link');
  unlike($md, qr/function-\d/, 'no generic headings');
}

## \ <create_project validation>
{
  eval { $gen->create_project('bad name!') };
  ok($@, 'bad project name rejected');
  require Cwd;
  my $cwd = Cwd::getcwd();
  chdir $dir or die;
  $gen->create_project('proj');
  chdir $cwd or die;
  ok(-f "$dir/proj/src/main.pl", 'main.pl created');
  ok(-f "$dir/proj/.wpdcsrc", 'config created');
}

done_testing();
