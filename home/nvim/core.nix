{config, ...}: {
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
      // config.colorScheme.nvf;
    # Transparent background so the glass terminal (alacritty at 72% +
    # Hyprland blur) shows through.  The base16 theme ignores
    # theme.transparent, so clear the backgrounds after it has loaded, and
    # again whenever a colorscheme is (re)applied.
    luaConfigPost = ''
      local function glass()
        for _, group in ipairs({
          "Normal", "NormalNC", "NormalFloat", "FloatBorder", "SignColumn",
          "LineNr", "CursorLineNr", "EndOfBuffer", "FoldColumn", "WinSeparator",
          "VertSplit", "MsgArea", "StatusLine", "StatusLineNC", "TabLineFill",
          "TelescopeNormal", "TelescopeBorder", "WhichKeyFloat",
        }) do
          local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
          hl.bg = nil
          hl.ctermbg = nil
          vim.api.nvim_set_hl(0, group, hl)
        end
      end
      glass()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = glass })
    '';

    telescope.enable = true;
    statusline.lualine.enable = true;
    tabline.nvimBufferline.enable = true;
    binds.whichKey.enable = true;
    git.gitlinker-nvim.enable = true;
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
  };
}
