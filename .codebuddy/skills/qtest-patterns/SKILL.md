---
name: qtest-patterns
description: >
  当用户请求"编写测试"、"添加测试"、"创建 QTest"、"如何测试控件"、"Qt 单元测试"、
  "pytest-qt"、"测试 PySide6 类"、"QML 测试"、"QtQuickTest"、"编写测试用例"、"测试此类"，
  或"生成测试文件"时使用此技能。
  涵盖 C++ QTest、Python pytest-qt 和 QML TestCase 模式，以及 CMake 集成。
  当请求"编写 C++ Qt 测试"、"添加 CMake 测试目标"或"设置 testlib"时也会激活。
---

# Qt 测试模式（Qt Test Patterns）

Qt 测试横跨三个生态系统：**C++ QTest**（原生，零依赖）、**Python pytest-qt**（PySide6 应用程序）和 **QML TestCase**（QML 组件逻辑）。本技能涵盖所有三种方式以及 CMake 集成。

## 选择测试框架

| 场景 | 框架 |
|---|---|
| C++ Qt 类 / 业务逻辑 | C++ QTest（`QObject` 子类 + `QTEST_MAIN`） |
| PySide6 GUI 应用程序 | pytest + pytest-qt（`qtbot` fixture） |
| QML 组件行为 | QtQuickTest（`TestCase` QML 类型） |
| PySide6 非 GUI 逻辑 | pytest（不需要 pytest-qt） |

## Python / PySide6 与 pytest-qt

**完整的 pytest-qt 模式** —— 参阅 [references/python-pytest-qt.md](references/python-pytest-qt.md) 获取完整的 `qtbot` fixture API、信号等待、conftest 模式、模型测试、参数化、异步测试和常见陷阱。

关键配置：
```ini
# pytest.ini
[pytest]
testpaths = tests
qt_api = pyside6
```

## C++ QTest

**完整的 C++ QTest 模式** —— 参阅 [references/cpp-qtest.md](references/cpp-qtest.md) 获取完整的宏参考、`QSignalSpy`、GUI/输入模拟、基准测试宏、输出格式、CMake 模式和故障排除。

关键结构：每个测试类是 `QObject` 子类；私有槽是测试函数；`QTEST_MAIN(ClassName)` + 在文件末尾包含 `#include "test_name.moc"`。

## QML TestCase

**完整的 QML TestCase 模式** —— 参阅 [references/qml-testcase.md](references/qml-testcase.md) 获取完整的断言 API、组件创建、`SignalSpy`、异步/定时器测试、CMake 设置和常见问题。

关键结构：`TestCase` QML 项目；测试函数必须以 `test_` 开头；始终调用 `obj.destroy()` 以防止泄漏。

## 其他资源

参阅此技能 `references/` 目录中的参考文件以获取详细模式：

- **`references/cpp-qtest.md`** —— 完整 QTest 宏参考、`QSignalSpy`、基准测试宏、输出格式
- **`references/python-pytest-qt.md`** —— 完整的 pytest-qt fixture API、异步模式、模型测试、常见陷阱
- **`references/qml-testcase.md`** —— QML TestCase 完整 API、异步信号测试、组件创建模式

工作示例：
- **`examples/test_calculator.py`** —— 带 fixture 的完整 pytest-qt 示例
- **`examples/calculator_test.cpp`** —— 带数据驱动测试的完整 C++ QTest 示例
