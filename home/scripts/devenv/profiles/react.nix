{
  description = "React Web App Development Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    claude-code.url = "github:ryoppippi/nix-claude-code";
  };

  outputs = {
    nixpkgs,
    claude-code,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    claude = claude-code.packages.${system}.default;

    customAliases = ''
      alias dev='npm run dev'
      alias build='npm run build'
      alias preview='npm run preview'
      alias lint='npm run lint'
      alias fmt='prettier --write .'
    '';
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "react";

      packages = with pkgs; [
        # Runtime
        nodejs_22
        nodePackages.npm

        # Tooling
        nodePackages.prettier
        # nodePackages.typescript-language-server
        # nodePackages.vscode-langservers-extracted # html/css/json LSP

        # Claude Code
        claude
      ];

      shellHook = ''
        echo -e "\n\033[1;34m⚛️  React shell activated!\033[0m"
        echo -e "\033[0;90m    → Environment: (react-env)\033[0m"
        echo -e "\033[0;90m    → Node: $(node --version)  npm: $(npm --version)\033[0m"
        echo -e "\033[0;90m    → Claude: $(claude --version 2>/dev/null || echo 'ready')\033[0m"

        # Scaffold a new Vite/React project if none exists
        if [ ! -f package.json ]; then
          echo ""
          read -rp "No package.json found. Scaffold a new Vite + React project? (y/N): " response
          if [[ "$response" =~ ^[Yy]$ ]]; then
            read -rp "Project name (default: my-app): " proj_name
            proj_name="''${proj_name:-my-app}"
            npm create vite@latest "$proj_name" -- --template react
            echo -e "\n\033[1;32m✓ Project '$proj_name' created.\033[0m"
            echo -e "  cd $proj_name && npm install && dev"
          fi
        fi

        ZSH_CMDS="${customAliases}" exec zsh
      '';
    };
  };
}
