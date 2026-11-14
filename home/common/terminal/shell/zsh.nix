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
      ignoreAllDups = true;
      ignorePatterns = shellShared.history.ignore;
      ignoreSpace = true;
      share = true;
    };
    # zsh picks viins when $EDITOR/$VISUAL mention vi, so pin emacs.
    defaultKeymap = "emacs";
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
    syntaxHighlighting.enable = true;
  };
}
