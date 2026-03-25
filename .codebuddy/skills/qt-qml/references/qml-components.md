# 常用 QtQuick.Controls 组件

标准组件面板的快速参考。所有组件都需要 `import QtQuick.Controls`。

## 布局容器

```qml
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout { spacing: 8; ... }
RowLayout { spacing: 4; ... }
GridLayout { columns: 3; ... }
StackLayout { currentIndex: tabBar.currentIndex; ... }
```

## 输入控件

```qml
TextField { placeholderText: "Enter name..." }
TextArea { wrapMode: TextArea.Wrap }
ComboBox { model: ["Option 1", "Option 2"] }
CheckBox { text: "Enable feature" }
Slider { from: 0; to: 100; value: 50 }
SpinBox { from: 0; to: 999 }
```

## 显示

```qml
Label { text: "Hello"; font.bold: true }
Image { source: "qrc:/icons/logo.svg" }
ProgressBar { value: 0.75 }
```

## 容器

```qml
ScrollView { clip: true; ListView { ... } }
GroupBox { title: "Settings"; ... }
TabBar { id: tabBar; TabButton { text: "Tab 1" } }
```
