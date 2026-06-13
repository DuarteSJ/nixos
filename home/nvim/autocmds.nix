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
          lua vim.hl.on_yank({higroup="IncSearch", timeout=50})
        '';
      }
      {
        event = ["FileType"];
        pattern = ["nix"];
        command = "setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab";
      }
      {
        event = ["FileType"];
        pattern = ["*"];
        command = "setlocal indentexpr=nvim_treesitter#indent()";
      }
    ]
    ++ map mkOpener externalOpeners;
}
