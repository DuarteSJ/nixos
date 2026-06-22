{pkgs, ...}: {
  users.users.duartesj = {
    isNormalUser = true;
    description = "Duarte S. Jose";
    shell = pkgs.zsh;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKaUcoEtcYjJQVwOE8hjF9JJ+HMAe4/PsjIJv5M6u1HN ddduarte@sapo.pt"
    ];
  };

  programs.zsh.enable = true;
}
