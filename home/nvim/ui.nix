{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.nvf.settings.vim = {
    # Enable various UI components
    statusline.lualine.enable = true;
    tabline.nvimBufferline.enable = true;

    theme = {
      enable = true;
      name = lib.toLower config.colorScheme.name;
      transparent = true;
    };

    extraPlugins = {
        # Highlight and manage some common comments
            #TODO:
            #FIXME:
            #NOTE:
            #HACK:
            #BUG:
            #OPTIMIZE:
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
