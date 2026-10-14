{
  config,
  lib,
  ...
}: let
  inherit (lib.generators) mkLuaInline;
  inherit (config.vars.paths) notes;

  dateFormat = "%d-%m-%Y";

  # Template dates relative to the daily note being created (its id is the
  # date), not "now": `:Obsidian tomorrow` must head with tomorrow and link
  # back to today. Non-daily notes fall back to now. Noon avoids DST edges when
  # stepping whole days. `suffix` is the optional `{{date:FORMAT}}` format.
  noteDay = days:
    mkLuaInline ''
      function(ctx, suffix)
        local id = ctx.partial_note and ctx.partial_note.id
        local d, m, y = tostring(id or ""):match("^(%d%d)%-(%d%d)%-(%d%d%d%d)$")
        local base = d
            and os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 12 })
          or os.time()
        return require("obsidian.util").format_date(base + ${toString days} * 86400, suffix or "${dateFormat}")
      end
    '';
in {
  programs.nvf.settings.vim = {
    notes.obsidian = {
      enable = true;
      setupOpts = {
        workspaces = [
          {
            name = "notes";
            path = notes;
          }
        ];
        daily_notes = {
          folder = "daily";
          date_format = dateFormat;
          alias_format = "%B %-d, %Y";
          template = "daily.md";
        };
        templates = {
          folder = "templates";
          date_format = dateFormat;
          time_format = "%H:%M";
          substitutions = {
            date = noteDay 0;
            yesterday = noteDay (-1);
            tomorrow = noteDay 1;
          };
        };
        frontmatter.func = mkLuaInline ''
          function(note)
            local out = {
              aliases = note.aliases,
              tags = note.tags,
              created = os.date("${dateFormat} %H:%M"),
            }
            if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
              for k, v in pairs(note.metadata) do
                out[k] = v
              end
            end
            return out
          end
        '';
        legacy_commands = false;
        notes_subdir = "zettelkasten";
        checkbox.order = [" " "d" "f"];
        # Glyphs for the custom states. obsidian.nvim still renders
        # `ui.checkboxes`, but warns on every startup if it is passed to setup
        # (ordering moved to `checkbox.order`), so inject it right after setup;
        # `_opts` too so a workspace re-switch keeps it.
        callbacks.post_setup = mkLuaInline ''
          function()
            local boxes = {
              [" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
              d = { char = "", hl_group = "ObsidianDone" },
              f = { char = "", hl_group = "ObsidianTilde" },
            }
            for _, opts in ipairs({ Obsidian._opts, Obsidian.opts }) do
              opts.ui.checkboxes = vim.tbl_extend("force", opts.ui.checkboxes or {}, boxes)
            end
          end
        '';
        ui = {
          external_link_icon = {
            char = "";
            hl_group = "ObsidianExtLinkIcon";
          };
          reference_text = {hl_group = "ObsidianRefText";};
          highlight_text = {hl_group = "ObsidianHighlightText";};
          tags = {hl_group = "ObsidianTag";};
        };
      };
    };
    keymaps = [
      {
        mode = "n";
        key = "<leader>on";
        action = ":Obsidian new<CR>";
      }
      {
        mode = "n";
        key = "<leader>oo";
        action = ":Obsidian quick_switch<CR>";
      }
      {
        mode = "n";
        key = "<leader>os";
        action = ":Obsidian search<CR>";
      }
      {
        mode = "n";
        key = "<leader>od";
        action = ":Obsidian today<CR>";
      }
      {
        mode = "n";
        key = "<leader>ob";
        action = ":Obsidian backlinks<CR>";
      }
      {
        mode = "n";
        key = "<leader>ol";
        action = ":Obsidian links<CR>";
      }
      {
        mode = "n";
        key = "<leader>ot";
        action = ":Obsidian new_from_template<CR>";
      }
    ];
  };
  home.activation.createObsidianDirs = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ${notes}/{templates,daily,zettelkasten}
  '';
}
