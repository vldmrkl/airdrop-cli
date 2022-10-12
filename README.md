# airdrop-cli

A command-line tool that allows you to share files and URLs with Apple
devices using AirDrop from your terminal.

## Installation

`airdrop-cli` is available for install with Homebrew

```
brew install vldmrkl/formulae/airdrop-cli
```

or

```
brew tap vldmrkl/formulae
brew install airdrop-cli
```

### Building from source

Before attempting to build this project from its source code, make sure
that you have Xcode version 11.4 (or higher) & GNU make installed.

Then, clone the project and use the Makefile

```
git clone https://github.com/vldmrkl/airdrop-cli.git
cd airdrop-cli
make
sudo make install
```

By default, make will build and install the project within
`/usr/local/bin`. This project location can be changed by appending
a new prefix to the `PREFIX` variable.

```
make PREFIX="YOUR_PREFIX_HERE"
```

You can append other Swift flags, in case you may need them for your
specific build, to the `FLAGS` variable.

## Usage

![airdrop-cli-demo](https://user-images.githubusercontent.com/26641473/103395121-762ef380-4afa-11eb-9bc8-6cf6068edf32.gif)

To airdrop files, run:

```
airdrop /path/to/your/file
```

You can also airdrop URLs:

```
airdrop https://apple.com/
```

You can pass as many paths as you want. As long as theese file URLs are correct,
the command will work.
