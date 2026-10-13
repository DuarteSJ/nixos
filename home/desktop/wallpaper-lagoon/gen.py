"""Aerial-lagoon wallpaper as an SVG, rendered by resvg.

Everything happens in SVG filters: a fractal-noise heightmap, tilted so the
left third rises out of the water, is colour-graded through a depth ramp
(deep water -> turquoise shallows -> wet sand -> dry sand -> rock), relief-
lit, and overlaid with caustic ripples over the shallows plus fine grain.
Deterministic (fixed seeds).

usage: gen.py WIDTH HEIGHT [SEED] > out.svg
"""

import sys

W = int(sys.argv[1]) if len(sys.argv) > 1 else 3840
H = int(sys.argv[2]) if len(sys.argv) > 2 else 2160
SEED = int(sys.argv[3]) if len(sys.argv) > 3 else 11

# Depth ramp: (height 0..1, colour).  Interpolated into component-transfer
# tables, so the stops can be uneven.
RAMP = [
    (0.00, (0x08, 0x30, 0x4c)),   # abyss
    (0.30, (0x0b, 0x4e, 0x74)),   # deep water
    (0.42, (0x0c, 0x6e, 0x96)),   # open water
    (0.50, (0x0e, 0x8c, 0xa8)),   # dropping off
    (0.58, (0x2b, 0xb0, 0xb8)),   # turquoise
    (0.625, (0x6c, 0xd6, 0xcf)),  # shallows
    (0.650, (0xa9, 0xe6, 0xda)),  # very shallow
    (0.664, (0xe6, 0xf4, 0xec)),  # surf line
    (0.676, (0xcf, 0xbe, 0x9a)),  # wet sand
    (0.70, (0xe0, 0xcf, 0xa8)),   # dry sand
    (0.75, (0xb8, 0xa2, 0x82)),   # sandy rock
    (0.82, (0x8c, 0x7a, 0x66)),   # rock
    (0.90, (0x6a, 0x5c, 0x4e)),   # dark rock
    (1.00, (0x4e, 0x45, 0x3d)),   # crag
]
N = 64


def table(ch):
    out = []
    for i in range(N):
        t = i / (N - 1)
        for (a, ca), (b, cb) in zip(RAMP, RAMP[1:]):
            if a <= t <= b:
                u = (t - a) / (b - a) if b > a else 0
                out.append((ca[ch] + (cb[ch] - ca[ch]) * u) / 255)
                break
    return " ".join(f"{v:.4f}" for v in out)


# Scale noise frequencies to the canvas so 1080p and 4K look the same.
s = 3840 / W
f_land = 0.00070 * s
f_detail = 0.0075 * s
f_caustic = 0.0105 * s
f_grain = 0.9

print(f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">
<defs>
  <!-- Tilt: high on the left (land), falling into deep water on the right. -->
  <linearGradient id="tilt" x1="0" y1="0" x2="1" y2="0.25">
    <stop offset="0" stop-color="#fff"/>
    <stop offset="0.30" stop-color="#b8b8b8"/>
    <stop offset="0.62" stop-color="#5c5c5c"/>
    <stop offset="1" stop-color="#262626"/>
  </linearGradient>

  <filter id="terrain" x="0" y="0" width="{W}" height="{H}" filterUnits="userSpaceOnUse"
          color-interpolation-filters="sRGB">
    <!-- big landforms + small detail, mixed -->
    <feTurbulence type="fractalNoise" baseFrequency="{f_land:.5f} {f_land*1.35:.5f}"
                  numOctaves="7" seed="{SEED}" result="big"/>
    <feTurbulence type="fractalNoise" baseFrequency="{f_detail:.5f}"
                  numOctaves="4" seed="{SEED + 3}" result="small"/>
    <feComposite in="big" in2="small" operator="arithmetic" k1="0" k2="0.86" k3="0.14" k4="0" result="noise"/>
    <!-- red channel as height; add the tilt (SourceGraphic) -->
    <feColorMatrix in="noise" type="matrix" values="
        1 0 0 0 0
        1 0 0 0 0
        1 0 0 0 0
        0 0 0 0 1" result="nGray"/>
    <feComposite in="nGray" in2="SourceGraphic" operator="arithmetic"
                 k1="0" k2="1.15" k3="0.62" k4="-0.47" result="height"/>

    <!-- depth -> colour -->
    <feComponentTransfer in="height" result="colour">
      <feFuncR type="table" tableValues="{table(0)}"/>
      <feFuncG type="table" tableValues="{table(1)}"/>
      <feFuncB type="table" tableValues="{table(2)}"/>
    </feComponentTransfer>

    <!-- relief: height into alpha, lit from the top left -->
    <feColorMatrix in="height" type="matrix" values="
        0 0 0 0 1
        0 0 0 0 1
        0 0 0 0 1
        1 0 0 0 0" result="bump"/>
    <feDiffuseLighting in="bump" surfaceScale="{30 / s:.2f}" diffuseConstant="1.10"
                       lighting-color="#ffffff" result="light">
      <feDistantLight azimuth="225" elevation="52"/>
    </feDiffuseLighting>
    <feComposite in="colour" in2="light" operator="arithmetic"
                 k1="1.12" k2="0" k3="0" k4="0" result="lit"/>
    <!-- relief on dry land only: water stays a flat surface over the seabed -->
    <feComponentTransfer in="bump" result="landA">
      <feFuncA type="table" tableValues="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.35 1 1 1 1 1 1"/>
    </feComponentTransfer>
    <feComposite in="lit" in2="landA" operator="in" result="land"/>
    <feComposite in="colour" in2="landA" operator="out" result="water"/>
    <feMerge><feMergeNode in="water"/><feMergeNode in="land"/></feMerge>
  </filter>

  <!-- Caustics: ridged turbulence sharpened into thin bright webs. -->
  <filter id="caustics" x="0" y="0" width="{W}" height="{H}" filterUnits="userSpaceOnUse"
          color-interpolation-filters="sRGB">
    <feTurbulence type="turbulence" baseFrequency="{f_caustic:.5f} {f_caustic*0.8:.5f}"
                  numOctaves="2" seed="{SEED + 7}" result="t0"/>
    <feTurbulence type="fractalNoise" baseFrequency="{f_caustic*0.25:.5f}"
                  numOctaves="2" seed="{SEED + 9}" result="warp"/>
    <feDisplacementMap in="t0" in2="warp" scale="{40 / s:.1f}" xChannelSelector="R" yChannelSelector="G" result="t"/>
    <feColorMatrix in="t" type="matrix" values="
        0 0 0 0 1
        0 0 0 0 1
        0 0 0 0 1
        -3.4 0 0 0 0.50" result="web"/>
    <feGaussianBlur in="web" stdDeviation="{0.8 / s:.2f}"/>
  </filter>

  <!-- Where the caustics may show: shallow water only (a band of height). -->
  <filter id="shallowMask" x="0" y="0" width="{W}" height="{H}" filterUnits="userSpaceOnUse"
          color-interpolation-filters="sRGB">
    <feTurbulence type="fractalNoise" baseFrequency="{f_land:.5f} {f_land*1.35:.5f}"
                  numOctaves="7" seed="{SEED}" result="big"/>
    <feTurbulence type="fractalNoise" baseFrequency="{f_detail:.5f}"
                  numOctaves="4" seed="{SEED + 3}" result="small"/>
    <feComposite in="big" in2="small" operator="arithmetic" k1="0" k2="0.86" k3="0.14" k4="0" result="noise"/>
    <feColorMatrix in="noise" type="matrix" values="
        1 0 0 0 0
        1 0 0 0 0
        1 0 0 0 0
        0 0 0 0 1" result="nGray"/>
    <feComposite in="nGray" in2="SourceGraphic" operator="arithmetic"
                 k1="0" k2="1.15" k3="0.62" k4="-0.47" result="height"/>
    <!-- height into alpha, then a bump-shaped response peaking in the
         shallows (zero on land and in deep water) -->
    <feColorMatrix in="height" type="matrix" values="
        0 0 0 0 1
        0 0 0 0 1
        0 0 0 0 1
        1 0 0 0 0" result="hA"/>
    <feComponentTransfer in="hA">
      <feFuncA type="table" tableValues="0 0 0 0 0 0 0 0 0.05 0.25 0.6 0.85 0.55 0 0 0 0 0 0 0"/>
    </feComponentTransfer>
    <feColorMatrix type="matrix" values="
        0 0 0 0 1
        0 0 0 0 1
        0 0 0 0 1
        0 0 0 1 0"/>
  </filter>
  <mask id="shallows" maskUnits="userSpaceOnUse" x="0" y="0" width="{W}" height="{H}">
    <rect width="{W}" height="{H}" fill="url(#tilt)" filter="url(#shallowMask)"/>
  </mask>

  <!-- Reef / seagrass: mid-frequency blotches, thresholded, dark teal. -->
  <filter id="reef" x="0" y="0" width="{W}" height="{H}" filterUnits="userSpaceOnUse"
          color-interpolation-filters="sRGB">
    <feTurbulence type="fractalNoise" baseFrequency="{f_detail*0.55:.5f}"
                  numOctaves="5" seed="{SEED + 21}" result="n"/>
    <feColorMatrix in="n" type="matrix" values="
        0 0 0 0 0.04
        0 0 0 0 0.27
        0 0 0 0 0.33
        6.5 0 0 0 -3.3"/>
    <feGaussianBlur stdDeviation="{1.2 / s:.2f}"/>
  </filter>

  <!-- Wind ripples on open water: stretched turbulence, faint light streaks. -->
  <filter id="ripples" x="0" y="0" width="{W}" height="{H}" filterUnits="userSpaceOnUse"
          color-interpolation-filters="sRGB">
    <feTurbulence type="turbulence" baseFrequency="{0.0035 * s:.5f} {0.016 * s:.5f}"
                  numOctaves="3" seed="{SEED + 31}" result="t"/>
    <feColorMatrix in="t" type="matrix" values="
        0 0 0 0 1
        0 0 0 0 1
        0 0 0 0 1
        -1.6 0 0 0 0.22"/>
  </filter>

  <filter id="grain" x="0" y="0" width="{W}" height="{H}" filterUnits="userSpaceOnUse">
    <feTurbulence type="fractalNoise" baseFrequency="{f_grain}" numOctaves="2" seed="{SEED + 13}"/>
    <feColorMatrix type="matrix" values="
        0 0 0 0 0.5
        0 0 0 0 0.5
        0 0 0 0 0.5
        0.9 0 0 0 -0.38"/>
  </filter>

  <radialGradient id="vignette" cx="0.55" cy="0.5" r="0.75">
    <stop offset="0.55" stop-color="#000" stop-opacity="0"/>
    <stop offset="1" stop-color="#021018" stop-opacity="0.30"/>
  </radialGradient>
</defs>

<rect width="{W}" height="{H}" fill="url(#tilt)" filter="url(#terrain)"/>
<rect width="{W}" height="{H}" filter="url(#reef)" mask="url(#shallows)" opacity="0.75"/>
<rect width="{W}" height="{H}" fill="#eafffb" filter="url(#caustics)" mask="url(#shallows)" opacity="0.8"/>
<rect width="{W}" height="{H}" fill="#d8fbff" filter="url(#ripples)" opacity="0.38"/>
<rect width="{W}" height="{H}" filter="url(#grain)" opacity="0.35"/>
<rect width="{W}" height="{H}" fill="url(#vignette)"/>
</svg>''')
