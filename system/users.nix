{pkgs, ...}: {
  users.users.duartesj = {
    isNormalUser = true;
    description = "Duarte S. Jose";
    shell = pkgs.zsh;
    extraGroups = ["wheel" "networkmanager" "gamemode" "uinput"];
  };

  programs.zsh = {
    enable = true;
    # Home Manager runs compinit in ~/.zshrc; a second pass here cost ~28 ms
    # per shell.
    enableGlobalCompInit = false;
    # Default runs `promptinit && prompt suse`, which starship overwrites.
    promptInit = "";
  };
}
