# Pure Lua/config helper functions shared across the hyprland modules.
{lib}: let
  inline = lib.generators.mkLuaInline;
in {
  inherit inline;

  # Monitor entry → hl monitor _args table.
  mkMonitor = m: {
    _args = [
      (
        {
          output =
            if m ? description
            then "desc:${m.description}"
            else m.name;
          inherit (m) mode position scale;
        }
        // lib.optionalAttrs ((m.transform or 0) != 0) {inherit (m) transform;}
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
