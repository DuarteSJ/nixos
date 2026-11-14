_: {
  programs.nvf.settings.vim = {
    # bufdelete.nvim (shipped with bufferline): closes the buffer but keeps the
    # window/split layout, unlike plain `:bdelete`.
    tabline.nvimBufferline.mappings.closeCurrent = "<leader>x";

    keymaps = [
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
      # Cycle in bufferline's displayed order, not `:bnext`'s buffer-number order.
      {
        mode = "n";
        key = "<C-Tab>";
        action = "<cmd>BufferLineCycleNext<CR>";
        desc = "Next buffer";
      }
      {
        mode = "n";
        key = "<C-S-Tab>";
        action = "<cmd>BufferLineCyclePrev<CR>";
        desc = "Previous buffer";
      }
    ];
  };
}
