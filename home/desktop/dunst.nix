# NOTE: For future, consider that it is possible to set per app rules in dunst.
# TODO: Icon does not exist.
{
  config,
  pkgs,
  ...
}: let
  colors = config.colorScheme.palette;
  vars = config.vars;
in {
  services.dunst = {
    enable = true;
    settings = {
      global = {
        ### Display ###
        monitor = 0;
        follow = "mouse";

        ### Geometry ###
        width = "(200, 400)";
        height = "(0, 200)";
        origin = "bottom-right";
        offset = "(15, 15)";
        scale = 0;
        notification_limit = 5;

        ### Progress bar ###
        progress_bar = true;
        progress_bar_height = 10;
        progress_bar_frame_width = 1;
        progress_bar_min_width = 150;
        progress_bar_max_width = 400;
        progress_bar_corner_radius = vars.rounding;
        progress_bar_corners = "all";

        ### Icons ###
        icon_position = "left";
        min_icon_size = 32;
        max_icon_size = 64;
        icon_corner_radius = vars.rounding;
        icon_corners = "all";
        icon_path = "${pkgs.hicolor-icon-theme}/share/icons/hicolor/32x32/status/:${pkgs.hicolor-icon-theme}/share/icons/hicolor/32x32/devices/:${pkgs.hicolor-icon-theme}/share/icons/hicolor/32x32/apps/";
        icon_theme = "hicolor";

        ### Visual ###
        indicate_hidden = "yes";
        transparency = 0;
        separator_height = 2;
        padding = 12;
        horizontal_padding = 14;
        text_icon_padding = 12;
        frame_width = 1;
        gap_size = 8;
        separator_color = "frame";
        sort = "yes";
        corner_radius = vars.rounding;
        corners = "all";

        ### Text ###
        font = vars.font.name;
        line_height = 2;
        markup = "full";
        format = "<b>%s</b>\\n%b";
        alignment = "left";
        vertical_alignment = "center";
        show_age_threshold = 60;
        ellipsize = "middle";
        ignore_newline = "no";
        word_wrap = true;
        stack_duplicates = true;
        hide_duplicate_count = false;
        show_indicators = "yes";

        ### History ###
        sticky_history = "yes";
        history_length = 30;

        ### Misc ###
        browser = "xdg-open";
        always_run_script = true;
        title = "Dunst";
        class = "Dunst";
        ignore_dbusclose = false;

        ### Wayland (native, no xwayland needed) ###
        force_xwayland = false;
        force_xinerama = false;
        layer = "overlay";  # renders above other wayland surfaces

        ### Mouse ###
        mouse_left_click = "do_action";
        mouse_middle_click = "close_current";
        mouse_right_click = "close_all";

        ### Idle ###
        idle_threshold = 120;

        ### Action menu (rofi, wayland-native) ###
        dmenu = "rofi -dmenu -p dunst";
      };

      experimental = {
        per_monitor_dpi = false;
      };

      urgency_low = {
        background = "#${colors.base00}";
        foreground = "#${colors.base05}";
        frame_color = "#${colors.base03}";
        highlight = "#${colors.base0D}";
        timeout = 6;
        default_icon = "dialog-information";
      };

      urgency_normal = {
        background = "#${colors.base00}";
        foreground = "#${colors.base05}";
        frame_color = "#${colors.base0D}";
        highlight = "#${colors.base0D}";
        timeout = 10;
        default_icon = "dialog-information";
      };

      urgency_critical = {
        background = "#${colors.base00}";
        foreground = "#${colors.base08}";
        frame_color = "#${colors.base08}";
        highlight = "#${colors.base08}";
        timeout = 0;
        default_icon = "dialog-error";
      };
    };
  };
}
