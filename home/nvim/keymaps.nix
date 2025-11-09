{
  programs.nvf.settings.vim = {
    keymaps = [
      {
        mode = "n";
        key = "<C-n>";
        action = "<cmd>lua require('mini.files').open()<CR>";
      }
      {
        mode = "n";
        key = "<leader>x";
        action = ":bdelete<CR>";
      }
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
      {
        mode = "i";
        key = "kj";
        action = "<Esc>";
      }
    ];

    autocmds = [
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
