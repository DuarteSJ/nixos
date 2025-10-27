{ config, pkgs, ... }: {
    programs.nvf.settings.vim = {
        statusline.lualine.enable = true;

        # Show buffer line at the top
        tabline.nvimBufferline.enable = true;

        # Enable cheatsheet for keybindings
        binds.cheatsheet.enable = true;

        # Neo-tree configuration
        filetree.neo-tree = {
            enable = true;
            setupOpts = {
                open_files_in_last_window = false;
                window = {
                    position = "right";
                    width = 30;
                };
            };
        };

        # Telescope for file finding
        telescope.enable = true;

        theme = {
            enable = true;
            name = "nord";
            transparent = true;
        };
    };
}
