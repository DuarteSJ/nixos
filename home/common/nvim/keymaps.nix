_: {
  programs.nvf.settings.vim.keymaps = [
    {
      mode = "n";
      key = "<leader>x";
      action = ":bdelete<CR>";
    }
    {
      mode = "i";
      key = "kj";
      action = "<Esc>";
    }
    {
      mode = "n";
      key = "<leader>gd";
      action = "<cmd>lua vim.lsp.buf.definition()<CR>";
      desc = "Go to definition";
    }
  ];
}
