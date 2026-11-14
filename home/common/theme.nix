{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types;

  schemeType = types.submodule ({name, ...}: {
    options = {
      name = mkOption {type = types.str;};
      slug = mkOption {
        description = "The scheme's key in `themes` (derived, read-only).";
        type = types.str;
        readOnly = true;
      };
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
    # `name` here is the module argument (the attrsOf key), not the option.
    # A definition rather than a default, so readOnly rejects any override.
    config.slug = name;
  });

  builtinSchemes = {
    nord = {
      name = "Nord";
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
    description = "Resolved active color scheme (read-only): the `themes` entry selected by vars.theme.";
    # Already type-checked as a themes entry; re-merging it through
    # schemeType would re-derive slug from this option's own name.
    type = types.raw;
    readOnly = true;
  };

  # A missing key must fail here, not in an assertion: consumers force
  # colorScheme while the config is evaluated, before assertions are checked.
  config.colorScheme =
    config.themes.${
      config.vars.theme
    }
    or (throw "vars.theme = \"${config.vars.theme}\" is not in themes (known: ${
      lib.concatStringsSep ", " (lib.attrNames config.themes)
    }).");
}
