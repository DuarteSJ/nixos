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
      conceallevel = 2;
      scrolloff = 9;
      foldlevel = 99;
      foldmethod = "expr";
      foldexpr = "nvim_treesitter#foldexpr()";
    };

    clipboard = {
      enable = true;
      providers.wl-copy.enable = true;
      registers = "unnamedplus";
    };

    theme = {
      enable = true;
      name = lib.toLower config.colorScheme.name;
      transparent = true;
    };

    statusline.lualine.enable = true;
    tabline.nvimBufferline.enable = true;
    binds.whichKey.enable = true;

    telescope.enable = true;

    mini = {
      pairs.enable = true;
      ai.enable = true;
      surround.enable = true;
      notify.enable = true;
      files = {
        enable = true;
        setupOpts.windows = {
          preview = true;
          width_preview = 80;
        };
      };
      move = {
        enable = true;
        setupOpts.mappings = {
          left = "<A-h>";
          right = "<A-l>";
          down = "<A-j>";
          up = "<A-k>";
        };
      };
    };

    lsp.enable = true;
    autocomplete.nvim-cmp.enable = true;
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

    notes.todo-comments.enable = true;

    languages = {
      enableTreesitter = true;
      nix.enable = true;
      rust.enable = true;
      clang.enable = true;
      python.enable = true;
      html.enable = true;
      css.enable = true;
      ts.enable = true;
      java.enable = true;
      markdown.enable = true;
    };

    keymaps = [
      {
        mode = "n";
        key = "<C-n>";
        action = "<cmd>lua require('mini.files').open()<CR>";
      }
      {
        mode = "n";
        key = "<leader>x";
        action = ":bdelete<CR>";
      }
      {
        mode = "n";
        key = "<Tab>";
        action = ":bnext<CR>";
      }
      {
        mode = "n";
        key = "<S-Tab>";
        action = ":bprevious<CR>";
      }
      {
        mode = "i";
        key = "kj";
        action = "<Esc>";
      }
    ];

    autocmds = [
      {
        event = ["TextYankPost"];
        pattern = ["*"];
        command = ''
          lua vim.highlight.on_yank({higroup="IncSearch", timeout=50})
        '';
      }
      {
        event = ["FileType"];
        pattern = ["nix"];
        command = "setlocal tabstop=2 shiftwidth=2";
      }
    ];
  };
}
