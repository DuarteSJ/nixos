# bonk-reroll: Megabonk map reroller.
# Spec: docs/superpowers/specs/2026-10-06-bonk-reroll-design.md
#
# Steam launch options for Megabonk:
#   nvidia-offload gamemoderun /home/duartesj/.local/bin/bonk-reroll run %command%
# (absolute path: Steam's FHS sandbox can't see /etc/profiles, and launch
# options aren't guaranteed to expand $HOME.)
{
  lib,
  pkgs,
  osConfig,
  ...
}: let
  # Keep in sync with LABELS/DERIVED in bonk_reroll/rules.py.
  counters = [
    "moais"
    "shady"
    "shady_moais"
    "microwaves"
    "boss_curses"
    "pots"
    "chests"
    "challenges"
    "charge_shrines"
    "greed_shrines"
    "magnet_shrines"
    "bald_heads"
  ];

  # Cycled in this order by Mod+Shift+F5. A map matches when every count is
  # >= its number.
  modes = [
    {
      name = "perfect";
      min = {
        microwaves = 2;
        boss_curses = 2;
        shady_moais = 9;
      };
    }
    {
      name = "good";
      min = {
        microwaves = 2;
        boss_curses = 2;
        shady_moais = 8;
      };
    }
  ];

  checkMode = mode:
    lib.throwIfNot (lib.all (k: lib.elem k counters) (lib.attrNames mode.min))
    "bonk-reroll: mode ${mode.name} uses an unknown counter"
    mode;

  configFile = pkgs.writeText "bonk-reroll.json" (builtins.toJSON {
    modes = map checkMode modes;
    reset_key = "KEY_Q"; # Megabonk's QuickReset binding
    pause_key = "KEY_ESC";
  });

  python = pkgs.python3.withPackages (ps: [ps.evdev]);

  bonk-reroll = pkgs.stdenvNoCC.mkDerivation {
    pname = "bonk-reroll";
    version = "0.1.0";
    # .py files only: keeps stray __pycache__ from local test runs out of
    # the store and the source hash.
    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.fileFilter (file: file.hasExt "py") ./.;
    };
    nativeBuildInputs = [pkgs.makeShellWrapper];
    dontBuild = true;

    # Steam sets LD_LIBRARY_PATH (runtime libs) and LD_PRELOAD (overlay) for
    # the launch command: stash them for the game, keep them out of our Python.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/bonk-reroll $out/bin
      cp -r bonk_reroll $out/lib/bonk-reroll/
      makeShellWrapper ${python.interpreter} $out/bin/bonk-reroll \
        --run 'if [ -n "''${LD_LIBRARY_PATH+set}" ]; then export BONK_REROLL_ORIG_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"; unset LD_LIBRARY_PATH; fi' \
        --run 'if [ -n "''${LD_PRELOAD+set}" ]; then export BONK_REROLL_ORIG_LD_PRELOAD="$LD_PRELOAD"; unset LD_PRELOAD; fi' \
        --prefix PATH : ${lib.makeBinPath [osConfig.programs.hyprland.package pkgs.dunst]} \
        --set PYTHONPATH $out/lib/bonk-reroll \
        --add-flags "-m bonk_reroll --config ${configFile}"
      runHook postInstall
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      mkdir -p "$TMPDIR/check"
      cp -r tests "$TMPDIR/check/"
      cd "$TMPDIR/check"
      PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=$out/lib/bonk-reroll \
        ${python.interpreter} -m unittest discover -s tests -t . -v
      runHook postInstallCheck
    '';

    meta.mainProgram = "bonk-reroll";
  };
in {
  home.packages = [bonk-reroll];
  home.file.".local/bin/bonk-reroll".source = lib.getExe bonk-reroll;
}
