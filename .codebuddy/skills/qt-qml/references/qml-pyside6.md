# QML + PySide6: 向 QML 暴露 Python 对象

三种方法，按从新到旧排序。对于新代码首选方法 1。

## 方法 1: 必需属性 (首选 — Qt 6 惯用法)

`setInitialProperties` + `required property` 提供类型检查的、作用域受限的注入。
`setContextProperty` 是无类型的且全局的 — 对新代码避免使用。

```python
# Python — 在 engine.load() 之前设置
backend = Backend()
engine.setInitialProperties({"backend": backend})
engine.load("qrc:/ui/main.qml")
```

```qml
// QML 根 — 声明为必需属性; 在加载时进行类型检查
ApplicationWindow {
    required property Backend backend
    // 通过以下方式访问: backend.count, backend.increment() 等
}
```

## 方法 2: 上下文属性 (适用于现有代码)

```python
from PySide6.QtCore import QObject, Signal, Property, Slot

class Backend(QObject):
    countChanged = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._count = 0

    @Property(int, notify=countChanged)
    def count(self) -> int:
        return self._count

    @Slot()                          # @Slot 是 QML 调用所必需的
    def increment(self) -> None:
        self._count += 1
        self.countChanged.emit()

    @Slot(str, result=str)           # 在 @Slot 中声明返回类型
    def greet(self, name: str) -> str:
        return f"Hello, {name}!"

backend = Backend()
engine.rootContext().setContextProperty("backend", backend)
```

```qml
Label { text: "Count: " + backend.count }
Button { onClicked: backend.increment() }
Label { text: backend.greet("World") }
```

**`@Slot` 对 QML 可调用的方法是强制的。** QML 没有 `Q_INVOKABLE` 等效物 — 任何可从 QML 调用的 Python 方法必须有 `@Slot`。缺少它会在运行时导致 `TypeError`。

## 方法 3: 注册的 QML 类型 (可重用，有命名空间)

当 Python 类是 QML 应直接实例化的模型或组件时使用。

```python
from PySide6.QtQml import QmlElement

QML_IMPORT_NAME = "com.myorg.myapp"
QML_IMPORT_MAJOR_VERSION = 1

@QmlElement
class PersonModel(QAbstractListModel):
    ...
```

```qml
import com.myorg.myapp 1.0

PersonModel { id: model }
ListView { model: model; ... }
```
