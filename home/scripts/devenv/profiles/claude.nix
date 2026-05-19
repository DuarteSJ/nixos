{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs = {
    nixpkgs,
    claude-code,
    ...
  }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    lib = nixpkgs.lib;
    claude = claude-code.packages.${system}.default;

    customEnvVars = {
    };

    normalPackages = with pkgs; [
      # Claude Code
      claude
    ];

    customScripts = with pkgs; [
    ];

    envExports = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (k: v: "export ${k}=${v}") customEnvVars
    );
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "";
      packages = normalPackages ++ customScripts;

      shellHook = ''
        echo -e "\n\033[1;34m⚛️  Custom shell activated!\033[0m"
        echo -e "\033[0;90m    → Environment: (name-env)\033[0m"
        echo -e "\033[0;90m    → Claude: $(claude --version 2>/dev/null || echo 'ready')\033[0m"

        ${envExports}
      '';
    };
  };
}
