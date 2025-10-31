{
  config,
  pkgs,
  ...
}: {
  programs.nvf.settings.vim.extraPlugins.vimtex = {
    package = pkgs.vimPlugins.vimtex;
    setup = ''
      vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_view_zathura_options = "-x 'nvim --servername " .. vim.v.servername .. " --remote +%{line} %{file}'"
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        aux_dir = ".build",
        out_dir = ".build",
        continuous = 1,
      }
      vim.g.vimtex_quickfix_mode = 0
    '';
  };
}
