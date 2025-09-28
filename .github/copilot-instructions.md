# Copilot Instructions for nix-lib

This repository contains shared Nix library functions for configuration management. Follow these guidelines when working with this codebase.

## Project Structure

```
nix-lib/
├── flake.nix          # Flake configuration
├── flake.lock         # Locked dependencies
├── README.md          # Project documentation
└── lib/
    └── default.nix    # Main library functions
```

## Key Functions

### `scanPaths`
- **Purpose**: Scans directories for `.nix` files and subdirectories
- **Usage**: `mylib.scanPaths ./some/path`
- **Behavior**: Excludes directories starting with `_` and `default.nix` files

### `mkEditableConfig`
- **Purpose**: Creates config files with backup functionality
- **Usage**: Generates shell scripts that safely overwrite configs
- **Features**: Automatic backups, diff display, JSON formatting support

### `mkEditableConfigDir`
- **Purpose**: Recursively processes entire config directories
- **Usage**: Bulk config file management with structure preservation
- **Features**: Handles nested directories, file type detection

## Development Guidelines

### Adding New Functions
1. Add functions to `lib/default.nix`
2. Follow the existing pattern: `{lib, ...}: rec { ... }`
3. Include comprehensive documentation comments
4. Test functions with `nix repl` or in consuming flakes

### Function Documentation
- Use multi-line comments with `#` for function descriptions
- Include usage examples in comments
- Document all parameters and their types
- Explain return values and behavior

### Testing
- Test functions locally with `nix repl`
- Verify integration in consuming flakes
- Use `nix flake check` to validate the flake

### Code Style
- Use `rec` for recursive attribute sets
- Prefer `lib.` prefixes for standard library functions
- Use descriptive variable names
- Follow Nix formatting conventions

## Integration Patterns

### In Flake Inputs
```nix
inputs = {
  nix-lib.url = "github:your-username/nix-lib";
};
```

### In Flake Outputs
```nix
outputs = { nix-lib, ... }: {
  mylib = nix-lib.lib;
};
```

### In Modules
```nix
{ mylib, ... }: {
  # Use mylib.scanPaths, mylib.mkEditableConfig, etc.
}
```

## Common Tasks

### Adding a New Utility Function
1. Define the function in `lib/default.nix`
2. Add comprehensive documentation
3. Test with `nix repl`
4. Update README.md if needed
5. Test integration in consuming projects

### Updating Dependencies
- Run `nix flake update` to update nixpkgs
- Test that all functions still work
- Update lock file if needed

### Publishing Changes
- Ensure all tests pass with `nix flake check`
- Update version in flake.nix if needed
- Update README.md documentation
- Tag releases appropriately

## Error Handling

- Functions should fail gracefully with clear error messages
- Use `lib.asserts` for parameter validation
- Provide helpful error context for debugging

## Performance Considerations

- Avoid expensive operations in function definitions
- Use lazy evaluation patterns where appropriate
- Consider caching for repeated operations

## Security Notes

- Be careful with file system operations
- Validate paths and inputs
- Use `lib.escapeShellArg` for shell safety
- Avoid arbitrary code execution risks
