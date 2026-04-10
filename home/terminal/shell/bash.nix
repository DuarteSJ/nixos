{
  config,
  shellShared,
  ...
}: {
  programs.bash = {
    enable = true;
    historySize = 1000;
    historyFileSize = 1000;
    historyFile = "${config.home.homeDirectory}/.bash_history";
    historyControl = ["ignoredups" "ignorespace"];
    historyIgnore = ["ls" "cd" "exit"];

    shellOptions = [
      "histappend"
      "checkwinsize"
      "extglob"
      "globstar"
      "checkjobs"
    ];

    shellAliases =
      shellShared.aliases
      // {
      };

    initExtra = ''
      set -o vi

      ${shellShared.functions}

      [[ -n $BASH_CMDS ]] && eval "$BASH_CMDS"
    '';
  };
}
