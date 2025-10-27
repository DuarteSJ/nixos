{ config, pkgs, ... }: {
    programs.nvf.settings.vim.keymaps = [
        # Toggle file tree with Ctrl+N
        {
            mode = "n";
            key = "<C-n>";
            action = ":Neotree toggle<CR>";
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
        # Window navigation with Ctrl+h/j/k/l
        {
            mode = "n";
            key = "<C-h>";
            action = "<C-w>h";
        }
        {
            mode = "n";
            key = "<C-j>";
            action = "<C-w>j";
        }
        {
            mode = "n";
            key = "<C-k>";
            action = "<C-w>k";
        }
        {
            mode = "n";
            key = "<C-l>";
            action = "<C-w>l";
        }
    ];
}
