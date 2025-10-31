{ config, pkgs, ... }:
{
    programs.zsh = {
        enable = true;
        history = {
            size = 1000;
            save = 1000;
            path = "${config.home.homeDirectory}/.histfile";
            ignoreDups = true;
            ignoreAllDups = true;
            ignoreSpace = true;
            share = true;
        };
        defaultKeymap = "viins";
        setOptions = [
            "hist_ignore_dups"
            "hist_ignore_all_dups"
            "hist_save_no_dups"
            "hist_ignore_space"
            "hist_verify"
            "share_history"
            "auto_cd"
        ];
        shellAliases = {
            # Temporary
            cljrepl = ''
                clj -Sdeps '{:deps {nrepl/nrepl {:mvn/version "1.0.0"} cider/cider-nrepl {:mvn/version "0.42.1"}}}' \
                    -M -m nrepl.cmdline \
                    --middleware '["cider.nrepl/cider-middleware"]' \
                    --interactive
            '';
            # Permanent
            l = "eza --color=always --group-directories-first --icons";
            ll = "l -l";
            la = "l -a";
            lla = "l -la";
            lt = "eza --color=always --tree --group-directories-first --icons";
            ls = "ls --color=auto";
            grep = "grep --color=auto";
            fetchall = "fastfetch --config examples/7.jsonc";
            cleanfetch = "fastfetch --config examples/8.jsonc";
            fetchip = "fastfetch --config ~/.config/fastfetch/configs/ip_info.jsonc";
            memfetch = "fastfetch --config ~/.config/fastfetch/configs/mem.jsonc";
            nv = "nvim";
            remind = "~/notes/remind.sh";
            # obsidian shortcuts
            odl = "nvim +'ObsidianToday'";
            onew = "nvim +'ObsidianNew'";
            osearch = "nvim +'ObsidianSearch'";
            caval = "hyprctl dispatch setfloating && hyprctl dispatch resizeactive exact 162 1000 && hyprctl dispatch movewindow l && hyprctl dispatch movewindow d && hyprctl dispatch moveactive 15 -15 && cava";
            cavar = "hyprctl dispatch setfloating && hyprctl dispatch resizeactive exact 162 1000 && hyprctl dispatch movewindow r && hyprctl dispatch movewindow d && hyprctl dispatch moveactive -15 -15 && cava";
        };
        initContent = with config.colorScheme.palette; ''
      # Custom prompt
      # export PS1=$'\n%F{#${base0D}}%B%b %F{#${base0D}}%1~%f%F{#${base0D}} ❯ %f'
      # export RPROMPT='%F{#${base0E}}'"''${NIX_PS1_OVERRIDE}"'%f'

      # Tree with depth
      ltl() {
        if [[ -z "$1" ]]; then
          echo -e "\033[1;33mUsage:\033[0m ltl <depth_level>"
          return 1
        fi
        eza --color=always --tree --level="$1"
      }

      # Copy file content
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

      # Copy pwd
      cpwd() {
        local current_path=$(pwd)
        if echo "$current_path" | wl-copy; then
          echo -e "\033[1;32m✓ Success:\033[0m '$current_path' copied."
        else
          echo -e "\033[1;31m✗ Error:\033[0m Failed to copy."
          return 1
        fi
      }
        # Run nixpkgs-lint in a given path
        lintnix() {
          if [[ -z "$1" ]]; then
            echo -e "\033[1;33mUsage:\033[0m lintnix <path>"
            return 1
          fi
          if [[ ! -d "$1" ]]; then
            echo -e "\033[1;31m✗ Error:\033[0m '$1' is not a valid directory."
            return 1
          fi
          if nix run github:nix-community/nixpkgs-lint -- "$1"; then
            echo -e "\033[1;32m✓ Success:\033[0m Lint completed for '$1'."
          else
            echo -e "\033[1;31m✗ Error:\033[0m Linting failed for '$1'."
            return 1
          fi
        }

      # Extra stuff to start zsh with
      [[ -n $ZSH_CMDS ]] && eval "$ZSH_CMDS"
        '';
        autosuggestion.enable = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;
    };
}
