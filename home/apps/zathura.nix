{config, ...}: let
  colors = config.colorScheme.palette;
in {
  programs.zathura = {
    enable = true;
    options = {
      # Recolor settings
      recolor = false;
      recolor-keephue = false;

      # Base colors
      default-bg = "#${colors.base00}";
      default-fg = "#${colors.base05}";

      # Statusbar
      statusbar-fg = "#${colors.base05}";
      statusbar-bg = "#${colors.base01}";

      # Inputbar
      inputbar-bg = "#${colors.base01}";
      inputbar-fg = "#${colors.base06}";

      # Completion
      completion-bg = "#${colors.base01}";
      completion-fg = "#${colors.base06}";
      completion-group-bg = "#${colors.base02}";
      completion-group-fg = "#${colors.base05}";
      completion-highlight-bg = "#${colors.base0D}";
      completion-highlight-fg = "#${colors.base00}";

      # Index (table of contents)
      index-bg = "#${colors.base00}";
      index-fg = "#${colors.base0C}";
      index-active-bg = "#${colors.base0D}";
      index-active-fg = "#${colors.base00}";

      # Notifications
      notification-bg = "#${colors.base01}";
      notification-fg = "#${colors.base05}";
      notification-error-bg = "#${colors.base08}";
      notification-error-fg = "#${colors.base00}";
      notification-warning-bg = "#${colors.base09}";
      notification-warning-fg = "#${colors.base00}";

      # TODO: these are opaque in zathura. need to look into this
      # highlight-color = "#${colors.base0A}";
      # highlight-active-color = "#${colors.base0D}";

      # Recolor mode colors
      recolor-lightcolor = "#${colors.base00}";
      recolor-darkcolor = "#${colors.base06}";

      # Rendering settings
      render-loading = true;
      render-loading-bg = "#${colors.base00}";
      render-loading-fg = "#${colors.base03}";
    };
  };
}
