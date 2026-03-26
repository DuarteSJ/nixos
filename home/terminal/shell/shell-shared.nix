{config, ...}: {
  _module.args.shellShared = rec {
    aliases = {
      memtis = "cd /home/duartesj/Tese/memtis/linux; nv mm/htmm_core.c mm/htmm_sampler.c mm/htmm_migrater.c include/linux/htmm.h";
      rb = "sudo -v && nixos-rebuild switch --sudo";
      l = "eza --color=always --group-directories-first --icons";
      ll = "l -l";
      la = "l -a";
      lla = "l -la";
      lt = "eza --color=always --tree --group-directories-first --icons";
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      nv = "nvim";
      remind = "~/notes/remind.sh";
      # obsidian shortcuts
      odl = "nvim +'Obsidian today'";
      onew = "nvim +'Obsidian new'";
      osearch = "nvim +'Obsidian search'";
      # cava floating window helpers
      caval = "hyprctl dispatch setfloating && hyprctl dispatch resizeactive exact 162 1000 && hyprctl dispatch movewindow l && hyprctl dispatch movewindow d && hyprctl dispatch moveactive 15 -15 && cava";
      cavar = "hyprctl dispatch setfloating && hyprctl dispatch resizeactive exact 162 1000 && hyprctl dispatch movewindow r && hyprctl dispatch movewindow d && hyprctl dispatch moveactive -15 -15 && cava";
      # fastfetch
      cleanfetch = "fastfetch --config examples/8.jsonc";
      fetchall = "fastfetch --config examples/25.jsonc";
      memfetch = "fastfetch --config examples/9.jsonc";
      cljrepl = "clj -Sdeps '{:deps {nrepl/nrepl {:mvn/version \"1.0.0\"} cider/cider-nrepl {:mvn/version \"0.42.1\"}}}' -M -m nrepl.cmdline --middleware '[\"cider.nrepl/cider-middleware\"]' --interactive";
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

      # Format nix files with alejandra
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
        local content=$(cat "$1")
        rm "$1"
        echo "$content" > "$1"
        echo -e "\033[1;32m✓ Success:\033[0m '$1' is now a regular writable file."
      }
      
    '';
  };
}
