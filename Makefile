PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin

build:
	swift build -c release --disable-sandbox $(FLAGS)

install: build
	install -d $(DESTDIR)$(BINDIR)
	install -m755 ".build/release/airdrop" "$(DESTDIR)$(BINDIR)"

uninstall:
	rm -rf $(DESTDIR)$(BINDIR)/airdrop

clean:
	rm -rf .build

.PHONY: build install uninstall clean
