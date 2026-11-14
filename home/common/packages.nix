{pkgs, ...}: {
  home.packages = with pkgs; [
    gh
    curl
    eza
    ripgrep
    jq
    file
    zip
    unzip
  ];
}
