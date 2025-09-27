{ config, pkgs, ... }:
{
  programs.git = {
    enable = true;
    userName = "DuarteSJ";
    userEmail = "ddduarte@sapo.pt";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}

