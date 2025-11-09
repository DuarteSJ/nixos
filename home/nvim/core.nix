{
  config,
  lib,
  ...
}: {
  programs.nvf.settings.vim = {
    options = {
      tabstop = 4;
      shiftwidth = 4;
      expandtab = true;
      autoindent = true;
      conceallevel = 1;
      scrolloff = 9;
    };

    clipboard = {
      enable = true;
      providers.wl-copy.enable = true;
      registers = "unnamedplus";
    };

    telescope.enable = true;

    assistant.copilot = {
      enable = true;
      cmp.enable = false;
      setupOpts = {
        suggestion = {
          enabled = true;
          auto_trigger = true;
        };
        panel = {
          enabled = false;
        };
      };
      mappings.suggestion.accept = "<C-l>";
    };

    lsp.enable = true;

    autocomplete.nvim-cmp.enable = true;

    languages = {
      enableTreesitter = true;
      nix.enable = true;
      python.enable = true;
      rust.enable = true;
      clang.enable = true;
      html.enable = true;
      css.enable = true;
      ts.enable = true;
      java.enable = true;
      markdown.enable = true;
    };

    statusline.lualine.enable = true;
    tabline.nvimBufferline.enable = true;

    theme = {
      enable = true;
      name = lib.toLower config.colorScheme.name;
      transparent = true;
    };
  };
}
