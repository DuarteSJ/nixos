{
  description = "Rust Development Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (nixpkgs) lib;

    customEnvVars = {
    };

    normalPackages = with pkgs; [
      rustc
      cargo
      rust-analyzer
      rustfmt
      clippy
      #cargo-edit
      #cargo-audit
      #cargo-watch
      #cargo-tarpaulin
    ];

    customScripts = with pkgs; [
    ];

    envExports = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (k: v: "export ${k}=${v}") customEnvVars
    );
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "rust";
      packages = normalPackages ++ customScripts;
      shellHook = ''
        echo -e "\n\033[1;36m🦀 Rust shell activated!\033[0m"
        echo -e "\033[0;90m    → Environment: (rust-env)\033[0m"

        ${envExports}
      '';
    };
  };
}
