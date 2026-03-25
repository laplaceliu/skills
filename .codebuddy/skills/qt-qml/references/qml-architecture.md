# QML 架构: QQmlApplicationEngine 引导

最小的 PySide6 + QML 应用程序接线。`engine.rootObjects()` 在加载失败时返回空 — 始终进行防护。

## Python 入口点

```python
# src/myapp/__main__.py
import sys
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine

def main() -> None:
    app = QGuiApplication(sys.argv)
    app.setApplicationName("MyApp")

    engine = QQmlApplicationEngine()
    qml_file = Path(__file__).parent / "ui" / "main.qml"
    engine.load(str(qml_file))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())
```

## 根 QML 文件

```qml
// src/myapp/ui/main.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    width: 800
    height: 600
    title: "MyApp"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        Label {
            text: "Hello, Qt Quick!"
            font.pixelSize: 24
        }

        Button {
            text: "Click Me"
            onClicked: console.log("Button clicked")
        }
    }
}
```

## QRC 资源文件

对所有 QML 资产使用 QRC — 保持开发和安装构建中的路径一致:

```xml
<qresource prefix="/ui">
  <file>main.qml</file>
  <file>components/Card.qml</file>
</qresource>
<qresource prefix="/icons">
  <file>logo.svg</file>
</qresource>
```

```python
# 从 QRC 加载 (优于文件系统路径，在发布的应用中)
engine.load("qrc:/ui/main.qml")
```

```qml
// 在 QML 中引用 QRC 资源
Image { source: "qrc:/icons/logo.svg" }
```

## 调试

```qml
// 从 QML 输出到控制台
Component.onCompleted: console.log("loaded, width:", width)
```

```bash
QML_IMPORT_TRACE=1 python -m myapp      # 跟踪 QML 导入解析
QSG_VISUALIZE=overdraw python -m myapp  # 可视化渲染过度绘制
```
