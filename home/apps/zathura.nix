{
  config,
  pkgs,
  ...
}: let
  colors = config.colorScheme.palette;
in {
  programs.zathura = {
    enable = true;
    options = {
      recolor = false;
      recolor-keephue = false;

      default-bg = "#${colors.base00}";
      default-fg = "#${colors.base05}";

      statusbar-fg = "#${colors.base05}";
      statusbar-bg = "#${colors.base01}";

      inputbar-bg = "#${colors.base01}";
      inputbar-fg = "#${colors.base06}";

      completion-bg = "#${colors.base01}";
      completion-fg = "#${colors.base06}";
      completion-highlight-bg = "#${colors.base0D}";
      completion-highlight-fg = "#${colors.base00}";

      notification-bg = "#${colors.base01}";
      notification-fg = "#${colors.base05}";
      notification-error-bg = "#${colors.base08}";
      notification-error-fg = "#${colors.base00}";
      notification-warning-bg = "#${colors.base09}";
      notification-warning-fg = "#${colors.base00}";

      # these are opaque
      # highlight-color = "#${colors.base0A}";
      # highlight-active-color = "#${colors.base0D}";

      recolor-lightcolor = "#${colors.base00}";
      recolor-darkcolor = "#${colors.base06}";
    };
  };
}
