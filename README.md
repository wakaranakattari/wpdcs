# WPDCS - Code Style & Documentation Toolchain

**Wakaranakattari Perl Docs and Code Style** - A tool to enforce consistent code style and generate documentation.

Supports **Perl**, **Clojure** and **ClojureScript**.

---

## Installation

```bash
git clone https://github.com/wakaranakattari/wpdcs
cd wpdcs
make install-user
export PATH="$HOME/.local/bin:$PATH"
```

### System-wide install (requires sudo):
```bash
sudo make install
```

## Quick Start
```bash
# Create a new project
wpdcs create my-app
cd my-app

# Add header to file
wpdcs gen header src/main.pl

# Check style
wpdcs lint src/main.pl

# Generate documentation
wpdcs docs src/main.pl
```

## Commands
| Command | Description |
| :--- | :--- |
| `wpdcs parse <file>` | Show all WPDCS tags |
| `wpdcs check <file>` | Validate required tags (file, author, info) |
| `wpdcs init [dir]` | Create `.wpdcsrc` and `examples/` folder |
| `wpdcs create <name>` | Create new project with cargo-like structure |
| `wpdcs gen header <file>` | Add WPDCS header to file |
| `wpdcs gen funcinfo <file>` | Add `@funcinfo` before functions |
| `wpdcs lint <file>` | Check style (whitespace, tabs, tags) |
| `wpdcs format <file>` | Auto-format code |
| `wpdcs docs <file>` | Generate Markdown documentation |
| `wpdcs version` | Show version |
| `wpdcs help` | Show this help |

## Supported Languages
| Language | Extension | Comment symbol |
| :--- | :--- | :--- |
| Perl | `.pl`, `.pm` | `##` |
| Clojure / ClojureScript | `.clj`, `.cljs` | `;;` |

## Example
### Input (main.pl)
```perl
## @file    <main.pl>
## @author  <dev@example.com>
## @info    <main entry point>

use strict;
use warnings;
use v5.35;

sub greet {
    say "Hello";
}
```

### After wpdcs gen funcinfo main.pl
```perl
## @file    <main.pl>
## @author  <dev@example.com>
## @info    <main entry point>

use strict;
use warnings;
use v5.35;

## @funcinfo <TODO: describe greet>
sub greet {
    say "Hello";
}
```

### After wpdcs docs main.pl
#### Generates main.md:
```perl
# Documentation for main.pl

## Function

**Description:** TODO: describe greet
```

## Philosophy
- Consistency - Same style across all your projects
- Portability - Same tags work for Perl, Clojure, and D (planned)
- Documentation as code - Docs live right next to functions
- Automation - Generate docs, add headers, check style with one command

## Uninstall
```bash
sudo make uninstall          # system-wide
rm -rf ~/.local/bin/wpdcs    # user install
rm -rf ~/.local/lib/WPDCS
```
