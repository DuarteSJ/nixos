{ config, pkgs, ... }: {
    home.username = "duartesj";
    home.homeDirectory = "/home/duartesj";

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    home.stateVersion = "24.11"; # Please read the comment before changing.

    programs.git = {
    	enable = true;
	userName = "DuarteSJ";
	userEmail = "ddduarte@sapo.pt";
	extraConfig = {
	    init.defaultBranch = "main";
	};
    };

    programs.zsh = {
        enable = true;

        # History Configuration
        history = {
            size = 1000;
            save = 1000;
            path = "${config.home.homeDirectory}/.histfile";
            ignoreDups = true;
            ignoreAllDups = true;
            ignoreSpace = true;
            share = true;
        };

        # Additional ZSH options
        defaultKeymap = "viins";  # vim key bindings

        # ZSH options
        setOptions = [
            "hist_ignore_dups"
            "hist_ignore_all_dups" 
            "hist_save_no_dups"
            "hist_ignore_space"
            "hist_verify"
            "share_history"
            "auto_cd"
        ];

        # Shell aliases
        shellAliases = {
            # Enhanced ls with colors and icons (eza)
            l = "eza --color=always --group-directories-first --icons";
            ll = "l -l";
            la = "l -a";
            lla = "l -la";
            lt = "eza --color=always --tree --group-directories-first --icons";

            # Standard Unix Tools with colors  
            ls = "ls --color=auto";
            grep = "grep --color=auto";

            # System Information (fastfetch)
            fetchall = "fastfetch --config examples/7.jsonc";
            cleanfetch = "fastfetch --config examples/8.jsonc";
            fetchip = "fastfetch --config ~/.config/fastfetch/configs/ip_info.jsonc";
            memfetch = "fastfetch --config ~/.config/fastfetch/configs/mem.jsonc";

            # Development Tools
            nv = "nvim";

            # Custom Scripts
            colors = "$HOME/scripts/print_colors.sh";
            timer = "$HOME/scripts/live_timer.sh";

            # Hyprland/Cava Window Management
            caval = "hyprctl dispatch setfloating && hyprctl dispatch resizeactive exact 162 1000 && hyprctl dispatch movewindow l && hyprctl dispatch movewindow d && hyprctl dispatch moveactive 15 -15 && cava";
            cavar = "hyprctl dispatch setfloating && hyprctl dispatch resizeactive exact 162 1000 && hyprctl dispatch movewindow r && hyprctl dispatch movewindow d && hyprctl dispatch moveactive -15 -15 && cava";
        };


        # Custom prompt - using the same style as your PS1
        initContent = ''
            # Custom prompt configuration
            export PS1=$'\n%F{110}%B%b %F{117}%1~%f%F{110} ❯ %f'


            # Color codes for functions
            GREEN="\e[32m"
            RED="\e[31m"
            YELLOW="\e[33m"
            BLUE="\e[34m"
            RESET="\e[0m"


	    # Shell functions

            # Tree with custom depth level
            ltl() {
                if [[ -z "$1" ]]; then
                    echo -e "''${YELLOW}Usage:''${RESET} ltl <depth_level>"
                        return 1
                        fi
                        eza --color=always --tree --level="$1"
            }

            # Copy file content to clipboard
            copyfile() {
                if [[ -z "$1" ]]; then
                    echo -e "''${YELLOW}Usage:''${RESET} copyfile <filename>."
                        return 1
                        fi

                        if [[ ! -f "$1" ]]; then
                            echo -e "''${RED} Error:''${RESET} File '$1' not found."
                                return 1
                                fi

                                if wl-copy < "$1"; then
                                    echo -e "''${GREEN} Success:''${RESET} $1's content copied to clipboard."
                                else
                                    echo -e "''${RED} Error:''${RESET} Failed to copy file content."
                                        return 1
                                        fi
            }

            # Copy current path to clipboard
                    cpwd() {
                        local current_path=$(pwd)
                            if echo "$current_path" | wl-copy; then
                                echo -e "''${GREEN} Success:''${RESET} '$current_path' copied to clipboard."
                            else
                                echo -e "''${RED} Error:''${RESET} Failed to copy path."
                                    return 1
                                    fi
                    }

            # Get weather information for a city (defaults to Lisbon)
                    weather() {
                        local city="''${1:-Lisbon}"
                            local format="''${2:-3}"

                            if ! command -v curl >/dev/null 2>&1; then
                                echo -e "''${RED} Error:''${RESET} curl is required for weather function."
                                    return 1
                                    fi

                                    echo -e "''${BLUE} Getting weather for ''${city}...''${RESET}"
                                    curl -s "wttr.in/''${city}?format=''${format}" || {
                                        echo -e "''${RED} Error:''${RESET} Failed to fetch weather data. Check your internet connection."
                                            return 1
                                    }
                        echo
                    }

                    # Extended weather with more details
                            weatherfull() {
                                local city="''${1:-Lisbon}"

                                    if ! command -v curl >/dev/null 2>&1; then
                                        echo -e "''${RED} Error:''${RESET} curl is required for weather function."
                                            return 1
                                            fi

                                            echo -e "''${BLUE} Getting detailed weather for ''${city}...''${RESET}"
                                            curl -s "wttr.in/''${city}" || {
                                                echo -e "''${RED} Error:''${RESET} Failed to fetch weather data. Check your internet connection."
                                                    return 1
                                            }
                            }
            '';

        # Enable plugins
        autosuggestion.enable = true;
        enableCompletion = true;
        syntaxHighlighting.enable = true;
    };

    # PATH additions - Home Manager way
    home.sessionPath = [
        "$HOME/.local/bin"
    ];

    # Install required packages
    home.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        eza          # Modern replacement for ls
        fastfetch    # System information tool
        curl         # For weather functions
        wl-clipboard # For clipboard functions
        cava         # Audio visualizer (for your Hyprland aliases)
    ];


    home.file = {
    };

    home.sessionVariables = {
    EDITOR = "nvim";
    };

    programs.home-manager.enable = true;
}
