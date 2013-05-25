default: run

SRCDIR         = src
LIBDIR         = lib/cloud

INDEX = $(LIBDIR)/index.js

COFFEES =    $(shell find $(SRCDIR) -name "*.coffee"    -type f | sort)
LITCOFFEES = $(shell find $(SRCDIR) -name "*.litcoffee" -type f | sort)
CLIBS =     $(COFFEES:$(SRCDIR)/%.coffee=$(LIBDIR)/%.js)
LCLIBS = $(LITCOFFEES:$(SRCDIR)/%.litcoffee=$(LIBDIR)/%.js)
ROOT = $(shell pwd)

COFFEE = node_modules/coffee-script/bin/coffee

run: build
	node $(INDEX)

build: $(CLIBS) $(LCLIBS)

$(LIBDIR):
	mkdir -p $(LIBDIR)/

$(LIBDIR)/%.js: $(SRCDIR)/%.coffee $(LIBDIR)
	cd $(SRCDIR) && ../$(COFFEE) -c -o ../$(LIBDIR)/ $(notdir $<)

$(LIBDIR)/%.js: $(SRCDIR)/%.litcoffee $(LIBDIR)
	cd $(SRCDIR) && ../$(COFFEE) -c -o ../$(LIBDIR)/ $(notdir $<)

.PHONY: install loc clean

loc:
	wc -l src/*

clean:
	rm -rf lib
