{
  config,
  pkgs,
  ...
}: let
  laptopMonitor = config.monitors.laptop;
  externalMonitors = config.monitors.external;
  themeName = config.colorScheme.slug or "nord";

  laptopOrientation =
    if laptopMonitor.transform == 1 || laptopMonitor.transform == 3
    then "vertical"
    else "horizontal";

  monitorOrientation = m:
    if m.transform == 1 || m.transform == 3
    then "vertical"
    else "horizontal";

  # Per-external-monitor array initialization
  wallpaperArrays = builtins.concatStringsSep "\n" (builtins.genList (i: let
    m = builtins.elemAt externalMonitors i;
    orientation = monitorOrientation m;
  in ''
    external_${toString i}_dir="$wallpapers_dir/${orientation}"
    mapfile -t external_${toString i}_wallpapers < <(get_wallpapers "$external_${toString i}_dir")
    if [[ ''${#external_${toString i}_wallpapers[@]} -eq 0 ]]; then
        ${pkgs.dunst}/bin/dunstify -u critical "Background Error" "No wallpapers found for monitor ${m.name} in $external_${toString i}_dir"
        exit 1
    fi
  '') (builtins.length externalMonitors));

  # State initialisation + reading
  stateReading = let
    inits = builtins.concatStringsSep "\n" (builtins.genList (i: ''
      external_${toString i}_index=0
    '') (builtins.length externalMonitors));

    branches = builtins.concatStringsSep "\n" (builtins.genList (i: ''
              if [[ "$key" == "external_${toString i}_index" ]]; then
                  external_${toString i}_index="$value"
    '') (builtins.length externalMonitors));
  in ''
    ${inits}
    laptop_index=0

    if [[ -f "$state_file" ]]; then
        while IFS='=' read -r key value; do
    ${branches}
            elif [[ "$key" == "laptop_index" ]]; then
                laptop_index="$value"
            fi
        done < "$state_file"
    fi
  '';

  # elif blocks for each external monitor
  externalMonitorBlocks = builtins.concatStringsSep "\n" (builtins.genList (i: let
    m = builtins.elemAt externalMonitors i;
    orientation = monitorOrientation m;
  in ''
    elif [[ "$active_monitor" == "${m.name}" ]]; then
        external_${toString i}_index=$(( (external_${toString i}_index + 1) % ''${#external_${toString i}_wallpapers[@]} ))
        next_wallpaper="''${external_${toString i}_wallpapers[$external_${toString i}_index]}"
        monitor_name="${m.name}"
        orientation="${orientation}"
        total_count=''${#external_${toString i}_wallpapers[@]}
        current_num=$((external_${toString i}_index + 1))
        state_key="external_${toString i}_index"
  '') (builtins.length externalMonitors));

  # Atomic state saving: write to tmp then mv
  stateSaving = let
    externalLines = builtins.concatStringsSep "\n" (builtins.genList (i: ''
      echo "external_${toString i}_index=$external_${toString i}_index" >> "$tmp_state"
    '') (builtins.length externalMonitors));
  in ''
    tmp_state=$(${pkgs.coreutils}/bin/mktemp "$HOME/.cache/wallpaper-state.XXXXXX")
    echo "laptop_index=$laptop_index" >> "$tmp_state"
    ${externalLines}
    ${pkgs.coreutils}/bin/mv "$tmp_state" "$state_file"
  '';

  # All known wallpaper paths across all monitors (for safe unload)
  allMonitorWallpaperVars = builtins.concatStringsSep " " (
    ["\"$laptop_current_wallpaper\""]
    ++ builtins.genList (i: "\"$external_${toString i}_current_wallpaper\"")
       (builtins.length externalMonitors)
  );

  # Track what's currently displayed on each monitor
  currentWallpaperReading = builtins.concatStringsSep "\n" (builtins.genList (i: let
    m = builtins.elemAt externalMonitors i;
  in ''
    external_${toString i}_current_wallpaper=$(hyprctl hyprpaper listactive | ${pkgs.gnugrep}/bin/grep "^${m.name}" | ${pkgs.coreutils}/bin/cut -d'=' -f2- | ${pkgs.coreutils}/bin/tr -d ' ' || true)
  '') (builtins.length externalMonitors));

in {
  home.packages = [
    (pkgs.writeShellScriptBin "switch-bg" ''
      set -euo pipefail
      cur_theme_name="${themeName}"
      wallpapers_dir="$HOME/Pictures/wallpapers/$cur_theme_name"

      if [[ ! -d "$wallpapers_dir" ]]; then
          ${pkgs.dunst}/bin/dunstify -u critical "Background Error" "Directory '$wallpapers_dir' not found"
          exit 1
      fi

      laptop_orientation="${laptopOrientation}"
      laptop_dir="$wallpapers_dir/$laptop_orientation"

      get_wallpapers() {
          local dir="$1"
          if [[ -d "$dir" ]]; then
              ${pkgs.findutils}/bin/find "$dir" -maxdepth 1 -type f \
                  \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
                  | ${pkgs.coreutils}/bin/sort -V
          fi
      }

      mapfile -t laptop_wallpapers < <(get_wallpapers "$laptop_dir")
      if [[ ''${#laptop_wallpapers[@]} -eq 0 ]]; then
          ${pkgs.dunst}/bin/dunstify -u critical "Background Error" "No wallpapers found in $laptop_dir"
          exit 1
      fi

      ${wallpaperArrays}

      active_monitor=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .name')

      state_file="$HOME/.cache/wallpaper-state"
      ${pkgs.coreutils}/bin/mkdir -p "$HOME/.cache"
      ${pkgs.coreutils}/bin/touch "$state_file"

      ${stateReading}

      # Read currently active wallpapers on each monitor so we can safely unload
      laptop_current_wallpaper=$(hyprctl hyprpaper listactive | ${pkgs.gnugrep}/bin/grep "^${laptopMonitor.name}" | ${pkgs.coreutils}/bin/cut -d'=' -f2- | ${pkgs.coreutils}/bin/tr -d ' ' || true)
      ${currentWallpaperReading}

      state_key=""
      if [[ "$active_monitor" == "${laptopMonitor.name}" ]]; then
          # Initialise to -1 on first use so index 0 is shown first
          if [[ "$laptop_index" -eq 0 && ! -f "$state_file.seen" ]]; then
              laptop_index=-1
              ${pkgs.coreutils}/bin/touch "$state_file.seen"
          fi
          laptop_index=$(( (laptop_index + 1) % ''${#laptop_wallpapers[@]} ))
          next_wallpaper="''${laptop_wallpapers[$laptop_index]}"
          monitor_name="${laptopMonitor.name}"
          orientation="$laptop_orientation"
          total_count=''${#laptop_wallpapers[@]}
          current_num=$((laptop_index + 1))
          state_key="laptop_index"
      ${externalMonitorBlocks}
      else
          ${pkgs.dunst}/bin/dunstify -u critical "Background Error" "Unrecognised active monitor: $active_monitor"
          exit 1
      fi

      # Persist state atomically
      ${stateSaving}

      hyprctl hyprpaper preload "$next_wallpaper"
      hyprctl hyprpaper wallpaper "$monitor_name,$next_wallpaper"

      # Only unload wallpapers not currently displayed on ANY monitor
      in_use=(${allMonitorWallpaperVars})
      loaded_wallpapers=$(hyprctl hyprpaper listloaded | ${pkgs.gnugrep}/bin/grep -v "no wallpapers loaded" || true)
      if [[ -n "$loaded_wallpapers" ]]; then
          while IFS= read -r loaded; do
              [[ -z "$loaded" ]] && continue
              still_needed=false
              for w in "''${in_use[@]}"; do
                  [[ "$loaded" == "$w" ]] && still_needed=true && break
              done
              if [[ "$still_needed" == false && "$loaded" != "$next_wallpaper" ]]; then
                  hyprctl hyprpaper unload "$loaded" 2>/dev/null || true
              fi
          done <<< "$loaded_wallpapers"
      fi

      wallpaper_name=$(${pkgs.coreutils}/bin/basename "$next_wallpaper" | ${pkgs.gnused}/bin/sed 's/\.[^.]*$//')
      # Show just the connector portion of the monitor name (e.g. "DP" from "DP-1")
      monitor_label=$(echo "$monitor_name" | ${pkgs.coreutils}/bin/cut -d'-' -f1)

      ${pkgs.dunst}/bin/dunstify -t 3000 -i "$next_wallpaper" \
          "Wallpaper Changed" \
          "$wallpaper_name\n$current_num/$total_count • $monitor_label ($orientation)"
    '')
  ];
}
