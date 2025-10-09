{ config, pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "pydev" ''
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
      
      ${pkgs.coreutils}/bin/echo -e "\033[1;34m🔨 Creating Python development environment...\033[0m"
      
      # Create flake.nix with helpful comments
      ${pkgs.coreutils}/bin/cat > flake.nix << 'FLAKEEOF'
{
  description = "Python development environment";
  
  inputs = {
    # Change version: nixos-22.05, nixos-23.11, nixos-24.05, or nixos-unstable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Alternative sources if you need packages not in official nixpkgs:
    # nixpkgs.url = "github:DuarteSJ/nixpkgs/current";  # Has jupynium and other packages
    # nixpkgs.url = "github:nixos/nixpkgs/master";      # Bleeding edge
    # nixpkgs.url = "github:nixos/nixpkgs/staging";     # Staging branch
  };
  
  outputs = { self, nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      
      # Change Python version: python39, python310, python311, python312, python313, or python3
      python = pkgs.python3;
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = [
          (python.withPackages (p: [
            # Add your Python packages here:
            # Example packages:
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
          echo -e "\033[1;36m🐍  Python development shell activated!\033[0m"
          echo -e "\033[0;90m→ Virtual environment: (py-env)\033[0m"
          
          export NIX_PS1_OVERRIDE="(py-env) "
          export PYTHONPATH="$PWD:$PYTHONPATH"
          exec zsh
        ''';
      };
    };
}
FLAKEEOF
      
      ${pkgs.coreutils}/bin/echo -e "\033[1;32m✓\033[0m Created flake.nix"
      ${pkgs.coreutils}/bin/echo ""
      ${pkgs.coreutils}/bin/echo -e "\033[1;35m✨ Done!\033[0m Next steps:"
      ${pkgs.coreutils}/bin/echo -e "  \033[0;36m1.\033[0m Edit flake.nix to configure Python version and packages"
      ${pkgs.coreutils}/bin/echo -e "  \033[0;36m2.\033[0m Run: \033[1;37mnix develop\033[0m"
    '')
  ];
}
