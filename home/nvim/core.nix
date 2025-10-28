{ config, pkgs, ... }: {
    programs.nvf.settings.vim = {
        # Tab settings
        options = {
            tabstop = 4;
            shiftwidth = 4;
            expandtab = true;
            autoindent = true;
            conceallevel = 2;
        };

        # Use system clipboard
        clipboard = {
            enable = true;
            providers.wl-copy.enable = true;
            registers = "unnamedplus";
        };

        # Telescope for file finding
        telescope.enable = true;

        # Copilot configuration
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

        extraPlugins = {
            # Better notifications
            nvim-notify = {
                package = pkgs.vimPlugins.nvim-notify;
                setup = ''
                    require('notify').setup()
                    vim.notify = require('notify')
                '';
            };

            # Mini Move for moving lines and selections
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

            # Automatically close brackets, quotes, parentheses
            mini-pairs = {
                package = pkgs.vimPlugins.mini-nvim;
                setup = ''
                    require('mini.pairs').setup()
                '';
            };

            # Add/change/delete surrounding pairs
            mini-surround = {
                package = pkgs.vimPlugins.mini-nvim;
                setup = ''
                    require('mini.surround').setup()
                '';
            };
            # Enhanced file explorer
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
        };
    };
}
