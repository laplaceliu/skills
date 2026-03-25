---
name: qt-resources
description: >
  Qt C++ 资源系统 — .qrc 文件、嵌入图标和资源、运行时加载资源，以及使用 Qt Resource Compiler (rcc)。适用于：将图标、图片或其他文件打包到应用程序中、通过 ":/" 路径加载资源，或从文件系统资源方式迁移。

  触发词：".qrc file"、"embed icon"、"rcc"、"Qt resource compiler"、"bundled assets"、"resource path"、" :/icons/"、"QIcon"、"QPixmap from resources"、"bundle image"
version: 1.0.0
---

## Qt C++ 资源系统

### .qrc 文件格式

```xml
<!-- resources/resources.qrc -->
<RCC>
  <qresource prefix="/icons">
    <file alias="app.png">icons/app.png</file>
    <file alias="save.svg">icons/save.svg</file>
    <file alias="open.svg">icons/open.svg</file>
  </qresource>
  <qresource prefix="/themes">
    <file alias="dark.qss">../resources/dark.qss</file>
    <file alias="light.qss">../resources/light.qss</file>
  </qresource>
  <qresource prefix="/data">
    <file alias="default_config.json">../resources/default_config.json</file>
  </qresource>
</RCC>
```

`.qrc` 中的文件路径相对于 `.qrc` 文件的位置。`alias` 属性设置运行时使用的名称。

### 编译资源

**使用 Qt Resource Compiler (rcc)：**
```bash
# 手动编译
rcc resources/resources.qrc -o resources/resources.qrc.cpp

# 在 CMake 中使用 qt_add_resources（推荐）
qt_add_resources(myapp "resources"
    PREFIX "/"
    FILES
        resources/icons/app.png
        resources/icons/save.svg
)
```

### CMake 集成

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.16)
project(MyApp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets)

# 添加资源文件
qt_add_resources(myapp "resources"
    PREFIX "/icons"
    FILES
        resources/icons/app.png
        resources/icons/save.png
        resources/icons/open.png
)

qt_add_resources(myapp "themes"
    PREFIX "/themes"
    FILES
        resources/dark.qss
        resources/light.qss
)
```

### 运行时使用资源

```cpp
#include <QIcon>
#include <QPixmap>
#include <QFile>
#include <QTextStream>

// 图标
QIcon icon(":/icons/save.png");
button->setIcon(icon);
button->setIconSize(QSize(16, 16));

// Pixmaps
QPixmap pixmap(":/icons/app.png");
label->setPixmap(pixmap.scaled(64, 64,
    Qt::AspectRatioMode::KeepAspectRatio,
    Qt::TransformationMode::SmoothTransformation));

// 文本文件（主题、配置）
QFile file(":/themes/dark.qss");
if (file.open(QFile::OpenModeFlag::ReadOnly | QFile::OpenModeFlag::Text)) {
    QTextStream stream(&file);
    QString stylesheet = stream.readAll();
    file.close();
    qApp->setStyleSheet(stylesheet);
}
```

### 内联资源加载（无需编译步骤）

对于开发中的小资源，直接嵌入：

```cpp
#include <QIcon>
#include <QPixmap>
#include <QByteArray>

QIcon iconFromBase64(const char *base64Data) {
    QByteArray data = QByteArray::fromBase64(base64Data);
    QPixmap pix;
    pix.loadFromData(data);
    return QIcon(&pix);
}
```

### SVG 图标

SVG 是首选格式 — 它们在任何 DPI 下都能完美缩放：

```cpp
#include <QSvgWidget>
#include <QIcon>

// 在布局中
QSvgWidget *svg = new QSvgWidget(":/icons/logo.svg", this);
svg->setFixedSize(48, 48);

// 作为窗口图标（QIcon 在大多数平台上原生处理 SVG）
setWindowIcon(QIcon(":/icons/app.svg"));
```

### 高 DPI（Retina/4K）支持

```cpp
int main(int argc, char *argv[]) {
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);

    QApplication app(argc, argv);
    // ...
}
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

```cmake
# CMakeLists.txt
# qt_add_resources 会自动处理编译
# 确保资源文件在 qt_add_resources 之前被复制到构建目录
```
