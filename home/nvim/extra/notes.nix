{
  config,
  pkgs,
  ...
}: {
  programs.nvf.settings.vim = {
    extraPlugins.obsidian = {
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
              ["d"] = { char = "", hl_group = "ObsidianDone" },
              ["f"] = { char = "", hl_group = "ObsidianTilde" },
            },
            external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
            reference_text = { hl_group = "ObsidianRefText" },
            highlight_text = { hl_group = "ObsidianHighlightText" },
            tags = { hl_group = "ObsidianTag" },
          },
        })
      '';
    };

    # Obsidian keybindings
    keymaps = [
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
}
