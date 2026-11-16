#pragma once

#include <KDecoration3/DecorationButton>

class QVariantAnimation;

namespace DockyardGlass
{
class Decoration;

class Button : public KDecoration3::DecorationButton
{
    Q_OBJECT
public:
    Button(KDecoration3::DecorationButtonType type, Decoration *decoration, QObject *parent);
    ~Button() override;

    // Factory used by KDecoration3::DecorationButtonGroup.
    static KDecoration3::DecorationButton *create(KDecoration3::DecorationButtonType type, KDecoration3::Decoration *decoration, QObject *parent);

    void paint(QPainter *painter, const QRectF &repaintArea) override;

    qreal hoverProgress() const
    {
        return m_hover;
    }
    // For the preview harness: force a hover state without animation.
    void setHoverProgress(qreal value);

    void reconfigure();

private:
    void startHoverAnimation(bool hovered);

    QVariantAnimation *m_animation = nullptr;
    qreal m_hover = 0.0;
};

} // namespace DockyardGlass
