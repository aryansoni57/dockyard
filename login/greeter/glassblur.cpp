// SPDX-License-Identifier: LGPL-2.0-or-later
#include "glassblur.h"

#include <KWindowEffects>
#include <QTimer>

// Below this effective opacity a capsule gets no blur: KWin cannot fade blur per region.
static constexpr qreal s_minOpacity = 0.35;

GlassBlur::GlassBlur(QObject *parent)
    : QObject(parent)
{
    const QByteArray env = qgetenv("AVDANOS_GREETER_BLUR");
    if (env == "0" || env == "1") {
        m_forced = true;
        m_available = env == "1";
        return;
    }
    checkAvailable();
    // The compositor may announce the blur capability after we start; look again.
    QTimer::singleShot(1000, this, &GlassBlur::checkAvailable);
    QTimer::singleShot(3000, this, &GlassBlur::checkAvailable);
}

bool GlassBlur::available() const
{
    return m_available;
}

void GlassBlur::checkAvailable()
{
    if (m_forced) {
        return;
    }
    const bool now = KWindowEffects::isEffectAvailable(KWindowEffects::BlurBehind);
    if (now == m_available) {
        return;
    }
    m_available = now;
    m_applied.clear(); // force a resend on the next frame
    Q_EMIT availableChanged();
    for (const auto &w : std::as_const(m_windows)) {
        if (w) {
            w->update();
        }
    }
}

void GlassBlur::addItem(QQuickItem *item)
{
    if (!item || m_items.contains(item)) {
        return;
    }
    m_items.append(item);
    connect(item, &QQuickItem::windowChanged, this, [this](QQuickWindow *w) {
        hookWindow(w);
    });
    connect(item, &QObject::destroyed, this, [this] {
        m_items.removeIf([](const QPointer<QQuickItem> &p) { return p.isNull(); });
    });
    hookWindow(item->window());
}

void GlassBlur::removeItem(QQuickItem *item)
{
    m_items.removeAll(item);
    if (item && item->window()) {
        item->window()->update();
    }
}

void GlassBlur::hookWindow(QQuickWindow *window)
{
    if (!window || m_windows.contains(window)) {
        return;
    }
    m_windows.append(window);
    connect(window, &QQuickWindow::afterAnimating, this, [this, window] {
        updateWindow(window);
    });
    connect(window, &QObject::destroyed, this, [this, window] {
        m_applied.remove(window);
        m_windows.removeIf([](const QPointer<QQuickWindow> &p) { return p.isNull(); });
    });
    window->update();
}

qreal GlassBlur::effectiveOpacity(const QQuickItem *item)
{
    qreal o = 1.0;
    for (const QQuickItem *i = item; i; i = i->parentItem()) {
        o *= i->opacity();
    }
    return o;
}

QRegion GlassBlur::roundedRegion(const QRectF &rectF, qreal radius)
{
    // 1 px inside the capsule edge, so the frost never pokes out past the border.
    const QRect r = rectF.adjusted(1, 1, -1, -1).toAlignedRect();
    if (r.isEmpty()) {
        return {};
    }
    const int rad = qBound(0, qRound(radius) - 1, qMin(r.width(), r.height()) / 2);
    if (rad == 0) {
        return QRegion(r);
    }
    const int d = 2 * rad;
    QRegion region(r.adjusted(rad, 0, -rad, 0));
    region += r.adjusted(0, rad, 0, -rad);
    region += QRegion(QRect(r.left(), r.top(), d, d), QRegion::Ellipse);
    region += QRegion(QRect(r.right() - d + 1, r.top(), d, d), QRegion::Ellipse);
    region += QRegion(QRect(r.left(), r.bottom() - d + 1, d, d), QRegion::Ellipse);
    region += QRegion(QRect(r.right() - d + 1, r.bottom() - d + 1, d, d), QRegion::Ellipse);
    return region;
}

void GlassBlur::updateWindow(QQuickWindow *window)
{
    QRegion region;
    if (m_available) {
        for (const auto &item : std::as_const(m_items)) {
            if (!item || item->window() != window || !item->isVisible()) {
                continue;
            }
            const QVariant opt = item->property("glassBlur");
            if (opt.isValid() && !opt.toBool()) {
                continue;
            }
            if (item->width() <= 0 || item->height() <= 0 || effectiveOpacity(item) < s_minOpacity) {
                continue;
            }
            const QRectF scene = item->mapRectToScene(QRectF(0, 0, item->width(), item->height()));
            const qreal scale = scene.height() / item->height();
            region += roundedRegion(scene, item->property("radius").toReal() * scale);
        }
    }

    const auto it = m_applied.constFind(window);
    if (it != m_applied.constEnd() && *it == region) {
        return;
    }
    m_applied.insert(window, region);
    if (region.isEmpty()) {
        KWindowEffects::enableBlurBehind(window, false); // an empty region would mean "whole window"
    } else {
        KWindowEffects::enableBlurBehind(window, true, region);
    }
}
