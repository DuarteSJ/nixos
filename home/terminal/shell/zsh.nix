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
      path = "${config.home.homeDirectory}/.histfile";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };
    defaultKeymap = "emacs";
    setOptions = [
      "hist_ignore_dups"
      "hist_ignore_all_dups"
      "hist_save_no_dups"
      "hist_ignore_space"
      "hist_verify"
      "share_history"
      "auto_cd"
    ];
    shellAliases = shellShared.aliases // {
    };
    initContent = ''
      ${shellShared.functions}

      [[ -n $ZSH_CMDS ]] && eval "$ZSH_CMDS"
    '';
    autosuggestion.enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
  };
}
