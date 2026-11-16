#include "glassstyle.h"

#include <KConfigGroup>
#include <KSharedConfig>

#include <QLinearGradient>
#include <QPainter>
#include <QPolygonF>

#include <algorithm>
#include <cmath>

namespace DockyardGlass
{

using KDecoration3::DecorationButtonType;

// ---------------------------------------------------------------- settings

Settings Settings::load()
{
    Settings s;
    KSharedConfig::Ptr config = KSharedConfig::openConfig(QStringLiteral("dockyardglassrc"), KConfig::NoGlobals);
    config->reparseConfiguration();
    const KConfigGroup g(config, QStringLiteral("General"));
    s.titleOpacityDark = std::clamp(g.readEntry("TitleOpacityDark", s.titleOpacityDark), 0.0, 1.0);
    s.titleOpacityLight = std::clamp(g.readEntry("TitleOpacityLight", s.titleOpacityLight), 0.0, 1.0);
    s.inactiveOpacityScale = std::clamp(g.readEntry("InactiveOpacityScale", s.inactiveOpacityScale), 0.0, 1.0);
    s.titleHeight = std::clamp(g.readEntry("TitleHeight", s.titleHeight), 24, 64);
    s.buttonWidth = std::clamp(g.readEntry("ButtonWidth", s.titleHeight), 20, 80);
    s.cornerRadius = std::clamp(g.readEntry("CornerRadius", s.cornerRadius), 0.0, 24.0);
    s.blurBorders = g.readEntry("BlurBorders", s.blurBorders);
    s.titleHighlight = g.readEntry("TitleHighlight", s.titleHighlight);
    s.titleHairline = g.readEntry("TitleHairline", s.titleHairline);
    s.shadowSize = std::clamp(g.readEntry("ShadowSize", s.shadowSize), 0, 96);
    s.shadowStrength = std::clamp(g.readEntry("ShadowStrength", s.shadowStrength), 0.0, 2.0);
    s.hoverDurationMs = std::clamp(g.readEntry("HoverDuration", s.hoverDurationMs), 0, 1000);

    KSharedConfig::Ptr globals = KSharedConfig::openConfig(QStringLiteral("kdeglobals"));
    globals->reparseConfiguration();
    s.animationFactor = std::max(0.0, KConfigGroup(globals, QStringLiteral("KDE")).readEntry("AnimationDurationFactor", 1.0));
    return s;
}

int Settings::animationDuration() const
{
    return int(std::lround(hoverDurationMs * animationFactor));
}

// ---------------------------------------------------------------- colours

bool isDarkColor(const QColor &c)
{
    // Relative luminance, good enough to pick night/day treatment.
    const qreal l = 0.2126 * c.redF() + 0.7152 * c.greenF() + 0.0722 * c.blueF();
    return l < 0.5;
}

static QColor withAlpha(QColor c, qreal a)
{
    c.setAlphaF(std::clamp(a, 0.0, 1.0));
    return c;
}

Palette makePalette(const QColor &titleBar, const QColor &foreground, const QColor &accent, bool active, const Settings &settings)
{
    Palette p;
    p.dark = isDarkColor(titleBar);
    p.active = active;

    qreal alpha = p.dark ? settings.titleOpacityDark : settings.titleOpacityLight;
    if (!active) {
        alpha *= settings.inactiveOpacityScale;
    }
    p.titleFill = withAlpha(titleBar, alpha);
    p.text = withAlpha(foreground, 1.0);

    const QColor white(255, 255, 255);
    const QColor black(0, 0, 0);
    if (p.dark) {
        p.glyph = withAlpha(foreground, active ? 0.72 : 0.62);
        p.glyphHover = withAlpha(foreground, 1.0);
        p.hoverFill = withAlpha(white, 0.10);
        p.pressFill = withAlpha(white, 0.16);
        p.closeHover = QColor(255, 59, 48);
        p.closePress = QColor(0xd9, 0x33, 0x2a);
        p.outline = withAlpha(white, active ? 0.14 : 0.09);
        p.topHighlight = withAlpha(white, active ? 0.12 : 0.07);
        p.hairline = withAlpha(black, active ? 0.34 : 0.24);
        p.checkedFill = withAlpha(accent, 0.30);
    } else {
        p.glyph = withAlpha(foreground, active ? 0.85 : 0.75);
        p.glyphHover = withAlpha(foreground, 1.0);
        p.hoverFill = withAlpha(black, 0.07);
        p.pressFill = withAlpha(black, 0.12);
        p.closeHover = QColor(224, 36, 46);
        p.closePress = QColor(0xb8, 0x1d, 0x26);
        p.outline = withAlpha(black, active ? 0.17 : 0.12);
        p.topHighlight = withAlpha(white, active ? 0.70 : 0.50);
        p.hairline = withAlpha(black, active ? 0.09 : 0.06);
        p.checkedFill = withAlpha(accent, 0.22);
    }
    p.closeGlyph = white;
    return p;
}

static QColor mix(const QColor &a, const QColor &b, qreal t)
{
    t = std::clamp(t, 0.0, 1.0);
    return QColor::fromRgbF(float(a.redF() + (b.redF() - a.redF()) * t),
                            float(a.greenF() + (b.greenF() - a.greenF()) * t),
                            float(a.blueF() + (b.blueF() - a.blueF()) * t),
                            float(a.alphaF() + (b.alphaF() - a.alphaF()) * t));
}

// ---------------------------------------------------------------- shapes

QPainterPath framePath(const QRectF &frame, CornerRadii radii)
{
    const qreal maxR = std::min(frame.width(), frame.height()) / 2.0;
    const qreal tl = std::clamp(radii.topLeft, 0.0, maxR);
    const qreal tr = std::clamp(radii.topRight, 0.0, maxR);

    QPainterPath path;
    path.moveTo(frame.left(), frame.bottom());
    path.lineTo(frame.left(), frame.top() + tl);
    if (tl > 0) {
        path.arcTo(QRectF(frame.left(), frame.top(), 2 * tl, 2 * tl), 180, -90);
    }
    path.lineTo(frame.right() - tr, frame.top());
    if (tr > 0) {
        path.arcTo(QRectF(frame.right() - 2 * tr, frame.top(), 2 * tr, 2 * tr), 90, -90);
    }
    path.lineTo(frame.right(), frame.bottom());
    path.closeSubpath();
    return path;
}

QRegion regionFromPath(const QPainterPath &path)
{
    QRegion region;
    for (const QPolygonF &poly : path.toFillPolygons()) {
        region |= QRegion(poly.toPolygon(), Qt::WindingFill);
    }
    return region;
}

// ---------------------------------------------------------------- frame

void paintFrame(QPainter *painter, const FrameGeometry &g, const Palette &pal, const Settings &settings)
{
    const qreal px = 1.0 / std::max(g.scale, 0.1);
    const QRectF frame = g.frame;
    const QRectF client = frame.marginsRemoved(g.borders);
    const QPainterPath shape = framePath(frame, g.radii);

    painter->save();
    painter->setRenderHint(QPainter::Antialiasing, true);
    painter->setPen(Qt::NoPen);

    // Title bar + borders: the frame shape minus the client area.
    QPainterPath deco = shape;
    if (client.width() > 0 && client.height() > 0) {
        QPainterPath hole;
        hole.addRect(client);
        deco = shape.subtracted(hole);
    }
    painter->fillPath(deco, pal.titleFill);

    painter->setClipPath(shape);

    // 1 px top highlight that follows the rounded corners and fades out
    // down the sides.
    if (settings.titleHighlight && pal.topHighlight.alpha() > 0) {
        const qreal inset = g.drawOutline ? px : 0;
        const QRectF hr = frame.adjusted(inset + px / 2, inset + px / 2, -(inset + px / 2), 0);
        const CornerRadii r{std::max(0.0, g.radii.topLeft - inset - px / 2), std::max(0.0, g.radii.topRight - inset - px / 2)};
        const qreal fade = std::max({r.topLeft, r.topRight, 2 * px}) + 2 * px;
        QLinearGradient grad(0, hr.top(), 0, hr.top() + fade);
        grad.setColorAt(0, pal.topHighlight);
        grad.setColorAt(0.55, pal.topHighlight);
        grad.setColorAt(1, Qt::transparent);
        QPen pen(QBrush(grad), px);
        pen.setCapStyle(Qt::FlatCap);
        painter->save();
        painter->setClipRect(QRectF(frame.left(), frame.top(), frame.width(), fade), Qt::IntersectClip);
        painter->setPen(pen);
        painter->setBrush(Qt::NoBrush);
        painter->drawPath(framePath(hr, r));
        painter->restore();
    }

    // 1 px hairline under the title bar.
    if (settings.titleHairline && client.height() > 0) {
        painter->fillRect(QRectF(frame.left(), g.borders.top() - px, frame.width(), px), pal.hairline);
    }

    // 1 px outline around the whole window.
    if (g.drawOutline) {
        painter->setClipping(false);
        const QRectF orect = frame.adjusted(px / 2, px / 2, -px / 2, -px / 2);
        const CornerRadii r{std::max(0.0, g.radii.topLeft - px / 2), std::max(0.0, g.radii.topRight - px / 2)};
        QPen pen(pal.outline, px);
        pen.setJoinStyle(Qt::MiterJoin);
        painter->setPen(pen);
        painter->setBrush(Qt::NoBrush);
        painter->drawPath(framePath(orect, r));
    }
    painter->restore();
}

// ---------------------------------------------------------------- glyphs

void paintGlyph(QPainter *painter, DecorationButtonType type, const QRectF &box, const QColor &color, bool checked)
{
    // Glyphs are drawn in the 34x34 design space of the Aurorae Dockyard SVGs
    // (already shifted by their translate(0,4)), centred in the box.
    const qreal k = box.height() / 34.0;
    painter->save();
    painter->setRenderHint(QPainter::Antialiasing, true);
    painter->translate(box.center().x() - 17.0 * k, box.top());
    painter->scale(k, k);
    QPen pen(color, 1.2);
    pen.setCapStyle(Qt::RoundCap);
    pen.setJoinStyle(Qt::RoundJoin);
    painter->setPen(pen);
    painter->setBrush(Qt::NoBrush);

    QPainterPath p;
    switch (type) {
    case DecorationButtonType::Close:
        p.moveTo(12, 12);
        p.lineTo(22, 22);
        p.moveTo(22, 12);
        p.lineTo(12, 22);
        break;
    case DecorationButtonType::Maximize:
        if (checked) { // restore
            p.addRect(QRectF(11, 14, 8, 8));
            p.moveTo(14, 14);
            p.lineTo(14, 11);
            p.lineTo(22, 11);
            p.lineTo(22, 19);
            p.lineTo(19, 19);
        } else {
            p.addRect(QRectF(12, 12, 10, 10));
        }
        break;
    case DecorationButtonType::Minimize:
        p.moveTo(12, 17);
        p.lineTo(22, 17);
        break;
    case DecorationButtonType::KeepAbove:
        p.moveTo(12, 19);
        p.lineTo(17, 14);
        p.lineTo(22, 19);
        break;
    case DecorationButtonType::KeepBelow:
        p.moveTo(12, 15);
        p.lineTo(17, 20);
        p.lineTo(22, 15);
        break;
    case DecorationButtonType::Shade:
        p.moveTo(12, 13);
        p.lineTo(22, 13);
        if (checked) { // unshade: arrow down
            p.moveTo(12, 18);
            p.lineTo(17, 22);
            p.lineTo(22, 18);
        } else {
            p.moveTo(12, 22);
            p.lineTo(17, 18);
            p.lineTo(22, 22);
        }
        break;
    case DecorationButtonType::OnAllDesktops:
        p.addRect(QRectF(12, 12, 10, 10));
        if (checked) {
            painter->save();
            painter->setPen(Qt::NoPen);
            painter->setBrush(color);
            painter->drawRect(QRectF(15, 15, 4, 4));
            painter->restore();
        } else {
            p.addRect(QRectF(15, 15, 4, 4));
        }
        break;
    case DecorationButtonType::ContextHelp:
        p.moveTo(14.5, 14.5);
        p.arcTo(QRectF(14.5, 12, 5, 5), 180, -233);
        p.cubicTo(21.5 - 4, 17.2, 17, 17.8, 17, 19);
        p.moveTo(17, 21.6);
        p.lineTo(17, 22.2);
        break;
    case DecorationButtonType::ApplicationMenu:
        p.moveTo(12, 13);
        p.lineTo(22, 13);
        p.moveTo(12, 17);
        p.lineTo(22, 17);
        p.moveTo(12, 21);
        p.lineTo(22, 21);
        break;
    case DecorationButtonType::ExcludeFromCapture:
        p.addRoundedRect(QRectF(11, 13, 12, 9), 1.5, 1.5);
        p.moveTo(10, 11);
        p.lineTo(24, 24);
        break;
    case DecorationButtonType::Menu:
    case DecorationButtonType::Spacer:
    case DecorationButtonType::Custom:
        break;
    }
    painter->drawPath(p);
    painter->restore();
}

void paintButton(QPainter *painter, DecorationButtonType type, const QRectF &box, const Palette &pal, const ButtonVisualState &st)
{
    painter->save();
    painter->setRenderHint(QPainter::Antialiasing, true);
    painter->setPen(Qt::NoPen);

    const qreal hover = st.enabled ? std::clamp(st.hover, 0.0, 1.0) : 0.0;
    const bool pressed = st.enabled && st.pressed;

    if (type == DecorationButtonType::Close) {
        if (pressed) {
            painter->fillRect(box, pal.closePress);
        } else if (hover > 0) {
            painter->fillRect(box, withAlpha(pal.closeHover, pal.closeHover.alphaF() * hover));
        }
        QColor glyph = mix(pal.glyph, pal.closeGlyph, pressed ? 1.0 : hover);
        if (!st.enabled) {
            glyph.setAlphaF(glyph.alphaF() * 0.35);
        }
        paintGlyph(painter, type, box, glyph, false);
        painter->restore();
        return;
    }

    const qreal k = box.height() / 34.0;
    const QRectF bg = box.adjusted(box.width() * 2.0 / 34.0, 5 * k, -box.width() * 2.0 / 34.0, -5 * k);
    const qreal r = 6 * k;
    if (st.checked && st.enabled && type != DecorationButtonType::Maximize) {
        painter->setBrush(pal.checkedFill);
        painter->drawRoundedRect(bg, r, r);
    }
    if (pressed) {
        painter->setBrush(pal.pressFill);
        painter->drawRoundedRect(bg, r, r);
    } else if (hover > 0) {
        painter->setBrush(withAlpha(pal.hoverFill, pal.hoverFill.alphaF() * hover));
        painter->drawRoundedRect(bg, r, r);
    }

    QColor glyph = mix(pal.glyph, pal.glyphHover, pressed ? 1.0 : std::max(hover, st.checked ? 1.0 : 0.0));
    if (!st.enabled) {
        glyph.setAlphaF(glyph.alphaF() * 0.35);
    }
    paintGlyph(painter, type, box, glyph, st.checked);
    painter->restore();
}

// ---------------------------------------------------------------- shadow

void blurAlpha(QImage &img, int radius)
{
    if (radius < 1 || img.isNull()) {
        return;
    }
    Q_ASSERT(img.format() == QImage::Format_Alpha8);
    const int w = img.width();
    const int h = img.height();
    std::vector<int> buf(std::max(w, h));

    auto pass = [&](uchar *data, int count, int stride) {
        // box blur of size 2r+1 with clamped (zero) edges
        int sum = 0;
        for (int i = 0; i < count; ++i) {
            buf[i] = data[i * stride];
        }
        for (int i = 0; i <= radius && i < count; ++i) {
            sum += buf[i];
        }
        const int div = 2 * radius + 1;
        for (int i = 0; i < count; ++i) {
            data[i * stride] = uchar(sum / div);
            const int add = i + radius + 1;
            const int sub = i - radius;
            if (add < count) {
                sum += buf[add];
            }
            if (sub >= 0) {
                sum -= buf[sub];
            }
        }
    };

    for (int p = 0; p < 3; ++p) {
        for (int y = 0; y < h; ++y) {
            pass(img.scanLine(y), w, 1);
        }
        for (int x = 0; x < w; ++x) {
            pass(img.bits() + x, h, int(img.bytesPerLine()));
        }
    }
}

ShadowTexture makeShadow(const Settings &settings, bool dark, bool active, qreal radius)
{
    ShadowTexture out;
    const int R = settings.shadowSize;
    if (R <= 0 || settings.shadowStrength <= 0) {
        return out;
    }
    const int offsetY = int(std::lround(R * 0.28));
    const int B = std::max(int(std::ceil(radius)) * 2 + 2, 16);
    const int W = R + B + R;
    const int H = 2 * R + B;
    const QRectF win(R, R - offsetY, B, B);
    const CornerRadii radii{radius, radius};

    qreal a1, a2;
    if (dark) {
        a1 = active ? 0.48 : 0.30;
        a2 = active ? 0.32 : 0.20;
    } else {
        a1 = active ? 0.24 : 0.14;
        a2 = active ? 0.16 : 0.10;
    }
    a1 = std::clamp(a1 * settings.shadowStrength, 0.0, 1.0);
    a2 = std::clamp(a2 * settings.shadowStrength, 0.0, 1.0);

    auto layer = [&](qreal alpha, qreal dy, qreal shrink, int blur) {
        QImage img(W, H, QImage::Format_Alpha8);
        img.fill(0);
        QPainter p(&img);
        p.setRenderHint(QPainter::Antialiasing, true);
        p.fillPath(framePath(win.translated(0, dy).adjusted(shrink, shrink, -shrink, 0), radii), QColor(0, 0, 0, int(alpha * 255)));
        p.end();
        blurAlpha(img, blur);
        return img;
    };
    const QImage ambient = layer(a1, offsetY, R * 0.08, std::max(1, R / 3));
    const QImage key = layer(a2, 1.0, 0, 2);

    QImage result(W, H, QImage::Format_ARGB32_Premultiplied);
    for (int y = 0; y < H; ++y) {
        const uchar *s1 = ambient.constScanLine(y);
        const uchar *s2 = key.constScanLine(y);
        QRgb *d = reinterpret_cast<QRgb *>(result.scanLine(y));
        for (int x = 0; x < W; ++x) {
            const int a = 255 - ((255 - s1[x]) * (255 - s2[x])) / 255;
            d[x] = qRgba(0, 0, 0, a);
        }
    }

    // Cut the window out so the shadow never shows through the translucent title bar.
    QPainter p(&result);
    p.setRenderHint(QPainter::Antialiasing, true);
    p.setCompositionMode(QPainter::CompositionMode_DestinationOut);
    p.fillPath(framePath(win, radii), Qt::black);
    p.end();

    out.image = result;
    out.padding = QMarginsF(R, R - offsetY, R, R + offsetY);
    out.innerRect = win;
    return out;
}

} // namespace DockyardGlass
