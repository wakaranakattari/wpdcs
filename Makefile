## @file    <Makefile>
## @author  <wakaranakattari@gmail.com>
## @info    <build and install wpdcs toolchain>
## @license <gpl 3.0>
## @version <2.0.0>
## @since   <2026-05-17>

PREFIX    ?= /usr/local
BINDIR    = $(PREFIX)/bin
LIBDIR    = $(PREFIX)/share/perl5
MANDIR    = $(PREFIX)/share/man/man1
PROG_NAME = wpdcs

## @secinfo <default target>
all:
	@echo "wpdcs toolchain"
	@echo ""
	@echo "targets:"
	@echo "  make install    - install wpdcs system-wide"
	@echo "  make install-user - install wpdcs for current user"
	@echo "  make uninstall  - remove wpdcs"
	@echo "  make test       - run tests"
	@echo "  make clean      - remove temporary files"
	@echo "  make dist       - create distribution tarball"

## @secinfo <install system-wide (requires sudo)>
install:
	@echo "installing wpdcs to $(PREFIX)"
	@mkdir -p $(BINDIR)
	@mkdir -p $(LIBDIR)
	@mkdir -p $(MANDIR)
	@install -m 755 bin/$(PROG_NAME) $(BINDIR)/
	@cp -r lib/* $(LIBDIR)/
	@install -m 644 man/wpdcs.1 $(MANDIR)/
	@echo "installed to $(BINDIR)/$(PROG_NAME)"
	@echo "run 'wpdcs --help' to get started"

## @secinfo <install for current user only>
install-user:
	@echo "installing wpdcs for user $(USER)"
	@mkdir -p $(HOME)/.local/bin
	@mkdir -p $(HOME)/.local/share/perl5
	@install -m 755 bin/$(PROG_NAME) $(HOME)/.local/bin/
	@cp -r lib/WPDCS $(HOME)/.local/share/perl5/
	@mkdir -p $(HOME)/.local/share/man/man1
	@install -m 644 man/wpdcs.1 $(HOME)/.local/share/man/man1/
	@echo "add to path: export PATH=$$HOME/.local/bin:$$PATH"
	@echo "add to perl5lib: export PERL5LIB=$$HOME/.local/share/perl5:$$PERL5LIB"

## @secinfo <uninstall>
uninstall:
	@echo "removing wpdcs from $(PREFIX)"
	@rm -f $(BINDIR)/$(PROG_NAME)
	@rm -rf $(LIBDIR)/WPDCS
	@rm -f $(MANDIR)/wpdcs.1
	@echo "uninstalled"

## @secinfo <uninstall user install>
uninstall-user:
	@echo "removing user wpdcs install"
	@rm -f $(HOME)/.local/bin/$(PROG_NAME)
	@rm -rf $(HOME)/.local/share/perl5/WPDCS
	@rm -f $(HOME)/.local/share/man/man1/wpdcs.1
	@echo "uninstalled"

## @secinfo <run tests>
test:
	@echo "running tests..."
	@if [ -d t ]; then prove -Ilib t/; fi
	@echo "testing check command..."
	@perl -Ilib bin/wpdcs check lib examples/perl/calc.pl examples/perl/user-auth.pl
	@echo "testing lint command..."
	@perl -Ilib bin/wpdcs lint lib bin/wpdcs examples/perl/calc.pl
	@perl -Ilib bin/wpdcs lint examples/perl/user-auth.pl examples/clojure/github.cljs Makefile
	@echo "testing parse command..."
	@perl -Ilib bin/wpdcs parse examples/perl/calc.pl > /dev/null
	@echo "testing doctests..."
	@perl -Ilib bin/wpdcs test examples/perl/calc.pl examples/perl/user-auth.pl
	@echo "testing stats..."
	@perl -Ilib bin/wpdcs stats lib > /dev/null
	@echo "all tests passed"

## @secinfo <clean temporary files>
clean:
	@echo "cleaning..."
	@find . -name "*.bak" -type f -delete
	@find . -name "*.swp" -type f -delete
	@echo "clean done"

## @secinfo <create distribution tarball>
dist:
	@echo "creating distribution..."
	@mkdir -p wpdcs-dist
	@cp -r bin lib man t examples Makefile README.md TODO.md Changes LICENSE META.json .wpdcsrc.example wpdcs-dist/
	@tar -czf wpdcs-2.0.0.tar.gz wpdcs-dist/
	@rm -rf wpdcs-dist
	@echo "created: wpdcs-2.0.0.tar.gz"

## @secinfo <help>
help:
	@echo "wpdcs toolkit"
	@echo ""
	@echo "make install        - install system-wide (sudo make install)"
	@echo "make install-user   - install for current user"
	@echo "make uninstall      - remove system-wide installation"
	@echo "make test           - run tests"
	@echo "make clean          - remove temp files"
	@echo "make dist           - create tarball for distribution"
	@echo "make help           - show this help"
