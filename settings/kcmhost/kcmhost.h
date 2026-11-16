#pragma once
#include <QQuickItem>
#include <QQmlEngine>
#include <QPointer>
#include <QWindow>

class QWidget;

// Loads one System Settings module and shows it inside our window.
class KcmHost : public QQuickItem
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString moduleId READ moduleId WRITE setModuleId NOTIFY moduleIdChanged)
    Q_PROPERTY(int status READ status NOTIFY statusChanged)          // 0 none, 1 ready, 2 error
    Q_PROPERTY(QString errorString READ errorString NOTIFY statusChanged)
    Q_PROPERTY(QObject *module READ module NOTIFY statusChanged)
    Q_PROPERTY(QQuickItem *content READ content NOTIFY statusChanged)
    Q_PROPERTY(QWindow *nativeWindow READ nativeWindow NOTIFY statusChanged)
    Q_PROPERTY(int buttons READ buttons NOTIFY buttonsChanged)   // Help 1, Default 2, Apply 4
    Q_PROPERTY(bool isWidget READ isWidget NOTIFY statusChanged)
    // Arguments handed to the module when it loads (System Settings: `kcm_x --args "a b"`).
    Q_PROPERTY(QVariantList args READ args WRITE setArgs NOTIFY argsChanged)
public:
    explicit KcmHost(QQuickItem *parent = nullptr);
    ~KcmHost() override;
    QString moduleId() const { return m_id; }
    void setModuleId(const QString &id);
    int status() const { return m_status; }
    QString errorString() const { return m_error; }
    QObject *module() const { return m_module; }
    QQuickItem *content() const { return m_content; }
    QWindow *nativeWindow() const { return m_window; }
    int buttons() const;
    bool isWidget() const { return m_widget != nullptr; }
    QVariantList args() const { return m_args; }
    void setArgs(const QVariantList &a);
    Q_INVOKABLE void save();
    Q_INVOKABLE void load();
    Q_INVOKABLE void defaults();
    Q_INVOKABLE void setDefaultsIndicators(bool on);
    // Pops the module's own top sub-page (its pageRemoved signal then pops our page row).
    Q_INVOKABLE void popPage();
    // Hands new arguments to a module that is already open (its activationRequested signal).
    Q_INVOKABLE void activate(const QVariantList &args);
Q_SIGNALS:
    void moduleIdChanged();
    void argsChanged();
    void statusChanged();
    void buttonsChanged();
    void pagePushed(QQuickItem *page);
    void pageRemoved();
protected:
    void componentComplete() override;
private:
    void reload();
    void unloadModule();
    QString m_id;
    QVariantList m_args;
    int m_status = 0;
    QString m_error;
    QPointer<QObject> m_module;
    QQuickItem *m_content = nullptr;
    QWidget *m_widget = nullptr;
    QWindow *m_window = nullptr;
    bool m_complete = false;
};
