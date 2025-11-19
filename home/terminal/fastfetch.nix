{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        type = "none";
      };
      display = {
        separator = " ";
      };
      modules = [
        "title"
        "os"
        "kernel"
        "shell"
        "uptime"
      ];
    };
  };
}
