/* ============================================================
 *
 * This file is a part of digiKam project
 * https://www.digikam.org
 *
 * Date        : 2004-08-02
 * Description : theme manager
 *
 * SPDX-FileCopyrightText: 2006-2011 Gilles Caulier <caulier dot gilles at gmail dot com>
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * ============================================================ */

#include "thememanager.h"
// Qt includes

#include <QStringList>
#include <QFileInfo>
#include <QFile>
#include <QApplication>
#include <QPalette>
#include <QColor>
#include <QActionGroup>
#include <QBitmap>
#include <QPainter>
#include <QPixmap>
#include <QDate>
#include <QScreen>
#include <QMenu>
#include <QMenuBar>
#include <QStatusBar>
#include <QDebug>
#include <QAction>
#include <QMessageBox>

// KDE includes

#include <klocalizedstring.h>
#include <kcolorscheme.h>
#include <kactioncollection.h>
#include <KoResourcePaths.h>
#include <kactionmenu.h>
#include <kconfig.h>
#include <kconfiggroup.h>

// Calligra
#include <kis_icon.h>
#include <kis_config_notifier.h>

#ifdef __APPLE__
#include <QStyle>
#endif

namespace Digikam
{

// ---------------------------------------------------------------


class ThemeManager::ThemeManagerPriv
{
public:

    ThemeManagerPriv()
        : themeMenuActionGroup(0)
        , themeMenuAction(0)
    {
    }

    QString                currentThemeName;
    QMap<QString, QString> themeMap;            // map<theme name, theme config path>

    QActionGroup*          themeMenuActionGroup;
    KActionMenu*           themeMenuAction;
};

ThemeManager::ThemeManager(const QString &theme, QObject *parent)
    : QObject(parent)
    , d(new ThemeManagerPriv)
{
    //qDebug() << "Creating theme manager with theme" << theme;
    d->currentThemeName = theme;
    populateThemeMap();
}

ThemeManager::~ThemeManager()
{
    delete d;
}

QString ThemeManager::currentThemeName() const
{
    //qDebug() << "getting current themename";
    QString themeName;
    if (d->themeMenuAction && d->themeMenuActionGroup) {

        QAction* action = d->themeMenuActionGroup->checkedAction();
        if (action) {
            themeName = action->text().remove('&');
        }

        //qDebug() << "\tthemename from action" << themeName;
    }
    else if (!d->currentThemeName.isEmpty()) {

        //qDebug() << "\tcurrent themename" << d->currentThemeName;
        themeName = d->currentThemeName;
    }
    if (themeName.isEmpty()) {
        //qDebug() << "\tfallback";
        themeName = "imagic dark";
    }
    //qDebug() << "\tresult" << themeName;
    return themeName;
}

void ThemeManager::setCurrentTheme(const QString& name)
{
    //qDebug() << "setCurrentTheme();" << d->currentThemeName << "to" << name;
    d->currentThemeName = name;

    if (d->themeMenuAction  && d->themeMenuActionGroup) {
        QList<QAction*> list = d->themeMenuActionGroup->actions();
        Q_FOREACH (QAction* action, list) {
            if (action->text().remove('&') == name) {
                action->setChecked(true);
            }
        }
    }
    slotChangePalette();
}

namespace {

// imagic studio: the brand palette in code, used whenever a scheme-file
// lookup misses. The upstream behavior in that case was to feed an empty
// config to KColorScheme, which silently produced its built-in light
// defaults — a light grey UI with azure highlights. Brand-correct worst
// case instead.
QPalette imagicDarkPalette()
{
    const QColor window(26, 26, 26);
    const QColor base(20, 20, 20);
    const QColor button(37, 37, 37);
    const QColor textPrimary(240, 240, 240);
    const QColor textDisabled(107, 107, 107);
    const QColor accent(255, 152, 0);
    const QColor onAccent(13, 13, 13);

    QPalette p;
    const QPalette::ColorGroup states[3] = { QPalette::Active, QPalette::Inactive, QPalette::Disabled };
    for (int i = 0; i < 3; ++i) {
        const QPalette::ColorGroup state = states[i];
        const bool disabled = (state == QPalette::Disabled);
        const QColor fg = disabled ? textDisabled : textPrimary;
        p.setColor(state, QPalette::Window,          window);
        p.setColor(state, QPalette::WindowText,      fg);
        p.setColor(state, QPalette::Base,            base);
        p.setColor(state, QPalette::AlternateBase,   window);
        p.setColor(state, QPalette::Text,            fg);
        p.setColor(state, QPalette::Button,          button);
        p.setColor(state, QPalette::ButtonText,      fg);
        p.setColor(state, QPalette::Highlight,       disabled ? QColor(51, 51, 51) : accent);
        p.setColor(state, QPalette::HighlightedText, disabled ? textDisabled : onAccent);
        p.setColor(state, QPalette::ToolTipBase,     window);
        p.setColor(state, QPalette::ToolTipText,     textPrimary);
        p.setColor(state, QPalette::PlaceholderText, textDisabled);
        p.setColor(state, QPalette::Link,            QColor(255, 167, 38));
        p.setColor(state, QPalette::LinkVisited,     QColor(245, 124, 0));
        p.setColor(state, QPalette::Light,           QColor(51, 51, 51));
        p.setColor(state, QPalette::Midlight,        QColor(42, 42, 42));
        p.setColor(state, QPalette::Mid,             QColor(31, 31, 31));
        p.setColor(state, QPalette::Dark,            QColor(10, 10, 10));
        p.setColor(state, QPalette::Shadow,          QColor(0, 0, 0));
    }
    return p;
}

// imagic studio: chrome layer on top of the palette — the surfaces Qt
// styles natively (menu bar, menus, toolbars, dock titles, tabs, status
// bar, scrollbars, tooltips) get explicit brand colors. Applied only for
// the imagic themes; picking any other theme clears it.
QString imagicChromeStyleSheet()
{
    return QStringLiteral(
        "QMenuBar { background-color: #141414; color: #f0f0f0; }"
        "QMenuBar::item { background: transparent; padding: 4px 10px; }"
        "QMenuBar::item:selected { background: #252525; }"
        "QMenuBar::item:pressed { background: #ff9800; color: #0d0d0d; }"
        "QMenu { background-color: #1a1a1a; color: #f0f0f0; border: 1px solid #333333; }"
        "QMenu::item { padding: 4px 24px; background: transparent; }"
        "QMenu::item:selected { background: #ff9800; color: #0d0d0d; }"
        "QMenu::item:disabled { color: #6b6b6b; }"
        "QMenu::separator { height: 1px; background: #333333; margin: 4px 8px; }"
        "QToolBar { background-color: #141414; border: none; }"
        "QStatusBar { background-color: #141414; color: #a0a0a0; }"
        "QDockWidget { color: #a0a0a0; }"
        "QDockWidget::title { background-color: #141414; padding: 4px 8px; text-align: left; }"
        "QTabBar::tab { background: #141414; color: #a0a0a0; padding: 4px 10px; border: 1px solid #2a2a2a; border-bottom: none; }"
        "QTabBar::tab:selected { background: #1a1a1a; color: #f0f0f0; }"
        "QTabBar::tab:hover { color: #f0f0f0; }"
        "QToolTip { background-color: #1a1a1a; color: #f0f0f0; border: 1px solid #333333; }"
        "QScrollBar:vertical { background: #141414; width: 12px; margin: 0; }"
        "QScrollBar::handle:vertical { background: #333333; border-radius: 4px; min-height: 24px; margin: 2px; }"
        "QScrollBar::handle:vertical:hover { background: #ff9800; }"
        "QScrollBar:horizontal { background: #141414; height: 12px; margin: 0; }"
        "QScrollBar::handle:horizontal { background: #333333; border-radius: 4px; min-width: 24px; margin: 2px; }"
        "QScrollBar::handle:horizontal:hover { background: #ff9800; }"
        "QScrollBar::add-line, QScrollBar::sub-line { height: 0; width: 0; }"
        "QScrollBar::add-page, QScrollBar::sub-page { background: transparent; }");
}

} // namespace

void ThemeManager::slotChangePalette()
{
    if (currentThemeName() == "System") {
        qApp->setPalette(QPalette());
        qApp->setStyleSheet(QString());
        Q_EMIT signalThemeChanged();
        return;
    }

    //qDebug() << "slotChangePalette" << sender();

    // We must clear the icon cache before the palette is changed. That way
    // The widgets can change the icons properly when they receive the
    // PaletteChange event if needed.
    KisIconUtils::clearIconCache();

    QString theme(currentThemeName());
    QString filename        = d->themeMap.value(theme);

    QPalette palette = qApp->palette();

    if (filename.isEmpty()) {
        qWarning() << "ThemeManager: theme" << theme << "is not in the theme map"
                   << d->themeMap.keys() << "- applying the built-in imagic dark palette";
        palette = imagicDarkPalette();
    } else {
        KSharedConfigPtr config = KSharedConfig::openConfig(filename);

        QPalette::ColorGroup states[3] = { QPalette::Active, QPalette::Inactive, QPalette::Disabled };
        // TT thinks tooltips shouldn't use active, so we use our active colors for all states
        KColorScheme schemeTooltip(QPalette::Active, KColorScheme::Tooltip, config);

        for ( int i = 0; i < 3 ; ++i ) {

            QPalette::ColorGroup state = states[i];
            KColorScheme schemeView(state,      KColorScheme::View,      config);
            KColorScheme schemeWindow(state,    KColorScheme::Window,    config);
            KColorScheme schemeButton(state,    KColorScheme::Button,    config);
            KColorScheme schemeSelection(state, KColorScheme::Selection, config);

            palette.setBrush(state, QPalette::WindowText,      schemeWindow.foreground());
            palette.setBrush(state, QPalette::Window,          schemeWindow.background());
            palette.setBrush(state, QPalette::Base,            schemeView.background());
            palette.setBrush(state, QPalette::Text,            schemeView.foreground());
            palette.setBrush(state, QPalette::Button,          schemeButton.background());
            palette.setBrush(state, QPalette::ButtonText,      schemeButton.foreground());
            palette.setBrush(state, QPalette::Highlight,       schemeSelection.background());
            palette.setBrush(state, QPalette::HighlightedText, schemeSelection.foreground());
            palette.setBrush(state, QPalette::ToolTipBase,     schemeTooltip.background());
            palette.setBrush(state, QPalette::ToolTipText,     schemeTooltip.foreground());
            palette.setBrush(state, QPalette::PlaceholderText, schemeView.foreground(KColorScheme::InactiveText));

            palette.setColor(state, QPalette::Light,           schemeWindow.shade(KColorScheme::LightShade));
            palette.setColor(state, QPalette::Midlight,        schemeWindow.shade(KColorScheme::MidlightShade));
            palette.setColor(state, QPalette::Mid,             schemeWindow.shade(KColorScheme::MidShade));
            palette.setColor(state, QPalette::Dark,            schemeWindow.shade(KColorScheme::DarkShade));
            palette.setColor(state, QPalette::Shadow,          schemeWindow.shade(KColorScheme::ShadowShade));

            palette.setBrush(state, QPalette::AlternateBase,   schemeView.background(KColorScheme::AlternateBackground));
            palette.setBrush(state, QPalette::Link,            schemeView.foreground(KColorScheme::LinkText));
            palette.setBrush(state, QPalette::LinkVisited,     schemeView.foreground(KColorScheme::VisitedText));
        }
    }

    //qDebug() << ">>>>>>>>>>>>>>>>>> going to set palette on app" << theme;
    // hint for the style to synchronize the color scheme with the window manager/compositor
    qApp->setProperty("KDE_COLOR_SCHEME_PATH", filename);
    qApp->setPalette(palette);

    // imagic studio: brand chrome for the imagic themes; a clean slate for
    // anything else the user picks in Settings.
    if (theme.startsWith(QLatin1String("imagic"), Qt::CaseInsensitive)) {
        qApp->setStyleSheet(imagicChromeStyleSheet());
    } else {
        qApp->setStyleSheet(QString());
    }

    KisConfigNotifier::instance()->notifyColorThemeChanged(filename);

    Q_EMIT signalThemeChanged();
}

void ThemeManager::setThemeMenuAction(KActionMenu* const action)
{
    d->themeMenuAction = action;
    populateThemeMenu();
}

void ThemeManager::registerThemeActions(KisKActionCollection *actionCollection)
{
    if (!d->themeMenuAction) return;
    actionCollection->addAction("theme_menu", d->themeMenuAction);
}

void ThemeManager::populateThemeMenu()
{
    if (!d->themeMenuAction) return;

    d->themeMenuAction->menu()->clear();
    delete d->themeMenuActionGroup;

    d->themeMenuActionGroup = new QActionGroup(d->themeMenuAction);
    connect(d->themeMenuActionGroup, SIGNAL(triggered(QAction*)),
            this, SLOT(slotChangePalette()));

    QAction * action;
    QStringList schemeFiles = KoResourcePaths::findAllAssets("data", "color-schemes/*.colors");
    schemeFiles += KoResourcePaths::findAllAssets("genericdata", "color-schemes/*.colors");

    QMap<QString, QAction*> actionMap;
    for (int i = 0; i < schemeFiles.size(); ++i) {
        const QString filename  = schemeFiles.at(i);
        const QFileInfo info(filename);
        KSharedConfigPtr config = KSharedConfig::openConfig(filename);
        QIcon icon = createSchemePreviewIcon(config);
        KConfigGroup group(config, "General");
        const QString name = group.readEntry("Name", info.completeBaseName());
        action = new QAction(name, d->themeMenuActionGroup);
        action->setIcon(icon);
        action->setCheckable(true);
        actionMap.insert(name, action);
    }

#ifdef Q_OS_MAC
    // Add a "System" theme, which resets the palette to system colors
    // It only seems to work as expected on macOS.
    action = new QAction("System", d->themeMenuActionGroup);
    action->setCheckable(true);
    actionMap.insert("System", action);
#endif

    // sort the list
    QStringList actionMapKeys = actionMap.keys();
    actionMapKeys.sort();

    Q_FOREACH (const QString& name, actionMapKeys) {
        if ( name ==  currentThemeName()) {
            actionMap.value(name)->setChecked(true);
        }
        d->themeMenuAction->addAction(actionMap.value(name));
    }
}

QPixmap ThemeManager::createSchemePreviewIcon(const KSharedConfigPtr& config)
{
    // code taken from kdebase/workspace/kcontrol/colors/colorscm.cpp
    const uchar bits1[] = { 0xff, 0xff, 0xff, 0x2c, 0x16, 0x0b };
    const uchar bits2[] = { 0x68, 0x34, 0x1a, 0xff, 0xff, 0xff };
    const QSize bitsSize(24, 2);
    const QBitmap b1    = QBitmap::fromData(bitsSize, bits1);
    const QBitmap b2    = QBitmap::fromData(bitsSize, bits2);

    QPixmap pixmap(23, 16);
    pixmap.fill(Qt::black); // FIXME use some color other than black for borders?

    KConfigGroup group(config, "WM");
    QPainter p(&pixmap);
    KColorScheme windowScheme(QPalette::Active, KColorScheme::Window, config);
    p.fillRect(1,  1, 7, 7, windowScheme.background());
    p.fillRect(2,  2, 5, 2, QBrush(windowScheme.foreground().color(), b1));

    KColorScheme buttonScheme(QPalette::Active, KColorScheme::Button, config);
    p.fillRect(8,  1, 7, 7, buttonScheme.background());
    p.fillRect(9,  2, 5, 2, QBrush(buttonScheme.foreground().color(), b1));

    p.fillRect(15,  1, 7, 7, group.readEntry("activeBackground", QColor(96, 148, 207)));
    p.fillRect(16,  2, 5, 2, QBrush(group.readEntry("activeForeground", QColor(255, 255, 255)), b1));

    KColorScheme viewScheme(QPalette::Active, KColorScheme::View, config);
    p.fillRect(1,  8, 7, 7, viewScheme.background());
    p.fillRect(2, 12, 5, 2, QBrush(viewScheme.foreground().color(), b2));

    KColorScheme selectionScheme(QPalette::Active, KColorScheme::Selection, config);
    p.fillRect(8,  8, 7, 7, selectionScheme.background());
    p.fillRect(9, 12, 5, 2, QBrush(selectionScheme.foreground().color(), b2));

    p.fillRect(15,  8, 7, 7, group.readEntry("inactiveBackground", QColor(224, 223, 222)));
    p.fillRect(16, 12, 5, 2, QBrush(group.readEntry("inactiveForeground", QColor(20, 19, 18)), b2));

    p.end();
    return pixmap;
}

void ThemeManager::populateThemeMap()
{
    QStringList schemeFiles = KoResourcePaths::findAllAssets("data", "color-schemes/*.colors");
    schemeFiles += KoResourcePaths::findAllAssets("genericdata", "color-schemes/*.colors");
    
    for (int i = 0; i < schemeFiles.size(); ++i) {
        const QString filename  = schemeFiles.at(i);
        const QFileInfo info(filename);
        KSharedConfigPtr config = KSharedConfig::openConfig(filename);
        KConfigGroup group(config, "General");
        const QString name = group.readEntry("Name", info.completeBaseName());
        d->themeMap.insert(name, filename);
    }


}

}  // namespace Digikam
