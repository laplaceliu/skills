# Python pytest-qt 参考

## 安装

```bash
pip install pytest pytest-qt
# 对于 PySide6 特别:
pip install pytest pytest-qt PySide6
```

在配置中指定 Qt 绑定:
```ini
# pytest.ini
[pytest]
qt_api = pyside6
```

## qtbot Fixture API

`qtbot` 是核心 fixture。它管理 `QApplication` 实例并确保每个测试后清理组件。

### 组件注册

始终注册要测试的组件以确保清理:

```python
def test_something(qtbot):
    widget = MyWidget()
    qtbot.addWidget(widget)  # 测试后清理，即使测试失败
    widget.show()
```

### 鼠标模拟

```python
from pytestqt.qtbot import QtBot
from PySide6.QtCore import Qt
from PySide6.QtCore import QPoint

def test_clicks(qtbot: QtBot):
    w = MyWidget()
    qtbot.addWidget(w)
    w.show()

    qtbot.mouseClick(w.button, Qt.MouseButton.LeftButton)
    qtbot.mouseClick(w.button, Qt.MouseButton.LeftButton, pos=QPoint(5, 5))
    qtbot.mouseDClick(w.button, Qt.MouseButton.LeftButton)
    qtbot.mousePress(w.button, Qt.MouseButton.RightButton)
    qtbot.mouseRelease(w.button, Qt.MouseButton.RightButton)
    qtbot.mouseMove(w, pos=QPoint(100, 100))
```

### 键盘模拟

```python
from PySide6.QtCore import Qt

def test_keys(qtbot):
    w = MyWidget()
    qtbot.addWidget(w)
    w.show()

    qtbot.keyClick(w.input, Qt.Key.Key_Return)
    qtbot.keyClicks(w.input, "hello world")
    qtbot.keyPress(w, Qt.Key.Key_Control)
    qtbot.keyRelease(w, Qt.Key.Key_Control)
    qtbot.keyClick(w.input, "a", Qt.KeyboardModifier.ControlModifier)
```

### 信号等待

`waitSignal` 和 `waitSignals` 阻塞直到信号发出或超时到期 (引发 `TimeoutError`):

```python
def test_async_result(qtbot):
    worker = MyWorker()
    qtbot.addWidget(worker)

    # 阻塞直到 result_ready 发出 (最多 2 秒)
    with qtbot.waitSignal(worker.result_ready, timeout=2000) as blocker:
        worker.start()
    assert blocker.args[0] == expected_value

    # 等待多个信号
    with qtbot.waitSignals([worker.started, worker.finished], timeout=5000):
        worker.run()
```

### 等待条件

```python
def test_eventual_state(qtbot):
    w = MyWidget()
    qtbot.addWidget(w)

    w.start_async_operation()
    qtbot.waitUntil(lambda: w.status_label.text() == "Done", timeout=3000)
    assert w.result == expected
```

### 信号录制

```python
from pytestqt.qt_compat import qt_api

def test_signal_emitted_n_times(qtbot):
    w = MyWidget()
    qtbot.addWidget(w)

    with qtbot.waitSignals([w.changed] * 3, timeout=1000):
        w.trigger_three_changes()
```

## conftest.py 模式

### 应用程序 Fixture

```python
# tests/conftest.py
import pytest
from myapp.main_window import MainWindow

@pytest.fixture
def app_window(qtbot):
    """提供完全初始化并显示的 MainWindow。"""
    window = MainWindow()
    qtbot.addWidget(window)
    window.show()
    qtbot.waitExposed(window)  # 等待直到窗口实际可见
    return window

@pytest.fixture
def populated_window(app_window, qtbot):
    """提供加载了示例数据的 MainWindow。"""
    app_window.load_sample_data()
    qtbot.waitUntil(lambda: app_window.is_data_loaded(), timeout=2000)
    return app_window
```

### 临时目录 Fixture

```python
@pytest.fixture
def temp_project(tmp_path):
    """提供带有最小项目结构的临时目录。"""
    (tmp_path / "data").mkdir()
    (tmp_path / "config.json").write_text('{"version": 1}')
    return tmp_path
```

## 测试模型 (QAbstractItemModel)

```python
def test_model_data(qtbot):
    model = MyTableModel()
    qtbot.addWidget(model)  # 非严格必需但是好习惯

    assert model.rowCount() == 0

    model.add_item({"name": "Alice", "age": 30})
    assert model.rowCount() == 1

    idx = model.index(0, 0)
    assert model.data(idx, Qt.ItemDataRole.DisplayRole) == "Alice"
```

## 常见陷阱

**`QApplication` 已存在**: pytest-qt 自动创建一个。永远不要在测试 fixture 中创建 `QApplication` — 会冲突。

**`RuntimeError: wrapped C++ object deleted`**: 组件被垃圾回收，因为 Python 失去了引用。在测试中保持引用或使用 `qtbot.addWidget`。

**信号测试不稳定**: 使用 `waitSignal` 而不是 `assert` + `qWait`。`qWait` 是基于时间的竞态条件; `waitSignal` 是事件驱动的。

**`waitSignal` 超时**: 为慢操作增加超时时间。默认是 1000ms。对文件 I/O 或网络操作使用 `timeout=5000`。

**Headless CI 失败**: 在 CI 环境中设置 `QT_QPA_PLATFORM=offscreen` 或使用 Xvfb。否则测试将失败并显示 `Could not connect to display`。

```yaml
# .github/workflows/test.yml
env:
  QT_QPA_PLATFORM: offscreen
  DISPLAY: ":99"
```

## 参数化模式

```python
import pytest

@pytest.mark.parametrize("value,expected", [
    ("", False),
    ("a", True),
    ("hello world", True),
    ("   ", False),  # 仅空白在我们的验证器中是假的
])
def test_input_validator(qtbot, value, expected):
    validator = InputValidator()
    assert validator.is_valid(value) == expected
```

## 异步测试模式 (Qt 事件循环)

```python
import pytest

@pytest.mark.asyncio
async def test_async_operation(qtbot):
    # 对于不使用 Qt 信号直接相关的协程逻辑
    result = await my_async_function()
    assert result == expected
```

对于 Qt 原生异步 (信号/slot)，优先使用 `waitSignal` 而不是 `asyncio`。
