{
  config,
  lib,
  ...
}: let
  colors = config.colorScheme.palette;

  # Zathura ignores the alpha bytes in 8-digit hex (#rrggbbaa). Its parser only
  # honours alpha via the rgba() form. Convert palette hex to rgba with given opacity.
  hexToRgba = hex: alpha: let
    r = lib.fromHexString (builtins.substring 0 2 hex);
    g = lib.fromHexString (builtins.substring 2 2 hex);
    b = lib.fromHexString (builtins.substring 4 2 hex);
  in "rgba(${toString r}, ${toString g}, ${toString b}, ${alpha})";
in {
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";

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

      highlight-color = hexToRgba colors.base0A "0.3"; # inactive matches
      highlight-active-color = hexToRgba colors.base0D "0.5"; # current match

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
