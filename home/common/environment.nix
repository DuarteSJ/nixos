{config, ...}: {
  home.sessionPath = ["$HOME/.local/bin"];

  home.sessionVariables = {
    EDITOR = config.vars.editor;
  };
}
