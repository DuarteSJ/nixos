{
  lib,
  pkgs,
  ...
}: let
  # Steam games shown in rofi. Add one line per game: the app ID is in the
  # store URL, or `steamapps/appmanifest_<id>.acf`. Per-game launch options
  # (e.g. `nvidia-offload gamemoderun %command%`) are still set in Steam.
  games = {
    megabonk = {
      name = "Megabonk";
      appId = "3405340";
    };
  };

  # steam-game <appid>: launch via steam://, wait for the game to exit, then
  # shut Steam down once no games are left -- but only if one of these
  # launchers started Steam (marker file), never a Steam opened by hand.
  # Steam runs every game (native or Proton) under
  # `reaper SteamLaunch AppId=<id> -- ...`, so wait on that instead of a
  # per-game process name.
  # `steam` itself comes from programs.steam (system PATH), not runtimeInputs.
  steam-game = pkgs.writeShellApplication {
    name = "steam-game";
    runtimeInputs = [pkgs.procps pkgs.util-linux];
    text = ''
      app_id="$1"
      pattern="SteamLaunch AppId=$app_id( |$)"
      any_game="SteamLaunch AppId=[0-9]+( |$)"
      marker="''${XDG_RUNTIME_DIR:-/tmp}/steam-game-started-steam"

      # Steam not running: we start it, so we own it. Running without the
      # marker: opened by hand, leave it alone.
      if ! pgrep -x steam >/dev/null; then
        touch "$marker"
      fi

      # When Steam isn't running, `steam` becomes the client and blocks, so detach.
      setsid -f steam "steam://rungameid/$app_id" >/dev/null 2>&1

      # Wait for the game to start. Give up (leaving Steam open) if it never
      # does, e.g. Steam asked for a login or an update first.
      started=false
      for _ in $(seq 180); do
        if pgrep -f "$pattern" >/dev/null; then
          started=true
          break
        fi
        sleep 1
      done
      if [ "$started" = false ]; then
        exit 0
      fi

      while pgrep -f "$pattern" >/dev/null; do
        sleep 2
      done

      # Last game out shuts Steam down. Skip if Steam is already gone (e.g. it
      # died with the session): `steam -shutdown` would *start* the client.
      if [ -e "$marker" ] && ! pgrep -f "$any_game" >/dev/null; then
        rm -f "$marker"
        if pgrep -x steam >/dev/null; then
          steam -shutdown
        fi
      fi
    '';
  };
in {
  home.packages = [steam-game];

  xdg.desktopEntries =
    lib.mapAttrs (_: game: {
      inherit (game) name;
      exec = "${lib.getExe steam-game} ${game.appId}";
      icon = "steam";
      categories = ["Game"];
    })
    games;
}
