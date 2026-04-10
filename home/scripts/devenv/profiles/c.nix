{
  description = "C Development Environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";

    customEnvVars = ''
    '';

    customAliases = ''
      alias build='make'
      alias clean='make clean'
      #alias format='clang-format -i **/*.c **/*.h'
    '';

    # Packages from nixpkgs
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
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      name = "c";
      packages = normalPackages;
      shellHook = ''
                echo -e "\n\033[1;36m⚙️  C shell activated!\033[0m"
                echo -e "\033[0;90m    → Environment: (c-env)\033[0m"

                ${customEnvVars}

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

                ZSH_CMDS="${customAliases}" exec zsh
      '';
    };
  };
}
