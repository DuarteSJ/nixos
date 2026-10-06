{...}: {
  # Steam games as drun entries. Launch via steam:// so Steam's per-game
  # launch options (e.g. `nvidia-offload %command%`) still apply.
  xdg.desktopEntries.megabonk = {
    name = "Megabonk";
    exec = "steam steam://rungameid/3405340";
    icon = "steam";
    categories = ["Game"];
  };
}
