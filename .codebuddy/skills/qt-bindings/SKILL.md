---
name: qt-bindings
description: >
  Python Qt 绑定差异和迁移指南 — PySide6 与 PyQt6 的 API 差异，以及从 PyQt5 迁移到两种现代绑定的路径。当需要在 PySide6 和 PyQt6 之间选择、移植 PyQt5 代码库、处理特定绑定的 API 差异，或编写必须同时兼容两种绑定的代码时使用此技能。

  触发短语："PySide6 vs PyQt6"、"PyQt5 migration"、"binding difference"、"migrate from PyQt5"、"PyQt6 migration"、"PySide6 or PyQt6"、"binding compatibility"、"porting Qt Python"、"LGPL vs GPL"
version: 1.0.0
---

## Python Qt 绑定

### 选择绑定

| 条件 | PySide6 | PyQt6 |
|----------|---------|-------|
| 维护者 | Qt Company（官方） | Riverbank Computing |
| 许可证 | LGPL v3 | GPL v3 / 商业版 |
| 商业使用 | 免费（LGPL） | 需要商业许可证 |
| QML/Qt Quick 支持 | 优秀 | 良好 |
| 类型存根（Type stubs） | 内置 | `PyQt6-stubs`（第三方） |
| `pyqtSignal` / `Signal` | `Signal` | `pySignal` |
| `pyqtSlot` / `Slot` | `Slot` | `pyqtSlot` |
| 获取方式 | pip | pip |

**默认推荐：PySide6** — 官方绑定、LGPL 许可、附带完整的类型存根、更好的 QML 工具。

### API 兼容层

对于必须同时支持两种绑定的代码：
```python
try:
    from PySide6.QtWidgets import QApplication, QPushButton
    from PySide6.QtCore import Signal, Slot
    PYSIDE6 = True
except ImportError:
    from PyQt6.QtWidgets import QApplication, QPushButton
    from PyQt6.QtCore import pyqtSignal as Signal, pyqtSlot as Slot
    PYSIDE6 = False
```

或使用 **`qtpy`** — 由社区维护的抽象层：
```python
from qtpy.QtWidgets import QApplication, QPushButton
from qtpy.QtCore import Signal, Slot
# 适用于 PySide6、PyQt6、PySide2、PyQt5 — 设置 QT_API 环境变量来选择
```

### PySide6 与 PyQt6：关键差异

#### 信号与槽（Signals and Slots）

```python
# PySide6
from PySide6.QtCore import Signal, Slot
class Foo(QObject):
    my_signal = Signal(int)

    @Slot(int)
    def my_slot(self, value: int): ...

# PyQt6
from PyQt6.QtCore import pyqtSignal, pyqtSlot
class Foo(QObject):
    my_signal = pyqtSignal(int)

    @pyqtSlot(int)
    def my_slot(self, value: int): ...
```

#### 枚举访问

两者都需要完全限定的枚举访问（与 Qt5 相比的重大变更）：
```python
# 正确（两种绑定）
Qt.AlignmentFlag.AlignLeft
QSizePolicy.Policy.Expanding
QPushButton.setCheckable(True)

# 错误 — Qt5 风格（不再有效）
Qt.AlignLeft
```

#### exec 方法（PyQt6 重大变更）

```python
# PySide6
app.exec()
dialog.exec()

# PyQt6 — exec() 在 PyQt6 中也能工作（exec_ 已移除）
app.exec()
dialog.exec()
```

两者都使用 `exec()` — 旧的 `exec_()` 变通方法不再需要，也不再适用于 PyQt6。

#### 属性装饰器

```python
# PySide6
from PySide6.QtCore import Property
@Property(int, notify=value_changed)
def value(self) -> int: return self._value

# PyQt6
from PyQt6.QtCore import pyqtProperty
@pyqtProperty(int, notify=value_changed)
def value(self) -> int: return self._value
```

### 从 PyQt5 迁移到 PySide6

**步骤 1：更新导入**

```bash
# 使用 sed 进行批量替换
sed -i 's/from PyQt5\./from PySide6./g' src/**/*.py
sed -i 's/import PyQt5\./import PySide6./g' src/**/*.py
```

**步骤 2：替换信号与槽装饰器**

```python
# PyQt5 → PySide6
pyqtSignal → Signal
pyqtSlot  → Slot
pyqtProperty → Property
```

**步骤 3：修复枚举用法**（PyQt5→PySide6 最常见的破坏性变更）

```python
# PyQt5（短形式）
Qt.AlignLeft          → Qt.AlignmentFlag.AlignLeft
Qt.Horizontal         → Qt.Orientation.Horizontal
QSizePolicy.Expanding → QSizePolicy.Policy.Expanding
Qt.WindowModal        → Qt.WindowModality.WindowModal
```

**步骤 4：修复 exec() 调用** — 移除 `exec_()` 后缀：

```python
app.exec_()   → app.exec()
dialog.exec_() → dialog.exec()
```

**步骤 5：移除已弃用的 Qt5 API**

```python
# 在 Qt6 中已移除
QWidget.show() — 仍然有效
QApplication.setDesktopSettingsAware() — 已移除
QFontDatabase.addApplicationFont() — 仍然有效
```

### 从 PyQt5 迁移到 PyQt6

与 PySide6 迁移相同的步骤，但：

```python
# PyQt5 → PyQt6 信号（保留 pyqt 前缀）
pyqtSignal → pyqtSignal  （不变）
pyqtSlot   → pyqtSlot    （不变）

# 导入变更
from PyQt5.QtWidgets import ... → from PyQt6.QtWidgets import ...
```

枚举变更与 PySide6 相同 — 两种 Qt6 绑定都强制使用完全限定的枚举。

### 从 PySide2 迁移到 PySide6

```python
# 导入
from PySide2. → from PySide6.

# exec_ 移除
.exec_() → .exec()

# 枚举限定（与 PyQt5→PySide6 相同）
```

PySide6 也放弃了 Python 3.6/3.7 支持 — 最低要求是 Python 3.8（推荐 Python 3.11）。

### 类型存根

```bash
# PySide6 附带存根 — 无需额外安装
pip install PySide6

# PyQt6
pip install PyQt6-stubs

# 配置 pyright/mypy
# pyproject.toml
[tool.pyright]
pythonVersion = "3.11"
```
