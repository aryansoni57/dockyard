// Offscreen harness for the Dockyard Glass decoration.
//
// It loads the built plugin the same way KWin does (KPluginMetaData::findPlugins
// in the "org.kde.kdecoration3" plugin folder, then KPluginFactory), drives it
// through a mock KDecoration3::DecorationBridge, checks borders / blur region /
// opacity / shadow / button actions, and renders preview PNGs over a fake
// wallpaper with the blur region simulated. KWin itself is never touched.
//
// Usage: QT_QPA_PLATFORM=offscreen glass-harness <plugin-root-dir> <output-dir>

#include "glassstyle.h"

#include <KDecoration3/DecoratedWindow>
#include <KDecoration3/Decoration>
#include <KDecoration3/DecorationButton>
#include <KDecoration3/DecorationButtonGroup>
#include <KDecoration3/DecorationSettings>
#include <KDecoration3/DecorationShadow>
#include <KDecoration3/Private/DecoratedWindowPrivate>
#include <KDecoration3/Private/DecorationBridge>
#include <KDecoration3/Private/DecorationSettingsPrivate>

#include <KPluginFactory>
#include <KPluginMetaData>

#include <QDir>
#include <QEventLoop>
#include <QGuiApplication>
#include <QHoverEvent>
#include <QJsonObject>
#include <QMouseEvent>
#include <QPainter>
#include <QPointingDevice>
#include <QRadialGradient>
#include <QRegularExpression>
#include <QTimer>

#include <cstdio>
#include <memory>

using namespace KDecoration3;

static int g_failures = 0;
#define CHECK(cond, msg)                                                                                                                                       \
    do {                                                                                                                                                       \
        if (cond) {                                                                                                                                            \
            std::printf("  ok    %s\n", qPrintable(QString(msg)));                                                                                            \
        } else {                                                                                                                                               \
            std::printf("  FAIL  %s\n", qPrintable(QString(msg)));                                                                                            \
            ++g_failures;                                                                                                                                      \
        }                                                                                                                                                      \
    } while (0)

struct Scheme {
    QString name;
    QColor titleActive, titleInactive, fgActive, fgInactive, highlight, client, clientInk;
};

static const Scheme kNight{QStringLiteral("night"),
                           QColor(33, 33, 40),
                           QColor(27, 27, 33),
                           QColor(236, 237, 242),
                           QColor(168, 169, 179),
                           QColor(0, 113, 227),
                           QColor(27, 27, 33),
                           QColor(236, 237, 242)};
static const Scheme kDay{QStringLiteral("day"),
                         QColor(230, 231, 237),
                         QColor(239, 240, 244),
                         QColor(28, 28, 30),
                         QColor(92, 94, 102),
                         QColor(0, 100, 214),
                         QColor(239, 240, 244),
                         QColor(28, 28, 30)};

// ------------------------------------------------------------------ mocks

class MockWindow : public DecoratedWindowPrivateV4
{
public:
    MockWindow(DecoratedWindow *w, Decoration *d)
        : DecoratedWindowPrivateV4(w, d)
    {
    }
    bool active = true;
    QString captionText = QStringLiteral("Dockyard Glass — a translucent title bar that KWin blurs");
    bool maximized = false;
    bool keepAbove = false;
    bool onAll = false;
    bool contextHelp = true;
    QSizeF clientSize{560, 200};
    qreal winScale = 1.0;
    Qt::Edges edges;
    Scheme scheme = kNight;
    QStringList calls;

    void emitActive(bool a)
    {
        active = a;
        Q_EMIT window()->activeChanged(a);
    }
    void emitMaximized(bool m)
    {
        maximized = m;
        Q_EMIT window()->maximizedHorizontallyChanged(m);
        Q_EMIT window()->maximizedVerticallyChanged(m);
        Q_EMIT window()->maximizedChanged(m);
    }
    void emitSize(const QSizeF &s)
    {
        clientSize = s;
        Q_EMIT window()->widthChanged(s.width());
        Q_EMIT window()->heightChanged(s.height());
        Q_EMIT window()->sizeChanged(s);
    }
    void emitKeepAbove(bool k)
    {
        keepAbove = k;
        Q_EMIT window()->keepAboveChanged(k);
    }
    void emitScheme(const Scheme &s)
    {
        scheme = s;
        Q_EMIT window()->paletteChanged(palette());
    }
    void emitScale(qreal s)
    {
        winScale = s;
        Q_EMIT window()->nextScaleChanged();
        Q_EMIT window()->scaleChanged();
    }

    bool isActive() const override { return active; }
    QString caption() const override { return captionText; }
    bool isOnAllDesktops() const override { return onAll; }
    bool isShaded() const override { return false; }
    QIcon icon() const override { return QIcon(); }
    bool isMaximized() const override { return maximized; }
    bool isMaximizedHorizontally() const override { return maximized; }
    bool isMaximizedVertically() const override { return maximized; }
    bool isKeepAbove() const override { return keepAbove; }
    bool isKeepBelow() const override { return false; }
    bool isCloseable() const override { return true; }
    bool isMaximizeable() const override { return true; }
    bool isMinimizeable() const override { return true; }
    bool providesContextHelp() const override { return contextHelp; }
    bool isModal() const override { return false; }
    bool isShadeable() const override { return true; }
    bool isMoveable() const override { return true; }
    bool isResizeable() const override { return true; }
    qreal width() const override { return clientSize.width(); }
    qreal height() const override { return clientSize.height(); }
    QSizeF size() const override { return clientSize; }
    QPalette palette() const override
    {
        QPalette p;
        p.setColor(QPalette::Highlight, scheme.highlight);
        p.setColor(QPalette::Window, scheme.client);
        p.setColor(QPalette::WindowText, scheme.clientInk);
        return p;
    }
    QColor color(ColorGroup group, ColorRole role) const override
    {
        const bool a = group != ColorGroup::Inactive;
        switch (role) {
        case ColorRole::TitleBar:
        case ColorRole::Frame:
            return a ? scheme.titleActive : scheme.titleInactive;
        case ColorRole::Foreground:
            return a ? scheme.fgActive : scheme.fgInactive;
        }
        return {};
    }
    Qt::Edges adjacentScreenEdges() const override { return edges; }
    qreal scale() const override { return winScale; }
    qreal nextScale() const override { return winScale; }
    void requestShowToolTip(const QString &text) override { calls << QStringLiteral("tooltip:") + text; }
    void requestHideToolTip() override {}
    void requestClose() override { calls << QStringLiteral("close"); }
    void requestToggleMaximization(Qt::MouseButtons) override { calls << QStringLiteral("maximize"); }
    void requestMinimize() override { calls << QStringLiteral("minimize"); }
    void requestContextHelp() override { calls << QStringLiteral("help"); }
    void requestToggleOnAllDesktops() override { calls << QStringLiteral("alldesktops"); }
    void requestToggleShade() override { calls << QStringLiteral("shade"); }
    void requestToggleKeepAbove() override { calls << QStringLiteral("keepabove"); }
    void requestToggleKeepBelow() override { calls << QStringLiteral("keepbelow"); }
    void requestShowWindowMenu(const QRect &) override { calls << QStringLiteral("windowmenu"); }
    QString windowClass() const override { return QStringLiteral("harness"); }
    bool hasApplicationMenu() const override { return false; }
    bool isApplicationMenuActive() const override { return false; }
    void showApplicationMenu(int) override {}
    void requestShowApplicationMenu(const QRect &, int) override {}
    QString applicationMenuServiceName() const override { return {}; }
    QString applicationMenuObjectPath() const override { return {}; }
    void popup(const Positioner &, QMenu *) override {}
    bool isExcludedFromCapture() const override { return false; }
    void requestToggleExcludeFromCapture() override {}
};

class MockSettings : public DecorationSettingsPrivateV2
{
public:
    explicit MockSettings(DecorationSettings *p, QList<DecorationButtonType> left, QList<DecorationButtonType> right)
        : DecorationSettingsPrivateV2(p)
        , m_left(std::move(left))
        , m_right(std::move(right))
    {
    }
    bool isOnAllDesktopsAvailable() const override { return true; }
    bool isAlphaChannelSupported() const override { return true; }
    bool isCloseOnDoubleClickOnMenu() const override { return false; }
    QList<DecorationButtonType> decorationButtonsLeft() const override { return m_left; }
    QList<DecorationButtonType> decorationButtonsRight() const override { return m_right; }
    BorderSize borderSize() const override { return BorderSize::None; }
    bool isAlwaysShowExcludeFromCapture() const override { return false; }
    QFont font() const override
    {
        QFont f(QStringLiteral("Inter"));
        f.setPixelSize(13);
        f.setWeight(QFont::Medium);
        return f;
    }

private:
    QList<DecorationButtonType> m_left, m_right;
};

class MockBridge : public DecorationBridge
{
public:
    QList<DecorationButtonType> left;
    QList<DecorationButtonType> right{DecorationButtonType::Minimize, DecorationButtonType::Maximize, DecorationButtonType::Close};
    MockWindow *lastWindow = nullptr;

    std::unique_ptr<DecoratedWindowPrivate> createClient(DecoratedWindow *client, Decoration *decoration) override
    {
        auto w = std::make_unique<MockWindow>(client, decoration);
        lastWindow = w.get();
        return w;
    }
    std::unique_ptr<DecorationSettingsPrivate> settings(DecorationSettings *parent) override
    {
        return std::make_unique<MockSettings>(parent, left, right);
    }
};

// ------------------------------------------------------------------ helpers

static void spin(int ms)
{
    QEventLoop loop;
    QTimer::singleShot(ms, &loop, &QEventLoop::quit);
    loop.exec();
}

static QImage makeWallpaper(QSize size)
{
    QImage img(size, QImage::Format_ARGB32_Premultiplied);
    QPainter p(&img);
    p.setRenderHint(QPainter::Antialiasing);
    QLinearGradient bg(0, 0, size.width(), size.height());
    bg.setColorAt(0, QColor(18, 52, 120));
    bg.setColorAt(0.5, QColor(120, 40, 140));
    bg.setColorAt(1, QColor(240, 140, 60));
    p.fillRect(img.rect(), bg);
    const QColor blobs[] = {QColor(255, 210, 60), QColor(40, 200, 170), QColor(255, 90, 120), QColor(90, 160, 255), QColor(250, 250, 250)};
    for (int i = 0; i < 14; ++i) {
        const qreal x = std::fmod(i * 173.0, size.width());
        const qreal y = std::fmod(i * 97.0 + 30, size.height());
        const qreal r = 30 + (i % 4) * 22;
        QRadialGradient g(x, y, r);
        QColor c = blobs[i % 5];
        g.setColorAt(0, c);
        c.setAlpha(0);
        g.setColorAt(1, c);
        p.setBrush(g);
        p.setPen(Qt::NoPen);
        p.drawEllipse(QPointF(x, y), r, r);
    }
    p.setPen(QPen(QColor(255, 255, 255, 140), 3));
    for (int x = -size.height(); x < size.width(); x += 46) {
        p.drawLine(x, size.height(), x + size.height(), 0);
    }
    return img;
}

static QImage fakeBlur(const QImage &src)
{
    // KWin's blur is a dual-Kawase blur; a smooth down/upscale is close enough
    // for a preview.
    const QImage small = src.scaled(std::max(1, src.width() / 14), std::max(1, src.height() / 14), Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    const QImage smaller = small.scaled(std::max(1, small.width() / 2), std::max(1, small.height() / 2), Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    return smaller.scaled(src.size(), Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
}

static void drawShadow(QPainter *p, const std::shared_ptr<DecorationShadow> &shadow, const QRectF &frame)
{
    if (!shadow || shadow->shadow().isNull()) {
        return;
    }
    const QImage img = shadow->shadow();
    const QRectF inner = shadow->innerShadowRect();
    const QMarginsF pad = shadow->padding();
    const QRectF outer = frame.marginsAdded(pad);
    // Nine-patch: source edges from innerShadowRect, destination from padding.
    const qreal sx[4] = {0, inner.left(), inner.right(), qreal(img.width())};
    const qreal sy[4] = {0, inner.top(), inner.bottom(), qreal(img.height())};
    const qreal dx[4] = {outer.left(), frame.left(), frame.right(), outer.right()};
    const qreal dy[4] = {outer.top(), frame.top(), frame.bottom(), outer.bottom()};
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            if (i == 1 && j == 1) {
                continue; // KWin does not draw the centre either
            }
            p->drawImage(QRectF(QPointF(dx[i], dy[j]), QPointF(dx[i + 1], dy[j + 1])), img, QRectF(QPointF(sx[i], sy[j]), QPointF(sx[i + 1], sy[j + 1])));
        }
    }
}

// Renders one decorated window over the wallpaper and returns the image.
static QImage renderWindow(Decoration *deco, MockWindow *w, const QImage &wallpaper, qreal scale, const QString &label)
{
    const qreal margin = 56;
    const QRectF frame(QPointF(margin, margin + 18), deco->size());
    const QSizeF canvas(frame.right() + margin, frame.bottom() + margin);

    QImage img((canvas * scale).toSize(), QImage::Format_ARGB32_Premultiplied);
    img.setDevicePixelRatio(scale);
    QPainter p(&img);
    p.setRenderHint(QPainter::Antialiasing);
    p.setRenderHint(QPainter::SmoothPixmapTransform);
    const QImage wall = wallpaper.scaled(img.size(), Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation).copy(QRect(QPoint(0, 0), img.size()));
    p.drawImage(QRectF(QPointF(0, 0), canvas), wall);

    drawShadow(&p, deco->shadow(), frame);

    // Simulated KWin blur behind the blur region (decoration coordinates).
    const QRegion blur = deco->blurRegion();
    if (!blur.isEmpty() && !deco->isOpaque()) {
        p.save();
        p.setClipRegion(blur.translated(frame.topLeft().toPoint()));
        p.drawImage(QRectF(QPointF(0, 0), canvas), fakeBlur(wall));
        p.restore();
    }

    // Client contents: an app surface with a few fake text lines.
    const QRectF client = QRectF(frame).marginsRemoved(deco->borders());
    p.fillRect(client, w->scheme.client);
    p.setPen(Qt::NoPen);
    QColor ink = w->scheme.clientInk;
    for (int i = 0; i < 6; ++i) {
        ink.setAlphaF(i == 0 ? 0.85 : 0.25);
        p.setBrush(ink);
        p.drawRoundedRect(QRectF(client.left() + 20, client.top() + 22 + i * 26, (i == 0 ? 180 : 320 - (i * 37) % 140), i == 0 ? 10 : 8), 3, 3);
    }

    p.save();
    p.translate(frame.topLeft());
    deco->paint(&p, deco->rect());
    p.restore();

    p.setPen(QColor(255, 255, 255, 230));
    QFont f;
    f.setPixelSize(12);
    p.setFont(f);
    p.drawText(QPointF(margin, 26), label);
    p.end();
    return img;
}

static QImage stack(const QList<QImage> &images)
{
    int w = 0, h = 0;
    for (const auto &i : images) {
        w = std::max(w, i.width());
        h += i.height();
    }
    QImage out(w, h, QImage::Format_ARGB32_Premultiplied);
    out.fill(Qt::black);
    QPainter p(&out);
    int y = 0;
    for (const auto &i : images) {
        QImage c = i;
        c.setDevicePixelRatio(1);
        p.drawImage(0, y, c);
        y += i.height();
    }
    return out;
}

static DecorationButton *findButton(Decoration *deco, DecorationButtonType type)
{
    for (auto *b : deco->findChildren<DecorationButton *>()) {
        if (b->type() == type && b->isVisible()) {
            return b;
        }
    }
    return nullptr;
}

static void hoverAt(Decoration *deco, QPointF pos)
{
    static QPointF last(-1, -1);
    QHoverEvent ev(QEvent::HoverMove, pos, pos, last);
    QCoreApplication::sendEvent(deco, &ev);
    last = pos;
}

static void mouse(Decoration *deco, QEvent::Type type, QPointF pos, Qt::MouseButton button = Qt::LeftButton)
{
    QMouseEvent ev(type, pos, pos, pos, button, type == QEvent::MouseButtonRelease ? Qt::NoButton : button, Qt::NoModifier);
    QCoreApplication::sendEvent(deco, &ev);
}

struct Instance {
    std::unique_ptr<MockBridge> bridge;
    std::shared_ptr<DecorationSettings> settings;
    Decoration *deco = nullptr;
    MockWindow *window = nullptr;
};

static Instance createInstance(KPluginFactory *factory, QList<DecorationButtonType> left, QList<DecorationButtonType> right, const Scheme &scheme, qreal scale)
{
    Instance in;
    in.bridge = std::make_unique<MockBridge>();
    in.bridge->left = std::move(left);
    in.bridge->right = std::move(right);
    in.settings = std::make_shared<DecorationSettings>(in.bridge.get());
    const QVariantMap args{{QStringLiteral("bridge"), QVariant::fromValue(static_cast<DecorationBridge *>(in.bridge.get()))}};
    in.deco = factory->create<Decoration>(nullptr, QVariantList{args});
    if (!in.deco) {
        return in;
    }
    in.deco->setSettings(in.settings);
    // KWin applies the decoration's next state once the window geometry has
    // been updated; here it is applied straight away.
    QObject::connect(in.deco, &Decoration::nextStateChanged, in.deco, [deco = in.deco](std::shared_ptr<DecorationState> state) {
        deco->apply(state);
    });
    in.deco->create();
    in.window = in.bridge->lastWindow;
    in.window->scheme = scheme;
    in.window->winScale = scale;
    in.deco->init();
    return in;
}

int main(int argc, char **argv)
{
    if (argc < 3) {
        std::fprintf(stderr, "usage: %s <plugin-root> <output-dir>\n", argv[0]);
        return 2;
    }
    qputenv("QT_PLUGIN_PATH", argv[1]);
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM")) {
        qputenv("QT_QPA_PLATFORM", "offscreen");
    }
    QGuiApplication app(argc, argv);
    const QString outDir = QString::fromLocal8Bit(argv[2]);
    QDir().mkpath(outDir);

    std::printf("plugin discovery (same call KWin uses)\n");
    const QList<KPluginMetaData> plugins = KPluginMetaData::findPlugins(QStringLiteral("org.kde.kdecoration3"));
    KPluginMetaData md;
    for (const auto &m : plugins) {
        std::printf("  found %s  (%s)\n", qPrintable(m.pluginId()), qPrintable(m.fileName()));
        if (m.pluginId() == QLatin1String("org.dockyard.glass")) {
            md = m;
        }
    }
    CHECK(md.isValid(), QStringLiteral("org.dockyard.glass is discoverable in org.kde.kdecoration3"));
    if (!md.isValid()) {
        return 1;
    }
    const QJsonObject deco3 = md.rawData().value(QStringLiteral("org.kde.kdecoration3")).toObject();
    CHECK(deco3.value(QStringLiteral("blur")).toBool(), QStringLiteral("metadata org.kde.kdecoration3.blur == true"));
    CHECK(md.name() == QLatin1String("Dockyard Glass"), QStringLiteral("metadata name: ") + md.name());

    auto factoryResult = KPluginFactory::loadFactory(md);
    CHECK(factoryResult.plugin != nullptr, QStringLiteral("KPluginFactory loads: ") + factoryResult.errorText);
    if (!factoryResult.plugin) {
        return 1;
    }
    KPluginFactory *factory = factoryResult.plugin;
    const QImage wallpaper = makeWallpaper(QSize(1400, 900));

    const QList<DecorationButtonType> stdRight{DecorationButtonType::Minimize, DecorationButtonType::Maximize, DecorationButtonType::Close};
    const QList<DecorationButtonType> fullLeft{DecorationButtonType::Menu, DecorationButtonType::OnAllDesktops};
    const QList<DecorationButtonType> fullRight{DecorationButtonType::ContextHelp,
                                                DecorationButtonType::KeepAbove,
                                                DecorationButtonType::Spacer,
                                                DecorationButtonType::Minimize,
                                                DecorationButtonType::Maximize,
                                                DecorationButtonType::Close};

    for (const Scheme &scheme : {kNight, kDay}) {
        std::printf("\n[%s] geometry / blur / shadow\n", qPrintable(scheme.name));
        Instance in = createInstance(factory, {}, stdRight, scheme, 1.0);
        CHECK(in.deco != nullptr, QStringLiteral("decoration created"));
        if (!in.deco) {
            return 1;
        }
        Decoration *deco = in.deco;
        MockWindow *w = in.window;

        const QMarginsF b = deco->borders();
        std::printf("  borders l%.2f t%.2f r%.2f b%.2f  size %.0fx%.0f\n", b.left(), b.top(), b.right(), b.bottom(), deco->size().width(), deco->size().height());
        CHECK(b.top() == 34 && b.left() == 1 && b.right() == 1 && b.bottom() == 1, QStringLiteral("borders 1/34/1/1 at scale 1"));
        CHECK(deco->titleBar() == QRectF(0, 0, deco->size().width(), 34), QStringLiteral("titleBar covers the title strip"));
        CHECK(!deco->isOpaque(), QStringLiteral("decoration is not opaque"));
        const QRegion blur = deco->blurRegion();
        std::printf("  blur region bounds %d,%d %dx%d, %d rects\n", blur.boundingRect().x(), blur.boundingRect().y(), blur.boundingRect().width(), blur.boundingRect().height(), int(blur.rectCount()));
        CHECK(!blur.isEmpty(), QStringLiteral("blur region set"));
        CHECK(blur.contains(QPoint(int(deco->size().width() / 2), 17)), QStringLiteral("blur covers the title bar centre"));
        CHECK(!blur.contains(QPoint(1, 1)), QStringLiteral("blur excludes the rounded top-left corner"));
        CHECK(!blur.contains(QPoint(100, 100)), QStringLiteral("blur excludes the client area"));
        CHECK(blur.contains(QPoint(0, 120)) && blur.contains(QPoint(100, int(deco->size().height()) - 1)), QStringLiteral("blur includes side and bottom borders"));
        CHECK(deco->borderRadius().topLeft() == 10 && deco->borderRadius().bottomLeft() == 0, QStringLiteral("border radius 10 top, 0 bottom"));
        auto sh = deco->shadow();
        CHECK(sh && !sh->shadow().isNull(), QStringLiteral("shadow set (padding %1/%2/%3/%4)").arg(sh ? sh->padding().left() : -1).arg(sh ? sh->padding().top() : -1).arg(sh ? sh->padding().right() : -1).arg(sh ? sh->padding().bottom() : -1));

        auto *close = findButton(deco, DecorationButtonType::Close);
        auto *maxb = findButton(deco, DecorationButtonType::Maximize);
        auto *minb = findButton(deco, DecorationButtonType::Minimize);
        CHECK(close && maxb && minb, QStringLiteral("close, maximize and minimize buttons exist"));
        if (!close || !maxb || !minb) {
            return 1;
        }
        CHECK(qFuzzyCompare(close->geometry().right(), deco->size().width()) && close->geometry().top() == 0 && close->geometry().height() == 34,
              QStringLiteral("close is flush top-right and full height (%1)").arg(QString::number(close->geometry().right())));

        QList<QImage> frames;
        frames << renderWindow(deco, w, wallpaper, 1.0, scheme.name + QStringLiteral(" · active"));

        // Hover the close button through real hover events (animation runs).
        hoverAt(deco, close->geometry().center());
        spin(260);
        frames << renderWindow(deco, w, wallpaper, 1.0, scheme.name + QStringLiteral(" · close hovered"));
        spin(1100);
        bool tip = false;
        for (const auto &c : std::as_const(w->calls)) {
            tip |= c.startsWith(QStringLiteral("tooltip:"));
        }
        CHECK(tip, QStringLiteral("tooltip requested on hover: ") + w->calls.join(QLatin1Char(',')));

        hoverAt(deco, maxb->geometry().center());
        spin(260);
        frames << renderWindow(deco, w, wallpaper, 1.0, scheme.name + QStringLiteral(" · maximize hovered"));

        // Click: minimize and maximize must reach the window.
        w->calls.clear();
        hoverAt(deco, minb->geometry().center());
        mouse(deco, QEvent::MouseButtonPress, minb->geometry().center());
        frames << renderWindow(deco, w, wallpaper, 1.0, scheme.name + QStringLiteral(" · minimize pressed"));
        mouse(deco, QEvent::MouseButtonRelease, minb->geometry().center());
        hoverAt(deco, maxb->geometry().center());
        mouse(deco, QEvent::MouseButtonPress, maxb->geometry().center());
        mouse(deco, QEvent::MouseButtonRelease, maxb->geometry().center());
        hoverAt(deco, close->geometry().center());
        mouse(deco, QEvent::MouseButtonPress, close->geometry().center());
        mouse(deco, QEvent::MouseButtonRelease, close->geometry().center());
        spin(50); // KDecoration3 delivers button actions queued
        CHECK(w->calls.contains(QStringLiteral("minimize")) && w->calls.contains(QStringLiteral("maximize")) && w->calls.contains(QStringLiteral("close")),
              QStringLiteral("button clicks reach the window: ") + w->calls.filter(QRegularExpression(QStringLiteral("^[a-z]+$"))).join(QLatin1Char(',')));

        hoverAt(deco, QPointF(200, 17)); // title bar, no button
        spin(260);
        CHECK(deco->sectionUnderMouse() == Qt::TitleBarArea, QStringLiteral("title bar area reported to KWin (drag, double-click, menu)"));

        w->emitActive(false);
        frames << renderWindow(deco, w, wallpaper, 1.0, scheme.name + QStringLiteral(" · inactive"));
        w->emitActive(true);

        // Maximize: borders go away, corners square, blur follows.
        w->emitMaximized(true);
        const QMarginsF mb = deco->borders();
        CHECK(mb.left() == 0 && mb.right() == 0 && mb.bottom() == 0 && mb.top() == 34, QStringLiteral("maximized: no side/bottom borders"));
        CHECK(deco->borderRadius().topLeft() == 0, QStringLiteral("maximized: square corners"));
        CHECK(deco->blurRegion().contains(QPoint(0, 0)), QStringLiteral("maximized: blur reaches the corner"));
        CHECK(qFuzzyCompare(close->geometry().right(), deco->size().width()), QStringLiteral("maximized: close still flush right"));
        frames << renderWindow(deco, w, wallpaper, 1.0, scheme.name + QStringLiteral(" · maximized (restore glyph)"));
        w->emitMaximized(false);

        // Resize: blur and buttons follow.
        w->emitSize(QSizeF(420, 160));
        CHECK(deco->blurRegion().boundingRect().width() == 422, QStringLiteral("resize: blur region follows width (%1)").arg(deco->blurRegion().boundingRect().width()));
        CHECK(qFuzzyCompare(close->geometry().right(), deco->size().width()), QStringLiteral("resize: close still flush right"));
        w->emitSize(QSizeF(560, 200));

        // Quick tile left: top-left square, blur follows.
        w->edges = Qt::LeftEdge;
        Q_EMIT deco->window()->adjacentScreenEdgesChanged(w->edges);
        CHECK(deco->borderRadius().topLeft() == 0 && deco->borderRadius().topRight() == 10, QStringLiteral("tiled left: top-left corner square"));
        w->edges = {};
        Q_EMIT deco->window()->adjacentScreenEdgesChanged(w->edges);

        // HiDPI 1.5: borders snap to device pixels.
        w->emitScale(1.5);
        const QMarginsF hb = deco->borders();
        CHECK(qFuzzyCompare(hb.left() * 1.5, 1.0) && qFuzzyCompare(hb.top() * 1.5, 51.0), QStringLiteral("scale 1.5: border = 1 device px, title = 51 device px"));
        QImage hidpi = renderWindow(deco, w, wallpaper, 1.5, scheme.name + QStringLiteral(" · scale 1.5"));
        hidpi.save(outDir + QStringLiteral("/glass-%1-hidpi.png").arg(scheme.name));
        w->emitScale(1.0);

        stack(frames).save(outDir + QStringLiteral("/glass-%1.png").arg(scheme.name));
        delete in.deco;

        // All optional buttons: menu, on all desktops, help, keep above (checked), spacer.
        Instance full = createInstance(factory, fullLeft, fullRight, scheme, 1.0);
        full.window->onAll = true;
        full.window->emitKeepAbove(true);
        Q_EMIT full.deco->window()->onAllDesktopsChanged(true);
        CHECK(findButton(full.deco, DecorationButtonType::KeepAbove) && findButton(full.deco, DecorationButtonType::ContextHelp)
                  && findButton(full.deco, DecorationButtonType::OnAllDesktops) && findButton(full.deco, DecorationButtonType::Menu),
              QStringLiteral("optional buttons created"));
        auto *help = findButton(full.deco, DecorationButtonType::ContextHelp);
        hoverAt(full.deco, help->geometry().center());
        spin(260);
        renderWindow(full.deco, full.window, wallpaper, 1.0, scheme.name + QStringLiteral(" · all buttons, keep above + all desktops on, help hovered"))
            .save(outDir + QStringLiteral("/glass-%1-buttons.png").arg(scheme.name));
        delete full.deco;
    }

    std::printf("\n%s (%d failures)\n", g_failures ? "FAILED" : "ALL CHECKS PASSED", g_failures);
    return g_failures ? 1 : 0;
}
