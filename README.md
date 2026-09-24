# WPDCS - Code Style & Documentation Toolchain

![version](https://img.shields.io/badge/version-2.0.0-blue)
![license](https://img.shields.io/badge/license-GPL--3.0--or--later-green)
![perl](https://img.shields.io/badge/perl-%3E%3D5.35-orange)
![ci](https://github.com/wakaranakattari/wpdcs/actions/workflows/ci.yml/badge.svg)

**Wakaranakattari Perl Docs and Code Style** — one binary to enforce comment-tag style,
run `@ex` examples as doctests, and generate markdown docs. Supports **Perl**
(`.pl`, `.pm`, `.t`) and **Clojure/ClojureScript** (`.clj`, `.cljs`, `.cljc`),
plus `Makefile` targets.

No CPAN dependencies: only core modules (`JSON::PP`, `File::Path`, `POSIX`,
`Test::More`) and perl `>= 5.35`. Git is optional (needed for `--staged` and hooks).

---

## Contents

- [Features](#features)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Command reference](#command-reference)
- [Global flags](#global-flags)
- [Tag standard v2.0](#tag-standard-v20)
- [House style](#house-style)
- [Configuration](#configuration)
- [Doctests](#doctests)
- [Documentation generation](#documentation-generation)
- [Testing](#testing)
- [Project structure](#project-structure)
- [Packaging and manual](#packaging-and-manual)
- [CI, hooks and completion](#ci-hooks-and-completion)
- [Philosophy](#philosophy)
- [Roadmap](#roadmap)
- [Uninstall](#uninstall)
- [License](#license)

---

## Features

- `parse` / `check` / `lint` / `format` over files **or directories** (recursive,
  honours `exclude_dirs`, symlink-safe)
- executable doctests from `@ex` tags with smart value compare (numbers,
  quoted strings, `undef`, failure cases)
- `stats` — functions, doc coverage and doctest counts per file and total
- `gen header` (shebang-safe), `gen funcinfo` (signature-aware `@param`
  inference for perl subs and clojure `defn`), `gen test` (`.t` skeletons)
- `docs` grouped per function with real names, `@see` links and optional
  `--out DIR` + `index.md`; `changelog` from version tags
- `--json` output for every read command, `--staged` for git workflows,
  `--strict` gates, `nolint` suppressions
- 142 unit tests, CI on three perl versions, man page, `META.json`

---

## Installation

### User install (recommended)

```bash
git clone https://github.com/wakaranakattari/wpdcs
cd wpdcs
make install-user
export PATH="$HOME/.local/bin:$PATH"
export PERL5LIB="$HOME/.local/share/perl5:$PERL5LIB"
wpdcs version   # expect: wpdcs 2.0.0
```

### System-wide install (needs sudo)

```bash
sudo make install
```

### From release tarball

```bash
tar -xzf wpdcs-2.0.0.tar.gz
cd wpdcs-dist
make install-user   # or: sudo make install
```

### Verify

```bash
wpdcs help
man wpdcs   # after install
```

---

## Quick start

```bash
# create a new project
wpdcs create my-app
cd my-app

# add header to file
wpdcs gen header src/main.pl

# document functions (infers @param from signatures)
wpdcs gen funcinfo src/main.pl

# check style + tags
wpdcs lint src/main.pl

# run doctests from @ex tags
wpdcs test src/main.pl

# coverage overview
wpdcs stats src

# generate documentation
wpdcs docs src/main.pl
```

---

## Command reference

### `wpdcs parse <path...>`

Print every tag with line numbers. Hyphenated names, `=>` inside values,
inline tags after code and legacy `secstart->secname` markers all parse.

```bash
wpdcs parse src/main.pl
wpdcs parse src/                  # recursive
wpdcs --json parse src/           # machine-readable
```

### `wpdcs check <path...>`

Validate required header tags from `.wpdcsrc` (`file, author, info, license,
version, since` by default). Reports `missing:`, `malformed:`, `duplicate:`
and `unknown tag:` lines. Exit non-zero on failure; unknown tags fail only
with `--strict` or `strict: 1` in config.

```bash
wpdcs check src/main.pl
wpdcs check --strict src/
```

### `wpdcs lint <path...>`

Rules: trailing whitespace, tab characters (never flagged in `Makefile`
recipes), CRLF endings, line length (`max_length`, default 120), tag format
(`@tag <value>`, `@param <name: type - desc>`), known-tag names, newline at
EOF. Whole-file opt-out with `## @nolint <all>` in the first 5 lines,
per-line opt-out with a trailing `wpdcs:nolint` marker.

```bash
wpdcs lint src/
wpdcs lint --staged   # only git staged files
```

### `wpdcs format <path...>`

In-place rewrite: strip trailing whitespace, expand tabs to 4 spaces, ensure
single trailing newline. No backup files — commit first.

### `wpdcs docs <path...> [--out DIR]`

One `.md` per source file, functions in definition order with real names.
With `--out DIR` all pages collect into `DIR` plus an `index.md`.

```bash
wpdcs docs src/main.pl
wpdcs docs src/ --out docs/
```

### `wpdcs test <path...>`

Execute `@ex` / `@ex-fail` cases (perl only). Values compare smartly:
`15` vs `15`, `"hi"` vs `hi`, `undef` vs empty return, and `ex-fail` passes
when the expression dies. Loading a file is stdout-silent. Clojure files
report their case count and skip (no js runtime bundled).

```bash
wpdcs test src/
```

> Safety note: doctests `eval` your source. Run `wpdcs test` only on code
> you trust, same as running the code itself.

### `wpdcs stats <path...>`

```text
files:      7
tags:       226
functions:  41 (documented 41, 100%)
doctests:   38
```

### `wpdcs changelog <path...> [--out FILE]`

Builds a changelog skeleton from `@version` / `@since` / `@deprecated`
tags, printed or written with `--out`.

### `wpdcs init [dir]` / `wpdcs create <name>`

`init` drops `.wpdcsrc`, `examples/`, `t/`, `docs/` into an existing dir.
`create` scaffolds `src/main.pl`, `.wpdcsrc`, `t/basic.t`, `README.md`.
Names match `[A-Za-z0-9][A-Za-z0-9_-]*`, new files start at version `0.1.0`.

### `wpdcs gen header|funcinfo|test`

- `header` — prepends the six-tag header; existing headers (any `@file` in
  the first 10 lines) are left alone; `#!/...` stays line 1.
- `funcinfo` — inserts `funcinfo` + `param` + `return` skeletons before
  undocumented perl `sub` (single-line, signature and legacy `sub`-newline
  styles) and clojure `defn`. Params come from signatures, `my (...) = @_`
  or arg vectors. Idempotent.
- `gen test <file>` — writes a `.t` file from the source's `@ex` cases.

### `wpdcs hook install` / `wpdcs completion` / `wpdcs help` / `wpdcs version`

`hook install` writes `.git/hooks/pre-commit` running `lint --staged` and
`check --staged`. `completion bash|zsh` prints a completion script.
`help [command]` shows per-command usage.

---

## Global flags

| Flag | Effect |
| :--- | :--- |
| `--json` | JSON output for `parse check lint test stats version` |
| `--staged` | use git staged files instead of `<path...>` |
| `--strict` | unknown tags fail `check` (overrides config) |
| `--out DIR\|FILE` | output dir/file for `docs` and `changelog` |

---

## Tag standard v2.0

Comment markers: `##` (perl, make), `;;` (clojure). Single `#` never opens
a tag. Tag names match `[\w-]+`; values live in `<...>` and may contain `=>`.

### Header tags (required by default)

| Tag | Meaning |
| :--- | :--- |
| `file` | file name |
| `author` | contact |
| `info` | one-line description |
| `license` | e.g. `gpl 3.0` |
| `version` | file version |
| `since` | date the file appeared |

### Function tags

| Tag | Meaning |
| :--- | :--- |
| `funcinfo` | what the function does |
| `param` | `<name: type - desc>` |
| `return` | `<type - desc>` |
| `throws` | when it dies |
| `complexity` | e.g. `o(n)` |
| `see` | cross reference, becomes a link when it points at a source file |
| `deprecated` | what to use instead |
| `todo` | open work item |
| `test` | related test path |

### Example tags (executable, see [Doctests](#doctests))

| Tag | Meaning |
| :--- | :--- |
| `ex` | `<expr => expected>` |
| `ex-fail` | `<expr => value>` or dies |
| `excode`, `excode-normalmode`, `excode-exmode` | legacy aliases, still parsed |

### Structural tags

`secinfo` (free section), `secstart` / `secend` (legacy
`@secstart->@secname` form still parsed), `docs` (free note),
`nolint` (`<all>` for whole-file lint opt-out).

---

## House style

Enforced by `lint`, produced by `gen`:

- every comment lives inside a tag — no bare `#` explanations
- prose inside tags is lowercase with no apostrophes (`dont`, not `don't`)
- code, paths, emails and versions keep exact form (`add(10, 5)`,
  `lib/WPDCS/Parser.pm`, `dev@example.com`, `2.0.0`)
- 2-space indent for perl blocks, tabs expand to 4 spaces
- max 120 chars per line, LF endings, one newline at EOF
- K&R `sub name {` for new code (legacy split style still parses)

---

## Configuration

`.wpdcsrc` (see `.wpdcsrc.example`), auto-discovered upward from the
working dir:

```yaml
## @info <wpdcs configuration>
language: perl
required_tags:
  - file
  - author
  - info
  - license
  - version
  - since
exclude_dirs:
  - .git
  - t
  - docs
max_length: 120
strict: 0
```

CLI `--strict` beats config `strict`; `lint`/`format` honour `max_length`.

---

## Doctests

Write examples you can run:

```perl
## @funcinfo <addition of two numbers>
## @param <num1: num - first operand>
## @param <num2: num - second operand>
## @return <num - sum>
## @ex <add(10, 5) => 15>
## @ex-fail <div(10, 0) => undef>
sub add {
  my ($num1, $num2) = @_;
  return $num1 + $num2;
}
```

```bash
wpdcs test calc.pl          # doctests ok in calc.pl: 5/5 passed
wpdcs gen test src/calc.pl  # t/calc.t skeleton from the same cases
```

`ex-fail` passes when the expression dies **or** returns the documented
value. Only the last `=>` splits expression from expectation, so inner
arrows survive.

---

## Documentation generation

`wpdcs docs` groups tags per function (`funcinfo` opens a block; header
tags before the first one stay file-scoped, so names never shift), renders
params/returns/examples/complexity, links `@see` file paths to their pages,
and keeps `secinfo` sections in file order:

```bash
wpdcs docs src/main.pl            # src/main.md next to source
wpdcs docs src/ --out docs/       # docs/*.md + docs/index.md
```

Tip: commit with `--out docs/` to keep generated pages out of `src/`.

---

## Testing

```bash
prove -Ilib t/     # 142 unit tests: parser, checker, linter,
                   # config, core, doctest, generator, cli
make test          # prove + CLI smoke tests (check/lint/parse/doctests/stats)
```

Test files follow the same tag standard (`@file`, `@secinfo` sections).

---

## Project structure

```text
bin/wpdcs            # cli: parse/check/lint/format/docs/test/stats/...
lib/WPDCS/
  Parser.pm          # tag parsing, known tags, per-function blocks
  Checker.pm         # required/malformed/duplicate/unknown + coverage
  Linter.pm          # style rules + format
  Generator.pm       # header/funcinfo/docs/test/index generation
  Doctest.pm         # @ex extraction + sandboxed quiet runner
  Config.pm          # .wpdcsrc loading
  Core.pm            # file io + recursive symlink-safe collector
t/                   # unit + cli tests
examples/            # perl + clojurescript samples in v2 style
man/wpdcs.1          # manual page
.github/workflows/  # ci on perl 5.34 / 5.36 / 5.38
```

---

## Packaging and manual

```bash
make dist          # wpdcs-2.0.0.tar.gz (bin, lib, man, t, examples)
man wpdcs          # installed manual page
```

Distribution metadata lives in `META.json`, history in `Changes`,
license in `LICENSE` (`gpl-3.0-or-later`).

---

## CI, hooks and completion

CI runs `prove`, `make test` and self-lint on three perl versions
(see `.github/workflows/ci.yml`). Locally:

```bash
wpdcs hook install              # pre-commit: lint + check staged files
wpdcs lint --staged             # same check by hand
eval "$(wpdcs completion bash)" # or: zsh
```

---

## Philosophy

- Consistency — same style across all your projects
- Portability — same tags for perl and clojure/clojurescript
- Documentation as code — docs live next to functions
- Tests as docs — `@ex` examples are executable
- Automation — docs, tests, headers and stats with one command

---

## Roadmap

- clojure doctests via an external runtime (currently counted + skipped)
- HTML docs site from the same tags
- changelog enrichment (breaking-change detection from signatures)
- language-server highlighting for tags (out of scope for the cli itself)

---

## Uninstall

```bash
sudo make uninstall          # system-wide
make uninstall-user          # user install
```

---

## License

`GPL-3.0-or-later`, see `LICENSE`. Copyright 2026 wakaranakattari
<wakaranakattari@gmail.com>.
