{
  programs.btop = {
    enable = true;
    settings = {
      # Use terminal colors
      color_theme = "TTY";
      theme_background = false; # Use terminal background

      # Graphs
      rounded_corners = true;
      graph_symbol = "braille";

      # Update intervals
      update_ms = 1000;

      # Process sorting
      proc_sorting = "cpu lazy";
      proc_tree = false;
      proc_colors = true;
      proc_gradient = true;

      # CPU
      show_cpu_freq = true;
      cpu_graph_upper = "total";
      cpu_graph_lower = "total";

      # Memory
      show_disks = true;
      show_io_stat = true;
      io_mode = false;

      # Network
      net_auto = true;
      net_sync = true;
      net_iface = "";

      # Other
      vim_keys = true;
      check_temp = true;
      show_battery = true;
      show_coretemp = true;
      temp_scale = "celsius";
    };
  };
}
