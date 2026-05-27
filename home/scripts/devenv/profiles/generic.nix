{
  description = "Generic development environment. Customize as needed.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (nixpkgs) lib;

    # Env vars exported into the shell when direnv loads the flake.
    customEnvVars = {
      # FOO = "bar";
    };

    # Packages from nixpkgs.
    normalPackages = with pkgs; [
      # hello
    ];

    # Project specific commands
    customScripts = with pkgs; [
      # (writeShellScriptBin "format" "black .")
      # (writeShellScriptBin "lint" "flake8 .")
    ];

    envExports = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (k: v: "export ${k}=${v}") customEnvVars
    );
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "dev";
      packages = normalPackages ++ customScripts;
      shellHook = ''
        echo -e "\n\033[1;36m🚀 Dev shell activated!\033[0m"
        echo -e "\033[0;90m    → Environment: (dev-env)\033[0m"

        ${envExports}
      '';
    };
  };
}
