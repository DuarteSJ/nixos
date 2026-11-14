{config, ...}: {
  programs.git = {
    enable = true;
    settings = {
      user.name = "DuarteSJ";
      user.email = "ddduarte@sapo.pt";

      init.defaultBranch = "main";
      alias.lg = "log --graph --decorate --pretty=format:'%C(yellow)%h%Creset%C(auto)%d%Creset %C(cyan)%ad%Creset %C(green)%an%Creset %s' --date=short --all";
      alias.alias = "config --show-origin --get-regexp alias";
    };
  };

  programs.delta = {
    enable = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
      syntax-theme = config.colorScheme.batTheme;
    };
    enableGitIntegration = true;
  };
}
