_: {
  # Night-time blue-light filter + screen dimming.
  # hyprsunset runs as a service and switches profile by time of day
  # Handles its own schedule, no systemd timer needed.
  services.hyprsunset = {
    enable = true;
    settings = {
      profile = [
        {
          # Daytime: neutral, no filter.
          time = "6:30";
          identity = true;
        }
        {
          # Night (from 23:30): warmer colour, dimmer screen.
          time = "23:30";
          temperature = 4000;
          gamma = 0.7;
        }
      ];
    };
  };
}
