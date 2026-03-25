---
name: qt-signals-slots
description: >
  Qt 信号与槽（Signals and Slots）—— 核心的对象间通信机制。适用于连接信号与槽、定义自定义信号、调试断开连接的信号、对象间传递数据，或安全处理跨线程通信。

  触发词："connect signal"、"custom signal"、"slot not firing"、"disconnect signal"、"cross-thread signal"、"signal not working"、"emit signal"、"define signal"、"QObject signal"
version: 1.0.0
---

## 信号与槽（Signals and Slots）

### 定义自定义信号（Defining Custom Signals）

**Python / PySide6 和 PyQt6：**
```python
from PySide6.QtCore import QObject, Signal

class DataProcessor(QObject):
    # 类级别的信号声明 —— 不是实例属性
    processing_started = Signal()
    data_ready = Signal(list)          # 携带一个列表
    progress_updated = Signal(int)     # 携带一个整数（0–100）
    error_occurred = Signal(str)       # 携带错误消息
    result_ready = Signal(object)      # 携带任意 Python 对象

    def process(self, data: list) -> None:
        self.processing_started.emit()
        # ... 处理中 ...
        self.data_ready.emit(result)
```

信号必须声明为**类属性**，不能放在 `__init__` 中。在 `__init__` 中声明会导致它们遮盖描述符并破坏连接跟踪。

**C++ / Qt：**
```cpp
class DataProcessor : public QObject {
    Q_OBJECT  // 必填 —— 启用信号/槽功能
public:
    explicit DataProcessor(QObject *parent = nullptr);

signals:
    void processingStarted();
    void dataReady(const QList<QVariant> &data);
    void progressUpdated(int percent);
    void errorOccurred(const QString &message);
};
```

`Q_OBJECT` 宏在每个使用信号/槽的 `QObject` 子类中是强制的。缺少它会导致在某些配置下运行时失败，且不会有编译错误。

### 连接信号（Connecting Signals）

**新式语法（推荐使用）：**
```python
# 直接连接方法
button.clicked.connect(self._on_button_clicked)

# 使用 Lambda 进行简单转换
slider.valueChanged.connect(lambda v: self._label.setText(str(v)))

# 跨对象连接
self._processor.data_ready.connect(self._table.populate)
self._processor.error_occurred.connect(self._status_bar.showMessage)
```

**C++：**
```cpp
connect(button, &QPushButton::clicked, this, &MainWindow::onButtonClicked);
connect(slider, &QSlider::valueChanged, this, [this](int v) {
    label->setText(QString::number(v));
});
```

在新式 C++ 代码中，永远不要使用旧式的 `SIGNAL()` / `SLOT()` 宏——它们会绕过类型检查，并在名称不匹配时静默失败。

### @Slot 装饰器（PySide6 必需）

始终使用 `@Slot` 标记槽方法。Qt 官方 Python 文档指出，省略它会导致：
- **运行时开销**—— 每次 `connect()` 调用时，方法都会被动态添加到 `QMetaObject`
- **在 QML 中导致 `TypeError`** —— QML 可调用方法需要 `@Slot`（没有它就没有 `Q_INVOKABLE` 等效物）
- **可能导致跨线程段错误** —— 没有 `@Slot`，代理对象可能在错误的线程上创建

```python
from PySide6.QtCore import QObject, Signal, Slot

class DataProcessor(QObject):
    result_ready = Signal(dict)
    error_occurred = Signal(str)

    @Slot()
    def start(self) -> None:
        """无参槽。"""
        ...

    @Slot(str)
    def on_input(self, text: str) -> None:
        """接收字符串的槽。"""
        ...

    @Slot(float, result=int)
    def convert(self, value: float) -> int:
        """有返回值的槽 —— 替代 C++ 的 Q_INVOKABLE。"""
        return int(value)
```

`@Slot` 的参数必须与信号声明的类型匹配。对于没有信号连接但可从 QML 调用的方法，仍然需要 `@Slot`——它将方法注册为元对象系统中的可调用方法。

启用警告以在开发期间捕获缺少的装饰器：
```bash
QT_LOGGING_RULES="qt.pyside.libpyside.warning=true" python -m myapp
```

### 连接类型（Connection Types）

| 类型 | 适用场景 |
|------|---------|
| `Qt.AutoConnection`（默认） | 同一或不同线程 —— 自动选择 |
| `Qt.DirectConnection` | 强制同线程，同步执行 |
| `Qt.QueuedConnection` | 跨线程，或推迟到下一次事件循环迭代 |
| `Qt.BlockingQueuedConnection` | 跨线程，调用方阻塞直到槽执行完成（存在死锁风险） |

```python
# 显式使用队列连接以确保线程安全
worker.result_ready.connect(self._on_result, Qt.QueuedConnection)
```

### 跨线程信号（安全模式）

Qt 信号是从工作线程向 UI 线程通信的唯一安全方式。

```python
from PySide6.QtCore import QObject, Signal, QThread

class Worker(QObject):
    result_ready = Signal(dict)
    error_occurred = Signal(str)
    finished = Signal()

    def run(self) -> None:
        try:
            result = self._do_work()   # 阻塞操作
            self.result_ready.emit(result)
        except Exception as e:
            self.error_occurred.emit(str(e))
        finally:
            self.finished.emit()

class MainWindow(QMainWindow):
    def _start_work(self) -> None:
        self._thread = QThread(self)
        self._worker = Worker()
        self._worker.moveToThread(self._thread)

        # 在启动线程前连接
        self._thread.started.connect(self._worker.run)
        self._worker.result_ready.connect(self._on_result)   # AutoConnection → 队列连接
        self._worker.finished.connect(self._thread.quit)
        self._worker.finished.connect(self._worker.deleteLater)
        self._thread.finished.connect(self._thread.deleteLater)

        self._thread.start()
```

`moveToThread` + `AutoConnection` 意味着 `result_ready` 自动成为队列连接，使得从槽中安全更新 UI 控件成为可能。

### 断开连接（Disconnecting）

```python
# 断开特定连接
button.clicked.disconnect(self._on_click)

# 断开连接到特定槽的所有连接
button.clicked.disconnect()

# Python：对象删除时自动处理断开连接
# C++：使用 QMetaObject::Connection 句柄进行手动控制
```

在 Python 中，当接收对象被销毁时，对 живых 对象方法的连接会自动清理。对 lambda 和自由函数的连接不会——需要显式断开。

### 调试断开的信号（Debugging Disconnected Signals）

当信号没有触发时，检查清单：
1. 确认发出信号的对象仍然存活（没有被过早垃圾回收）
2. 验证 `connect()` 被调用且返回成功
3. 检查信号类型是否匹配 —— 如果传递 `str`，`Signal(int)` 不会触发
4. 对于 C++：验证 `Q_OBJECT` 存在且 `moc` 已运行（添加后重新构建）
5. 对于跨线程：验证 `moveToThread` 在线程启动之前发生
6. 添加调试连接：`signal.connect(lambda *args: print("FIRED", args))`

### 重载信号（PyQt6 / C++）

当信号有多个重载时，使用下标语法：
```python
# 仅 PyQt6 —— PySide6 自动处理
from PyQt6.QtWidgets import QSpinBox
spin_box.valueChanged[int].connect(self._on_value)
```
