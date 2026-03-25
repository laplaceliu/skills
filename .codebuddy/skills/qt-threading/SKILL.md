---
name: qt-threading
description: >
  Qt 线程模式 —— QThread、QRunnable、QThreadPool，以及 GUI 应用程序的线程安全。适用于运行后台任务、在长时间操作期间保持 UI 响应、管理工作线程、使用线程池，或调试竞态条件和死锁。

  触发词："QThread"、"worker"、"background task"、"thread safety"、"UI freezing"、"long operation"、"QRunnable"、"QThreadPool"、"thread pool"、"concurrent"、"responsive UI"、"blocking the event loop"
version: 1.0.0
---

## Qt 线程（Qt Threading）

### 黄金法则（The Golden Rule）

**永远不要从非主线程更新 UI 控件。** 所有控件操作必须在主（GUI）线程上进行。使用信号将结果从工作线程传回。

### 模式一：Worker 对象 + QThread（适用于有状态 Worker）

将 `QObject` 子类移动到 `QThread`。Worker 的槽在线程的事件循环中执行。

```python
from PySide6.QtCore import QObject, QThread, Signal, Slot

class DataFetcher(QObject):
    """在工作线程中获取数据的工作线程。"""
    result_ready = Signal(dict)
    error_occurred = Signal(str)
    progress = Signal(int)
    finished = Signal()

    def __init__(self, url: str) -> None:
        super().__init__()
        self._url = url
        self._cancelled = False

    @Slot()
    def cancel(self) -> None:
        self._cancelled = True

    @Slot()   # @Slot 必需 —— 通过 thread.started 信号连接
    def fetch(self) -> None:
        """槽 —— 在工作线程中执行。"""
        try:
            for i, chunk in enumerate(stream_data(self._url)):
                if self._cancelled:
                    break
                self.progress.emit(int(i / total * 100))
            self.result_ready.emit(final_data)
        except Exception as e:
            self.error_occurred.emit(str(e))
        finally:
            self.finished.emit()

class MainWindow(QMainWindow):
    def _start_fetch(self, url: str) -> None:
        self._thread = QThread(self)
        self._fetcher = DataFetcher(url)
        self._fetcher.moveToThread(self._thread)

        # 在启动前接线 —— 所有连接都是原子建立的
        self._thread.started.connect(self._fetcher.fetch)
        self._fetcher.result_ready.connect(self._on_result)
        self._fetcher.error_occurred.connect(self._on_error)
        self._fetcher.progress.connect(self._progress_bar.setValue)
        self._fetcher.finished.connect(self._thread.quit)
        self._fetcher.finished.connect(self._fetcher.deleteLater)
        self._thread.finished.connect(self._thread.deleteLater)

        self._thread.start()
        self._cancel_btn.setEnabled(True)

    def _on_result(self, data: dict) -> None:
        """槽 —— 在主线程中执行（AutoConnection → 队列连接）。"""
        self._table.populate(data)
        self._cancel_btn.setEnabled(False)
```

`finished → deleteLater` 链确保 Qt 在完成时清理 worker 和线程对象，防止内存泄漏。

### 模式二：QRunnable + QThreadPool（fire-and-forget 任务）

适用于不需要取消或每实例状态的任务：

```python
from PySide6.QtCore import QRunnable, QThreadPool, QObject, Signal, Slot

class WorkerSignals(QObject):
    """QRunnable 不能直接有信号 —— 使用 QObject 容器。"""
    finished = Signal()
    result = Signal(object)
    error = Signal(str)

class ProcessTask(QRunnable):
    def __init__(self, data: list) -> None:
        super().__init__()
        self.signals = WorkerSignals()
        self._data = data
        self.setAutoDelete(True)   # 池在 run() 后删除任务

    @Slot()   # @Slot 必需 —— 防止从不同线程调用时出现段错误
    def run(self) -> None:
        try:
            result = expensive_computation(self._data)
            self.signals.result.emit(result)
        except Exception as e:
            self.signals.error.emit(str(e))
        finally:
            self.signals.finished.emit()

# 用法
pool = QThreadPool.globalInstance()
task = ProcessTask(my_data)
task.signals.result.connect(self._on_result)
pool.start(task)

# 限制线程数
pool.setMaxThreadCount(4)
```

### 模式三：使用 QTimer 的简单后台任务

适用于不需要单独线程的周期性、轻量级任务：

```python
from PySide6.QtCore import QTimer

# 每 500ms 轮询，不阻塞
self._timer = QTimer(self)
self._timer.timeout.connect(self._check_status)
self._timer.start(500)

# 单次触发 —— 2 秒后触发一次
QTimer.singleShot(2000, self._delayed_init)
```

### 线程安全：共享数据（Thread Safety: Shared Data）

Qt 容器和 Python 对象不是线程安全的。使用互斥锁或队列：

```python
from threading import Lock

class SafeDataStore(QObject):
    data_updated = Signal()

    def __init__(self) -> None:
        super().__init__()
        self._data: list = []
        self._lock = Lock()

    def append(self, item: object) -> None:
        with self._lock:
            self._data.append(item)
        self.data_updated.emit()   # 安全 —— 发射信号是线程安全的

    def snapshot(self) -> list:
        with self._lock:
            return list(self._data)
```

**发射信号是线程安全的。** 当发射器和接收器在不同线程时，`AutoConnection` 自动将槽调用排队。

### 调试线程问题（Debugging Thread Issues）

**UI 冻结（响应卡顿）：** 主线程上正在运行阻塞调用。常见原因：`requests.get()`、`time.sleep()`、大文件 I/O、重计算。移到 `QRunnable` 或工作 `QThread`。

**崩溃并显示 "QObject: Cannot create children for a parent that is in a different thread"：** 在工作线程中创建的 `QObject` 有一个由主线程拥有的父对象。创建无父对象的对象并使用 `moveToThread` 或 `deleteLater`。

**信号发出但槽从未被调用：** 验证 `moveToThread` 在 `start()` 之前发生。验证接收者的线程有正在运行的事件循环（`QThread.exec()` 或 `QThread.start()`）。

**竞态条件：** 在槽中读取可变共享状态时永远不要不加锁。优先使用信号参数传递数据（按值复制）而不是共享可变对象。
