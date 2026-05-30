{...}: {
  programs.nvf.settings.vim.keymaps = [
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
    {
      mode = "n";
      key = "gd";
      action = "<cmd>lua vim.lsp.buf.definition()<CR>";
    }
  ];
}
