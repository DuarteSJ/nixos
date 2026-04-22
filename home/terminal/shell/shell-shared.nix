{config, ...}: {
  _module.args.shellShared = {
    aliases = {
      rb = "sudo -v && nixos-rebuild switch --sudo";
      l = "eza --color=always --group-directories-first --icons";
      ll = "l -l";
      la = "l -a";
      lla = "l -la";
      lt = "eza --color=always --tree --group-directories-first --icons";
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      nv = config.vars.editor;
      # obsidian shortcuts
      odl = "${config.vars.editor} +'Obsidian today'";
      onew = "${config.vars.editor} +'Obsidian new'";
      osearch = "${config.vars.editor} +'Obsidian search'";
      # fastfetch
      cleanfetch = "fastfetch --config examples/8.jsonc";
      fetchall = "fastfetch --config examples/25.jsonc";
      memfetch = "fastfetch --config examples/9.jsonc";
    };

    functions = ''
        # Tree with depth
        ltl() {
          if [[ -z "$1" ]]; then
            echo -e "\033[1;33mUsage:\033[0m ltl <depth_level>"
            return 1
          fi
          eza --color=always --tree --level="$1"
        }

        # Copy file content to clipboard
        copyfile() {
          if [[ -z "$1" ]]; then
            echo -e "\033[1;33mUsage:\033[0m copyfile <filename>"
            return 1
          fi
          if [[ ! -f "$1" ]]; then
            echo -e "\033[1;31m✗ Error:\033[0m File '$1' not found."
            return 1
          fi
          if wl-copy < "$1"; then
            echo -e "\033[1;32m✓ Success:\033[0m $1's content copied."
          else
            echo -e "\033[1;31m✗ Error:\033[0m Failed to copy."
            return 1
          fi
        }

        # Copy current working directory to clipboard
        cpwd() {
          local current_path=$(pwd)
          if echo "$current_path" | wl-copy; then
            echo -e "\033[1;32m✓ Success:\033[0m '$current_path' copied."
          else
            echo -e "\033[1;31m✗ Error:\033[0m Failed to copy."
            return 1
          fi
        }

        # nixfix: format + lint Nix files nicely
        nixfix() {
          local do_format=1
          local do_lint=1
          local do_fix=0
          local target=""

          # Parse flags + positional args
          while [[ $# -gt 0 ]]; do
            case "$1" in
              --no-format)
                do_format=0
                ;;
              --no-lint)
                do_lint=0
                ;;
              --fix)
                do_fix=1
                ;;
              -h|--help)
                echo "Usage: nixfix <path> [options]"
                echo
                echo "Options:"
                echo "  --no-format   Skip alejandra formatting"
                echo "  --no-lint     Skip statix linting"
                echo "  --fix         Apply statix fixes"
                echo "  -h, --help    Show this help"
                return 0
                ;;
              -*)
                echo -e "\033[1;31m✗ Unknown option:\033[0m $1"
                return 1
                ;;
              *)
                # first non-flag becomes target
                if [[ -z "$target" ]]; then
                  target="$1"
                else
                  echo -e "\033[1;31m✗ Unexpected extra argument:\033[0m $1"
                  return 1
                fi
                ;;
            esac
            shift
          done

          # Validate input
          if [[ -z "$target" ]]; then
            echo -e "\033[1;33mUsage:\033[0m nixfix <path> [options]"
            return 1
          fi

          if [[ ! -e "$target" ]]; then
            echo -e "\033[1;31m✗ Error:\033[0m '$target' does not exist."
            return 1
          fi

          echo -e "\033[1;36m→ Processing:\033[0m $target"
          echo

          # Format
          if [[ $do_format -eq 1 ]]; then
            echo -e "\033[1;34m[format]\033[0m Running alejandra..."
            if alejandra "$target"; then
              echo -e "\033[1;32m✓ Formatting complete\033[0m"
            else
              echo -e "\033[1;31m✗ Formatting failed\033[0m"
              return 1
            fi
            echo
          fi

          # Lint
          if [[ $do_lint -eq 1 ]]; then
            if [[ $do_fix -eq 1 ]]; then
              echo -e "\033[1;34m[lint]\033[0m Running statix (with fixes)..."
              if statix fix "$target"; then
                echo -e "\033[1;32m✓ Lint fixes applied\033[0m"
              else
                echo -e "\033[1;31m✗ Lint fix failed\033[0m"
                return 1
              fi
            else
              echo -e "\033[1;34m[lint]\033[0m Running statix check..."
              statix check "$target"

              if [[ $? -eq 0 ]]; then
                echo -e "\033[1;32m✓ No issues found\033[0m"
              else
                echo -e "\033[1;33m⚠ Issues detected (run with --fix to auto-fix)\033[0m"
              fi
            fi
            echo
          fi

          echo -e "\033[1;32m✔ Done\033[0m"
        }

      # Make a file that is "owned by nix" writable
      unnix() {
        if [[ -z "$1" ]]; then
          echo -e "\033[1;33mUsage:\033[0m unnix <filename>"
          return 1
        fi
        if [[ ! -L "$1" ]]; then
          echo -e "\033[1;31m✗ Error:\033[0m '$1' is not a symlink."
          return 1
        fi
        local target
        target=$(readlink -f "$1")
        rm "$1"
        cp --no-preserve=mode,ownership "$target" "$1"
        echo -e "\033[1;32m✓ Success:\033[0m '$1' is now a regular writable file."
      }

    '';
  };
}
