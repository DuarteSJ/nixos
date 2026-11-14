# Pure Lua/config helper functions shared across the hyprland modules.
{lib}: let
  inline = lib.generators.mkLuaInline;

  # A configured output's static geometry, as an HL.MonitorSpec fragment
  # (no `output` key).  Shared by the static `monitor` rules below and the
  # runtime profile layer (monitor-manager), so both build the same spec.
  specOf = o:
    {inherit (o) mode position scale;}
    // lib.optionalAttrs (o.transform != 0) {inherit (o) transform;};
in {
  inherit inline specOf;

  # Configured output -> hl monitor _args table.  Static geometry only; the
  # runtime profile layer (monitor-manager) overrides this where it needs to.
  mkMonitor = m: {
    _args = [
      (
        {
          output =
            if m.description != null
            then "desc:${m.description}"
            else m.name;
        }
        // specOf m
      )
    ];
  };

  # Key spec builders.
  modKey = key: inline ''mainMod .. " + ${key}"'';
  modShiftKey = key: inline ''mainMod .. " + SHIFT + ${key}"'';
  bareKey = key: inline ''"${key}"'';

  # Dispatcher action builders.
  exec = cmd: inline ''hl.dsp.exec_cmd("${cmd}")'';
  focusDir = d: inline ''hl.dsp.focus({ direction = "${d}" })'';
  swapDir = d: inline ''hl.dsp.window.swap({ direction = "${d}" })'';
  focusWs = n: inline ''hl.dsp.focus({ workspace = ${toString n} })'';
  moveToWs = n: inline ''hl.dsp.window.move({ workspace = ${toString n} })'';
  moveToSpecial = s: inline ''hl.dsp.window.move({ workspace = "special:${s}" })'';
  toggleSpecial = s: inline ''hl.dsp.workspace.toggle_special("${s}")'';
  resizeBy = x: y: inline ''hl.dsp.window.resize({ x = ${toString x}, y = ${toString y}, relative = true })'';

  # Bind entry builders.
  kb = key: dsp: {_args = [key dsp];};
  kbo = key: dsp: opts: {_args = [key dsp opts];};
}
