# nix-lib

[![Built with Nix](https://img.shields.io/badge/Built_With-Nix-5277C3.svg?logo=nixos&labelColor=73C3D5)](https://nixos.org)
[![Build Check](https://img.shields.io/github/actions/workflow/status/neversad-dev/nix-lib/build-check.yml?branch=main&logo=github-actions&logoColor=white&label=build%20check)](https://github.com/neversad-dev/nix-lib/actions/workflows/build-check.yml)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://choosealicense.com/licenses/mit/)
[![Nix Flakes](https://img.shields.io/badge/Nix-Flakes-blue.svg?logo=nixos&logoColor=white)](https://nixos.wiki/wiki/Flakes)

A shared Nix library containing common utility functions for configuration management.

## Functions

### `scanPaths`
Scans a directory and returns a list of paths for all `.nix` files and directories (excluding those starting with `_` and `default.nix`).

### `mkEditableConfig`
Creates an editable config file with backup functionality. Automatically backs up existing configs and shows diffs when overwriting.

### `mkEditableConfigDir`
Creates editable config files for all files in a directory recursively, preserving directory structure.

## Usage

Add this flake as an input to your configuration:

```nix
inputs = {
  nix-lib.url = "github:your-username/nix-lib";
};

outputs = { self, nix-lib, ... }: {
  # Use the library functions
  mylib = nix-lib.lib;
};
```

## License

MIT
