# Per-monitor wallpapers, driven off live monitor state.
#
# Split out of the monitor manager: this is topology-agnostic.  It iterates
# whatever `hl.get_monitors()` reports and picks orientation from each
# monitor's live `transform`, so a display that no profile has ever heard of
# still gets a correct wallpaper with zero configuration.
{
  pkgs,
  themeName,
  wallpapersPath,
}: let
  # `sort -V | head -n1` picks the first by version-sorted filename (a
  # deterministic choice within the curated per-theme dir), NOT the newest by
  # mtime.  Filesystem globbing has no Lua-sandbox equivalent, so this stays a
  # tiny shell script invoked per-monitor via hl.exec_cmd.
  setWallpaper = pkgs.writeShellApplication {
    name = "set-wallpaper";
    runtimeInputs = [pkgs.findutils pkgs.coreutils pkgs.hyprland];
    text = ''
      monitor="$1"
      orientation="$2"
      dir="${wallpapersPath}/${themeName}/$orientation"
      # `|| true`: head closes the pipe early, so sort takes SIGPIPE and the
      # pipeline returns non-zero — which would abort under set -o pipefail.
      wp=$(find "$dir" -maxdepth 1 -type f \
             \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) 2>/dev/null \
           | sort -V | head -n1) || true
      [ -n "$wp" ] || exit 0
      hyprctl hyprpaper wallpaper "$monitor,$wp" 2>/dev/null || true
    '';
  };

  setup = ''
    -- ====================================================================
    -- Wallpapers
    -- ====================================================================
    function _G.hlWallpapers()
      for _, m in ipairs(hl.get_monitors()) do
        local orient = (m.transform == 1 or m.transform == 3)
          and "vertical" or "horizontal"
        hl.exec_cmd("${pkgs.lib.getExe setWallpaper} " .. m.name .. " " .. orient)
      end
    end
  '';

  # Top-level program, for `extraConfig`.  No event subscriptions: every
  # topology change goes through a config reload now, which re-runs this.
  # 800ms puts it after the monitor manager.s 500ms match, so geometry has
  # settled before wallpapers are pushed.
  topLevel = ''
    ${setup}

    _G.__hlHandles = _G.__hlHandles or {}
    _G.__hlHandles[#_G.__hlHandles + 1] = hl.timer(
      function() _G.hlWallpapers() end,
      { timeout = 800, type = "oneshot" })
  '';
in {
  inherit setup topLevel setWallpaper;
}
