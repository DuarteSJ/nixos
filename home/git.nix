{ config, ... }: {
  programs.git = {
    enable = true;
    settings = {
      user.name = "DuarteSJ";
      user.email = "ddduarte@sapo.pt";

      # Move extraConfig here
      init.defaultBranch = "main";
      alias.lg = "log --graph --decorate --pretty=format:'%C(yellow)%h%Creset %C(cyan)%ad%Creset %C(green)%an%Creset %s' --date=short --all";
    };
  };

  programs.delta = {
    enable = true;
    options = {
      navigate = true;
      light = false;
      side-by-side = true;
      line-numbers = true;
      syntax-theme = config.colorScheme.name;
    };
    enableGitIntegration = true; # explicit now
  };
}
