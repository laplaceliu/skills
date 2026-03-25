---
name: qt-qml
description: >
  QML 和 Qt Quick — 用于现代 Qt 应用程序的声明式 UI 语言。适用于：构建基于 QML 的 UI、在 Python/C++ 应用中嵌入 QML、向 QML 暴露 Python/C++ 对象、创建 QML 组件，或在 QML 和 widgets 之间选择。

  触发词："QML"、"Qt Quick"、"declarative UI"、"QQmlApplicationEngine"、"expose to QML"、"QML component"、"QML signal"、"pyqtProperty"、"QML vs widgets"、"QtQuick.Controls"、"Item"、"Rectangle"
version: 1.0.0
---

## QML 和 Qt Quick

### QML vs Widgets：何时选择 QML

| 使用 QML 当... | 使用 Widgets 当... |
|-----------------|---------------------|
| 构建现代、动画、流畅的 UI | 构建传统桌面工具 |
| 目标平台是移动端或嵌入式 | 重度数据表格和表单 |
| 设计师参与 UI 工作 | 需要富文本编辑 |
| 需要 GPU 加速渲染 | 复杂平台组件集成 |
| 从头开始编写新应用 | 扩展现有 widget 应用 |

对于新的 Python/PySide6 桌面应用程序，QML 以更少代码提供更好的视觉效果。对于数据密集型企业工具，widgets 仍是务实的选择。

**引导和架构** — 参见 [references/qml-architecture.md](references/qml-architecture.md)

### 官方最佳实践（Qt Quick）

**1. 类型安全的属性声明** — 始终使用显式类型，而非 `var`：
```qml
// 错误 — 阻止静态分析，错误信息不清晰
property var name

// 正确
property string name
property int count
property MyModel optionsModel
```

**2. 优先使用声明式绑定而非命令式赋值：**
```qml
// 错误 — 命令式赋值会覆盖绑定，破坏 Qt Design Studio
Rectangle {
    Component.onCompleted: color = "red"
}

// 正确 — 声明式绑定，在加载时评估一次
Rectangle {
    color: "red"
}
```

**3. 交互信号优于值变化信号：**
```qml
// 错误 — valueChanged 在 clamping/rounding 时触发，导致事件级联
Slider { onValueChanged: model.update(value) }

// 正确 — moved 仅在用户交互时触发
Slider { onMoved: model.update(value) }
```

**4. 不要为 Layout 的直接子项设置锚点：**
```qml
// 错误 — 直接子项上的锚点导致绑定循环
RowLayout {
    Rectangle { anchors.fill: parent }
}

// 正确 — 使用 Layout 附加属性
RowLayout {
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 40
    }
}
```

**5. 不要自定义原生样式** — Windows 和 macOS 原生样式忽略 QSS。将所有自定义样式基于跨平台样式：`Basic`、`Fusion`、`Material` 或 `Universal`：
```qml
// 在 main() 中 — 必须在 QGuiApplication 之前设置
QQuickStyle.setStyle("Material")
```

**6. 从一开始就让所有用户可见的字符串可翻译：**
```qml
Label { text: qsTr("Save File") }
Button { text: qsTr("Cancel") }
```

### 向 QML 暴露 Python 对象

三种方法：必需属性（首选）、上下文属性、注册的 QML 类型。

**关键规则：任何可从 QML 调用的 Python 方法必须带有 `@Slot`。** 缺少它会导致运行时 `TypeError`。

**完整模式** — 参见 [references/qml-pyside6.md](references/qml-pyside6.md)

### QML 信号和连接

**完整模式** — 参见 [references/qml-signals-properties.md](references/qml-signals-properties.md)

### 常用 QtQuick.Controls 组件

**完整组件参考** — 参见 [references/qml-components.md](references/qml-components.md)
