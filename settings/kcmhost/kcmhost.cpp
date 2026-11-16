#include "kcmhost.h"
#include "kcmmodel.h"
#include <KAbstractConfigModule>
#include <KQuickConfigModule>
#include <KQuickConfigModuleLoader>
#include <KCModuleLoader>
#include <KCModule>
#include <QTimer>
#include <QVBoxLayout>
#include <QWidget>

static KAbstractConfigModule *am(QObject *o) { return qobject_cast<KAbstractConfigModule *>(o); }

KcmHost::KcmHost(QQuickItem *parent) : QQuickItem(parent) {}

KcmHost::~KcmHost() { unloadModule(); }

void KcmHost::componentComplete()
{
    QQuickItem::componentComplete();
    m_complete = true;
    if (!m_id.isEmpty())
        reload();
}

void KcmHost::setModuleId(const QString &id)
{
    if (id == m_id) return;
    m_id = id;
    Q_EMIT moduleIdChanged();
    if (m_complete)
        QTimer::singleShot(0, this, &KcmHost::reload);
}

void KcmHost::setArgs(const QVariantList &a)
{
    if (a == m_args) return;
    m_args = a;
    Q_EMIT argsChanged();
}

void KcmHost::popPage()
{
    if (auto *q = qobject_cast<KQuickConfigModule *>(m_module.data()))
        q->pop();
}

void KcmHost::activate(const QVariantList &args)
{
    if (auto *m = am(m_module))
        Q_EMIT m->activationRequested(args);
}

void KcmHost::unloadModule()
{
    if (m_content) { m_content->setParentItem(nullptr); }
    if (m_module) { delete m_module.data(); }
    m_module = nullptr;
    m_content = nullptr;
    m_window = nullptr;
    if (m_widget) { delete m_widget; m_widget = nullptr; }
}

void KcmHost::reload()
{
    unloadModule();
    m_error.clear();
    m_status = 0;
    const KcmModel::Entry *e = KcmModel::find(m_id);
    if (!e) {
        m_error = QStringLiteral("Module not found: %1").arg(m_id);
        m_status = 2;
        Q_EMIT statusChanged();
        return;
    }
    QQmlEngine *eng = qmlEngine(this);
    std::shared_ptr<QQmlEngine> shared(eng, [](QQmlEngine *) {});
    if (!e->widget) {
        auto res = KQuickConfigModuleLoader::loadModule(e->md, this, m_args, shared);
        if (!res.plugin) {
            m_error = res.errorString;
            m_status = 2;
        } else {
            KQuickConfigModule *m = res.plugin;
            m_module = m;
            m_content = m->mainUi();
            if (!m_content) {
                m_error = m->errorString().isEmpty() ? QStringLiteral("The module has no page") : m->errorString();
                m_status = 2;
            } else {
                m_status = 1;
                m->load();
                connect(m, &KQuickConfigModule::pagePushed, this, &KcmHost::pagePushed);
                connect(m, &KQuickConfigModule::pageRemoved, this, &KcmHost::pageRemoved);
            }
        }
    } else {
        auto *holder = new QWidget;
        holder->setAttribute(Qt::WA_NativeWindow);
        holder->setWindowFlag(Qt::FramelessWindowHint);
        auto *lay = new QVBoxLayout(holder);
        lay->setContentsMargins(0, 0, 0, 0);
        KCModule *w = KCModuleLoader::loadModule(e->md, holder, m_args, shared);
        if (!w) {
            delete holder;
            m_error = QStringLiteral("Could not load %1").arg(m_id);
            m_status = 2;
        } else {
            lay->addWidget(w->widget());
            m_widget = holder;
            m_module = w;
            holder->winId();
            m_window = holder->windowHandle();
            m_status = m_window ? 1 : 2;
            w->load();
            if (!m_window) m_error = QStringLiteral("No native window for this module");
        }
    }
    if (auto *m = am(m_module))
        connect(m, &KAbstractConfigModule::buttonsChanged, this, &KcmHost::buttonsChanged);
    Q_EMIT statusChanged();
    Q_EMIT buttonsChanged();
}

int KcmHost::buttons() const { auto *m = am(m_module); return m ? int(m->buttons()) : 0; }
void KcmHost::save() { if (auto *m = am(m_module)) m->save(); }
void KcmHost::load() { if (auto *m = am(m_module)) m->load(); }
void KcmHost::defaults() { if (auto *m = am(m_module)) m->defaults(); }
void KcmHost::setDefaultsIndicators(bool on) { if (auto *m = am(m_module)) m->setDefaultsIndicatorsVisible(on); }
