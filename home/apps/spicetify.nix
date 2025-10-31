{
  config,
  pkgs,
  inputs,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  colors = config.colorScheme.palette;

  # Flow theme with nix-colors integration
  flowThemeWithColors = {
    name = "flow-nix-colors";
    src = spicePkgs.themes.ziro.src;

    # Enable theme features
    injectCss = true;
    injectThemeJs = true;
    replaceColors = true;
    sidebarConfig = true;
    homeConfig = true;
    overwriteAssets = false;

    # Additional CSS to replace Flow theme colors with nix-colors
    additionalCss = ''
      :root {
        /* Direct Flow theme color replacements */
        --spice-text: #${colors.base05} !important;
        --spice-subtext: #${colors.base04} !important;
        --spice-main: #${colors.base00} !important;
        --spice-sidebar: #${colors.base01} !important;
        --spice-player: #${colors.base02} !important;
        --spice-card: #${colors.base01} !important;
        --spice-shadow: #${colors.base03} !important;
        --spice-button: #${colors.base0D} !important;
        --spice-button-active: #${colors.base0C} !important;
        --spice-notification: #${colors.base0B} !important;
        --spice-notification-error: #${colors.base08} !important;
      }
    '';
  };
in {
  programs.spicetify = {
    enable = true;

    theme = flowThemeWithColors;

    enabledExtensions = with spicePkgs.extensions; [
      adblock
      shuffle
      keyboardShortcut
      loopyLoop
    ];

    enabledCustomApps = with spicePkgs.apps; [
      newReleases
      lyricsPlus
    ];
  };
}
