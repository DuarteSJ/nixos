# Gap baseline, as a single source the productivity toggle inlines.
#
# Lives here rather than inside the monitor manager: gaps have nothing to do
# with monitor topology.  Values match the static `config` block in
# default.nix, so restoring the baseline always lands on exactly what you get
# at login.
{
  gapsOuter,
  gapsInner,
}: {
  baselineGapsLua = ''
    hl.config({
      general = {
        gaps_out = ${toString gapsOuter},
        gaps_in  = ${toString gapsInner},
      },
    })'';
}
