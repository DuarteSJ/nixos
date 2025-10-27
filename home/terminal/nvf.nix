{ config, pkgs, ... }: {
  programs.nvf = {
    enable = true;
    settings.vim = {
      viAlias = true;
      vimAlias = true;

      # Tab settings
      options = {
        tabstop = 4;
        shiftwidth = 4;
        expandtab = true;
        autoindent = true;
        conceallevel = 2;
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

      extraPlugins = {
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

        # Obsidian.nvim for note-taking
        obsidian = {
          package = pkgs.vimPlugins.obsidian-nvim;
          setup = ''
            -- Create vault directory structure if it doesn't exist
            local vault_path = vim.fn.expand("~/notes")
            if vim.fn.isdirectory(vault_path) == 0 then
              vim.fn.mkdir(vault_path, "p")
            end

            -- Create subdirectories for organized structure
            local subdirs = {
              "templates",
              "daily",
              "zettelkasten",
            }

            for _, dir in ipairs(subdirs) do
              local dir_path = vault_path .. "/" .. dir
              if vim.fn.isdirectory(dir_path) == 0 then
                vim.fn.mkdir(dir_path, "p")
              end
            end

            require('obsidian').setup({
              workspaces = {
                {
                  name = "notes",
                  path = "~/notes",
                },
              },

              -- Completion of wiki links and tags
              completion = {
                nvim_cmp = true,
                min_chars = 2,
              },

              -- Configure daily notes
              daily_notes = {
                folder = "daily",
                date_format = "%d-%m-%Y",
                alias_format = "%B %-d, %Y",
                template = "daily.md",
              },

              -- Templates configuration
              templates = {
                subdir = "templates",
                date_format = "%d-%m-%Y",
                time_format = "%H:%M",
                -- Template substitutions
                substitutions = {
                  yesterday = function()
                    return os.date("%d-%m-%Y", os.time() - 86400)
                  end,
                  tomorrow = function()
                    return os.date("%d-%m-%Y", os.time() + 86400)
                  end,
                },
              },

              -- Note ID function - use title as ID
              note_id_func = function(title)
                if title ~= nil then
                  return title
                end
                -- If no title provided, use timestamp
                vim.notify("No title provided, using timestamp", vim.log.levels.WARN)
                return tostring(os.date("%d%m%Y%H%M%S"))
              end,

              -- Note frontmatter - Zettelkasten style
              note_frontmatter_func = function(note)
                local out = {
                  aliases = note.aliases,
                  tags = note.tags,
                  created = os.date("%d-%m-%Y %H:%M"),
                }

                -- Preserve any existing metadata
                if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
                  for k, v in pairs(note.metadata) do
                    out[k] = v
                  end
                end

                return out
              end,

              -- Follow URL behavior
              follow_url_func = function(url)
                vim.fn.jobstart({"xdg-open", url})
              end,

              -- Use wiki-style links
              use_advanced_uri = false,

              -- Finder (telescope integration)
              finder = "telescope.nvim",

              -- Notes path - defaults to zettelkasten folder
              notes_subdir = "zettelkasten",

              -- Disable some default mappings if desired
              disable_frontmatter = false,

              -- UI configuration
              ui = {
                enable = true,
                checkboxes = {
                  [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
                  ["d"] = { char = "", hl_group = "ObsidianDone" },
                  ["f"] = { char = "", hl_group = "ObsidianTilde" },
                },
                external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
                reference_text = { hl_group = "ObsidianRefText" },
                highlight_text = { hl_group = "ObsidianHighlightText" },
                tags = { hl_group = "ObsidianTag" },
              },
            })
          '';
        };

        # nvim-notify for better notifications
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
        # Obsidian keybindings
        {
          mode = "n";
          key = "<leader>on";
          action = ":ObsidianNew<CR>";
        }
        {
          mode = "n";
          key = "<leader>oo";
          action = ":ObsidianQuickSwitch<CR>";
        }
        {
          mode = "n";
          key = "<leader>os";
          action = ":ObsidianSearch<CR>";
        }
        {
          mode = "n";
          key = "<leader>od";
          action = ":ObsidianToday<CR>";
        }
        {
          mode = "n";
          key = "<leader>ob";
          action = ":ObsidianBacklinks<CR>";
        }
        {
          mode = "n";
          key = "<leader>ol";
          action = ":ObsidianLinks<CR>";
        }
        {
          mode = "n";
          key = "<leader>ot";
          action = ":ObsidianNewFromTemplate<CR>";
        }
      ];
    };
  };
}
