#version 440
// Liquid-glass frame.
//
// The whole frame is one signed distance field: the screen minus a rounded
// "hole" (where windows live), smooth-unioned with up to four drawer
// rectangles and four drip circles.  The smooth union is what makes it
// liquid: a drawer near the frame is joined to it by a soft neck, and when
// the drawer moves away the neck thins and snaps by itself.
//
// Everything is in window pixels, y down.  Alpha only where the shape is;
// Hyprland blurs behind exactly those pixels (layer_rule ignore_alpha).

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 res;        // window size
    vec4 hole;       // x, y, w, h of the window area
    float holeR;     // its corner radius
    float k;         // smooth-union width (px): bigger = gooier
    vec4 d0;         // drawer rects: x, y, w, h (w or h < 1 = absent)
    vec4 d1;
    vec4 d2;
    vec4 d3;
    vec4 radii;      // corner radius per drawer
    vec4 dripX;      // up to four drip circles
    vec4 dripY;
    vec4 dripR;      // radius (< 0.5 = absent)
    vec4 tint;       // glass body colour (straight alpha)
    vec4 rim;        // edge highlight colour (straight alpha)
};

float sdRect(vec2 p, vec4 r, float rad) {
    vec2 h = r.zw * 0.5;
    vec2 c = r.xy + h;
    rad = min(rad, min(h.x, h.y));
    vec2 q = abs(p - c) - h + rad;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - rad;
}

// Polynomial smooth minimum (iq).
float smin(float a, float b, float kk) {
    float h = max(kk - abs(a - b), 0.0) / kk;
    return min(a, b) - h * h * kk * 0.25;
}

float drawer(vec2 p, vec4 r, float rad, float d) {
    if (r.z < 1.0 || r.w < 1.0) return d;
    return smin(d, sdRect(p, r, rad), k);
}

float drip(vec2 p, float x, float y, float r, float d) {
    if (r < 0.5) return d;
    return smin(d, length(p - vec2(x, y)) - r, k * 0.7);
}

float scene(vec2 p) {
    float d = -sdRect(p, hole, holeR);
    d = drawer(p, d0, radii.x, d);
    d = drawer(p, d1, radii.y, d);
    d = drawer(p, d2, radii.z, d);
    d = drawer(p, d3, radii.w, d);
    d = drip(p, dripX.x, dripY.x, dripR.x, d);
    d = drip(p, dripX.y, dripY.y, dripR.y, d);
    d = drip(p, dripX.z, dripY.z, dripR.z, d);
    d = drip(p, dripX.w, dripY.w, dripR.w, d);
    return d;
}

void main() {
    vec2 p = qt_TexCoord0 * res;
    float d = scene(p);

    // 1px anti-aliased coverage; bail early outside the glass.
    float cover = clamp(0.5 - d, 0.0, 1.0);
    if (cover <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    // Outward normal from the field's gradient.
    vec2 e = vec2(1.0, 0.0);
    vec2 n = vec2(scene(p + e.xy) - scene(p - e.xy),
                  scene(p + e.yx) - scene(p - e.yx));
    n = n / max(length(n), 1e-4);

    // Light from the top-left: edges facing it catch a brighter rim.
    float facing = dot(n, normalize(vec2(-0.55, -0.85)));
    float light = 0.45 + 0.55 * clamp(facing * 0.5 + 0.5, 0.0, 1.0);

    float inside = -d;                                  // px from the edge, inward
    float rimBand = 1.0 - smoothstep(0.0, 1.4, inside); // crisp 1px rim
    float glow = exp(-inside / 9.0);                    // soft inner glow

    vec3 rgb = tint.rgb;
    float a = tint.a;

    rgb = mix(rgb, rim.rgb, glow * 0.18 * light);
    a = a + glow * 0.06;

    float rimA = rimBand * rim.a * light;
    rgb = mix(rgb, rim.rgb, rimA);
    a = max(a, rimA);

    a *= cover * qt_Opacity;
    fragColor = vec4(rgb * a, a);
}
