package WPDCS::Parser;
## @file    <lib/WPDCS/Parser.pm>
## @author  <wakaranakattari@gmail.com>
## @info    <parse WPDCS tags from files>

use strict;
use warnings;
use v5.35;

## @funcinfo <constructor>
sub 
new
{
  my     ($class) = @_;
  return bless {}, $class;
}

## @funcinfo <parse file and return arrayref of tags>
## @excode   <my $tags = $parser->parse_file("calc.pl")>
sub 
parse_file
{
  my     ($self, $file) = @_;
  open my $fh, '<', $file or return [];

  my @tags;

  while (<$fh>)
  {
    if (/^(##|;;)\s+\@(\w+)\s+<(.*?)>/)
    {
      push @tags, {
        tag   => $2,
        value => $3,
        line  => $.,
        type  => $1,
      };
    }
  }

  close $fh;
  return \@tags;
}

## @funcinfo <print tags in human-readable format>
sub 
print_tags
{
  my     ($self, $tags) = @_;
  for my $tag (@$tags)
  {
    printf "%-12s: %s\n", $tag->{tag}, $tag->{value};
  }
}

1;
