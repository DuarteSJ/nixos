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
