# WPDCS - My Perl Style Guide

**Wakaranakattari Perl Docs and Code Style** - My personal standart for writing Perl code

## Main rules

### File always starting with a cap:

```perl
# @file       script.pl
## @author    <email@example.com>
## @infofile  <Information for file...>
## @license   GPL 3.0
## @version   1.0-SNAP
## @docs      <path to docs>
## @since     YYYY-MM-DD
```

### Functions are written vertically:
```perl
sub
name
{
  my     ($param1, $param2) = @_;
  return $result;
}
```

### Each function has documentation:
```perl
## @funcinfo <function info>
## @excode < example code />
```

### Code sections are separated:
```perl
## @secinfo <section info>
```

## Full examples:

(Calculator)[github.com/wakaranakattari/wpdcs/examples/calc.pl]
(Authentication)[github.com/wakaranakattari/wpdcs/examples/user-auth.pl]

## Template for new scripts
```perl
## @file     script.pl
## @author   <your@email.com>
## @infofile <description>
## @license  GPL 3.0
## @version  1.0-SNAP
## @since    2026-05-07

use strict;
use warnings;
use v5.35;

## @funcinfo <function description>
## @excode < example />
sub 
function_name
{
  my     ($arg) = @_;
  return $arg;
}

## @secinfo <main>
say function_name("test");
```

## How to use
```bash

# 1. Create project directory
mkdir my-perl-project
cd my-perl-project

# 2. Copy templates for new script
cp /path/to/wpdcs/templates/template.pl myscript.pl

# 3. Edit to suit your needs
vim/nvim/emacs/code myscript.pl

# 4. See examples if necessary
less /path/to/wpdcs/examples/calc.pl
```
