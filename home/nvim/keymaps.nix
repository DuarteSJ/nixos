{
  config,
  pkgs,
  ...
}: {
  programs.nvf.settings.vim = {
    keymaps = [
      # Open file explorer with Ctrl+n
      {
        mode = "n";
        key = "<C-n>";
        action = "<cmd>lua require('mini.files').open()<CR>";
      }
      # Close current buffer with Leader+X
      {
        mode = "n";
        key = "<leader>x";
        action = ":bdelete<CR>";
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
      # Exit insert mode with 'kj'
      {
        mode = "i";
        key = "kj";
        action = "<Esc>";
      }
    ];

    autocmds = [
      # Highlight on yank
      {
        event = ["TextYankPost"];
        pattern = ["*"];
        command = ''
          lua vim.highlight.on_yank({higroup="IncSearch", timeout=50})
        '';
      }
    ];
  };
}
