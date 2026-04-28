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
      conceallevel = 2;
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
      // (
        if lib.hasInfix "gruvbox" (lib.toLower config.colorScheme.name)
        then {
          name = "gruvbox";
          style = "light";
        }
        else {name = "nord";}
      );
    telescope.enable = true;
    statusline.lualine.enable = true;
    tabline.nvimBufferline.enable = true;
    binds.whichKey.enable = true;
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
    keymaps = [
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
      {
        mode = "n";
        key = "gd";
        action = "<cmd>lua vim.lsp.buf.definition()<CR>";
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
        command = "setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab";
      }
      # Workaround for treesitter indent not working in the latest nvf commits
      {
        enable = true;
        event = ["BufEnter"];
        pattern = ["*"];
        command = "setlocal indentexpr=nvim_treesitter#indent()";
      }
    ];
  };
}
