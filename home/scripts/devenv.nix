{
  config,
  pkgs,
  ...
}: {
  home.packages = [
    (pkgs.writeShellScriptBin "devenv" ''
      set -e

      # Ask if this is a Python environment
      ${pkgs.coreutils}/bin/echo -n "Is this a Python environment? (y/N): "
      read -r is_python

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

      if [ "$is_python" = "y" ] || [ "$is_python" = "Y" ]; then
        # Create Python-specific flake.nix
        ${pkgs.coreutils}/bin/cat > flake.nix << 'FLAKEEOF'
      {
        description = "Python development environment";
        inputs = {
          nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
          # nixpkgs.url = "github:nixos/nixpkgs/release-24.05";
          # nixpkgs.url = "github:DuarteSJ/nixpkgs/current";
        };
        outputs = {
          self,
          nixpkgs,
          ...
        }: let
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
          python = pkgs.python3;
          # python = pkgs.python310;
          # python = pkgs.python311;

          customEnvVars = '''
            export VAR="value"
            export OTHER_VAR="other value"
          ''';

          customAliases = '''
            alias hw='echo \"hello world\"'
            alias test='echo \"This is a test alias\"'
          ''';
        in {
          devShells.x86_64-linux.default = pkgs.mkShell {
            name = "py";
            packages = [
              (python.withPackages (p: [
                # Exta Python:
                # p.numpy
                # p.pandas
                # p.matplotlib
                # For Jupyter workflow with Jupynium for editing notebooks in nvim (plugin required):
                # p.jupynium
                # p.nbclassic
                # p.notebook
              ]))
            ];
            shellHook = '''
              echo -e "\n\033[1;36m🐍 Python development shell activated!\033[0m"
              echo -e "\033[0;90m    → Virtual environment: (py-env)\033[0m"

              # Apply custom environment variables and aliases
              ''${customEnvVars}
              ZSH_CMDS="''${customAliases}" exec zsh
            ''';
          };
        };
      }
      FLAKEEOF
      else
        # Create generic flake.nix
        ${pkgs.coreutils}/bin/cat > flake.nix << 'FLAKEEOF'
      {
        description = "Development environment";
        inputs = {
          nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
          # nixpkgs.url = "github:nixos/nixpkgs/release-24.05";
          # nixpkgs.url = "github:DuarteSJ/nixpkgs/current";
        };
        outputs = {
          self,
          nixpkgs,
          ...
        }: let
          pkgs = nixpkgs.legacyPackages."x86_64-linux";

          customEnvVars = '''
            export VAR="value"
            export OTHER_VAR="other value"
          ''';

          customAliases = '''
            alias hw='echo \"hello world\"'
            alias test='echo \"This is a test alias\"'
          ''';
        in {
          devShells.x86_64-linux.default = pkgs.mkShell {
            name = "dev";
            packages = with pkgs; [
              # Extra packages:
              # feh
              # unzip
            ];
            shellHook = '''
              echo -e "\n\033[1;36m🚀 Development shell activated!\033[0m"
              echo -e "\033[0;90m    → Environment: (dev-env)\033[0m"

              # Apply custom environment variables and aliases
              ''${customEnvVars}
              ZSH_CMDS="''${customAliases}" exec zsh
            ''';
          };
        };
      }
      FLAKEEOF
      fi

      ${pkgs.coreutils}/bin/echo -e "\033[1;32m✓\033[0m Created flake.nix"
      ${pkgs.coreutils}/bin/echo ""
      ${pkgs.coreutils}/bin/echo -e "\033[1;35m✨ Done!\033[0m Next steps:"
      ${pkgs.coreutils}/bin/echo -e "  \033[0;36m1.\033[0m Edit flake.nix to configure packages"
      ${pkgs.coreutils}/bin/echo -e "  \033[0;36m2.\033[0m Run: \033[1;37mnix develop\033[0m"
    '')
  ];
}
