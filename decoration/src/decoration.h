#pragma once

#include "glassstyle.h"

#include <KDecoration3/Decoration>
#include <KDecoration3/DecorationButtonGroup>
#include <KDecoration3/DecorationShadow>

#include <QPainterPath>
#include <QPointer>
#include <QVariant>

namespace DockyardGlass
{

class Decoration : public KDecoration3::Decoration
{
    Q_OBJECT
public:
    explicit Decoration(QObject *parent = nullptr, const QVariantList &args = QVariantList());
    ~Decoration() override;

    bool init() override;
    void paint(QPainter *painter, const QRectF &repaintArea) override;

    const Settings &glassSettings() const
    {
        return m_settings;
    }
    Palette currentPalette() const;
    QPainterPath frameShape() const
    {
        return m_frameShape;
    }
    QRectF titleTextRect() const;

    KDecoration3::DecorationButtonGroup *leftButtons() const
    {
        return m_leftButtons;
    }
    KDecoration3::DecorationButtonGroup *rightButtons() const
    {
        return m_rightButtons;
    }

public Q_SLOTS:
    void reconfigure();

private:
    void createButtons();
    void updateLayout();
    void updateGeometryDerived();
    void updateButtonsGeometry();
    void updateBlur();
    void updateShadow();

    qreal effectiveScale() const;
    qreal snap(qreal value) const;
    qreal borderWidth() const;
    CornerRadii cornerRadii() const;
    bool isFullyMaximized() const;

    Settings m_settings;
    QPointer<KDecoration3::DecorationButtonGroup> m_leftButtons;
    QPointer<KDecoration3::DecorationButtonGroup> m_rightButtons;
    QPainterPath m_frameShape;
    CornerRadii m_radii;
    std::shared_ptr<KDecoration3::DecorationShadow> m_shadow;
    QString m_shadowKey;
    bool m_inButtonLayout = false;
};

} // namespace DockyardGlass
