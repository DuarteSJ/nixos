{
  config,
  pkgs,
  ...
}: {
  home.packages = [
    (pkgs.writeShellScriptBin "devenv" ''
      set -e

      # Check if flake.nix already exists
      if [ -f flake.nix ]; then
        ${pkgs.coreutils}/bin/echo -e "\033[1;33m⚠️  Warning:\033[0m flake.nix already exists."
        ${pkgs.coreutils}/bin/echo -n "Do you want to replace it? (y/N): "
        read -r response
        if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
          ${pkgs.coreutils}/bin/echo "Aborted."
          exit 0
        fi
      fi

      ${pkgs.coreutils}/bin/echo -e "\033[1;34m🔨 Creating development environment...\033[0m"

      # Create flake.nix
      ${pkgs.coreutils}/bin/cat > flake.nix << 'FLAKEEOF'
{
  description = "Development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    myFork.url = "github:DuarteSJ/nixpkgs/current";
  };

  outputs = {
    self,
    nixpkgs,
    myFork,
    ...
  }: let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";
    spkgs = myFork.legacyPackages."x86_64-linux";

    pythonV = "python3"; # python310, python313, python38, ...

    customEnvVars = '''
      export VAR="value"
      export OTHER_VAR="other value"
    ''';

    customAliases = '''
      alias format='nix run nixpkgs#cljfmt -- fix'
      alias lint='nix run nixpkgs#cljfmt -- check'
      alias format='black .'
      alias lint='flake8 .'
    ''';

    # Packages from nixpkgs
    normalPackages = with pkgs; [
      # feh
      # unzip
      (pkgs.''${pythonV}.withPackages (p: [
        # p.numpy
      ]))
    ];

    # Packages from my fork
    specialPackages = with spkgs; [
      (spkgs.''${pythonV}.withPackages (p: [
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
      shellHook = '''
        echo -e "\n\033[1;36m🚀 Development shell activated!\033[0m"
        echo -e "\033[0;90m    → Environment: (dev-env)\033[0m"

        ''${customEnvVars}
        ZSH_CMDS="''${customAliases}" exec zsh
      ''';
    };
  };
}
FLAKEEOF

      ${pkgs.coreutils}/bin/echo -e "\033[1;32m✓\033[0m Created flake.nix"
      ${pkgs.coreutils}/bin/echo ""
      ${pkgs.coreutils}/bin/echo -e "\033[1;35m✨ Done!\033[0m Next steps:"
      ${pkgs.coreutils}/bin/echo -e "  \033[0;36m1.\033[0m Edit flake.nix to configure packages"
      ${pkgs.coreutils}/bin/echo -e "  \033[0;36m2.\033[0m Run: \033[1;37mnix develop\033[0m"
    '')
  ];
}
