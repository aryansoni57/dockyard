#include "decoration.h"
#include "button.h"

#include <KDecoration3/DecoratedWindow>
#include <KDecoration3/DecorationSettings>
#include <KDecoration3/ScaleHelpers>

#include <QFontMetricsF>
#include <QPainter>

#include <cmath>

namespace DockyardGlass
{

using KDecoration3::BorderSize;
using KDecoration3::DecorationButtonType;

Decoration::Decoration(QObject *parent, const QVariantList &args)
    : KDecoration3::Decoration(parent, args)
{
}

Decoration::~Decoration() = default;

bool Decoration::init()
{
    m_settings = Settings::load();

    auto *w = window();
    connect(w, &KDecoration3::DecoratedWindow::activeChanged, this, [this] {
        updateShadow();
        update();
    });
    connect(w, &KDecoration3::DecoratedWindow::captionChanged, this, [this] {
        update(titleTextRect());
    });
    connect(w, &KDecoration3::DecoratedWindow::paletteChanged, this, [this] {
        updateBlur(); // opacity depends on dark/light
        updateShadow();
        update();
    });
    connect(w, &KDecoration3::DecoratedWindow::maximizedChanged, this, &Decoration::updateLayout);
    connect(w, &KDecoration3::DecoratedWindow::maximizedHorizontallyChanged, this, &Decoration::updateLayout);
    connect(w, &KDecoration3::DecoratedWindow::maximizedVerticallyChanged, this, &Decoration::updateLayout);
    connect(w, &KDecoration3::DecoratedWindow::adjacentScreenEdgesChanged, this, &Decoration::updateLayout);
    connect(w, &KDecoration3::DecoratedWindow::shadedChanged, this, &Decoration::updateLayout);
    connect(w, &KDecoration3::DecoratedWindow::sizeChanged, this, &Decoration::updateLayout);
    connect(w, &KDecoration3::DecoratedWindow::nextScaleChanged, this, &Decoration::updateLayout);
    connect(w, &KDecoration3::DecoratedWindow::scaleChanged, this, [this] {
        update();
    });

    connect(this, &KDecoration3::Decoration::currentStateChanged, this, &Decoration::updateGeometryDerived);

    auto s = settings();
    connect(s.get(), &KDecoration3::DecorationSettings::borderSizeChanged, this, &Decoration::updateLayout);
    connect(s.get(), &KDecoration3::DecorationSettings::fontChanged, this, [this] {
        update();
    });
    connect(s.get(), &KDecoration3::DecorationSettings::reconfigured, this, &Decoration::reconfigure);
    connect(s.get(), &KDecoration3::DecorationSettings::decorationButtonsLeftChanged, this, [this] {
        createButtons();
        updateLayout();
    });
    connect(s.get(), &KDecoration3::DecorationSettings::decorationButtonsRightChanged, this, [this] {
        createButtons();
        updateLayout();
    });

    createButtons();
    updateLayout();
    updateShadow();
    return true;
}

void Decoration::reconfigure()
{
    m_settings = Settings::load();
    for (auto *group : {m_leftButtons.data(), m_rightButtons.data()}) {
        if (!group) {
            continue;
        }
        for (auto *b : group->buttons()) {
            if (auto *button = qobject_cast<Button *>(b)) {
                button->reconfigure();
            }
        }
    }
    m_shadowKey.clear();
    updateLayout();
    updateShadow();
    update();
}

void Decoration::createButtons()
{
    delete m_leftButtons;
    delete m_rightButtons;
    m_leftButtons = new KDecoration3::DecorationButtonGroup(KDecoration3::DecorationButtonGroup::Position::Left, this, &Button::create);
    m_rightButtons = new KDecoration3::DecorationButtonGroup(KDecoration3::DecorationButtonGroup::Position::Right, this, &Button::create);
    for (auto *group : {m_leftButtons.data(), m_rightButtons.data()}) {
        group->setSpacing(0);
        // A button became (in)visible, e.g. ContextHelp or ApplicationMenu.
        connect(group, &KDecoration3::DecorationButtonGroup::geometryChanged, this, [this] {
            if (!m_inButtonLayout) {
                updateButtonsGeometry();
                update();
            }
        });
    }
}

// ---------------------------------------------------------------- geometry

qreal Decoration::effectiveScale() const
{
    const qreal s = window()->nextScale();
    return s > 0.01 ? s : 1.0;
}

qreal Decoration::snap(qreal value) const
{
    return KDecoration3::snapToPixelGrid(value, effectiveScale());
}

qreal Decoration::borderWidth() const
{
    const qreal px = KDecoration3::pixelSize(effectiveScale());
    switch (settings()->borderSize()) {
    case BorderSize::None:
    case BorderSize::NoSides:
        return px; // a single device pixel
    case BorderSize::Tiny:
        return std::max(px, snap(2));
    case BorderSize::Normal:
        return snap(3);
    case BorderSize::Large:
        return snap(4);
    case BorderSize::VeryLarge:
        return snap(6);
    case BorderSize::Huge:
        return snap(8);
    case BorderSize::VeryHuge:
        return snap(11);
    case BorderSize::Oversized:
        return snap(16);
    }
    return px;
}

bool Decoration::isFullyMaximized() const
{
    const auto *w = window();
    return w->isMaximized() || (w->isMaximizedHorizontally() && w->isMaximizedVertically());
}

CornerRadii Decoration::cornerRadii() const
{
    const auto *w = window();
    if (m_settings.cornerRadius <= 0 || w->isMaximizedHorizontally() || w->isMaximizedVertically() || w->isMaximized()) {
        return {0, 0};
    }
    const Qt::Edges edges = w->adjacentScreenEdges();
    const qreal r = snap(m_settings.cornerRadius);
    CornerRadii radii{r, r};
    if (edges & Qt::TopEdge) {
        radii = {0, 0};
    }
    if (edges & Qt::LeftEdge) {
        radii.topLeft = 0;
    }
    if (edges & Qt::RightEdge) {
        radii.topRight = 0;
    }
    return radii;
}

void Decoration::updateLayout()
{
    const auto *w = window();
    const qreal border = borderWidth();
    const qreal side = w->isMaximizedHorizontally() || isFullyMaximized() ? 0 : border;
    const qreal bottom = w->isMaximizedVertically() || isFullyMaximized() ? 0 : border;
    const qreal title = snap(m_settings.titleHeight);

    setBorders(QMarginsF(side, title, side, bottom));

    // Thin borders are hard to grab: add invisible resize margins outside.
    const qreal ext = snap(4);
    setResizeOnlyBorders(QMarginsF(side > 0 && side < ext ? ext : 0, 0, side > 0 && side < ext ? ext : 0, bottom > 0 && bottom < ext ? ext : 0));

    const CornerRadii radii = cornerRadii();
    setBorderRadius(KDecoration3::BorderRadius(radii.topLeft, radii.topRight, 0, 0));

    // Borders and radius above go into the decoration's *next* state; KWin
    // applies it when the window is resized to match. Everything derived from
    // the geometry is refreshed in updateGeometryDerived(), which also runs on
    // currentStateChanged.
    updateGeometryDerived();
}

void Decoration::updateGeometryDerived()
{
    const auto state = currentState();
    const KDecoration3::BorderRadius r = state ? state->borderRadius() : KDecoration3::BorderRadius();
    m_radii = CornerRadii{r.topLeft(), r.topRight()};
    m_frameShape = framePath(rect(), m_radii);
    setTitleBar(QRectF(0, 0, size().width(), borderTop()));

    updateButtonsGeometry();
    updateBlur();
    updateShadow();
    update();
}

void Decoration::updateButtonsGeometry()
{
    if (!m_leftButtons || !m_rightButtons) {
        return;
    }
    m_inButtonLayout = true;
    const qreal height = snap(m_settings.titleHeight);
    const qreal width = snap(m_settings.buttonWidth);
    for (auto *group : {m_leftButtons.data(), m_rightButtons.data()}) {
        for (auto *button : group->buttons()) {
            const qreal bw = button->type() == DecorationButtonType::Spacer ? snap(8) : width;
            button->setGeometry(QRectF(QPointF(0, 0), QSizeF(bw, height)));
        }
    }
    m_leftButtons->setPos(QPointF(borderLeft() + snap(4), 0));
    // Flush with the right edge: the close button runs into the corner.
    m_rightButtons->setPos(QPointF(size().width() - m_rightButtons->geometry().width(), 0));
    m_inButtonLayout = false;
}

QRectF Decoration::titleTextRect() const
{
    const qreal title = borderTop();
    qreal left = borderLeft() + snap(14);
    if (m_leftButtons && m_leftButtons->geometry().width() > 0) {
        left = m_leftButtons->geometry().right() + snap(8);
    }
    qreal right = size().width() - borderRight() - snap(8);
    if (m_rightButtons && m_rightButtons->geometry().width() > 0) {
        right = m_rightButtons->geometry().left() - snap(8);
    }
    return QRectF(left, 0, std::max<qreal>(0, right - left), title);
}

void Decoration::updateBlur()
{
    const Palette pal = currentPalette();
    const bool opaque = pal.titleFill.alpha() >= 255;
    setOpaque(opaque);
    if (opaque) {
        setBlurRegion(QRegion());
        return;
    }

    QRegion region = regionFromPath(m_frameShape);
    if (!m_settings.blurBorders) {
        region &= QRegion(0, 0, int(std::ceil(size().width())), int(std::ceil(borderTop())));
    }
    // Remove the client area, rounded inwards so border pixels are kept.
    const QRectF client = rect().marginsRemoved(borders());
    if (client.width() > 0 && client.height() > 0) {
        const QRect inner(QPoint(int(std::ceil(client.left())), int(std::ceil(client.top()))),
                          QPoint(int(std::floor(client.right())) - 1, int(std::floor(client.bottom())) - 1));
        if (inner.isValid()) {
            region -= inner;
        }
    }
    if (region != blurRegion()) {
        setBlurRegion(region);
    }
}

void Decoration::updateShadow()
{
    const bool active = window()->isActive();
    const bool dark = isDarkColor(window()->color(active ? KDecoration3::ColorGroup::Active : KDecoration3::ColorGroup::Inactive, KDecoration3::ColorRole::TitleBar));
    const qreal radius = std::min(m_radii.topLeft, m_radii.topRight);
    const QString key = QStringLiteral("%1-%2-%3").arg(active).arg(dark).arg(radius);
    if (key == m_shadowKey && m_shadow) {
        return;
    }
    m_shadowKey = key;

    const ShadowTexture tex = makeShadow(m_settings, dark, active, radius);
    if (tex.image.isNull()) {
        m_shadow.reset();
        setShadow(nullptr);
        return;
    }
    auto shadow = std::make_shared<KDecoration3::DecorationShadow>();
    shadow->setPadding(tex.padding);
    shadow->setInnerShadowRect(tex.innerRect);
    shadow->setShadow(tex.image);
    m_shadow = shadow;
    setShadow(shadow);
}

// ---------------------------------------------------------------- painting

Palette Decoration::currentPalette() const
{
    const auto *w = window();
    const bool active = w->isActive();
    const auto group = active ? KDecoration3::ColorGroup::Active : KDecoration3::ColorGroup::Inactive;
    const QColor accent = w->palette().color(QPalette::Active, QPalette::Highlight);
    return makePalette(w->color(group, KDecoration3::ColorRole::TitleBar), w->color(group, KDecoration3::ColorRole::Foreground), accent, active, m_settings);
}

void Decoration::paint(QPainter *painter, const QRectF &repaintArea)
{
    const auto *w = window();
    const Palette pal = currentPalette();

    FrameGeometry g;
    g.frame = rect();
    g.borders = borders();
    g.radii = m_radii;
    g.drawOutline = !isFullyMaximized();
    g.scale = w->scale() > 0.01 ? w->scale() : 1.0;
    paintFrame(painter, g, pal, m_settings);

    // Title: left aligned, vertically centred, elided.
    const QRectF textRect = titleTextRect();
    if (textRect.width() > 0 && textRect.intersects(repaintArea)) {
        painter->save();
        const QFont font = settings()->font();
        painter->setFont(font);
        painter->setPen(pal.text);
        const QString text = QFontMetricsF(font).elidedText(w->caption(), Qt::ElideRight, textRect.width());
        painter->drawText(textRect, Qt::AlignVCenter | Qt::AlignLeft | Qt::TextSingleLine, text);
        painter->restore();
    }

    if (m_leftButtons) {
        m_leftButtons->paint(painter, repaintArea);
    }
    if (m_rightButtons) {
        m_rightButtons->paint(painter, repaintArea);
    }
}

} // namespace DockyardGlass
