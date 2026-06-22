{
  config,
  shellShared,
  ...
}: {
  programs.zsh = {
    enable = true;
    history = {
      size = shellShared.history.size;
      save = shellShared.history.size;
      path = "${config.xdg.dataHome}/.histfile";
      ignoreAllDups = shellShared.history.ignoreAllDups;
      ignorePatterns = shellShared.history.ignore;
      ignoreSpace = true;
      share = true;
    };
    defaultKeymap =
      if shellShared.keymap == "vi"
      then "viins"
      else "emacs";
    setOptions = [
      "hist_verify"
      "auto_cd"
    ];
    shellAliases = shellShared.aliases;
    initContent = ''
      ${shellShared.functions}
      # Keep Ctrl-L as clear-screen; accept autosuggestions with Ctrl-Space.
      bindkey '^@' autosuggest-accept
    '';
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
  };
}
