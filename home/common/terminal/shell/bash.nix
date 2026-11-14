{shellShared, ...}: {
  programs.bash = {
    enable = true;
    # historyFile, shellOptions (HM default + checkwinsize, on by default since
    # bash 5) and emacs line editing are all defaults.
    historySize = shellShared.history.size;
    historyFileSize = shellShared.history.size;
    historyControl = ["erasedups" "ignorespace"];
    historyIgnore = shellShared.history.ignore;

    shellAliases = shellShared.aliases;

    initExtra = shellShared.functions;
  };
}
