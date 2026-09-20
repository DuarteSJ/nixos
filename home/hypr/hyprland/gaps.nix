# Gap baseline, as a single source both the start handler and the
# productivity toggle read.
#
# Lives here rather than inside the monitor manager: gaps have nothing to do
# with monitor topology.  They were reconciled on hotplug only because
# prodToggle's restore path needed a writer to call, which coupled two
# unrelated concerns through one function.
#
# `baselineGapsLua` is exported raw so prodToggle can inline it as a fallback
# for the case where `hyprctl reload` has wiped _G.hlBaselineGaps but the
# keybind closure itself survives.
{
  gapsOuter,
  gapsInner,
}: let
  baselineGapsLua = ''
    hl.config({
      general = {
        gaps_out = ${toString gapsOuter},
        gaps_in  = ${toString gapsInner},
      },
    })'';

  setup = ''
    -- Values match the static `config` block in default.nix, so restoring the
    -- baseline always lands on exactly what you get at login.
    function _G.hlBaselineGaps()
      ${baselineGapsLua}
    end
  '';
in {
  inherit setup baselineGapsLua;
}
