{
  config,
  pkgs,
  ...
}: {
  programs.nvf.settings.vim = {
    # Enable various UI components
    statusline.lualine.enable = true;
    tabline.nvimBufferline.enable = true;

    theme = {
      enable = true;
      name = "nord";
      transparent = true;
    };

    extraPlugins = {
      # Highlight TODO, FIXME, NOTE, etc.
      todo-comments = {
        package = pkgs.vimPlugins.todo-comments-nvim;
        setup = ''
          require('todo-comments').setup()
        '';
      };

      # Show available keybindings in popup
      which-key = {
        package = pkgs.vimPlugins.which-key-nvim;
        setup = ''
          require('which-key').setup({
              delay = 500,
          })
        '';
      };
    };
  };
}
