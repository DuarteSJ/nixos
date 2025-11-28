{
  description = "Python Development Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    nixpkgs,
    ...
  }: let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";

    pythonV = "python3"; # python310, python313, python38, ...

    customEnvVars = ''
    '';

    customAliases = ''
      alias format='black .'
      alias lint='flake8 .'
    '';

    # Packages from nixpkgs
    normalPackages = with pkgs; [
      (pkgs.${pythonV}.withPackages (p: [
        # p.numpy
      ]))
    ];

  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      name = "python";
      packages = normalPackages;
      shellHook = ''
        echo -e "\n\033[1;36m🐍 Python shell activated!\033[0m"
        echo -e "\033[0;90m    → Environment: (python-env)\033[0m"

        ${customEnvVars}
        ZSH_CMDS="${customAliases}" exec zsh
      '';
    };
  };
}
