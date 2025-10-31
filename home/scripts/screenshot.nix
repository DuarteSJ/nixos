{
  config,
  pkgs,
  ...
}: {
  home.packages = [
    (pkgs.writeShellScriptBin "screenshot" ''
      # Ensure screenshots directory exists
      mkdir -p ~/Pictures/screenshots
      selection=$(${pkgs.slurp}/bin/slurp -d \
        -b "${config.colorScheme.palette.base00}66" \
        -c "${config.colorScheme.palette.base0E}ff" \
        -s "${config.colorScheme.palette.base0D}40" \
        -w 3 \
        -B "${config.colorScheme.palette.base01}99")

      if [ $? -eq 0 ]; then
        # Small delay to let slurp's UI fully disappear
        sleep 0.1

        tempfile=$(mktemp --suffix=.png)
        ${pkgs.grim}/bin/grim -g "$selection" "$tempfile"
        ${pkgs.wl-clipboard}/bin/wl-copy < "$tempfile"

        # First notification: click to save
        action=$(${pkgs.dunst}/bin/dunstify -u normal -i "$tempfile" \
          -A "save,Save" \
          "Copied to clipboard" \
          "Click to save")
        if [ "$action" = "save" ]; then
          filename=~/Pictures/screenshots/screenshot_$(date +%d_%m_%Y_%H:%M:%S).png
          mv "$tempfile" "$filename"
          # Second notification: click to open
          feh_action=$(${pkgs.dunst}/bin/dunstify -u normal -i "$filename" \
            -A "open,Open" \
            "Screenshot saved" \
            "Click to open")
          if [ "$feh_action" = "open" ]; then
            ${pkgs.feh}/bin/feh "$filename"
          fi
        else
          # Clean up tempfile if not saved
          rm -f "$tempfile"
        fi
      else
        ${pkgs.dunst}/bin/dunstify -u normal "Screenshot cancelled"
      fi
    '')
  ];
}
