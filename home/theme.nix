{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;

  schemeType = types.submodule {
    options = {
      name = mkOption {type = types.str;};
      slug = mkOption {type = types.str;};
      palette = mkOption {type = types.attrsOf types.str;};
    };
  };

  builtinSchemes = {
    nord = {
      name = "Nord";
      slug = "nord";
      palette = {
        base00 = "2E3440";
        base01 = "3B4252";
        base02 = "434C5E";
        base03 = "4C566A";
        base04 = "D8DEE9";
        base05 = "E5E9F0";
        base06 = "ECEFF4";
        base07 = "8FBCBB";
        base08 = "BF616A";
        base09 = "D08770";
        base0A = "EBCB8B";
        base0B = "A3BE8C";
        base0C = "88C0D0";
        base0D = "81A1C1";
        base0E = "B48EAD";
        base0F = "5E81AC";
      };
    };

    mono = {
      name = "Mono";
      slug = "mono";
      palette = {
        base00 = "0f0f11";
        base01 = "17171a";
        base02 = "232328";
        base03 = "3a3a42";
        base04 = "6e6e78";
        base05 = "c8c8d0";
        base06 = "e0e0e4";
        base07 = "f2f2f5";
        base08 = "b08585";
        base09 = "b09585";
        base0A = "b0a585";
        base0B = "85a090";
        base0C = "85a0a8";
        base0D = "d0d0d6";
        base0E = "a090b0";
        base0F = "5a5a64";
      };
    };

    rose-pine-moon = {
      name = "Rose Pine Moon";
      slug = "rose-pine-moon";
      palette = {
        base00 = "232136";
        base01 = "2a273f";
        base02 = "393552";
        base03 = "6e6a86";
        base04 = "908caa";
        base05 = "e0def4";
        base06 = "e0def4";
        base07 = "c4a7e7";
        base08 = "eb6f92";
        base09 = "f6c177";
        base0A = "ea9a97";
        base0B = "3e8fb0";
        base0C = "9ccfd8";
        base0D = "c4a7e7";
        base0E = "f6c177";
        base0F = "56526e";
      };
    };

    gruvbox-dark = {
      name = "Gruvbox Dark";
      slug = "gruvbox-dark";
      palette = {
        base00 = "282828";
        base01 = "3c3836";
        base02 = "504945";
        base03 = "665c54";
        base04 = "bdae93";
        base05 = "d5c4a1";
        base06 = "ebdbb2";
        base07 = "fbf1c7";
        base08 = "fb4934";
        base09 = "fe8019";
        base0A = "fabd2f";
        base0B = "b8bb26";
        base0C = "8ec07c";
        base0D = "83a598";
        base0E = "d3869b";
        base0F = "d65d0e";
      };
    };

    tokyo-night = {
      name = "Tokyo Night";
      slug = "tokyo-night";
      palette = {
        base00 = "1a1b26";
        base01 = "1f2335";
        base02 = "292e42";
        base03 = "565f89";
        base04 = "9aa5ce";
        base05 = "c0caf5";
        base06 = "cfc9c2";
        base07 = "d5d6db";
        base08 = "f7768e";
        base09 = "ff9e64";
        base0A = "e0af68";
        base0B = "9ece6a";
        base0C = "73daca";
        base0D = "7aa2f7";
        base0E = "bb9af7";
        base0F = "db4b4b";
      };
    };

    catppuccin-mocha = {
      name = "Catppuccin Mocha";
      slug = "catppuccin-mocha";
      palette = {
        base00 = "1e1e2e";
        base01 = "181825";
        base02 = "313244";
        base03 = "45475a";
        base04 = "585b70";
        base05 = "cdd6f4";
        base06 = "f5e0dc";
        base07 = "b4befe";
        base08 = "f38ba8";
        base09 = "fab387";
        base0A = "f9e2af";
        base0B = "a6e3a1";
        base0C = "94e2d5";
        base0D = "89b4fa";
        base0E = "cba6f7";
        base0F = "f2cdcd";
      };
    };
  };
in {
  options.themes = {
    schemes = mkOption {
      description = "All known color schemes, keyed by slug.";
      type = types.attrsOf schemeType;
      default = builtinSchemes;
    };

    active = mkOption {
      description = "Slug of the active scheme. Must exist in themes.schemes.";
      type = types.str;
      default = "nord";
    };
  };

  options.colorScheme = mkOption {
    description = "Resolved active color scheme (read-only).";
    type = schemeType;
    readOnly = true;
  };

  config = {
    assertions = [
      {
        assertion = config.themes.schemes ? ${config.themes.active};
        message = "themes.active = \"${config.themes.active}\" is not in themes.schemes (known: ${
          lib.concatStringsSep ", " (lib.attrNames config.themes.schemes)
        }).";
      }
    ];

    colorScheme = config.themes.schemes.${config.themes.active};
  };
}
