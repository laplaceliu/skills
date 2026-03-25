---
name: qt-debugging
description: >
  诊断和修复 Qt 应用程序问题 — 崩溃、事件循环问题、widget 渲染失败、段错误和常见运行时错误。当 Qt 崩溃、widget 不显示、事件循环冻结、信号未连接或应用程序意外退出时使用此技能。

  触发短语："Qt error"、"crash"、"segfault"、"widget not showing"、"event loop"、"app exits unexpectedly"、"Qt warning"、"QPainter error"、"assertion failed"、"QObject destroyed"、"application not responding"
version: 1.0.0
---

## Qt 调试

### 诊断方法

1. **阅读完整的 Qt 警告输出** — Qt 在崩溃前会打印可操作的警告
2. **对失败类型进行分类**（参见下面的类别）
3. **隔离** — 用最小测试用例重现
4. **使用 `QT_QPA_PLATFORM=offscreen pytest` 进行修复和验证**

### 启用详细 Qt 输出

```bash
# 显示所有 Qt 调试/警告消息
QT_LOGGING_RULES="*.debug=true" python -m myapp

# 过滤到特定类别
QT_LOGGING_RULES="qt.qpa.*=true;qt.widgets.*=true" python -m myapp

# C++
qputenv("QT_LOGGING_RULES", "*.debug=true");
```

```python
# Python：安装消息处理程序以捕获 Qt 输出
from PySide6.QtCore import qInstallMessageHandler, QtMsgType

def qt_message_handler(mode: QtMsgType, context, message: str) -> None:
    if mode == QtMsgType.QtCriticalMsg or mode == QtMsgType.QtFatalMsg:
        import traceback
        traceback.print_stack()
    print(f"Qt [{mode.name}]: {message}")

qInstallMessageHandler(qt_message_handler)
```

### 常见失败类别

#### Widget 从不显示

- 未在顶级 widget 上调用 `show()`
- 父 widget 未显示（子级继承可见性）
- `setFixedSize(0, 0)` 或零内容边距导致其折叠
- widget 在 `app.exec()` 返回后创建（事件循环退出后）
- `setVisible(False)` 仍然生效

```python
# 诊断
print(widget.isVisible(), widget.size(), widget.parentWidget())
```

#### 访问 Widget 时崩溃/段错误

- Widget 被垃圾回收（Python 在 Qt 完成处理之前删除了 QWidget）
- 常见原因：widget 仅存储在局部变量中，而非 `self._widget`
- 修复：在 `__init__` 中始终将 widgets 赋值给 `self` 属性

```python
# 错误 — 局部变量，GC 可能会收集它
def setup(self):
    btn = QPushButton("Click")   # 可能立即被删除

# 正确
def setup(self):
    self._btn = QPushButton("Click")
```

#### "QObject: Cannot create children for a parent in a different thread"

- 具有父级的 `QObject` 正在非主线程中创建
- 修复：创建时无父级，然后使用 `moveToThread` 或 `deleteLater` 进行清理

#### "QPixmap: Must construct a QGuiApplication before a QPaintDevice"

- `QPixmap`、`QImage` 或 `QIcon` 在 `QApplication` 存在之前创建
- 修复：将所有 Qt 对象构造移动到 `app = QApplication(sys.argv)` 之后

#### "RuntimeError: Internal C++ object (QWidget) already deleted"

- 在 Qt 删除底层 C++ 对象后访问 Python 包装器
- 与 `deleteLater()` 一起常见 — 删除是异步发生的
- 修复：检查 `sip.isdeleted(widget)`（PyQt6）或使用 `QPointer` 模式

#### 事件循环冻结/UI 无响应

- 主线程上有阻塞调用（I/O、`time.sleep`、重计算）
- 修复：移动到 `QRunnable`/`QThread`（参见 `qt-threading` 技能）

```python
# 快速诊断：添加到慢代码路径
from PySide6.QtCore import QCoreApplication
QCoreApplication.processEvents()  # 临时解除阻塞 — 确认事件循环卡住
```

#### 信号已连接但从未触发

1. 验证发送者对象仍然存活
2. 添加调试连接：`signal.connect(lambda *a: print("FIRED", a))`
3. 检查信号类型签名是否匹配 — 如果你发射的是 `Signal(str)` 等价物，`Signal(int)` 不会触发
4. 对于 C++：验证 `Q_OBJECT` 存在且 moc 在上次更改后运行

### 内存/资源泄漏检测

```python
# 跟踪活动的 QObject 计数
from PySide6.QtCore import QObject
# 无内置功能 — 使用 objgraph
import objgraph
objgraph.show_most_common_types(limit=20)
objgraph.show_growth()
```

### 有用的诊断模式

```python
# 转储完整的 widget 树
def dump_widget_tree(widget, indent=0):
    print("  " * indent + repr(widget))
    for child in widget.children():
        if isinstance(child, QWidget):
            dump_widget_tree(child, indent + 1)

# 检查事件循环是否正在运行
from PySide6.QtCore import QEventLoop
print(QCoreApplication.instance().loopLevel())  # 如果 exec() 正在运行则 > 0

# 强制同步绘制（调试绘制问题）
widget.repaint()  # 同步 vs update() 延迟
```

### QSS/样式调试

```python
# 打印 widget 的有效样式表
print(widget.styleSheet())

# 检查样式规则是否正在应用
# 添加唯一的背景以进行隔离
widget.setStyleSheet("background: lime;")   # 可见指示器

# 属性更改后强制重新评估
widget.style().unpolish(widget)
widget.style().polish(widget)
widget.update()
```

### C++ 特定

```cpp
// 启用 ASAN 以检测内存错误
// cmake -DCMAKE_CXX_FLAGS="-fsanitize=address" ...

// Qt 调试输出
qDebug() << "Widget size:" << widget->size();
qWarning() << "Unexpected state:" << state;

// 打印所有对象属性
qDebug() << widget->metaObject()->className();
```
