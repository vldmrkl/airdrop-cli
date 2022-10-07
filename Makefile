PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin

build:
	swift build -c release --disable-sandbox $(FLAGS)

install: build
	install ".build/release/airdrop" "$(BINDIR)"

uninstall:
	rm -rf $(BINDIR)/airdrop

clean:
	rm -rf .build

.PHONY: build install uninstall clean
