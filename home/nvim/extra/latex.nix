{pkgs, ...}: {
  programs.nvf.settings.vim = {
    # texlab LSP + latex/bibtex treesitter grammars. Formatting (tex-fmt) rides
    # on `languages.enableFormat`, which is off, so no formatter is pulled in.
    languages.tex.enable = true;

    # vimtex is not packaged by nvf, so it stays a manual extraPlugin. It only
    # supplies the viewer/compiler side; syntax and completion come from the
    # native module above.
    extraPlugins.vimtex = {
      package = pkgs.vimPlugins.vimtex;
      setup = ''
        vim.g.vimtex_view_method = "zathura"
        vim.g.vimtex_compiler_method = "latexmk"
        vim.g.vimtex_compiler_latexmk = {
          continuous = 1,
        }
        vim.g.vimtex_quickfix_mode = 1
        -- Treesitter owns highlighting; vimtex's own syntax engine would
        -- double up and fight the latex grammar.
        vim.g.vimtex_syntax_enabled = 0
      '';
    };
  };
}
