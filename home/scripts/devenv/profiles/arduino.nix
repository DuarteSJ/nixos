{
  description = "StreetAware Development Environment";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
  outputs = { nixpkgs, ... }: let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";
    pythonV = "python3";
    customEnvVars = ''
      export ARDUINO_DATA_DIR=$PWD/.arduino
    '';
    customAliases = ''
      alias aupdate='arduino-cli core update-index'
      alias ainstall-avr='arduino-cli core install arduino:avr'
      alias acompile='arduino-cli compile --fqbn arduino:avr:uno'
      alias aupload='arduino-cli upload --fqbn arduino:avr:uno -p /dev/ttyACM0'
      alias serial='picocom /dev/ttyACM0 -b 115200'
    '';
    normalPackages = with pkgs; [
      arduino-cli
      picocom
      (pkgs.${pythonV}.withPackages (p: [
        p.flask
      ]))
    ];
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      name = "streetaware";
      packages = normalPackages;
      shellHook = ''
        echo -e "\n\033[1;34m💡 StreetAware shell activated!\033[0m"
        echo -e "\033[0;90m    → Environment: (streetaware-env)\033[0m"
        echo -e "\nFirst time setup:"
        echo "  aupdate"
        echo "  ainstall-avr"
        ${customEnvVars}
        ZSH_CMDS="${customAliases}" exec zsh
      '';
    };
  };
}
