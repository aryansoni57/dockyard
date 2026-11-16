// SPDX-License-Identifier: LGPL-2.0-or-later
// Dockyard: compositor blur behind the greeter capsules (KWindowEffects, ext-background-effect on KWin 6.8).
#pragma once

#include <QHash>
#include <QList>
#include <QObject>
#include <QPointer>
#include <QQuickItem>
#include <QQuickWindow>
#include <QRegion>

class GlassBlur : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)

public:
    explicit GlassBlur(QObject *parent = nullptr);

    bool available() const;
    Q_INVOKABLE void addItem(QQuickItem *item);
    Q_INVOKABLE void removeItem(QQuickItem *item);

Q_SIGNALS:
    void availableChanged();

private:
    void checkAvailable();
    void hookWindow(QQuickWindow *window);
    void updateWindow(QQuickWindow *window);
    static qreal effectiveOpacity(const QQuickItem *item);
    static QRegion roundedRegion(const QRectF &rect, qreal radius);

    bool m_available = false;
    bool m_forced = false;
    QList<QPointer<QQuickItem>> m_items;
    QList<QPointer<QQuickWindow>> m_windows;
    QHash<QQuickWindow *, QRegion> m_applied; // last region sent, per window
};
