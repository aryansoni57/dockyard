.pragma library

// Motion tokens from the AvdanOS research (research/features.md, easing guide).
// Use with easing.type: Easing.BezierSpline and easing.bezierCurve: Motion.enter.
// Each curve is [c1x, c1y, c2x, c2y, 1, 1], the format QtQuick expects.

// Popups and tiles entering.
var enter = [0.16, 1.0, 0.3, 1.0, 1, 1];
var enterMs = 400;

// Elastic feedback: overshoots, then settles. Presses and toggles.
var elastic = [0.34, 1.56, 0.64, 1.0, 1, 1];
var elasticMs = 280;

// Snapping: layout changes such as a tile or a pill sliding into place.
var snap = [0.2, 0.0, 0.0, 1.0, 1, 1];
var snapMs = 400;

// Theme morph uses Easing.InOutQuad for 750 ms.
var morphMs = 750;

// Rows of a list rise one after another by this much.
var staggerMs = 40;
// Only the first rows are staggered, so a long list does not take seconds to appear.
var staggerRows = 8;

// Duration to use for `base` ms. `unit` is Kirigami.Units.longDuration, which is 0
// when the user turned animations off in Plasma, so every motion drops to 0 then.
function ms(base, unit) {
    return unit === 0 ? 0 : base;
}
