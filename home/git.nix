{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;
    userName = "DuarteSJ";
    userEmail = "ddduarte@sapo.pt";
    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
        side-by-side = true;
        line-numbers = true;
        syntax-theme = "Nord";
      };
    };
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}

