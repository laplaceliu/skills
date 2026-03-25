---
name: qt-resources
description: >
  Qt 资源系统 — .qrc 文件、嵌入图标和资源、运行时加载资源，以及使用 pyrcc6 或 PySide6-rcc。适用于：将图标、图片或其他文件打包到应用程序中、通过 ":/" 路径加载资源，或从文件系统资源方式迁移。

  触发词：".qrc file"、"embed icon"、"pyrcc6"、"PySide6-rcc"、"bundled assets"、"resource path"、" :/icons/"、"QIcon"、"QPixmap from resources"、"bundle image"
version: 1.0.0
---

## Qt 资源系统

### .qrc 文件格式

```xml
<!-- resources/resources.qrc -->
<!DOCTYPE RCC>
<RCC version="1.0">
  <qresource prefix="/icons">
    <file alias="app.png">icons/app.png</file>
    <file alias="save.svg">icons/save.svg</file>
    <file alias="open.svg">icons/open.svg</file>
  </qresource>
  <qresource prefix="/themes">
    <file>dark.qss</file>
    <file>light.qss</file>
  </qresource>
  <qresource prefix="/data">
    <file>default_config.json</file>
  </qresource>
</RCC>
```

`.qrc` 中的文件路径相对于 `.qrc` 文件的位置。`alias` 属性设置运行时使用的名称。

### 编译资源（Python）

**PySide6：**
```bash
pyside6-rcc resources/resources.qrc -o src/myapp/resources/rc_resources.py
```

**PyQt6：**
```bash
pyrcc6 resources/resources.qrc -o src/myapp/resources/rc_resources.py
```

添加到 `pyproject.toml` 构建脚本或 `Makefile` 以保持同步。编译后的文件可以干净地导入：

```python
# src/myapp/resources/__init__.py
from . import rc_resources  # noqa: F401 — 副作用导入注册资源
```

在任何使用 `:/` 路径的代码之前导入 `rc_resources`。在 `resources/__init__.py` 中的模块级导入是最简洁的方式 — 它在包首次导入时运行一次。

### 运行时使用资源

```python
from PySide6.QtGui import QIcon, QPixmap

# 图标
icon = QIcon(":/icons/save.svg")
button.setIcon(icon)
button.setIconSize(QSize(16, 16))

# Pixmaps
pixmap = QPixmap(":/icons/app.png")
label.setPixmap(pixmap.scaled(64, 64, Qt.AspectRatioMode.KeepAspectRatio))

# 文本文件（主题、配置）
from PySide6.QtCore import QFile, QTextStream

file = QFile(":/themes/dark.qss")
if file.open(QFile.OpenModeFlag.ReadOnly | QFile.OpenModeFlag.Text):
    stream = QTextStream(file)
    stylesheet = stream.readAll()
    file.close()
```

### 内联资源加载（无需编译步骤）

对于开发中的小资源，直接嵌入：

```python
import base64
from PySide6.QtGui import QIcon, QPixmap
from PySide6.QtCore import QByteArray

def icon_from_base64(data: str) -> QIcon:
    b = QByteArray.fromBase64(data.encode())
    pix = QPixmap()
    pix.loadFromData(b)
    return QIcon(pix)
```

### SVG 图标

SVG 是首选格式 — 它们在任何 DPI 下都能完美缩放：

```python
from PySide6.QtSvgWidgets import QSvgWidget
from PySide6.QtGui import QIcon

# 在布局中
svg = QSvgWidget(":/icons/logo.svg")
svg.setFixedSize(48, 48)

# 作为窗口图标（QIcon 在大多数平台上原生处理 SVG）
self.setWindowIcon(QIcon(":/icons/app.svg"))
```

### 高 DPI（Retina/4K）支持

```python
# 在 main() 中 — QApplication 之前
os.environ["QT_ENABLE_HIGHDPI_SCALING"] = "1"

app = QApplication(sys.argv)
app.setHighDpiScaleFactorRoundingPolicy(
    Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
)
```

尽可能使用 SVG 图标。对于光栅图标，提供 `@2x` 变体：
```xml
<qresource prefix="/icons">
  <file alias="save.png">icons/save.png</file>
  <file alias="save@2x.png">icons/save@2x.png</file>
</qresource>
```

Qt 会在高 DPI 显示上自动选择 `@2x` 变体。

### 项目自动化

将资源编译添加到构建过程中：

```toml
# pyproject.toml — 使用 hatch
[tool.hatch.build.hooks.custom]
path = "build_hooks.py"
```

```python
# build_hooks.py
import subprocess
from pathlib import Path

def build_editable(config, ...):
    subprocess.run([
        "pyside6-rcc",
        "resources/resources.qrc",
        "-o", "src/myapp/resources/rc_resources.py"
    ], check=True)
```

或简单的 `Makefile` 目标：
```makefile
resources: resources/resources.qrc
	pyside6-rcc $< -o src/myapp/resources/rc_resources.py
```
