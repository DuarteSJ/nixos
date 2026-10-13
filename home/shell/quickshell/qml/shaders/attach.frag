#version 440
// Status panel "attached" to the bar's right group.
//
// The group and the drawer card are smooth-unioned as signed distance
// fields, so where they meet the card flows out of the group with soft
// concave joins (the liquid-glass branch's look, opaque here).  Only the
// part *outside* the group is painted -- the group itself is drawn by the
// bar underneath, and painting over it would hide its icons.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 res;       // window size
    vec4 group;     // bar group rect (x, y, w, h), extended past the screen edges
    float groupR;   // its corner radius
    vec4 card;      // drawer rect (w or h < 1 = absent)
    float cardR;
    float k;        // smooth-union width (px)
    vec4 color;     // fill (straight alpha)
    vec4 rim;       // 1px outline on the part outside the group
};

float sdRect(vec2 p, vec4 r, float rad) {
    vec2 h = r.zw * 0.5;
    vec2 c = r.xy + h;
    rad = min(rad, min(h.x, h.y));
    vec2 q = abs(p - c) - h + rad;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - rad;
}

float smin(float a, float b, float kk) {
    float h = max(kk - abs(a - b), 0.0) / kk;
    return min(a, b) - h * h * kk * 0.25;
}

void main() {
    vec2 p = qt_TexCoord0 * res;
    float dg = sdRect(p, group, groupR);
    float du = dg;
    if (card.z >= 1.0 && card.w >= 1.0) du = smin(dg, sdRect(p, card, cardR), k);

    float covUnion = clamp(0.5 - du, 0.0, 1.0);
    float covGroup = clamp(0.5 - dg, 0.0, 1.0);
    float a = max(covUnion - covGroup, 0.0) * color.a * qt_Opacity;

    // Outline: a band just inside the union's edge, faded out near the
    // group so it doesn't draw a seam across the join.
    float band = (1.0 - smoothstep(0.0, 1.3, -du)) * smoothstep(1.0, 6.0, dg);
    vec3 rgb = mix(color.rgb, rim.rgb, band * rim.a);
    fragColor = vec4(rgb * a, a);
}
