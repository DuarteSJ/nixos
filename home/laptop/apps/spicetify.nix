{
  config,
  pkgs,
  inputs,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  colors = config.colorScheme.palette;
in {
  programs.spicetify = {
    enable = true;

    theme = spicePkgs.themes.ziro;

    # Ziro's roles (its color.ini): `shadow` is the *text* drawn on buttons,
    # the active tab and the selected row, so it must be the dark base00
    # against the bright accents; `selected-row`/`tab-active` are those
    # accents (missing keys fell back to greys at ~1.7:1).  With Nord:
    # base00 on base0C 6.2:1, on base0D 4.6:1; base05 on base02 7.1:1.
    customColorScheme = {
      text = colors.base05;
      subtext = colors.base04;
      main = colors.base00;
      sidebar = colors.base01;
      player = colors.base02;
      card = colors.base01;
      shadow = colors.base00;
      "selected-row" = colors.base0C;
      "tab-active" = colors.base0C;
      button = colors.base0D;
      "button-active" = colors.base0C;
      # Volume/seek track, scrollbar handle, borders and row hover.
      "button-disabled" = colors.base02;
      notification = colors.base0B;
      "notification-error" = colors.base08;
      misc = colors.base01;
    };

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
