{ config, pkgs, ... }:
{
  # Create custom NIX logo file
  xdg.configFile."fastfetch/logos/nix.txt".text = ''
    ░███    ░██ 
    ░████   ░██ 
    ░██░██  ░██ 
    ░██ ░██ ░██ 
    ░██  ░██░██ 
    ░██   ░████ 
    ░██    ░███ 
                
                
                
      ░██████   
        ░██     
        ░██     
        ░██     
        ░██     
        ░██     
      ░██████   
                
                
                
    ░██    ░██  
     ░██  ░██   
      ░██░██    
       ░███     
      ░██░██    
     ░██  ░██   
    ░██    ░██  
  '';
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "~/.config/fastfetch/logos/nix.txt";
        padding = {
          right = 3;
          top = 1;
        };
      };
      display = {
        size = {
          binaryPrefix = "si";
        };
        color = "blue";
        separator = " ";
        key = {
          width = 5;
        };
      };
      modules = [
        # Header with system name
        {
          type = "custom";
          format = "┌──────────────────────────────────────────────────────────┐";
        }
        {
          type = "custom"; 
          format = "│                        DuarteSJ                        │";
        }
        {
          type = "custom";
          format = "└──────────────────────────────────────────────────────────┘";
        }
        "break"
        # Hardware section
        {
          type = "custom";
          format = "┌──────────────────────── Hardware ────────────────────────┐";
        }
        {
          type = "cpu";
          key = "├ 󰻠 ";
          format = "{1} ({3}) @ {7} GHz";
        }
        {
          type = "gpu";
          key = "├ 󰍛 ";
        }
        {
          type = "memory";
          key = "├ 󰑭 ";
          format = "{1} / {2} ({3})";
        }
        {
          type = "custom";
          format = "└──────────────────────────────────────────────────────────┘";
        }
        "break"
        # Operating System section  
        {
          type = "custom";
          format = "┌──────────────────── Operating System ────────────────────┐";
        }
        {
          type = "os";
          key = "├ 󱄅 ";
        }
        {
          type = "kernel";
          key = "├ 󰌽 ";
        }
        {
          type = "packages";
          key = "├ 󰏖 ";
        }
        {
          type = "custom";
          format = "└──────────────────────────────────────────────────────────┘";
        }
        "break"
        # Desktop section
        {
          type = "custom";
          format = "┌──────────────────────── Desktop ─────────────────────────┐";
        }
        {
          type = "wm";
          key = "├ 󰨇 ";
        }
        {
          type = "display";
          key = "├ 󰍹 ";
        }
        {
          type = "terminal";
          key = "├ 󰆍 ";
        }
        {
          type = "custom";
          format = "└──────────────────────────────────────────────────────────┘";
        }
        "break"
        # Terminal / Shell section
        {
          type = "custom";
          format = "┌──────────────────── Terminal / Shell ────────────────────┐";
        }
        {
          type = "shell";
          key = "├ 󰆍 ";
        }
        {
          type = "terminalfont";
          key = "├ 󰛖 ";
        }
        {
          type = "custom";
          format = "└──────────────────────────────────────────────────────────┘";
        }
	# Color palette section
        {
          type = "colors";
          paddingLeft = 22;
          symbol = "star";
        }
      ];
    };
  };
}
