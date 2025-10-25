{ config, ... }:
let
  colors = config.colorScheme.palette;
in
{
  programs.cava = {
    enable = true;
    settings = {
      general = {
        # Accepts only non-negative values.
        framerate = 60;

        # 'autosens' will attempt to decrease sensitivity if the bars peak. 1 = on, 0 = off
        # new as of 0.6.0 autosens of low values (dynamic range)
        autosens = 1;

        # Manual sensitivity in %. If autosens is enabled, this will only be the initial value.
        # 200 means double height. Accepts only non-negative values.
        sensitivity = 100;

        # The number of bars (0-200). 0 sets it to auto (fill up console).
        # Bars' width and space between bars in number of characters.
        bars = 0;
        bar_width = 3;
        bar_spacing = 2;
        
        # Lower and higher cutoff frequencies for lowest and highest bars
        # the bandwidth of the visualizer.
        # Note: there is a minimum total bandwidth of 43Mhz x number of bars.
        # Cava will automatically increase the higher cutoff if a too low band is specified.
        lower_cutoff_freq = 50;
        higher_cutoff_freq = 10000;

        # Seconds with no input before cava goes to sleep mode. Cava will not perform FFT or drawing and
        # only check for input once per second. Cava will wake up once input is detected. 0 = disable.
        sleep_timer = 0;
      };

      input = {
        # Audio capturing method. Possible methods are: 'pulse', 'alsa', 'fifo', 'sndio' or 'oss'.
        # Defaults to 'pulse', 'alsa' or 'fifo', in that order, dependent on what support cava was built with.
        method = "pulse";
      };

      output = {
        # Output method. Can be 'ncurses', 'noncurses', 'raw', 'noritake', 'sdl' or 'sdl_glsl'.
        method = "ncurses";

        # Visual channels. Can be 'stereo' or 'mono'.
        # 'stereo' mirrors both channels with low frequencies in center.
        # 'mono' outputs left to right lowest to highest frequencies.
        # 'mono_option' set mono to either take input from 'left', 'right' or 'average'.
        # set 'reverse' to 1 to display frequencies the other way around.
        channels = "stereo";
        mono_option = "average";
        reverse = 0;

        # Raw output target. A fifo will be created if target does not exist.
        raw_target = "/dev/stdout";

        # Raw data format. Can be 'binary' or 'ascii'.
        data_format = "binary";

        # Binary bit format, can be '8bit' (0-255) or '16bit' (0-65530).
        bit_format = "16bit";

        # Ascii max value. In 'ascii' mode range will run from 0 to value specified here
        ascii_max_range = 1000;

        # Ascii delimiters. In ascii format each bar and frame is separated by a delimiters.
        # Use decimal value in ascii table (i.e. 59 = ';' and 10 = '\n' (line feed)).
        bar_delimiter = 59;
        frame_delimiter = 10;

        # sdl window size and position. -1,-1 is centered.
        sdl_width = 1000;
        sdl_height = 500;
        sdl_x = -1;
        sdl_y = -1;

        # set label on bars on the x-axis. Can be 'frequency' or 'none'. Default: 'none'
        # 'frequency' displays the lower cut off frequency of the bar above.
        # Only supported on ncurses and noncurses output.
        xaxis = "none";

        # enable alacritty synchronized updates. 1 = on, 0 = off
        # removes flickering in alacritty terminal emulator.
        # defaults to off since the behaviour in other terminal emulators is unknown
        alacritty_sync = 0;
      };

      color = {
        # Colors can be one of seven predefined: black, blue, cyan, green, magenta, red, white, yellow.
        # Or defined by hex code '#rrggbb' (hex code must be within '').
        background = "default";
        foreground = "'#${colors.base0C}'"; # nord8 - bright ice blue

        # Gradient mode, only hex defined colors are supported,
        # background must also be defined in hex or remain commented out. 1 = on, 0 = off.
        # You can define as many as 8 different colors. They range from bottom to top of screen
        gradient = 0;
      };

      smoothing = {
        # Disables or enables the so-called "Monstercat smoothing" with or without "waves". Set to 0 to disable.
        monstercat = 0;
        waves = 0;
      };
    };
  };
}
