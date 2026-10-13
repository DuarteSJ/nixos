# The lagoon wallpaper, rendered at build time (gen.py -> SVG -> resvg).
{
  runCommand,
  python3,
  resvg,
  width ? 1920,
  height ? 1080,
  seed ? 11,
}:
runCommand "lagoon-wallpaper-${toString width}x${toString height}.png" {
  nativeBuildInputs = [python3 resvg];
} ''
  python3 ${./gen.py} ${toString width} ${toString height} ${toString seed} > wallpaper.svg
  resvg wallpaper.svg $out
''
