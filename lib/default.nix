{lib, ...}: rec {
  scanPaths = path:
    builtins.map
    (f: (path + "/${f}"))
    (builtins.attrNames
      (lib.attrsets.filterAttrs
        (
          path: _type:
            (
              (_type == "directory") # include directories
              && !lib.strings.hasPrefix "_" path # ignore directories starting with _
            )
            || (
              (path != "default.nix") # ignore default.nix
              && (lib.strings.hasSuffix ".nix" path) # include .nix files
            )
        )
        (builtins.readDir path)));

  # Creates an editable config file with backup functionality
  # Usage: mkEditableConfig {
  #   name = "myapp";
  #   configPath = "$HOME/.config/myapp/config";
  #   content = "config content here";
  #   pkgs = pkgs; # recommended for delta diffs and jq formatting
  #   isJson = false; # optional, formats with jq if true
  # }
  mkEditableConfig = {
    name,
    configPath,
    content,
    pkgs ? null,
    isJson ? false,
    executable ? false,
  }: let
    configDir = builtins.dirOf configPath;
    configFile = builtins.baseNameOf configPath;
    backupFile = "${configDir}/${configFile}.home-manager.backup";

    shouldFormatJson = isJson && pkgs != null;

    # Use delta if available, fallback to diff
    diffCommand =
      if pkgs != null
      then "${pkgs.delta}/bin/delta --file-style=omit --hunk-header-style=omit"
      else "diff -u";
  in ''
        CONFIG_DIR="${configDir}"
        CONFIG_FILE="${configPath}"
        BACKUP_FILE="${backupFile}"

        # Create directory if it doesn't exist
        mkdir -p "$CONFIG_DIR"

    # Create new config content in a temp file (safely, without shell interpretation)
    TEMP_FILE=$(mktemp)
    if ${
      if shouldFormatJson
      then "true"
      else "false"
    }; then
      # For JSON: use jq to format
      printf '%s' ${lib.escapeShellArg content} | ${
      if pkgs != null
      then "${pkgs.jq}/bin/jq '.'"
      else "cat"
    } > "$TEMP_FILE"
    else
      # For plain text: write content directly without trailing newline
      printf '%s' ${lib.escapeShellArg content} > "$TEMP_FILE"
    fi

        # If config exists and is different from new content, create backup and show diff
        if [ -f "$CONFIG_FILE" ]; then
          if ! cmp -s "$CONFIG_FILE" "$TEMP_FILE"; then
            cp "$CONFIG_FILE" "$BACKUP_FILE"
            echo "" >&2
            printf "📁 \033[1;36m%s\033[0m config backed up to %s\n" "${name}" "$BACKUP_FILE" >&2
            printf "🔄 Overwriting manual changes in \033[1;33m%s\033[0m config (%s):\n" "${name}" "$CONFIG_FILE" >&2
            ${diffCommand} "$CONFIG_FILE" "$TEMP_FILE" >&2 || true
            echo "" >&2
          fi
        fi

        # Always overwrite with new config
        cp "$TEMP_FILE" "$CONFIG_FILE"
        rm "$TEMP_FILE"

        # Make sure it's writable and set executable permission if needed
        chmod ${
      if executable
      then "755"
      else "644"
    } "$CONFIG_FILE"

  '';

  # Creates editable config files for all files in a directory recursively
  # Usage: mkEditableConfigDir {
  #   name = "myapp";
  #   configDir = "$HOME/.config/myapp";
  #   sourceDir = ./config;
  #   pkgs = pkgs; # recommended for delta diffs and jq formatting
  # }
  mkEditableConfigDir = {
    name,
    configDir,
    sourceDir,
    pkgs ? null,
  }: let
    # Recursively read all files from source directory, preserving structure
    readDirRecursive = dir: let
      entries = builtins.readDir dir;
      files = lib.filterAttrs (name: type: type == "regular") entries;
      dirs = lib.filterAttrs (name: type: type == "directory") entries;

      # Process files in current directory (relative to sourceDir)
      currentFiles = builtins.listToAttrs (builtins.map (name: let
        fullPath = dir + "/${name}";
        sourceDirStr = toString sourceDir + "/";
        fullPathStr = toString fullPath;
        relativePath = lib.removePrefix sourceDirStr fullPathStr;
      in {
        name = relativePath; # Use relative path as key to avoid conflicts
        value = {
          sourcePath = fullPath;
          relativePath = relativePath;
        };
      }) (builtins.attrNames files));

      # Recursively process subdirectories
      subdirFiles = builtins.foldl' (
        acc: dirName:
          acc
          // (readDirRecursive (dir + "/${dirName}"))
      ) {} (builtins.attrNames dirs);
    in
      currentFiles // subdirFiles;

    allFiles = readDirRecursive sourceDir;

    # Create activation scripts for each file
    fileActivations =
      builtins.mapAttrs (
        relativePath: fileInfo: let
          targetPath = "${configDir}/${fileInfo.relativePath}";
          content = builtins.readFile fileInfo.sourcePath;
          fileName = builtins.baseNameOf fileInfo.relativePath;
          fileExtension = let
            parts = lib.strings.splitString "." fileName;
          in
            if builtins.length parts > 1
            then builtins.elemAt parts 1
            else "";
          isJson = fileExtension == "json";
          isExecutable = fileExtension == "sh" || fileName == "sketchybarrc";
        in
          mkEditableConfig {
            name = "${name} ${fileName}";
            configPath = targetPath;
            content = content;
            pkgs = pkgs;
            isJson = isJson;
            executable = isExecutable;
          }
      )
      allFiles;

    # Combine all activation scripts
    combinedScript = builtins.foldl' (acc: script: acc + "\n" + script) "" (builtins.attrValues fileActivations);
  in
    combinedScript;
}
