# airdrop-cli

This is a command line tool that allows you to share files with Apple devices using AirDrop from your terminal.

## Installation
### Homebrew
```
brew install vldmrkl/formulae/airdrop-cli
```
or
```
brew tap vldmrkl/formulae
brew install airdrop-cli
```


### Manually

```
git clone https://github.com/vldmrkl/airdrop-cli.git
cd airdrop-cli
make install
```

## Usage

![airdrop-cli-demo](https://user-images.githubusercontent.com/26641473/103395121-762ef380-4afa-11eb-9bc8-6cf6068edf32.gif)

To airdrop files, run:
```
airdrop /path/to/your/file
```

You can pass as many paths as you want. As long as theese file URLs are correct, the command will work.
