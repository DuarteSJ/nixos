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

    # Override spice CSS variables with nix-colors palette
    customColorScheme = {
      text = colors.base05;
      subtext = colors.base04;
      main = colors.base00;
      sidebar = colors.base01;
      player = colors.base02;
      card = colors.base01;
      shadow = colors.base03;
      button = colors.base0D;
      "button-active" = colors.base0C;
      notification = colors.base0B;
      "notification-error" = colors.base08;
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
