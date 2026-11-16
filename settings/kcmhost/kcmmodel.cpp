#include "kcmmodel.h"
#include <KConfig>
#include <KPluginFactory>
#include <KCModuleData>
#include <KConfigGroup>
#include <KColorScheme>
#include <QMouseEvent>
#include <KWindowEffects>
#include <KSharedConfig>
#include <QGuiApplication>
#include <QColor>
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QSet>
#include <QIcon>
#include <QCoreApplication>
#include <algorithm>

namespace {
// The app runs inside the qml6 runtime, so without this its window's app id is the runtime's and
// the dock / task switcher show the generic Qt icon. This runs when the plugin library is loaded
// (the QML import), before the window exists, so the Wayland app id matches our desktop entry.
void brandApp()
{
    QGuiApplication::setDesktopFileName(QStringLiteral("dev.aryan.dockyard.settings"));
    const QIcon icon = QIcon::fromTheme(QStringLiteral("dev.aryan.dockyard.settings"));
    if (!icon.isNull())
        QGuiApplication::setWindowIcon(icon);
}
}
Q_COREAPP_STARTUP_FUNCTION(brandApp)

namespace {
struct Cat { QString id, parent, name, icon; int weight = 0; };

QHash<QString, Cat> readCategories()
{
    QHash<QString, Cat> out;
    const QDir dir(QStringLiteral("/usr/share/systemsettings/categories"));
    for (const QString &f : dir.entryList({QStringLiteral("*.desktop")}, QDir::Files)) {
        KConfig c(dir.filePath(f), KConfig::SimpleConfig);
        KConfigGroup g = c.group(QStringLiteral("Desktop Entry"));
        Cat cat;
        cat.id = g.readEntry("X-KDE-System-Settings-Category");
        cat.parent = g.readEntry("X-KDE-System-Settings-Parent-Category");
        cat.name = g.readEntry("Name");
        cat.icon = g.readEntry("Icon");
        cat.weight = g.readEntry("X-KDE-Weight", 0);
        if (!cat.id.isEmpty())
            out.insert(cat.id, cat);
    }
    return out;
}

QList<KcmModel::Entry> build()
{
    const auto cats = readCategories();
    struct Src { const char *dir; bool widget; bool info; };
    const Src srcs[] = {
        {"plasma/kcms/systemsettings", false, false},
        {"plasma/kcms/systemsettings_qwidgets", true, false},
        {"plasma/kcms/kinfocenter", false, true},
        {"plasma/kcms/desktop", false, false},
        {"plasma/kcms", false, false},   // About this System (kcm_about-distro) lives here
    };
    QList<KcmModel::Entry> list;
    QSet<QString> seen;
    for (const Src &s : srcs) {
        for (const KPluginMetaData &md : KPluginMetaData::findPlugins(QString::fromLatin1(s.dir))) {
            const QString id = md.pluginId();
            if (seen.contains(id) || md.name().isEmpty())
                continue;
            if (id == QLatin1String("kcm_landingpage") || id == QLatin1String("kcm_breezedecoration"))
                continue;
            const QStringList ff = md.formFactors();
            if (!ff.isEmpty() && !ff.contains(QLatin1String("desktop")))
                continue;
            // System Settings only lists a module that names its category (the rest are helpers),
            // and honours the platform it is limited to.
            if (!s.info && md.value(QStringLiteral("X-KDE-System-Settings-Parent-Category")).isEmpty())
                continue;
            // Modules for hardware that is not there (touchpad, tablet, touchscreen, game controller...)
            // report themselves not relevant through their module data, as System Settings reads it.
            if (md.value(QStringLiteral("X-KDE-System-Settings-Uses-ModuleData"), false)) {
                auto data = KPluginFactory::instantiatePlugin<KCModuleData>(md, nullptr);
                const bool relevant = !data.plugin || data.plugin->isRelevant();
                delete data.plugin;
                if (!relevant)
                    continue;
            }
            const QStringList only = md.value(QStringLiteral("X-KDE-OnlyShowOnQtPlatforms"), QStringList());
            if (!only.isEmpty() && !only.contains(QGuiApplication::platformName(), Qt::CaseInsensitive))
                continue;
            KcmModel::Entry e;
            e.md = md; e.id = id; e.name = md.name(); e.comment = md.description(); e.icon = md.iconName();
            e.keywords = md.value(QStringLiteral("X-KDE-Keywords")).split(QLatin1Char(','), Qt::SkipEmptyParts);
            e.widget = s.widget;
            e.weight = md.rawData().value(QStringLiteral("KPlugin")).toObject().value(QStringLiteral("X-KDE-Weight")).toInt(
                md.value(QStringLiteral("X-KDE-Weight"), QStringLiteral("100")).toInt());
            QString parent = md.value(QStringLiteral("X-KDE-System-Settings-Parent-Category"));
            QString top = parent;
            for (int i = 0; i < 4 && cats.contains(top) && !cats[top].parent.isEmpty(); ++i)
                top = cats[top].parent;
            // The direct parent, when it is a sub-category, becomes a section on the category page.
            if (cats.contains(parent) && parent != top) {
                e.sub = parent; e.subName = cats[parent].name; e.subWeight = cats[parent].weight;
            }
            if (s.info) {
                e.group = QStringLiteral("info"); e.groupName = QStringLiteral("System information"); e.groupWeight = 200;
            } else if (cats.contains(top) && top != QLatin1String("rootcategory")) {
                e.group = top; e.groupName = cats[top].name; e.groupWeight = cats[top].weight;
            } else {
                e.group = QStringLiteral("other"); e.groupName = QStringLiteral("Other"); e.groupWeight = 150;
            }
            seen.insert(id);
            list.append(e);
        }
    }
    std::sort(list.begin(), list.end(), [](const KcmModel::Entry &a, const KcmModel::Entry &b) {
        if (a.groupWeight != b.groupWeight) return a.groupWeight < b.groupWeight;
        if (a.group != b.group) return a.group < b.group;
        if (a.sub.isEmpty() != b.sub.isEmpty()) return a.sub.isEmpty();
        if (a.subWeight != b.subWeight) return a.subWeight < b.subWeight;
        if (a.sub != b.sub) return a.sub < b.sub;
        if (a.weight != b.weight) return a.weight < b.weight;
        return a.name.localeAwareCompare(b.name) < 0;
    });
    return list;
}
}

const QList<KcmModel::Entry> &KcmModel::all()
{
    static const QList<Entry> l = build();
    return l;
}

const KcmModel::Entry *KcmModel::find(const QString &id)
{
    for (const Entry &e : all())
        if (e.id == id)
            return &e;
    return nullptr;
}

static QString schemePath()
{
    return QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + QStringLiteral("/dockyard-settings.colors");
}

KcmModel::KcmModel(QObject *parent) : QAbstractListModel(parent)
{
    const auto cats = readCategories();
    QStringList order;
    QHash<QString, int> counts;
    QHash<QString, QString> names;
    for (const Entry &e : all()) {
        if (!counts.contains(e.group)) { order.append(e.group); names.insert(e.group, e.groupName); }
        counts[e.group] += 1;
    }
    for (const QString &g : order) {
        const QString icon = cats.contains(g) ? cats[g].icon : QStringLiteral("applications-system");
        m_groups.append(QVariantMap{{QStringLiteral("id"), g}, {QStringLiteral("name"), names.value(g)}, {QStringLiteral("icon"), icon},
                                    {QStringLiteral("count"), counts.value(g)}});
    }
}

int KcmModel::rowCount(const QModelIndex &p) const { return p.isValid() ? 0 : all().size(); }

QVariant KcmModel::data(const QModelIndex &i, int role) const
{
    if (!i.isValid() || i.row() >= all().size()) return {};
    const Entry &e = all().at(i.row());
    switch (role) {
    case IdRole: return e.id;
    case NameRole: return e.name;
    case CommentRole: return e.comment;
    case IconRole: return e.icon;
    case GroupRole: return e.group;
    case GroupNameRole: return e.groupName;
    case KeywordsRole: return e.keywords;
    case WidgetRole: return e.widget;
    case WeightRole: return e.weight;
    }
    return {};
}

QHash<int, QByteArray> KcmModel::roleNames() const
{
    return {{IdRole, "kcmId"}, {NameRole, "name"}, {CommentRole, "comment"}, {IconRole, "icon"}, {GroupRole, "group"},
            {GroupNameRole, "groupName"}, {KeywordsRole, "keywords"}, {WidgetRole, "widget"}, {WeightRole, "weight"}};
}

int KcmModel::indexOfId(const QString &id) const
{
    for (int i = 0; i < all().size(); ++i)
        if (all().at(i).id == id) return i;
    return -1;
}

static QVariantMap toMap(const KcmModel::Entry &e)
{
    return {{QStringLiteral("kcmId"), e.id}, {QStringLiteral("name"), e.name}, {QStringLiteral("comment"), e.comment}, {QStringLiteral("icon"), e.icon},
            {QStringLiteral("group"), e.group}, {QStringLiteral("groupName"), e.groupName}, {QStringLiteral("widget"), e.widget},
            {QStringLiteral("sub"), e.sub}, {QStringLiteral("subName"), e.subName}};
}

QVariantList KcmModel::search(const QString &text) const
{
    // Ranked: name starts with the query, then a word in the name does, then name, keywords, description or id contain it.
    const QString q = text.trimmed();
    if (q.isEmpty()) return {};
    QList<QPair<int, const Entry *>> hits;
    for (const Entry &e : all()) {
        int score = -1;
        if (e.name.startsWith(q, Qt::CaseInsensitive)) score = 0;
        else if (e.name.contains(QLatin1Char(' ') + q, Qt::CaseInsensitive)) score = 1;
        else if (e.name.contains(q, Qt::CaseInsensitive)) score = 2;
        else if (std::any_of(e.keywords.begin(), e.keywords.end(), [&](const QString &k) { return k.trimmed().startsWith(q, Qt::CaseInsensitive); })) score = 3;
        else if (std::any_of(e.keywords.begin(), e.keywords.end(), [&](const QString &k) { return k.contains(q, Qt::CaseInsensitive); })) score = 4;
        else if (e.comment.contains(q, Qt::CaseInsensitive) || e.id.contains(q, Qt::CaseInsensitive)) score = 5;
        if (score >= 0) hits.append({score, &e});
    }
    std::stable_sort(hits.begin(), hits.end(), [](const auto &a, const auto &b) { return a.first < b.first; });
    QVariantList out;
    for (const auto &h : hits) out.append(toMap(*h.second));
    return out;
}

QVariantList KcmModel::inGroup(const QString &group) const
{
    QVariantList out;
    for (const Entry &e : all())
        if (e.group == group) out.append(toMap(e));
    return out;
}

QVariantMap KcmModel::info(const QString &id) const
{
    const Entry *e = find(id);
    return e ? toMap(*e) : QVariantMap{};
}

void KcmModel::applyScheme(const QVariantMap &t)
{
    auto col = [&](const char *k) { return t.value(QString::fromLatin1(k)).value<QColor>(); };
    const QString path = schemePath();
    QDir().mkpath(QFileInfo(path).absolutePath());
    {
        KConfig cfg(path, KConfig::SimpleConfig);
        auto set = [&](const QString &grp, const QColor &bg, const QColor &alt, const QColor &fg, const QColor &dim) {
            KConfigGroup g = cfg.group(QStringLiteral("Colors:") + grp);
            g.writeEntry("BackgroundNormal", bg); g.writeEntry("BackgroundAlternate", alt);
            g.writeEntry("ForegroundNormal", fg); g.writeEntry("ForegroundInactive", dim);
            g.writeEntry("ForegroundActive", col("accentInk")); g.writeEntry("ForegroundLink", col("accentInk"));
            g.writeEntry("ForegroundVisited", dim); g.writeEntry("ForegroundNegative", col("bad"));
            g.writeEntry("ForegroundNeutral", col("neutral")); g.writeEntry("ForegroundPositive", col("ok"));
            g.writeEntry("DecorationFocus", col("accent")); g.writeEntry("DecorationHover", col("accent"));
        };
        const QColor paper = col("paper"), alt = col("paperAlt"), ink = col("ink"), dim = col("ink2"), btn = col("field");
        set(QStringLiteral("View"), paper, alt, ink, dim);
        set(QStringLiteral("Window"), paper, alt, ink, dim);
        set(QStringLiteral("Button"), btn, alt, ink, dim);
        set(QStringLiteral("Tooltip"), paper, alt, ink, dim);
        set(QStringLiteral("Complementary"), paper, alt, ink, dim);
        set(QStringLiteral("Header"), paper, alt, ink, dim);
        set(QStringLiteral("Selection"), col("accent"), col("accent"), QColor(Qt::white), QColor(255, 255, 255, 200));
        KConfigGroup wm = cfg.group(QStringLiteral("WM"));
        wm.writeEntry("activeBackground", paper); wm.writeEntry("activeForeground", ink);
        wm.writeEntry("inactiveBackground", paper); wm.writeEntry("inactiveForeground", dim);
        // Breeze's colour effects, so disabled controls dim gently and inactive windows do not fade.
        KConfigGroup dis = cfg.group(QStringLiteral("ColorEffects:Disabled"));
        dis.writeEntry("Color", QColor(56, 56, 56)); dis.writeEntry("ColorAmount", 0); dis.writeEntry("ColorEffect", 0);
        dis.writeEntry("ContrastAmount", 0.65); dis.writeEntry("ContrastEffect", 1);
        dis.writeEntry("IntensityAmount", 0.1); dis.writeEntry("IntensityEffect", 2);
        KConfigGroup ina = cfg.group(QStringLiteral("ColorEffects:Inactive"));
        ina.writeEntry("Enable", false); ina.writeEntry("ChangeSelectionColor", false);
        KConfigGroup gen = cfg.group(QStringLiteral("General"));
        gen.writeEntry("ColorScheme", QStringLiteral("DockyardSettings"));
        cfg.sync();
    }
    qApp->setProperty("KDE_COLOR_SCHEME_PATH", path);
    // The shared config is cached per path; reparse so a new mode or accent is picked up.
    KSharedConfigPtr shared = KSharedConfig::openConfig(path);
    shared->reparseConfiguration();
    qApp->setPalette(KColorScheme::createApplicationPalette(shared));
}

void KcmModel::setBlur(QWindow *window, bool on)
{
    if (window)
        KWindowEffects::enableBlurBehind(window, on);
}

void KcmModel::watchBackButton()
{
    qApp->installEventFilter(this);
}

bool KcmModel::eventFilter(QObject *obj, QEvent *ev)
{
    if (ev->type() == QEvent::MouseButtonPress) {
        auto *me = static_cast<QMouseEvent *>(ev);
        if (me->button() == Qt::BackButton) {
            Q_EMIT backRequested();
            return true;
        }
    }
    return QObject::eventFilter(obj, ev);
}
