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
      batTheme = mkOption {
        description = "bat/delta syntax-theme name for this scheme (must be a theme bat ships or knows; e.g. \"Nord\", \"ansi\").";
        type = types.str;
        default = "ansi";
      };
      nvf = mkOption {
        description = "nvf vim.theme settings for this scheme (merged into programs.nvf.settings.vim.theme); at minimum the theme name.";
        type = types.attrsOf types.anything;
        default = {};
        example = {
          name = "gruvbox";
          style = "dark";
        };
      };
    };
  };

  builtinSchemes = {
    # Light-on-deep teal, made for the liquid-glass frame: white text over
    # frosted turquoise, aqua accent.
    lagoon = {
      name = "Lagoon";
      slug = "lagoon";
      batTheme = "base16";
      nvf = {
        name = "base16";
        base16-colors = builtinSchemes.lagoon.palette;
      };
      palette = {
        base00 = "0f1c24";
        base01 = "16262f";
        base02 = "1f3440";
        base03 = "3a5562";
        base04 = "9fb6c0";
        base05 = "dce9ee";
        base06 = "eef6f8";
        base07 = "ffffff";
        base08 = "f2777a";
        base09 = "f6a86c";
        base0A = "f2d27a";
        base0B = "8fd6a8";
        base0C = "6ee0e0";
        base0D = "7cc4f2";
        base0E = "b9a6f2";
        base0F = "e09f7d";
      };
    };

    nord = {
      name = "Nord";
      slug = "nord";
      batTheme = "Nord";
      nvf = {name = "nord";};
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
  };
in {
  options.themes = mkOption {
    description = "All known color schemes, keyed by slug. Active one is selected via vars.theme.";
    type = types.attrsOf schemeType;
    default = builtinSchemes;
  };

  options.colorScheme = mkOption {
    description = "Resolved active color scheme (read-only).";
    type = schemeType;
    readOnly = true;
  };

  config = {
    assertions =
      [
        {
          assertion = config.themes ? ${config.vars.theme};
          message = "vars.theme = \"${config.vars.theme}\" is not in themes (known: ${
            lib.concatStringsSep ", " (lib.attrNames config.themes)
          }).";
        }
      ]
      # Guard the slug/key dual source of truth: every scheme's slug must
      # equal its attribute key, since consumers read .slug as the key.
      ++ lib.mapAttrsToList (key: scheme: {
        assertion = scheme.slug == key;
        message = "themes.${key}.slug = \"${scheme.slug}\" must equal its attr key \"${key}\".";
      })
      config.themes;

    colorScheme = config.themes.${config.vars.theme};
  };
}
