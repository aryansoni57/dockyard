#include "button.h"
#include "decoration.h"
#include "glassstyle.h"

#include <KDecoration3/DecoratedWindow>

#include <QEasingCurve>
#include <QPainter>
#include <QVariantAnimation>

namespace DockyardGlass
{

using KDecoration3::DecorationButtonType;

Button::Button(DecorationButtonType type, Decoration *decoration, QObject *parent)
    : KDecoration3::DecorationButton(type, decoration, parent)
    , m_animation(new QVariantAnimation(this))
{
    m_animation->setStartValue(0.0);
    m_animation->setEndValue(1.0);
    m_animation->setEasingCurve(QEasingCurve::OutCubic);
    connect(m_animation, &QVariantAnimation::valueChanged, this, [this](const QVariant &v) {
        m_hover = v.toReal();
        update();
    });
    connect(this, &KDecoration3::DecorationButton::hoveredChanged, this, &Button::startHoverAnimation);
    connect(this, &KDecoration3::DecorationButton::pressedChanged, this, [this] {
        update();
    });
    connect(this, &KDecoration3::DecorationButton::checkedChanged, this, [this] {
        update();
    });
    connect(this, &KDecoration3::DecorationButton::enabledChanged, this, [this] {
        update();
    });

    if (type == DecorationButtonType::Maximize) {
        // left: toggle, middle: vertical, right: horizontal maximization
        setAcceptedButtons(Qt::LeftButton | Qt::MiddleButton | Qt::RightButton);
    }
    if (type == DecorationButtonType::Spacer) {
        setEnabled(false);
    }
    // Repaint the window icon when it changes.
    if (type == DecorationButtonType::Menu) {
        connect(decoration->window(), &KDecoration3::DecoratedWindow::iconChanged, this, [this] {
            update();
        });
    }
    reconfigure();
}

Button::~Button() = default;

KDecoration3::DecorationButton *Button::create(DecorationButtonType type, KDecoration3::Decoration *decoration, QObject *parent)
{
    auto *d = qobject_cast<Decoration *>(decoration);
    if (!d) {
        return nullptr;
    }
    switch (type) {
    case DecorationButtonType::Close:
    case DecorationButtonType::Maximize:
    case DecorationButtonType::Minimize:
    case DecorationButtonType::OnAllDesktops:
    case DecorationButtonType::KeepAbove:
    case DecorationButtonType::KeepBelow:
    case DecorationButtonType::ContextHelp:
    case DecorationButtonType::Shade:
    case DecorationButtonType::Menu:
    case DecorationButtonType::ApplicationMenu:
    case DecorationButtonType::ExcludeFromCapture:
    case DecorationButtonType::Spacer:
        return new Button(type, d, parent);
    case DecorationButtonType::Custom:
        break;
    }
    return nullptr;
}

void Button::reconfigure()
{
    auto *d = qobject_cast<Decoration *>(decoration());
    const int duration = d ? d->glassSettings().animationDuration() : 120;
    m_animation->setDuration(std::max(duration, 0));
}

void Button::setHoverProgress(qreal value)
{
    m_animation->stop();
    m_hover = value;
    update();
}

void Button::startHoverAnimation(bool hovered)
{
    m_animation->stop();
    if (m_animation->duration() <= 0) {
        m_hover = hovered ? 1.0 : 0.0;
        update();
        return;
    }
    m_animation->setStartValue(m_hover);
    m_animation->setEndValue(hovered ? 1.0 : 0.0);
    m_animation->start();
}

void Button::paint(QPainter *painter, const QRectF &repaintArea)
{
    Q_UNUSED(repaintArea)
    auto *d = qobject_cast<Decoration *>(decoration());
    if (!d || !isVisible() || type() == DecorationButtonType::Spacer) {
        return;
    }
    const QRectF box = geometry();
    const Palette pal = d->currentPalette();

    if (type() == DecorationButtonType::Menu) {
        const QIcon icon = d->window()->icon();
        const qreal s = std::min(16.0 * box.height() / 34.0, box.height() - 4);
        const QRectF iconRect(box.center().x() - s / 2, box.center().y() - s / 2, s, s);
        painter->save();
        if (isHovered() || isPressed()) {
            painter->setRenderHint(QPainter::Antialiasing, true);
            painter->setPen(Qt::NoPen);
            painter->setBrush(isPressed() ? pal.pressFill : pal.hoverFill);
            const qreal k = box.height() / 34.0;
            painter->drawRoundedRect(box.adjusted(2 * k, 5 * k, -2 * k, -5 * k), 6 * k, 6 * k);
        }
        icon.paint(painter, iconRect.toRect(), Qt::AlignCenter, d->window()->isActive() ? QIcon::Normal : QIcon::Disabled);
        painter->restore();
        return;
    }

    ButtonVisualState st;
    st.hover = m_hover;
    st.pressed = isPressed();
    st.checked = isChecked();
    st.enabled = isEnabled();

    painter->save();
    if (type() == DecorationButtonType::Close) {
        // The red fill runs flush into the rounded corner: clip to the frame.
        painter->setClipPath(d->frameShape(), Qt::IntersectClip);
    }
    paintButton(painter, type(), box, pal, st);
    painter->restore();
}

} // namespace DockyardGlass
