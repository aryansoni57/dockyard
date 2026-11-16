#version 440
// Flowing liquid wallpaper.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 res;
    float t;
    vec4 base;
    vec4 c1;
    vec4 c2;
    vec4 c3;
};

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3. - 2. * f);
    return mix(mix(hash(i), hash(i + vec2(1., 0.)), f.x), mix(hash(i + vec2(0., 1.)), hash(i + vec2(1., 1.)), f.x), f.y);
}
float fbm(vec2 p) {
    float v = 0., a = .5;
    for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.; a *= .5; }
    return v;
}
void main() {
    vec2 uv = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y);
    vec2 p = (uv - .5) * vec2(res.x / res.y, 1.) * 2.;
    float tt = t * .05;
    vec2 q = vec2(fbm(p + tt), fbm(p + vec2(5.2, 1.3) - tt));
    vec2 r = vec2(fbm(p + 3. * q + vec2(1.7, 9.2) + tt * 1.3), fbm(p + 3. * q + vec2(8.3, 2.8) - tt));
    float f = fbm(p + 3. * r);
    vec3 col = mix(base.rgb, c1.rgb, smoothstep(.2, .8, f));
    col = mix(col, c2.rgb, smoothstep(.4, 1., length(q)));
    col = mix(col, c3.rgb, smoothstep(.5, 1., r.x) * .6);
    col *= .85 + .3 * f;
    fragColor = vec4(col, 1.) * qt_Opacity;
}
