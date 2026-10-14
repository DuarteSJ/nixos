{lib, ...}: let
  inherit (lib.generators) mkLuaInline;
  inherit (lib.strings) stringToCharacters toLower toUpper concatMapStrings;

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

  # Autocmd patterns are case-sensitive on Linux; `pdf` -> `*.[pP][dD][fF]`.
  caseInsensitive = s: concatMapStrings (c: "[${toLower c}${toUpper c}]") (stringToCharacters s);

  # BufReadCmd replaces nvim's own file read, so the (possibly huge) media file
  # is never loaded into a buffer. The app gets argv directly (no shell, no
  # escaping) with stdio on /dev/null so it can't die of SIGPIPE, detached so
  # it outlives nvim. The placeholder buffer is wiped on the next tick: it is
  # still in use while its BufReadCmd runs (E937).
  mkOpener = {
    app,
    exts,
  }: {
    event = ["BufReadCmd"];
    pattern = map (e: "*.${caseInsensitive e}") exts;
    desc = "Open with ${app} instead of editing";
    callback = mkLuaInline ''
      function(args)
        -- Nothing to open yet (e.g. `nvim new.pdf`): leave an empty buffer.
        if vim.fn.filereadable(args.match) == 0 then
          return
        end
        local ok, err = pcall(vim.system, { "${app}", args.match }, {
          detach = true,
          stdin = false,
          stdout = false,
          stderr = false,
        })
        if not ok then
          vim.notify("${app}: " .. tostring(err), vim.log.levels.ERROR)
        end
        local buf = args.buf
        vim.schedule(function()
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end)
      end
    '';
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
        # Obsidian's UI needs concealing, but globally it hides e.g. JSON quotes.
        event = ["FileType"];
        pattern = ["markdown"];
        command = "setlocal conceallevel=2";
      }
    ]
    ++ map mkOpener externalOpeners;
}
