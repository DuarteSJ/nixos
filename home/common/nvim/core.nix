{config, ...}: {
  programs.nvf.settings.vim = {
    options = {
      tabstop = 4;
      shiftwidth = 4;
      expandtab = true;
      scrolloff = 9;
      foldlevel = 99;
    };
    clipboard = {
      enable = true;
      providers.wl-copy.enable = true;
      registers = "unnamedplus";
    };
    theme =
      {
        enable = true;
        transparent = true;
      }
      // config.colorScheme.nvf;
    telescope.enable = true;
    statusline.lualine.enable = true;
    tabline.nvimBufferline.enable = true;
    binds.whichKey.enable = true;
    git.gitlinker-nvim.enable = true;
    notes.todo-comments.enable = true;
    mini = {
      pairs.enable = true;
      ai.enable = true;
      surround.enable = true;
      notify.enable = true;
      move.enable = true;
    };
    lsp.enable = true;
    autocomplete.nvim-cmp.enable = true;
    languages = {
      enableTreesitter = true;
      nix.enable = true;
      rust.enable = true;
      clang.enable = true;
      python.enable = true;
      html.enable = true;
      css.enable = true;
      typescript.enable = true;
      java.enable = true;
      markdown.enable = true;
    };
    assistant.copilot = {
      enable = true;
      setupOpts = {
        suggestion.auto_trigger = true;
        panel.enabled = false;
      };
      mappings = {
        suggestion.accept = "<C-l>";
        # Panel is off, but nvf still binds its keys globally (<CR>, ]], [[,
        # gr, <M-CR>) unless they are nulled.
        panel = {
          accept = null;
          jumpNext = null;
          jumpPrev = null;
          refresh = null;
          open = null;
        };
      };
    };
  };
}
