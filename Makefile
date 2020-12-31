prefix ?= /usr/local
bindir = $(prefix)/bin

build:
	swift build -c release --disable-sandbox

install: build
	install ".build/release/airdrop" "$(bindir)"

uninstall:
	rm -rf "$(bindir)/airdrop"

clean:
	rm -rf .build

.PHONY: build install uninstall clean
