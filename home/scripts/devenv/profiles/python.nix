{
  description = "Python Development Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    inherit (nixpkgs) lib;

    pythonV = "python3"; # python310, python313, python38, ...

    customEnvVars = {
    };

    normalPackages = with pkgs; [
      (pkgs.${pythonV}.withPackages (p: [
        # p.numpy
      ]))
    ];

    customScripts = with pkgs; [
      (writeShellScriptBin "format" "black .")
      (writeShellScriptBin "lint" "flake8 .")
    ];

    envExports = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (k: v: "export ${k}=${v}") customEnvVars
    );
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "python";
      packages = normalPackages ++ customScripts;
      shellHook = ''
        echo -e "\n\033[1;36m🐍 Python shell activated!\033[0m"
        echo -e "\033[0;90m    → Environment: (python-env)\033[0m"

        ${envExports}
      '';
    };
  };
}
