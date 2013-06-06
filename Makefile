default: watch

SRCDIR         = src
LIBDIR         = lib/cloud

INDEX = $(LIBDIR)/index.js

COFFEE = node_modules/coffee-script/bin/coffee
NODEMON = node node_modules/nodemon/nodemon.js

watch:
	$(COFFEE) -o $(LIBDIR) -cw $(SRCDIR) &
	sleep 2
	$(NODEMON) $(INDEX)

.PHONY: loc clean

loc:
	wc -l src/*

clean:
	rm -rf lib
