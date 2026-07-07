{pkgs, ...}: {
  home.packages = with pkgs; [
    gh
    curl
    eza
    ripgrep
    jq
    zip
    unzip
  ];
}
