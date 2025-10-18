{ config, pkgs, ... }: {
  programs.nvf = {
    enable = true;
    settings.vim = {
      viAlias = true;
      vimAlias = true;

      # Tab settings
      options = {
        tabstop = 2;
        shiftwidth = 2;
        expandtab = true;
        autoindent = true;
      };

      # System clipboard integration
      clipboard = {
        enable = true;
        providers.wl-copy.enable = true;
        registers = "unnamedplus";
      };

      # Enable LSP globally
      lsp.enable = true;

      # Enable completion engine (for LSP completions only)
      autocomplete.nvim-cmp.enable = true;

      # Enable Copilot with inline suggestions
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

      # Enable languages with LSP and Treesitter
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

      # Enable bufferline (shows buffers at the top like tabs)
      tabline.nvimBufferline.enable = true;

      # Enable cheatsheet for keybindings
      binds.cheatsheet.enable = true;

      # Enable git integration
      git = {
        enable = true;
        gitsigns.enable = true;
      };

      # Neo-tree configuration
      filetree.neo-tree = {
        enable = true;
        setupOpts = {
          open_files_in_last_window = false;
          window = {
            position = "right";
            width = 30;
          };
        };
      };

      # Telescope for file finding
      telescope.enable = true;

      theme = {
        enable = true;
        name = "nord";
        transparent = true;
      };

      # Add extra plugins
      extraPlugins = {
        # VimTeX for LaTeX support
        vimtex = {
          package = pkgs.vimPlugins.vimtex;
          setup = ''
            vim.g.vimtex_view_method = "zathura"
            vim.g.vimtex_view_zathura_options = "-x 'nvim --servername " .. vim.v.servername .. " --remote +%{line} %{file}'"
            vim.g.vimtex_compiler_method = "latexmk"
            vim.g.vimtex_compiler_latexmk = {
              aux_dir = ".build",
              out_dir = ".build",
              continuous = 1,
            }
            vim.g.vimtex_quickfix_mode = 0
          '';
        };

        # Jupynium for Jupyter notebook integration
        jupynium = {
          package = pkgs.vimUtils.buildVimPlugin {
            name = "jupynium.nvim";
            src = pkgs.fetchFromGitHub {
              owner = "kiyoon";
              repo = "jupynium.nvim";
              rev = "master";
              sha256 = "13ssf2fpikfghmjr39nafjsdr83amddn4m9bqpp443ab852ai6d6";
            };
          };
          setup = ''
            require('jupynium').setup({
              python_host = vim.g.python3_host_prog or "python3",
              default_notebook_URL = "localhost:8888/nbclassic",
              
              auto_start_server = {
                enable = false,
                file_pattern = { "*.ju.*" },
              },
              
              auto_attach_to_server = {
                enable = true,
                file_pattern = { "*.ju.*", "*.md" },
              },
              
              auto_start_sync = {
                enable = false,
                file_pattern = { "*.ju.*" },
              },
              
              auto_download_ipynb = true,
              auto_close_tab = true,
              
              autoscroll = {
                enable = true,
                mode = "always",
              },
              
              use_default_keybindings = true,
              
              syntax_highlight = {
                enable = true,
              },
            })
            
            -- Highlight groups for jupynium cells
            vim.cmd [[
              hi! link JupyniumCodeCellSeparator CursorLine
              hi! link JupyniumMarkdownCellSeparator CursorLine
              hi! link JupyniumMarkdownCellContent CursorLine
              hi! link JupyniumMagicCommand Keyword
            ]]
          '';
        };
        
        # Optional: nvim-notify for better notifications
        nvim-notify = {
          package = pkgs.vimPlugins.nvim-notify;
          setup = ''
            require('notify').setup()
            vim.notify = require('notify')
          '';
        };
      };

      # Custom keybindings
      keymaps = [
        # Toggle file tree with Ctrl+N
        {
          mode = "n";
          key = "<C-n>";
          action = ":Neotree toggle<CR>";
        }
        # Close current buffer with Leader+X
        {
          mode = "n";
          key = "<leader>x";
          action = ":bdelete<CR>";
        }
        # Git status with Leader+GT (with preview of diffs)
        {
          mode = "n";
          key = "<leader>gt";
          action = ":Telescope git_status previewer=true<CR>";
        }
        # Git commits with Leader+GL
        {
          mode = "n";
          key = "<leader>gl";
          action = ":Telescope git_commits<CR>";
        }
        {
          mode = "n";
          key = "<leader>gt";
          action = ":Telescope git_status previewer=true<CR>";
        }
        # Buffer cycling with Tab and Shift+Tab
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
        # Window navigation with Ctrl+h/j/k/l
        {
          mode = "n";
          key = "<C-h>";
          action = "<C-w>h";
        }
        {
          mode = "n";
          key = "<C-j>";
          action = "<C-w>j";
        }
        {
          mode = "n";
          key = "<C-k>";
          action = "<C-w>k";
        }
        {
          mode = "n";
          key = "<C-l>";
          action = "<C-w>l";
        }
        # Move lines up/down
        {
          mode = "n";
          key = "<A-k>";
          action = ":m .-2<CR>==";
        }
        {
          mode = "n";
          key = "<A-j>";
          action = ":m .+1<CR>==";
        }
        {
          mode = "v";
          key = "<A-k>";
          action = ":m '<-2<CR>gv=gv";
        }
        {
          mode = "v";
          key = "<A-j>";
          action = ":m '>+1<CR>gv=gv";
        }
      ];
    };
  };
}
