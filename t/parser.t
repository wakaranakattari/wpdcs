## @file    <t/parser.t>
## @author  <wakaranakattari@gmail.com>
## @info    <tests for tag parser>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-09-23>

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);

use WPDCS::Parser;

my $parser = WPDCS::Parser->new();
isa_ok($parser, 'WPDCS::Parser');

## \ <known tags>
ok(WPDCS::Parser->is_known('param'), 'param is known');
ok(WPDCS::Parser->is_known('ex-fail'), 'ex-fail is known');
ok(!WPDCS::Parser->is_known('nonsense'), 'nonsense is unknown');

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

## \ <basic + hyphenated + arrow values>
{
  my $f = write_tmp(<<'EOF');
## @file    <a.pl>
## @author  <me>
## @ex <add(1, 2) => 3>
## @excode-normalmode <div(1, 2) => 0.5>
## @ex-fail <div(1, 0) => undef>
EOF
  my $tags = $parser->parse_file($f);
  is(scalar(@$tags), 5, 'five tags parsed');
  is($tags->[2]{tag}, 'ex', 'ex tag');
  is($tags->[2]{value}, 'add(1, 2) => 3', 'arrow value preserved');
  is($tags->[3]{tag}, 'excode-normalmode', 'hyphen tag parsed');
  is($tags->[4]{value}, 'div(1, 0) => undef', 'ex-fail value');
}

## \ <bare value is parsed but flagged unbracketed>
{
  my $f = write_tmp("## \@file bare.pl\n");
  my $tags = $parser->parse_file($f);
  is($tags->[0]{value}, 'bare.pl', 'bare value captured');
  ok(!$tags->[0]{bracketed}, 'bare flagged unbracketed');
}

## \ <inline tag after code>
{
  my $f = write_tmp("(ns foo) ;; \@info <inline note>\n");
  my $tags = $parser->parse_file($f);
  is(scalar(@$tags), 1, 'inline tag found');
  is($tags->[0]{value}, 'inline note', 'inline value');
}

## \ <quoted ## inside a plain comment is not a tag>
{
  my $f = write_tmp("# note \"## \@file fake\"\n## \@file <real.pl>\n");
  my $tags = $parser->parse_file($f);
  is(scalar(@$tags), 1, 'quoted tag ignored');
  is($tags->[0]{value}, 'real.pl', 'real tag kept');
}

## \ <legacy section markers>
{
  my ($fh, $f) = tempfile(SUFFIX => '.cljs', UNLINK => 1);
  print $fh ";; \@secstart->\@secname <ns>\n;; \@secend->\@secname <ns>\n";
  close $fh;
  my $tags = $parser->parse_file($f);
  is($tags->[0]{tag}, 'secstart', 'secstart parsed');
  is($tags->[0]{value}, 'ns', 'secstart value');
  is($tags->[1]{tag}, 'secend', 'secend parsed');
}

## \ <blocks: header @see before first funcinfo stays header-level>
{
  my $f = write_tmp(<<'EOF');
## @file <a.pl>
## @see <other.pl>
## @funcinfo <does x>
## @param <x: int - input>
## @return <int - output>
EOF
  my $tags = $parser->parse_file($f);
  my $blocks = $parser->parse_blocks($f, $tags);
  my @func = grep { !$_->{header} } @$blocks;
  is(scalar(@func), 1, 'one func block');
  is(scalar(@{$func[0]{tags}}), 3, 'funcinfo+param+return grouped');
  my @hdr = grep { $_->{header} } @$blocks;
  is(scalar(@hdr), 2, 'file + see stay header-level');
}

## \ <missing file dies>
{
  eval { $parser->parse_file('/no/such/file.pl') };
  ok($@, 'missing file dies');
}

done_testing();
