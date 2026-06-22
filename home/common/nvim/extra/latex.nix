{pkgs, ...}: {
  programs.nvf.settings.vim = {
    extraPlugins.vimtex = {
      package = pkgs.vimPlugins.vimtex;
      setup = ''
        vim.g.vimtex_view_method = "zathura"
        vim.g.vimtex_compiler_method = "latexmk"
        vim.g.vimtex_compiler_latexmk = {
          continuous = 1,
        }
        vim.g.vimtex_quickfix_mode = 1
      '';
    };
  };
}
