{pkgs, ...}: {
  home.packages = [
    (pkgs.writeShellScriptBin "devenv" ''
      #!/usr/bin/env bash
      set -e
      FLAKE_DIR="''${FLAKE_DIR:-''${HOME}/nixos/home/scripts/devenv/profiles}"

      if [ -z "''${1:-}" ]; then
          echo "Available profiles:"
          PS3="Select a profile: "
          options=()
          for f in "$FLAKE_DIR"/*.nix; do options+=("$(basename "$f" .nix)"); done
          options+=("quit")
          select PROFILE in "''${options[@]}"; do
              case "$PROFILE" in
                  quit) exit 0 ;;
                  "")   echo "Invalid selection, try again." ;;
                  *)    break ;;
              esac
          done
      else
          PROFILE="$1"
      fi

      FLAKE_FILE="$FLAKE_DIR/$PROFILE.nix"
      if [ ! -f "$FLAKE_FILE" ]; then
          echo -e "\033[1;31m❌ Flake profile '$PROFILE' does not exist in $FLAKE_DIR.\033[0m"
          exit 1
      fi
      if [ -f flake.nix ]; then
          echo -e "\033[1;33m⚠️  Warning: flake.nix already exists.\033[0m"
          read -rp "Do you want to replace it? (y/N): " response
          if [[ ! "$response" =~ ^[Yy]$ ]]; then
              echo "Aborted."
              exit 0
          fi
      fi
      cp "$FLAKE_FILE" flake.nix
      echo -e "\033[1;32m✓ Using profile '$PROFILE'. flake.nix created.\033[0m"
      echo -e "\nNext steps:"
      echo -e "  \033[0;36m1.\033[0m Edit flake.nix if needed"
      echo -e "  \033[0;36m2.\033[0m Run: \033[1;37mnix develop\033[0m"
    '')
  ];
}
