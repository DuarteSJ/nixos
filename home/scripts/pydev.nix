{ config, pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellScriptBin "pydev" ''
      set -e

      # Check if files already exist
      if [ -f flake.nix ] || [ -f python-packages.nix ]; then
        ${pkgs.coreutils}/bin/echo "Warning: One or more files already exist."
        ${pkgs.coreutils}/bin/echo -n "Do you want to replace them? (y/N): "
        read -r response
        if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
          ${pkgs.coreutils}/bin/echo "Aborted."
          exit 0
        fi
      fi

      # Ask for Python version
      ${pkgs.coreutils}/bin/echo -n "Enter Python version (9, 10, 11, etc. - leave empty for python3): "
      read -r python_version
      if [ -z "$python_version" ]; then
        python_attr="python3"
      else
        python_attr="python3$python_version"
      fi

      # Ask for nixpkgs version
      ${pkgs.coreutils}/bin/echo -n "Enter nixpkgs version (e.g., 22.05, 23.11, 24.05 - leave empty for unstable): "
      read -r nixpkgs_version
      if [ -z "$nixpkgs_version" ]; then
        nixpkgs_url="github:nixos/nixpkgs/nixos-unstable"
      else
        nixpkgs_url="github:nixos/nixpkgs/nixos-$nixpkgs_version"
      fi

      ${pkgs.coreutils}/bin/echo ""
      ${pkgs.coreutils}/bin/echo "Setting up Python development environment with Nix flake..."

      # Create flake.nix
      ${pkgs.coreutils}/bin/cat > flake.nix << EOF
{
  description = "flake";
  inputs = {
    nixpkgs.url = "$nixpkgs_url";
  };
  outputs = { self, nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      packageOverrides = pkgs.callPackage ./python-packages.nix {};
      # Specify version if needed, e.g., python39, python310, python311
      python = pkgs.$python_attr.override { inherit packageOverrides; };
    in
    {
        devShells.x86_64-linux.default = pkgs.mkShell
        {
          packages = [
            (python.withPackages(p: [ 
              # List packages here
              # p.numpy
              # p.matplotlib
              # p.tabulate
            ]))
          ];
        };
    };
}
EOF

      ${pkgs.coreutils}/bin/echo "✓ Created flake.nix"

      # Create python-packages.nix
      ${pkgs.coreutils}/bin/cat > python-packages.nix << 'EOF'
{ pkgs, fetchurl, fetchgit, fetchhg }:
self: super: {
  # Only add packages here that need custom overrides

  # Example:
  # "certify" = super.buildPythonPackage rec {
  #   pname = "certify";
  #   version = "2024.12.14";
  #   src = fetchurl {
  #     url = "https://files.pythonhosted.org/packages/xx/xx/xx/certify-2024.12.14.tar.gz";
  #     sha256 = "sha256-hash";
  #   };
  #   format = "wheel";
  #   doCheck = true;
  #   buildInputs = [];
  #   checkInputs = [];
  #   nativeBuildInputs = [];
  #   propagatedBuildInputs = [];
  # };

  # You can also autogenerate this file by putting the packages you need to override in requirements.txt and running the following command:
  # nix run github:nix-community/pip2nix -- generate -r requirements.txt
}
EOF

      ${pkgs.coreutils}/bin/echo "✓ Created python-packages.nix"

      ${pkgs.coreutils}/bin/echo ""
      ${pkgs.coreutils}/bin/echo "Python development environment files created successfully!"
      ${pkgs.coreutils}/bin/echo "Python version: $python_attr"
      ${pkgs.coreutils}/bin/echo "Nixpkgs: $nixpkgs_url"
      ${pkgs.coreutils}/bin/echo ""
      ${pkgs.coreutils}/bin/echo "To use this environment, run: nix develop"
    '')
  ];
}
