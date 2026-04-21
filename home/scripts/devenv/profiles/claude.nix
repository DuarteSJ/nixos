{
  description = "";

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
    '';
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "";

      packages = with pkgs; [
        # Claude Code
        claude
      ];

      shellHook = ''
        echo -e "\n\033[1;34m⚛️  Custom shell activated!\033[0m"
        echo -e "\033[0;90m    → Environment: (name-env)\033[0m"
        echo -e "\033[0;90m    → Claude: $(claude --version 2>/dev/null || echo 'ready')\033[0m"

        ZSH_CMDS="${customAliases}" exec zsh
      '';
    };
  };
}
