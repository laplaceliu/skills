---
name: qt-settings
description: >
  Qt C++ 使用 QSettings 的持久化应用程序设置 — 存储和恢复用户偏好、窗口几何、近期文件和应用程序状态。适用于：保存用户偏好、持久化窗口大小/位置、存储近期文件列表或管理应用程序配置。

  触发词："QSettings"、"persistent settings"、"save preferences"、"restore window"、"user preferences"、"remember state"、"save window geometry"、"recent files"、"app configuration"、"settings persistence"
version: 1.0.0
---

## QSettings — 持久化应用程序设置（C++）

### 设置和初始化

在首次使用 `QSettings` 之前设置应用程序元数据 — 这些会设置默认存储路径：

```cpp
int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    app.setApplicationName("MyApp");
    app.setOrganizationName("MyOrg");
    app.setOrganizationDomain("myorg.com");
    // ...
}
```

默认存储位置（无需路径参数）：
- **Windows**：注册表 `HKCU\Software\MyOrg\MyApp`
- **macOS**：`~/Library/Preferences/com.myorg.myapp.plist`
- **Linux**：`~/.config/MyOrg/MyApp.ini`

### 基本用法

```cpp
#include <QSettings>
#include <QStringList>

// 不带参数构造 — 使用 QApplication 上设置的应用程序名/组织
QSettings settings;

// 写入
settings.setValue("theme", "dark");
settings.setValue("fontSize", 13);
settings.setValue("recentFiles",
    QStringList({"/path/to/file1.csv", "/path/to/file2.csv"}));

// 读取（带默认值）
QString theme = settings.value("theme", "light").toString();
int fontSize = settings.value("fontSize", 12).toInt();
QStringList recent = settings.value("recentFiles").toStringList();

// 删除
settings.remove("obsoleteKey");

// 检查存在性
if (settings.contains("theme")) {
    // ...
}

// 强制写入磁盘（通常会延迟写入）
settings.sync();
```

始终在 `settings.value()` 中提供默认值 — 否则返回无效的 QVariant。

### 分组

```cpp
QSettings settings;

// 分组
settings.beginGroup("window");
settings.setValue("width", 1200);
settings.setValue("height", 800);
settings.setValue("maximized", false);
settings.endGroup();

// 读取分组值
settings.beginGroup("window");
int width = settings.value("width", 800).toInt();
settings.endGroup();

// 或使用斜杠分隔的键
settings.setValue("window/width", 1200);
int width = settings.value("window/width", 800).toInt();
```

### 窗口几何（常见模式）

```cpp
// mainwindow.h
#pragma once
#include <QMainWindow>
#include <QSettings>

class MainWindow : public QMainWindow {
    Q_OBJECT
public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow() override;

protected:
    void closeEvent(QCloseEvent *event) override;

private:
    void saveGeometry();
    void restoreGeometry();

    QSettings m_settings;
};

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , m_settings()
{
    restoreGeometry();
}

void MainWindow::closeEvent(QCloseEvent *event) {
    saveGeometry();
    QMainWindow::closeEvent(event);
}

void MainWindow::saveGeometry() {
    m_settings.setValue("window/geometry", saveGeometry());
    m_settings.setValue("window/state", saveState());
    m_settings.setValue("window/maximized", isMaximized());
}

void MainWindow::restoreGeometry() {
    // 如果保存了几何信息则恢复
    if (m_settings.contains("window/geometry")) {
        restoreGeometry(m_settings.value("window/geometry").toByteArray());
    }
    if (m_settings.contains("window/state")) {
        restoreState(m_settings.value("window/state").toByteArray());
    }
}
```

`saveGeometry()` 和 `restoreGeometry()` 正确处理多显示器设置。

### 近期文件列表

```cpp
// recentfilesmanager.h
#pragma once
#include <QObject>
#include <QSettings>
#include <QStringList>
#include <QVector>

class RecentFilesManager : public QObject {
    Q_OBJECT
public:
    static constexpr int MAX_RECENT = 10;
    static const QString KEY;

    explicit RecentFilesManager(QObject *parent = nullptr);

    void add(const QString &path);
    QStringList all() const;
    void clear();

signals:
    void recentFilesChanged();

private:
    QSettings m_settings;
};

const QString RecentFilesManager::KEY = "recent_files";

RecentFilesManager::RecentFilesManager(QObject *parent)
    : QObject(parent)
    , m_settings()
{}

void RecentFilesManager::add(const QString &path) {
    QStringList files = all();
    files.removeAll(path);
    files.prepend(path);
    if (files.size() > MAX_RECENT) {
        files = files.mid(0, MAX_RECENT);
    }
    m_settings.setValue(KEY, files);
    emit recentFilesChanged();
}

QStringList RecentFilesManager::all() const {
    return m_settings.value(KEY).toStringList();
}

void RecentFilesManager::clear() {
    m_settings.remove(KEY);
    emit recentFilesChanged();
}
```

### 设置对话框集成

```cpp
// settingsdialog.h
#pragma once
#include <QDialog>
#include <QComboBox>
#include <QSpinBox>
#include <QDialogButtonBox>
#include <QSettings>

class SettingsDialog : public QDialog {
    Q_OBJECT
public:
    explicit SettingsDialog(QWidget *parent = nullptr);

private slots:
    void accept() override;

private:
    void loadSettings();
    void saveSettings();

    QComboBox *m_themeCombo = nullptr;
    QSpinBox *m_fontSizeSpin = nullptr;
    QSettings m_settings;
};

SettingsDialog::SettingsDialog(QWidget *parent)
    : QDialog(parent)
    , m_settings()
{
    setupUi();
    loadSettings();
}

void SettingsDialog::loadSettings() {
    m_themeCombo->setCurrentText(
        m_settings.value("theme", "light").toString());
    m_fontSizeSpin->setValue(
        m_settings.value("fontSize", 12).toInt());
}

void SettingsDialog::saveSettings() {
    m_settings.setValue("theme", m_themeCombo->currentText());
    m_settings.setValue("fontSize", m_fontSizeSpin->value());
}
```

### INI 文件（便携/版本控制配置）

对于应该放在可执行文件旁边或已知位置中的配置文件：

```cpp
#include <QStandardPaths>
#include <QDir>

QString configPath = QStandardPaths::writableLocation(
    QStandardPaths::StandardLocation::AppConfigLocation);
QDir().mkpath(configPath);  // 确保目录存在
configPath += "/settings.ini";

QSettings settings(configPath, QSettings::Format::IniFormat);
```

### QStandardPaths — 平台正确的文件位置

```cpp
#include <QStandardPaths>

// 用户数据（文档、导出）
QString dataDir = QStandardPaths::writableLocation(
    QStandardPaths::StandardLocation::AppDataLocation);

// 缓存
QString cacheDir = QStandardPaths::writableLocation(
    QStandardPaths::StandardLocation::CacheLocation);

// 临时文件
QString tempDir = QStandardPaths::writableLocation(
    QStandardPaths::StandardLocation::TempLocation);
```

使用 `QStandardPaths` 而不是硬编码 `~/.config` 或 `%APPDATA%` — 它会自动返回正确的平台路径。
