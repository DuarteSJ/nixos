{...}: {
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
  ];
}
