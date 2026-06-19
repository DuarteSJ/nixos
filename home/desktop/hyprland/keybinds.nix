# The full `bind` list: static binds + computed bind tables.
{
  lib,
  helpers,
  scripts,
  luaActions,
  vars,
}: let
  inherit (helpers) inline modKey modShiftKey bareKey exec focusDir swapDir focusWs moveToWs moveToSpecial toggleSpecial resizeBy kb kbo;
  inherit (scripts) rofi-launcher rofi-powermenu toggleWaybar toggleMic;
  inherit (luaActions) prodToggle incGaps decGaps cursorZoom cycleLayout;

  # 1..10 → keys 1..9,0; SUPER+N focus, SUPER+SHIFT+N move
  numWsBinds = lib.flatten (lib.genList (i: let
      n = i + 1;
      k =
        if n == 10
        then "0"
        else toString n;
    in [
      (kb (modKey k) (focusWs n))
      (kb (modShiftKey k) (moveToWs n))
    ])
    10);

  # a/s/d/f/g → workspaces 1..5
  letterWsBinds = lib.flatten (lib.imap1 (i: l: [
    (kb (modKey l) (focusWs i))
    (kb (modShiftKey l) (moveToWs i))
  ]) ["a" "s" "d" "f" "g"]);

  # special workspaces: SUPER+key toggles, SUPER+SHIFT+key moves window there.
  specialWs = [
    {
      key = "comma";
      name = "music";
    }
    {
      key = "M";
      name = "messages";
    }
  ];
  specialBinds =
    lib.concatMap (s: [
      (kb (modKey s.key) (toggleSpecial s.name))
      (kb (modShiftKey s.key) (moveToSpecial s.name))
    ])
    specialWs;

  # media / volume / brightness keys, derived from a {key, cmd, opts} list.
  mediaBinds = map (b: kbo (bareKey b.key) (exec b.cmd) b.opts) [
    {
      key = "XF86AudioRaiseVolume";
      cmd = "wpctl set-volume @DEFAULT_SINK@ 0.05+";
      opts = {
        locked = true;
        repeating = true;
      };
    }
    {
      key = "XF86AudioLowerVolume";
      cmd = "wpctl set-volume @DEFAULT_SINK@ 0.05-";
      opts = {
        locked = true;
        repeating = true;
      };
    }
    {
      key = "XF86AudioMicMute";
      cmd = "${lib.getExe toggleMic}";
      opts = {locked = true;};
    }
    {
      key = "XF86AudioMute";
      cmd = "wpctl set-mute @DEFAULT_SINK@ toggle";
      opts = {locked = true;};
    }
    {
      key = "XF86MonBrightnessUp";
      cmd = "brightnessctl s 4%+";
      opts = {
        locked = true;
        repeating = true;
      };
    }
    {
      key = "XF86MonBrightnessDown";
      cmd = "brightnessctl s 4%-";
      opts = {
        locked = true;
        repeating = true;
      };
    }
    {
      key = "XF86AudioNext";
      cmd = "playerctl next";
      opts = {locked = true;};
    }
    {
      key = "XF86AudioPause";
      cmd = "playerctl play-pause";
      opts = {locked = true;};
    }
    {
      key = "XF86AudioPlay";
      cmd = "playerctl play-pause";
      opts = {locked = true;};
    }
    {
      key = "XF86AudioPrev";
      cmd = "playerctl previous";
      opts = {locked = true;};
    }
  ];
in
  [
    # Apps & window ops
    (kb (modKey "Q") (exec vars.terminal))
    (kb (modKey "C") (inline "hl.dsp.window.close()"))
    (kb (modKey "P") (inline "hl.dsp.window.pin()"))
    (kb (modKey "V") (inline ''hl.dsp.window.float({ action = "toggle" })''))
    (kb (modKey "E") (exec "${lib.getExe rofi-launcher}"))
    (kb (modKey "R") (inline "hl.dsp.window.pseudo()"))
    (kb (modKey "T") (inline ''hl.dsp.layout("togglesplit")''))
    (kb (modKey "Tab") cycleLayout) # cycle workspace tiled layout

    # Focus h/j/k/l
    (kb (modKey "H") (focusDir "left"))
    (kb (modKey "L") (focusDir "right"))
    (kb (modKey "K") (focusDir "up"))
    (kb (modKey "J") (focusDir "down"))
  ]
  ++ numWsBinds
  ++ letterWsBinds
  ++ specialBinds # #4 generated special-workspace binds
  ++ mediaBinds # #4 generated media/volume/brightness binds
  ++ [
    # Misc execs
    (kb (modKey "B") (exec "${lib.getExe toggleWaybar}"))
    (kb (modKey "N") (exec "${lib.getExe toggleMic}"))
    (kb (modShiftKey "P") (exec "${lib.getExe rofi-powermenu}"))
    (kb (modShiftKey "N") (exec "switch-bg"))
    (kb (modKey "X") (exec "hyprshot -z -m region"))
    (kb (modShiftKey "X") (exec "screenrec"))

    # Cursor magnifier: SUPER+scroll (step 0.5, clamp 1..3)
    (kb (modKey "mouse_down") cursorZoom.zoomIn)
    (kb (modKey "mouse_up") cursorZoom.zoomOut)
    (kb (modKey "slash") prodToggle) # #1 inline Lua closure

    # Swap windows
    (kb (modShiftKey "h") (swapDir "left"))
    (kb (modShiftKey "j") (swapDir "down"))
    (kb (modShiftKey "k") (swapDir "up"))
    (kb (modShiftKey "l") (swapDir "right"))

    # Resize
    (kb (modKey "Left") (resizeBy (-65) 0))
    (kb (modKey "Down") (resizeBy 0 65))
    (kb (modKey "Up") (resizeBy 0 (-65)))
    (kb (modKey "Right") (resizeBy 65 0))

    # Gaps (#1 inline Lua closures, locked + repeating)
    (kbo (modKey "minus") incGaps {
      locked = true;
      repeating = true;
    })
    (kbo (modKey "equal") decGaps {
      locked = true;
      repeating = true;
    })

    # Lid (bindl = locked)
    (kbo (bareKey "switch:on:Lid Switch") (exec "systemctl suspend") {locked = true;})

    # Mouse (bindm)
    (kbo (modKey "mouse:272") (inline "hl.dsp.window.drag()") {mouse = true;})
    (kbo (modKey "mouse:273") (inline "hl.dsp.window.resize()") {mouse = true;})
  ]
