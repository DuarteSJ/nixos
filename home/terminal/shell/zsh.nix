{
  config,
  shellShared,
  ...
}: {
  programs.zsh = {
    enable = true;
    history = {
      size = 1000;
      save = 1000;
      path = "${config.xdg.dataHome}/.histfile";
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };
    defaultKeymap = "emacs";
    setOptions = [
      "hist_verify"
      "auto_cd"
    ];
    shellAliases = shellShared.aliases;
    initContent = ''
      ${shellShared.functions}
      bindkey '^L' autosuggest-accept
    '';
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
  };
}
