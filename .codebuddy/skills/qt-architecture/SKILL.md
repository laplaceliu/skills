---
name: qt-architecture
description: >
  Qt 应用程序架构、项目结构和入口点模式，适用于 PySide6、PyQt6 和 C++/Qt。当需要构建 Qt 应用结构、设置 QApplication、设计主窗口、在 MVC/MVP 模式之间选择、组织 src 布局，或决定如何在 GUI 应用中分离关注点时使用此技能。

  触发短语："structure my Qt app"、"QApplication setup"、"app entry point"、"Qt project layout"、"organize Qt code"、"Qt MVC"、"Qt MVP"、"main window architecture"、"new Qt project"
version: "1.0.0"
---

## Qt 应用程序架构

### 入口点模式

每个 Qt 应用程序都需要恰好一个 `QApplication`（widgets）或 `QGuiApplication`（仅 QML）实例。在任何 widgets 之前创建它。

**Python/PySide6 标准入口点：**
```python
# src/myapp/__main__.py
import sys
from PySide6.QtWidgets import QApplication
from myapp.ui.main_window import MainWindow

def main() -> None:
    app = QApplication(sys.argv)
    app.setApplicationName("MyApp")
    app.setOrganizationName("MyOrg")
    app.setOrganizationDomain("myorg.com")
    window = MainWindow()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
```

使用 `__main__.py` 可以启用 `python -m myapp` 调用。在创建任何 widgets 之前设置 `applicationName` 和 `organizationName` —— 这些值会注入 `QSettings`。

**C++/Qt 标准 main.cpp：**
```cpp
#include <QApplication>
#include "mainwindow.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    app.setApplicationName("MyApp");
    app.setOrganizationName("MyOrg");
    MainWindow window;
    window.show();
    return app.exec();
}
```

### 项目布局（Python/PySide6）

使用 `src` 布局来防止从项目根目录意外导入：

```
my-qt-app/
├── src/
│   └── myapp/
│       ├── __init__.py
│       ├── __main__.py          # 入口点
│       ├── ui/
│       │   ├── __init__.py
│       │   ├── main_window.py   # QMainWindow 子类
│       │   ├── dialogs/         # QDialog 子类
│       │   └── widgets/         # 自定义 QWidget 子类
│       ├── models/              # 数据模型（非 Qt）
│       ├── services/            # 业务逻辑、I/O
│       └── resources/           # .qrc 编译输出
├── tests/
│   ├── conftest.py
│   └── test_*.py
├── resources/
│   ├── icons/
│   └── resources.qrc
├── pyproject.toml
└── .qt-test.json                # qt-test-suite 配置
```

保持 `ui/`、`models/` 和 `services/` 分离。UI 代码不应包含业务逻辑。

### QMainWindow 结构

```python
# src/myapp/ui/main_window.py
from PySide6.QtWidgets import QMainWindow, QWidget, QVBoxLayout
from PySide6.QtCore import Qt

class MainWindow(QMainWindow):
    def __init__(self, parent: QWidget | None = None) -> None:
        super().__init__(parent)
        self.setWindowTitle("MyApp")
        self.setMinimumSize(800, 600)
        self._setup_ui()
        self._setup_menu()
        self._connect_signals()

    def _setup_ui(self) -> None:
        """构建中央部件和布局。"""
        central = QWidget()
        self.setCentralWidget(central)
        layout = QVBoxLayout(central)
        # 在此处将 widgets 添加到布局

    def _setup_menu(self) -> None:
        """构建菜单栏和动作。"""
        pass

    def _connect_signals(self) -> None:
        """连接所有信号与槽（signal→slot）连接。"""
        pass
```

将 `_setup_ui`、`_setup_menu` 和 `_connect_signals` 分离为独立的方法。这使得每个职责都易于查找和测试。

### 架构模式

**MVP（Model-View-Presenter，模型-视图-呈现器）** — 适用于可测试的 Qt 应用程序：
- **Model（模型）**：纯 Python 类，不导入 Qt。持有数据和业务逻辑。
- **View（视图）**：QWidget 子类。发出用户操作的信号；接收要显示的数据。
- **Presenter（呈现器）**：在 Model 和 View 之间进行协调。包含决策逻辑。可以在没有 Qt 的情况下进行测试。

```python
# Presenter 拥有 view 和 model
class CalculatorPresenter:
    def __init__(self, view: CalculatorView, model: CalculatorModel) -> None:
        self._view = view
        self._model = model
        view.calculate_requested.connect(self._on_calculate)

    def _on_calculate(self, expression: str) -> None:
        result = self._model.evaluate(expression)
        self._view.display_result(result)
```

**MVC** 与 Qt 的信号与槽（signals and slots）系统配合不太自然。MVP 是惯用选择。

**对于简单的应用程序**：直接连接信号与槽是可行的。当需要可单元测试的业务逻辑时再引入 MVP。

### pyproject.toml 配置

```toml
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "myapp"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = ["PySide6>=6.6"]

[project.scripts]
myapp = "myapp.__main__:main"

[tool.hatch.build.targets.wheel]
packages = ["src/myapp"]

[tool.pytest.ini_options]
testpaths = ["tests"]
qt_api = "pyside6"

[tool.pyright]
pythonVersion = "3.11"
include = ["src"]
```

### Qt 项目配置（.qt-test.json）

始终在项目根目录创建此文件以确保 `qt-test-suite` 兼容性：

```json
{
  "project_type": "python",
  "app_entry": "src/myapp/__main__.py",
  "test_dir": "tests/",
  "coverage_source": ["src/myapp"]
}
```

### 关键约束

- 每个进程只有一个 `QApplication` —— 永远不要创建两次或将其放在可能被多次调用的函数内
- 所有 widget 创建必须在 `QApplication` 构建之后进行
- 没有父级的 widget 会成为顶级窗口；始终传递 `parent` 以避免产生孤儿 widgets
- 永远不要将 Qt 对象（QWidget、QObject）存储在模块级全局变量中 —— 延迟销毁会导致段错误
- `app.exec()` 会阻塞直到最后一个窗口关闭；所有应用程序逻辑都通过此循环内的信号与槽运行
