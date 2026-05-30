{...}: let
  externalOpeners = [
    {
      app = "zathura";
      exts = ["pdf"];
    }
    {
      app = "mpv";
      exts = ["mp4" "mkv" "webm"];
    }
    {
      app = "swayimg";
      exts = ["png" "jpg" "jpeg" "gif"];
    }
  ];
  mkOpener = {
    app,
    exts,
  }: {
    enable = true;
    event = ["BufEnter"];
    pattern = map (e: "*.${e}") exts;
    command = "silent execute '!${app} ' . shellescape(expand('%')) . ' &' | bd";
  };
in {
  programs.nvf.settings.vim.autocmds =
    [
      {
        event = ["TextYankPost"];
        pattern = ["*"];
        command = ''
          lua vim.highlight.on_yank({higroup="IncSearch", timeout=50})
        '';
      }
      {
        event = ["FileType"];
        pattern = ["nix"];
        command = "setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab";
      }
      {
        enable = true;
        event = ["BufEnter"];
        pattern = ["*"];
        command = "setlocal indentexpr=nvim_treesitter#indent()";
      }
    ]
    ++ map mkOpener externalOpeners;
}
