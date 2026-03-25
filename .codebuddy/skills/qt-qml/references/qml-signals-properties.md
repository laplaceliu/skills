# QML 信号与连接

## 在 QML 中定义和连接信号

```qml
// 在 QML 组件中定义信号
signal dataChanged(var newData)

// 使用 Connections 块在 QML 中连接
Connections {
    target: someItem
    function onDataChanged(data) {
        console.log("Got:", data)
    }
}
```

## 将 QML 信号连接到 Python Slot

```python
# 在 engine.load() 之后，将 QML 信号连接到 Python slot
engine.rootObjects()[0].dataChanged.connect(backend.on_data_changed)
```
