{
  description = "C Development Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    lib = nixpkgs.lib;

    customEnvVars = {
    };

    normalPackages = with pkgs; [
      gcc
      gnumake
      gdb
      clang-tools # clangd LSP + clang-format
      #lldb
      #valgrind
      #cmake
      #pkg-config
      #bear            # generate compile_commands.json for clangd
    ];

    customScripts = with pkgs; [
      (writeShellScriptBin "build" "make")
      (writeShellScriptBin "clean" "make clean")
      # (writeShellScriptBin "format" "clang-format -i **/*.c **/*.h")
    ];

    envExports = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (k: v: "export ${k}=${v}") customEnvVars
    );
  in {
    devShells.${system}.default = pkgs.mkShell {
      name = "c";
      packages = normalPackages ++ customScripts;
      shellHook = ''
        echo -e "\n\033[1;36m⚙️  C shell activated!\033[0m"
        echo -e "\033[0;90m    → Environment: (c-env)\033[0m"

        ${envExports}

        if [ ! -f Makefile ]; then
          cat > Makefile << 'EOF'
        CC = gcc
        CFLAGS = -Wall -Wextra -g

        main: main.c
        	$(CC) $(CFLAGS) -o main main.c

        clean:
        	rm -f main
        EOF
          echo -e "\033[0;90m    → Makefile created\033[0m"
        fi
      '';
    };
  };
}
