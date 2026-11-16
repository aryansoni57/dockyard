// Dockyard Glass: drawing code shared by the KDecoration3 plugin and the
// offscreen preview harness. Nothing in here talks to KWin.
#pragma once

#include <KDecoration3/DecorationButton>

#include <QColor>
#include <QImage>
#include <QMarginsF>
#include <QPainterPath>
#include <QRectF>
#include <QRegion>

class QPainter;

namespace DockyardGlass
{

// User settings, read from ~/.config/dockyardglassrc [General].
struct Settings {
    qreal titleOpacityDark = 0.62; // alpha of the title bar fill on a dark scheme
    qreal titleOpacityLight = 0.70; // alpha of the title bar fill on a light scheme
    qreal inactiveOpacityScale = 0.92; // inactive windows are slightly clearer
    int titleHeight = 34; // logical px
    int buttonWidth = 34; // logical px
    qreal cornerRadius = 10.0; // top corners, logical px; 0 = square
    bool blurBorders = true; // also blur the side and bottom borders
    bool titleHighlight = true; // 1 px top highlight
    bool titleHairline = true; // 1 px line under the title bar
    int shadowSize = 32; // 0 disables the shadow
    qreal shadowStrength = 1.0; // multiplier on shadow alpha
    qreal animationFactor = 1.0; // kdeglobals [KDE] AnimationDurationFactor
    int hoverDurationMs = 120; // before the animation factor is applied

    static Settings load();
    int animationDuration() const;
};

// Colours for one window state, derived from the colour scheme.
struct Palette {
    bool dark = true;
    bool active = true;
    QColor titleFill;
    QColor text;
    QColor glyph;
    QColor glyphHover;
    QColor hoverFill;
    QColor pressFill;
    QColor checkedFill;
    QColor closeHover;
    QColor closePress;
    QColor closeGlyph;
    QColor outline;
    QColor topHighlight;
    QColor hairline;
};

// titleBar/foreground: [WM] colours of the scheme; accent: palette Highlight.
Palette makePalette(const QColor &titleBar, const QColor &foreground, const QColor &accent, bool active, const Settings &settings);

bool isDarkColor(const QColor &c);

struct CornerRadii {
    qreal topLeft = 0;
    qreal topRight = 0;
};

// Outer shape of the decorated window: rounded top corners, square bottom.
QPainterPath framePath(const QRectF &frame, CornerRadii radii);
QRegion regionFromPath(const QPainterPath &path);

struct FrameGeometry {
    QRectF frame; // whole decoration rect
    QMarginsF borders; // left, title height, right, bottom
    CornerRadii radii;
    bool drawOutline = true; // false when maximized
    qreal scale = 1.0; // device pixel ratio, for 1 px lines
};

// Fills title bar and borders, draws highlight, hairline and outline.
void paintFrame(QPainter *painter, const FrameGeometry &geometry, const Palette &palette, const Settings &settings);

// Paints the glyph for one button type in a box (normally titleHeight high).
void paintGlyph(QPainter *painter, KDecoration3::DecorationButtonType type, const QRectF &box, const QColor &color, bool checked);

struct ButtonVisualState {
    qreal hover = 0; // 0..1, animated
    bool pressed = false;
    bool checked = false;
    bool enabled = true;
};

// Full button paint (background + glyph). For Close the fill covers the whole
// box; the caller clips it to the frame shape.
void paintButton(QPainter *painter,
                 KDecoration3::DecorationButtonType type,
                 const QRectF &box,
                 const Palette &palette,
                 const ButtonVisualState &state);

// Shadow texture with the window shape cut out, for KDecoration3::DecorationShadow.
struct ShadowTexture {
    QImage image;
    QMarginsF padding; // how far the image extends past the window
    QRectF innerRect; // the part of the image that maps to the window
};
ShadowTexture makeShadow(const Settings &settings, bool dark, bool active, qreal radius);

// Small separable box blur on the alpha channel (3 passes approximate a Gaussian).
void blurAlpha(QImage &image, int radius);

} // namespace DockyardGlass
