{pkgs, ...}: {
  programs.nvf.settings.vim.extraPlugins.jupynium = {
    package = pkgs.vimUtils.buildVimPlugin {
      name = "jupynium.nvim";
      src = pkgs.fetchFromGitHub {
        owner = "kiyoon";
        repo = "jupynium.nvim";
        # TODO: pin to a commit SHA instead of the mutable `master` branch.
        # With a branch ref, a content change upstream makes the fixed sha256
        # mismatch and the build fails until the hash is bumped.
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
}
