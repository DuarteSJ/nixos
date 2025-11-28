{ pkgs, ... }: {
  home.packages = [
    (pkgs.writeShellScriptBin "devenv" ''
      #!/usr/bin/env bash
      set -e

      # Directory where profile flakes live
      FLAKE_DIR="''${FLAKE_DIR:-''${HOME}/nixos/home/scripts/devenv/profiles}"

      # Default profile
      PROFILE="''${1:-generic}"
      FLAKE_FILE="$FLAKE_DIR/$PROFILE.nix"

      # Check that the profile flake exists
      if [ ! -f "$FLAKE_FILE" ]; then
          echo -e "\033[1;31m❌ Flake profile '$PROFILE' does not exist in $FLAKE_DIR.\033[0m"
          echo "Available profiles:"
          for f in "$FLAKE_DIR"/*.nix; do
              echo "$(basename "$f" .nix)"
          done
          exit 1
      fi

      # Warn if flake.nix already exists
      if [ -f flake.nix ]; then
          echo -e "\033[1;33m⚠️  Warning: flake.nix already exists.\033[0m"
          read -rp "Do you want to replace it? (y/N): " response
          if [[ ! "$response" =~ ^[Yy]$ ]]; then
              echo "Aborted."
              exit 0
          fi
      fi

      # Copy the chosen profile to flake.nix
      cp "$FLAKE_FILE" flake.nix
      echo -e "\033[1;32m✓ Using profile '$PROFILE'. flake.nix created.\033[0m"

      # Print instructions
      echo -e "\nNext steps:"
      echo -e "  \033[0;36m1.\033[0m Edit flake.nix if needed"
      echo -e "  \033[0;36m2.\033[0m Run: \033[1;37mnix develop\033[0m"
    '')
  ];
}
