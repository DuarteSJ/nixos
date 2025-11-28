{
  description = "Generic Development environment. Customize as needed.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    myFork.url = "github:DuarteSJ/nixpkgs/current";
  };

  outputs = {
    nixpkgs,
    myFork,
    ...
  }: let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";
    spkgs = myFork.legacyPackages."x86_64-linux";

    pythonV = "python3"; # python310, python313, python38, ...

    customEnvVars = ''
      export VAR="value"
      export OTHER_VAR="other value"
    '';

    customAliases = ''
      alias format='nix run nixpkgs#cljfmt -- fix'
      alias lint='nix run nixpkgs#cljfmt -- check'
      alias format='black .'
      alias lint='flake8 .'
    '';

    # Packages from nixpkgs
    normalPackages = with pkgs; [
      # feh
      # unzip
      (pkgs.${pythonV}.withPackages (p: [
        # p.numpy
      ]))
    ];

    # Packages from my fork
    specialPackages = with spkgs; [
      (spkgs.${pythonV}.withPackages (p: [
        # Jupyter+nvim integration (requires the nvim plugin)
        # p.jupynium
        # p.nbclassic
        # p.notebook
      ]))
    ];
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      name = "dev";
      packages = normalPackages ++ specialPackages;
      shellHook = ''
        echo -e "\n\033[1;36m🚀 Development shell activated!\033[0m"
        echo -e "\033[0;90m    → Environment: (dev-env)\033[0m"

        ${customEnvVars}
        ZSH_CMDS="${customAliases}" exec zsh
      '';
    };
  };
}
