{
  description = "Rust Development Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }: let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";

    customEnvVars = ''
    '';

    customAliases = ''
    '';

    # Packages from nixpkgs
    normalPackages = with pkgs; [
      rustc
      cargo
      rust-analyzer
      #cargo-edit
      #cargo-audit
      #cargo-watch
      #cargo-tarpaulin
      #clippy
      
    ];

  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      name = "rust";
      packages = normalPackages;
      shellHook = ''
        echo -e "\n\033[1;36m🦀 Rust shell activated!\033[0m"
        echo -e "\033[0;90m    → Environment: (rust-env)\033[0m"

        ${customEnvVars}
        ZSH_CMDS="${customAliases}" exec zsh
      '';
    };
  };
}
