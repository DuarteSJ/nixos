{ config, pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "pydev" ''
      set -e
      
      # Check if flake.nix already exists
      if [ -f flake.nix ]; then
        ${pkgs.coreutils}/bin/echo "Warning: flake.nix already exists."
        ${pkgs.coreutils}/bin/echo -n "Do you want to replace it? (y/N): "
        read -r response
        if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
          ${pkgs.coreutils}/bin/echo "Aborted."
          exit 0
        fi
      fi
      
      ${pkgs.coreutils}/bin/echo "Creating Python development environment..."
      
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
      };
    };
}
FLAKEEOF
      
      ${pkgs.coreutils}/bin/echo "✓ Created flake.nix"
      ${pkgs.coreutils}/bin/echo ""
      ${pkgs.coreutils}/bin/echo "✨ Done! Next steps:"
      ${pkgs.coreutils}/bin/echo "  1. Edit flake.nix to configure Python version and packages"
      ${pkgs.coreutils}/bin/echo "  2. Run: nix develop"
    '')
  ];
}
