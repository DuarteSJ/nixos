{
  config,
  pkgs,
  ...
}: let
  laptopMonitor = config.monitors.laptop;
  externalMonitors = builtins.filter (m: m.enabled) config.monitors.external;
  themeName = config.colorScheme.slug or "nord";

  monitorChecks = builtins.concatStringsSep " || " (map (m:
    ''[[ "$active_monitor" == "${m.name}" ]]''
  ) externalMonitors);

  externalMonitorBlocks = builtins.concatStringsSep "\n" (builtins.genList (i: let
    m = builtins.elemAt externalMonitors i;
    orientation = if m.orientation == "vertical" then "vertical" else "horizontal";
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

  stateReading = builtins.concatStringsSep "\n" (builtins.genList (i: ''
    external_${toString i}_index=0
  '') (builtins.length externalMonitors)) + ''
    laptop_index=0

    if [[ -f "$state_file" ]]; then
        while IFS='=' read -r key value; do
  '' + builtins.concatStringsSep "\n" (builtins.genList (i: ''
            if [[ "$key" == "external_${toString i}_index" ]]; then
                external_${toString i}_index="$value"
  '') (builtins.length externalMonitors)) + ''
            elif [[ "$key" == "laptop_index" ]]; then
                laptop_index="$value"
            fi
        done < "$state_file"
    fi
  '';

  wallpaperArrays = builtins.concatStringsSep "\n" (builtins.genList (i: let
    m = builtins.elemAt externalMonitors i;
    orientation = if m.orientation == "vertical" then "vertical" else "horizontal";
  in ''
    external_${toString i}_dir="$wallpapers_dir/${orientation}"
    mapfile -t external_${toString i}_wallpapers < <(get_wallpapers "$external_${toString i}_dir")
  '') (builtins.length externalMonitors));

  stateSaving = builtins.concatStringsSep "\n" (builtins.genList (i: ''
    echo "external_${toString i}_index=$external_${toString i}_index" >> "$state_file"
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

      laptop_orientation="${if laptopMonitor.orientation == "vertical" then "vertical" else "horizontal"}"
      laptop_dir="$wallpapers_dir/$laptop_orientation"

      get_wallpapers() {
          local dir="$1"
          if [[ -d "$dir" ]]; then
              ${pkgs.findutils}/bin/find "$dir" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | ${pkgs.coreutils}/bin/sort -V
          fi
      }

      mapfile -t laptop_wallpapers < <(get_wallpapers "$laptop_dir")

      ${wallpaperArrays}

      active_monitor=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .name')

      state_file="$HOME/.cache/wallpaper-state"
      ${pkgs.coreutils}/bin/mkdir -p "$HOME/.cache"
      ${pkgs.coreutils}/bin/touch "$state_file"

      ${stateReading}

      state_key=""
      if [[ "$active_monitor" == "${laptopMonitor.name}" ]]; then
          laptop_index=$(( (laptop_index + 1) % ''${#laptop_wallpapers[@]} ))
          next_wallpaper="''${laptop_wallpapers[$laptop_index]}"
          monitor_name="${laptopMonitor.name}"
          orientation="$laptop_orientation"
          total_count=''${#laptop_wallpapers[@]}
          current_num=$((laptop_index + 1))
          state_key="laptop_index"
      ${externalMonitorBlocks}
      else
          ${pkgs.dunst}/bin/dunstify -u critical "Background Error" "Could not determine active monitor"
          exit 1
      fi

      > "$state_file"
      echo "laptop_index=$laptop_index" >> "$state_file"
      ${stateSaving}

      hyprctl hyprpaper preload "$next_wallpaper"
      hyprctl hyprpaper wallpaper "$monitor_name,$next_wallpaper"

      loaded_wallpapers=$(hyprctl hyprpaper listloaded | ${pkgs.gnugrep}/bin/grep -v "no wallpapers loaded" || true)
      if [[ -n "$loaded_wallpapers" ]]; then
          while IFS= read -r loaded; do
              if [[ "$loaded" != "$next_wallpaper" && -n "$loaded" ]]; then
                  hyprctl hyprpaper unload "$loaded" 2>/dev/null || true
              fi
          done <<< "$loaded_wallpapers"
      fi

      wallpaper_name=$(${pkgs.coreutils}/bin/basename "$next_wallpaper" | ${pkgs.gnused}/bin/sed 's/\.[^.]*$//')

      ${pkgs.dunst}/bin/dunstify -t 3000 -i "$next_wallpaper" "Wallpaper Changed" "$wallpaper_name\n$current_num/$total_count • $(echo $monitor_name | ${pkgs.coreutils}/bin/cut -d'-' -f1) ($orientation)"
    '')
  ];
}
