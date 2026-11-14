_: {
  # Only what differs from `btop --default-config`.
  programs.btop = {
    enable = true;
    settings = {
      # Use terminal colors and background
      color_theme = "TTY";
      theme_background = false;

      update_ms = 1000;

      cpu_graph_upper = "total";
      cpu_graph_lower = "total";

      vim_keys = true;
    };
  };
}
