#pragma once
#include <QAbstractListModel>
#include <QQmlEngine>
#include <KPluginMetaData>
#include <QWindow>

// Every System Settings and Info Center module found in the plugin folders.
class KcmModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QVariantList groups READ groups CONSTANT)
public:
    enum Role { IdRole = Qt::UserRole + 1, NameRole, CommentRole, IconRole, GroupRole, GroupNameRole, KeywordsRole, WidgetRole, WeightRole };
    struct Entry {
        KPluginMetaData md;
        QString id, name, comment, icon, group, groupName, sub, subName;
        QStringList keywords;
        bool widget = false;
        int weight = 0, groupWeight = 0, subWeight = 0;
    };
    explicit KcmModel(QObject *parent = nullptr);
    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;
    QVariantList groups() const { return m_groups; }
    Q_INVOKABLE int indexOfId(const QString &id) const;
    Q_INVOKABLE QVariantList search(const QString &text) const;
    // Writes a KDE colour scheme from our theme tokens and applies it, so embedded modules match.
    Q_INVOKABLE void applyScheme(const QVariantMap &tokens);
    // Asks KWin to blur whatever is behind the window (needs a translucent window).
    Q_INVOKABLE void setBlur(QWindow *window, bool on);
    // Emits backRequested() when the mouse back button is pressed anywhere in the app, including
    // inside embedded module windows.
    Q_INVOKABLE void watchBackButton();
    Q_INVOKABLE QVariantMap info(const QString &id) const;
    // Modules of one top-level category, in display order, each with its sub-category (subName).
    Q_INVOKABLE QVariantList inGroup(const QString &group) const;
    static const KcmModel::Entry *find(const QString &id);
    static const QList<Entry> &all();
Q_SIGNALS:
    void backRequested();
protected:
    bool eventFilter(QObject *obj, QEvent *ev) override;
private:
    QVariantList m_groups;
};
