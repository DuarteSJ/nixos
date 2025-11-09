{
  config,
  pkgs,
  ...
}: {
  programs.nvf.settings.vim = {
    # Enable LSP globally
    lsp.enable = true;

    # Enable autocomplete with nvim-cmp
    autocomplete.nvim-cmp.enable = true;

    # Enable languages with LSP and Treesitter
    languages = {
      enableTreesitter = true;

      nix.enable = true;
      python.enable = true;
      rust.enable = true;
      clang.enable = true;
      html.enable = true;
      css.enable = true;
      ts.enable = true;
      java.enable = true;
      markdown.enable = true;
    };
  };
}
