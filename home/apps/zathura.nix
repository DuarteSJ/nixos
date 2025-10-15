{ config, pkgs, ... }:
let
  colors = config.colorScheme.palette;
in
{
  programs.zathura = {
    enable = true;
    
    options = {
      # Selection and clipboard
      selection-clipboard = "clipboard";
      
      # Window settings
      adjust-open = "width";
      statusbar-h-padding = 0;
      statusbar-v-padding = 0;
      page-padding = 1;
      
      # Zoom and scroll
      zoom-min = 10;
      scroll-step = 50;
      guioptions = "none";
      
      # Recolor settings (for dark mode reading)
      recolor = false;
      recolor-keephue = true;
    } // (if config.programs.zathura.useNixColors or false then {
      # Background and foreground colors
      default-bg = "#${colors.base00}";
      default-fg = "#${colors.base01}";
      
      # Statusbar colors
      statusbar-bg = "#${colors.base01}";
      statusbar-fg = "#${colors.base04}";
      
      # Inputbar colors
      inputbar-bg = "#${colors.base00}";
      inputbar-fg = "#${colors.base07}";
      
      # Notification colors
      notification-bg = "#${colors.base00}";
      notification-fg = "#${colors.base07}";
      notification-error-bg = "#${colors.base00}";
      notification-error-fg = "#${colors.base08}";
      notification-warning-bg = "#${colors.base00}";
      notification-warning-fg = "#${colors.base09}";
      
      # Highlight colors
      highlight-color = "#${colors.base0A}";
      highlight-active-color = "#${colors.base0D}";
      highlight-transparency = "0.4";
      
      # Completion menu colors
      completion-bg = "#${colors.base01}";
      completion-fg = "#${colors.base05}";
      completion-highlight-bg = "#${colors.base0D}";
      completion-highlight-fg = "#${colors.base00}";
      completion-group-bg = "#${colors.base00}";
      completion-group-fg = "#${colors.base0C}";
      
      # Index mode colors
      index-bg = "#${colors.base00}";
      index-fg = "#${colors.base05}";
      index-active-bg = "#${colors.base02}";
      index-active-fg = "#${colors.base0D}";
      
      # Recolor mode colors
      recolor-lightcolor = "#${colors.base00}";
      recolor-darkcolor = "#${colors.base06}";
    } else {});
  };
}
