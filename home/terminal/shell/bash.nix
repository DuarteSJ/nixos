{
  config,
  shellShared,
  ...
}: {
  programs.bash = {
    enable = true;
    historySize = shellShared.history.size;
    historyFileSize = shellShared.history.size;
    historyFile = "${config.home.homeDirectory}/.bash_history";
    historyControl =
      (
        if shellShared.history.ignoreAllDups
        then ["erasedups"]
        else ["ignoredups"]
      )
      ++ ["ignorespace"];
    historyIgnore = shellShared.history.ignore;

    shellOptions = [
      "histappend"
      "checkwinsize"
      "extglob"
      "globstar"
      "checkjobs"
    ];

    shellAliases = shellShared.aliases;

    initExtra = ''
      ${
        if shellShared.keymap == "vi"
        then "set -o vi"
        else "set -o emacs"
      }

      ${shellShared.functions}
    '';
  };
}
