---
name: qt-settings
description: >
  使用 QSettings 的持久化应用程序设置 — 存储和恢复用户偏好、窗口几何、近期文件和应用程序状态。适用于：保存用户偏好、持久化窗口大小/位置、存储近期文件列表或管理应用程序配置。

  触发词："QSettings"、"persistent settings"、"save preferences"、"restore window"、"user preferences"、"remember state"、"save window geometry"、"recent files"、"app configuration"、"settings persistence"
version: 1.0.0
---

## QSettings — 持久化应用程序设置

### 设置和初始化

在首次使用 `QSettings` 之前设置应用程序元数据 — 这些会设置默认存储路径：

```python
app.setApplicationName("MyApp")
app.setOrganizationName("MyOrg")
app.setOrganizationDomain("myorg.com")
```

默认存储位置（无需路径参数）：
- **Windows**：注册表 `HKCU\Software\MyOrg\MyApp`
- **macOS**：`~/Library/Preferences/com.myorg.myapp.plist`
- **Linux**：`~/.config/MyOrg/MyApp.ini`

### 基本用法

```python
from PySide6.QtCore import QSettings

# 不带参数构造 — 使用 QApplication 上设置的应用程序名/组织
settings = QSettings()

# 写入
settings.setValue("theme", "dark")
settings.setValue("font_size", 13)
settings.setValue("recent_files", ["/path/to/file1.csv", "/path/to/file2.csv"])

# 读取（带默认值）
theme = settings.value("theme", "light")
font_size = settings.value("font_size", 12, type=int)   # type= 强制类型转换
recent = settings.value("recent_files", [], type=list)

# 删除
settings.remove("obsolete_key")

# 检查存在性
if settings.contains("theme"):
    ...

# 强制写入磁盘（通常会延迟写入）
settings.sync()
```

始终在 `settings.value()` 中提供默认值 — 否则返回 `None`，这在传递给期望特定类型的 Qt 方法时会导致类型错误。

### 分组（命名空间）

```python
settings = QSettings()

# 分组上下文管理器（不是内置的 — 使用 begin/end）
settings.beginGroup("window")
settings.setValue("width", 1200)
settings.setValue("height", 800)
settings.setValue("maximized", False)
settings.endGroup()

# 读取分组值
settings.beginGroup("window")
width = settings.value("width", 800, type=int)
settings.endGroup()

# 或使用斜杠分隔的键
settings.setValue("window/width", 1200)
width = settings.value("window/width", 800, type=int)
```

### 窗口几何（常见模式）

```python
class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self._restore_geometry()

    def closeEvent(self, event) -> None:
        self._save_geometry()
        super().closeEvent(event)

    def _save_geometry(self) -> None:
        settings = QSettings()
        settings.setValue("window/geometry", self.saveGeometry())
        settings.setValue("window/state", self.saveState())
        settings.setValue("window/maximized", self.isMaximized())

    def _restore_geometry(self) -> None:
        settings = QSettings()
        geometry = settings.value("window/geometry")
        if geometry:
            self.restoreGeometry(geometry)
        state = settings.value("window/state")
        if state:
            self.restoreState(state)
```

`saveGeometry()` 和 `restoreGeometry()` 正确处理多显示器设置。

### 近期文件列表

```python
class RecentFilesManager:
    MAX_RECENT = 10
    KEY = "recent_files"

    def __init__(self) -> None:
        self._settings = QSettings()

    def add(self, path: str) -> None:
        files = self.all()
        if path in files:
            files.remove(path)
        files.insert(0, path)
        self._settings.setValue(self.KEY, files[:self.MAX_RECENT])

    def all(self) -> list[str]:
        return self._settings.value(self.KEY, [], type=list)

    def clear(self) -> None:
        self._settings.remove(self.KEY)
```

### 设置对话框集成

```python
class SettingsDialog(QDialog):
    def _load_settings(self) -> None:
        s = QSettings()
        self._theme_combo.setCurrentText(s.value("theme", "light"))
        self._font_spin.setValue(s.value("font_size", 12, type=int))

    def _save_settings(self) -> None:
        s = QSettings()
        s.setValue("theme", self._theme_combo.currentText())
        s.setValue("font_size", self._font_spin.value())
```

### INI 文件（便携/版本控制配置）

对于应该放在可执行文件旁边或已知位置中的配置文件：

```python
config_path = Path(QStandardPaths.writableLocation(
    QStandardPaths.StandardLocation.AppConfigLocation
)) / "settings.ini"
config_path.parent.mkdir(parents=True, exist_ok=True)

settings = QSettings(str(config_path), QSettings.Format.IniFormat)
```

### QStandardPaths — 平台正确的文件位置

```python
from PySide6.QtCore import QStandardPaths

# 用户数据（文档、导出）
data_dir = QStandardPaths.writableLocation(QStandardPaths.StandardLocation.AppDataLocation)

# 缓存
cache_dir = QStandardPaths.writableLocation(QStandardPaths.StandardLocation.CacheLocation)

# 临时文件
temp_dir = QStandardPaths.writableLocation(QStandardPaths.StandardLocation.TempLocation)
```

使用 `QStandardPaths` 而不是硬编码 `~/.config` 或 `%APPDATA%` — 它会自动返回正确的平台路径。
