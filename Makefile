## @file    <Makefile>
## @author  <wakaranakattari@gmail.com>
## @info    <build and install WPDCS toolchain>
## @version <1.0-SNAP>

PREFIX    ?= /usr/local
BINDIR    = $(PREFIX)/bin
LIBDIR    = $(PREFIX)/share/perl5
MANDIR    = $(PREFIX)/share/man/man1
PROG_NAME = wpdcs

## @secinfo <default target>
all:
	@echo "WPDCS Toolchain"
	@echo ""
	@echo "Targets:"
	@echo "  make install    - install wpdcs system-wide"
	@echo "  make install-user - install wpdcs for current user"
	@echo "  make uninstall  - remove wpdcs"
	@echo "  make test       - run tests"
	@echo "  make clean      - remove temporary files"
	@echo "  make dist       - create distribution tarball"

## @secinfo <install system-wide (requires sudo)>
install:
	@echo "Installing WPDCS to $(PREFIX)"
	@mkdir -p $(BINDIR)
	@mkdir -p $(LIBDIR)
	@mkdir -p $(MANDIR)
	@install -m 755 bin/$(PROG_NAME) $(BINDIR)/
	@cp -r lib/* $(LIBDIR)/
	@echo "Installed to $(BINDIR)/$(PROG_NAME)"
	@echo "Run 'wpdcs --help' to get started"

## @secinfo <install for current user only>
install-user:
	@echo "Installing WPDCS for user $(USER)"
	@mkdir -p $(HOME)/.local/bin
	@mkdir -p $(HOME)/.local/lib
	@install -m 755 bin/$(PROG_NAME) $(HOME)/.local/bin/
	@cp -r lib/* $(HOME)/.local/lib/
	@echo "Add to PATH: export PATH=$$HOME/.local/bin:$$PATH"

## @secinfo <uninstall>
uninstall:
	@echo "Removing WPDCS from $(PREFIX)"
	@rm -f $(BINDIR)/$(PROG_NAME)
	@rm -rf $(LIBDIR)/WPDCS
	@echo "Uninstalled"

## @secinfo <run tests>
test:
	@echo "Running tests..."
	@echo "Testing check command..."
	@perl -Ilib bin/wpdcs check examples/perl/calc.pl
	@echo "Testing lint command..."
	@perl -Ilib bin/wpdcs lint examples/perl/calc.pl
	@echo "All tests passed"

## @secinfo <clean temporary files>
clean:
	@echo "Cleaning..."
	@find . -name "*.bak" -type f -delete
	@find . -name "*.swp" -type f -delete
	@echo "Clean done"

## @secinfo <create distribution tarball>
dist:
	@echo "Creating distribution..."
	@mkdir -p wpdcs-dist
	@cp -r bin lib share t docs examples Makefile README.md LICENSE .wpdcsrc.example wpdcs-dist/
	@tar -czf wpdcs-1.0-SNAP.tar.gz wpdcs-dist/
	@rm -rf wpdcs-dist
	@echo "Created: wpdcs-1.0-SNAP.tar.gz"

## @secinfo <help>
help:
	@echo "WPDCS Toolkit"
	@echo ""
	@echo "make install        - install system-wide (sudo make install)"
	@echo "make install-user   - install for current user"
	@echo "make uninstall      - remove system-wide installation"
	@echo "make test           - run tests"
	@echo "make clean          - remove temp files"
	@echo "make dist           - create tarball for distribution"
	@echo "make help           - show this help"
