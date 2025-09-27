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
      colors = "$HOME/scripts/print_colors.sh";
      timer = "$HOME/scripts/live_timer.sh";
      caval = "hyprctl dispatch setfloating && hyprctl dispatch resizeactive exact 162 1000 && hyprctl dispatch movewindow l && hyprctl dispatch movewindow d && hyprctl dispatch moveactive 15 -15 && cava";
      cavar = "hyprctl dispatch setfloating && hyprctl dispatch resizeactive exact 162 1000 && hyprctl dispatch movewindow r && hyprctl dispatch movewindow d && hyprctl dispatch moveactive -15 -15 && cava";
    };

    initContent = ''
      # Custom prompt
      export PS1=$'\n%F{110}%B%b %F{117}%1~%f%F{110} ❯ %f'

      # Color vars
      GREEN="\e[32m"; RED="\e[31m"; YELLOW="\e[33m"; BLUE="\e[34m"; RESET="\e[0m"

      # Tree with depth
      ltl() {
        if [[ -z "$1" ]]; then
          echo -e "''${YELLOW}Usage:''${RESET} ltl <depth_level>"
          return 1
        fi
        eza --color=always --tree --level="$1"
      }

      # Copy file content
      copyfile() {
        if [[ -z "$1" ]]; then
          echo -e "''${YELLOW}Usage:''${RESET} copyfile <filename>"
          return 1
        fi
        if [[ ! -f "$1" ]]; then
          echo -e "''${RED} Error:''${RESET} File '$1' not found."
          return 1
        fi
        if wl-copy < "$1"; then
          echo -e "''${GREEN} Success:''${RESET} $1's content copied."
        else
          echo -e "''${RED} Error:''${RESET} Failed to copy."
          return 1
        fi
      }

      # Copy pwd
      cpwd() {
        local current_path=$(pwd)
        if echo "$current_path" | wl-copy; then
          echo -e "''${GREEN} Success:''${RESET} '$current_path' copied."
        else
          echo -e "''${RED} Error:''${RESET} Failed to copy."
          return 1
        fi
      }

      # Weather
      weather() {
        local city="''${1:-Lisbon}"
        local format="''${2:-3}"
        curl -s "wttr.in/''${city}?format=''${format}" || {
          echo -e "''${RED} Error:''${RESET} Failed to fetch weather."
          return 1
        }
      }

      weatherfull() {
        local city="''${1:-Lisbon}"
        curl -s "wttr.in/''${city}" || {
          echo -e "''${RED} Error:''${RESET} Failed to fetch weather."
          return 1
        }
      }
    '';

    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
  };
}

