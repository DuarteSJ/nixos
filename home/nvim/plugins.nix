{pkgs, ...}: {
  programs.nvf.settings.vim = {
    extraPlugins = {
      # ==========================================
      # Mini.nvim Ecosystem
      # ==========================================
      mini-move = {
        package = pkgs.vimPlugins.mini-nvim;
        setup = ''
          require('mini.move').setup({
            mappings = {
              -- Move visual selection in Visual mode
              left = '<A-h>',
              right = '<A-l>',
              down = '<A-j>',
              up = '<A-k>',

              -- Move current line in Normal mode
              line_left = '<A-h>',
              line_right = '<A-l>',
              line_down = '<A-j>',
              line_up = '<A-k>',
            },
          })
        '';
      };

      mini-pairs = {
        package = pkgs.vimPlugins.mini-nvim;
        setup = ''
          require('mini.pairs').setup()
        '';
      };

      mini-surround = {
        package = pkgs.vimPlugins.mini-nvim;
        setup = ''
          require('mini.surround').setup()
        '';
      };

      mini-files = {
        package = pkgs.vimPlugins.mini-nvim;
        setup = ''
          require('mini.files').setup({
            windows = {
              preview = true,
              width_preview = 80,
            },
          })
        '';
      };

      # ==========================================
      # Other Plugins
      # ==========================================
      todo-comments = {
        package = pkgs.vimPlugins.todo-comments-nvim;
        setup = ''
          require('todo-comments').setup()
        '';
      };

      which-key = {
        package = pkgs.vimPlugins.which-key-nvim;
        setup = ''
          require('which-key').setup({
            delay = 500,
          })
        '';
      };

      nvim-notify = {
        package = pkgs.vimPlugins.nvim-notify;
        setup = ''
          require('notify').setup()
          vim.notify = require('notify')
        '';
      };
    };
  };
}
