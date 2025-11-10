{lib, ...}: let
  inherit (lib.generators) mkLuaInline;
in {
  programs.nvf.settings.vim = {
    notes.obsidian = {
      enable = true;

      setupOpts = {
        workspaces = [
          {
            name = "notes";
            path = "~/notes";
          }
        ];

        completion = {
          nvim_cmp = true;
          min_chars = 2;
        };

        daily_notes = {
          folder = "daily";
          date_format = "%d-%m-%Y";
          alias_format = "%B %-d, %Y";
          template = "daily.md";
        };

        templates = {
          subdir = "templates";
          date_format = "%d-%m-%Y";
          time_format = "%H:%M";
          substitutions = {
            yesterday = mkLuaInline ''
              function()
                return os.date("%d-%m-%Y", os.time() - 86400)
              end
            '';
            tomorrow = mkLuaInline ''
              function()
                return os.date("%d-%m-%Y", os.time() + 86400)
              end
            '';
          };
        };

        note_id_func = mkLuaInline ''
          function(title)
            if title ~= nil then
              return title
            end
            -- If no title provided, use timestamp
            vim.notify("No title provided, using timestamp", vim.log.levels.WARN)
            return tostring(os.date("%d%m%Y%H%M%S"))
          end
        '';

        note_frontmatter_func = mkLuaInline ''
          function(note)
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
          end
        '';

        follow_url_func = mkLuaInline ''
          function(url)
            vim.fn.jobstart({"xdg-open", url})
          end
        '';

        finder = "telescope.nvim";

        notes_subdir = "zettelkasten";

        ui = {
          enable = true;
          checkboxes = {
            " " = {
              char = "󰄱";
              hl_group = "ObsidianTodo";
            };
            "d" = {
              char = "";
              hl_group = "ObsidianDone";
            };
            "f" = {
              char = "";
              hl_group = "ObsidianTilde";
            };
          };
          external_link_icon = {
            char = "";
            hl_group = "ObsidianExtLinkIcon";
          };
          reference_text = {hl_group = "ObsidianRefText";};
          highlight_text = {hl_group = "ObsidianHighlightText";};
          tags = {hl_group = "ObsidianTag";};
        };
      };
    };

    # keybindings
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

  home.activation.createObsidianDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/notes/{templates,daily,zettelkasten}
  '';
}
