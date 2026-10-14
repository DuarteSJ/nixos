{config, ...}: let
  colors = config.colorScheme.palette;
in {
  # Only what differs from cava's defaults (cava 0.10 config.c).
  programs.cava = {
    enable = true;
    settings = {
      general = {
        # Bars' width and space between bars, in characters.
        bar_width = 3;
        bar_spacing = 2;
      };

      # Pulse first (cava's own fallback order tries others before it).
      input.method = "pulse";

      # Default is 'noncurses'.
      output.method = "ncurses";

      color.foreground = "'#${colors.base0C}'"; # nord8 - bright ice blue
    };
  };
}
