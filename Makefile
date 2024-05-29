DESTDIR ?= /
PREFIX ?= $(DESTDIR)usr/local
EXEC_PREFIX ?= $(PREFIX)
DATAROOTDIR ?= $(PREFIX)/share
BINDIR ?= $(EXEC_PREFIX)/bin
MANDIR ?= $(DATAROOTDIR)/man
MAN1DIR ?= $(MANDIR)/man1

.PHONY: all clean test

all: moonblast.1

clean:
	-rm moonblast.1

moonblast.1: moonblast.1.scd
	scdoc < $< > $@

install: moonblast.1 moonblast
	@install -v -D -m 0644 moonblast.1 --target-directory "$(MAN1DIR)"
	@install -v -D -m 0755 moonblast --target-directory "$(BINDIR)"

uninstall: moonblast.1 moonblast
	rm "$(MAN1DIR)/moonblast.1"
	rm "$(BINDIR)/moonblast"
