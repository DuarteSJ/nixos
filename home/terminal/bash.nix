{config, ...}: {
  programs.bash = {
    enable = true;
    historySize = 1000;
    historyFileSize = 1000;
    historyFile = "${config.home.homeDirectory}/.bash_history";
    historyControl = ["ignoredups" "ignorespace"];
    historyIgnore = ["ls" "cd" "exit"];

    shellOptions = [
      "histappend"
      "checkwinsize"
      "extglob"
      "globstar"
      "checkjobs"
    ];

    shellAliases = {
      cljrepl = "clj -Sdeps '{:deps {nrepl/nrepl {:mvn/version \"1.0.0\"} cider/cider-nrepl {:mvn/version \"0.42.1\"}}}' -M -m nrepl.cmdline --middleware '[\"cider.nrepl/cider-middleware\"]' --interactive";
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

    initExtra = with config.colorScheme.palette; ''
      # Enable vi mode
      set -o vi

      # Custom prompt
      # export PS1='\n\[\e[1;38;5;#${base0D}m\]\w\[\e[0m\] \[\e[1;38;5;#${base0D}m\]❯\[\e[0m\] '
      # export PS2='\[\e[1;38;5;#${base0E}m\]>\[\e[0m\] '

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
      nixfmt() {
        if [[ -z "$1" ]]; then
          echo -e "\033[1;33mUsage:\033[0m nixfmt <path>"
          return 1
        fi
        if [[ ! -e "$1" ]]; then
          echo -e "\033[1;31m✗ Error:\033[0m '$1' does not exist."
          return 1
        fi
        echo -e "\033[1;34mFormatting:\033[0m '$1'..."
        if alejandra "$1"; then
          echo -e "\033[1;32m✓ Success:\033[0m Formatted '$1'."
        else
          echo -e "\033[1;31m✗ Error:\033[0m Formatting failed for '$1'."
          return 1
        fi
      }

      # Extra stuff to start bash with
      [[ -n $BASH_CMDS ]] && eval "$BASH_CMDS"
    '';
  };
}
