{
  description = "StreetAware Development Environment";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    lib = nixpkgs.lib;
    pythonV = "python3";

    customEnvVars = {
      ARDUINO_DATA_DIR = "$PWD/.arduino";
    };

    normalPackages = with pkgs; [
      arduino-cli
      picocom
      (pkgs.${pythonV}.withPackages (p: [
        p.flask
      ]))
    ];

    customScripts = with pkgs; [
      (writeShellScriptBin "aupdate" "arduino-cli core update-index")
      (writeShellScriptBin "ainstall-avr" "arduino-cli core install arduino:avr")
      (writeShellScriptBin "acompile" "arduino-cli compile --fqbn arduino:avr:uno \"$@\"")
      (writeShellScriptBin "aupload" "arduino-cli upload --fqbn arduino:avr:uno -p /dev/ttyACM0 \"$@\"")
      (writeShellScriptBin "serial" "picocom /dev/ttyACM0 -b 115200")
    ];

    envExports = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (k: v: "export ${k}=${v}") customEnvVars
    );
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "streetaware";
      packages = normalPackages ++ customScripts;
      shellHook = ''
        echo -e "\n\033[1;34m💡 StreetAware shell activated!\033[0m"
        echo -e "\033[0;90m    → Environment: (streetaware-env)\033[0m"
        echo -e "\nFirst time setup:"
        echo "  aupdate"
        echo "  ainstall-avr"

        ${envExports}
      '';
    };
  };
}
