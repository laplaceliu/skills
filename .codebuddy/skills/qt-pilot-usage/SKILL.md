---
name: qt-pilot-usage
description: >
  当用户要求"可视化测试"、"测试 GUI"、"无头测试"、"测试正在运行的应用"、"与 UI 交互"、"截取应用截图"、"点击组件"、"查找组件"、"测试 UI 行为"、"Qt Pilot"、"无头启动应用"或"测试用户所见"时使用此技能。
  涵盖 Qt Pilot MCP 服务器的 15 个工具，用于 Qt/PySide6 应用的 AI 驱动无头 GUI 测试。
  同时适用于："Xvfb"、"自动化 UI"、"视觉回归"、"捕获应用截图"。
---

# Qt Pilot 使用指南

Qt Pilot 是一个捆绑的 MCP 服务器，允许 Claude 启动、交互并可视化测试 PySide6 Qt 应用程序 — 无需物理显示器。它使用 Xvfb（X Virtual Framebuffer）进行无头渲染，并通过 Unix socket 与测试 harness 通信。

使用 `/qt:visual` 启动可视化测试会话。

## 架构

```
Claude (MCP tools)
       ↓
Qt Pilot MCP server (mcp/qt-pilot/main.py)
       ↓  (Unix socket)
Qt Pilot Harness (runs inside Xvfb)
       ↓
Target Qt/PySide6 Application
```

harness 在虚拟显示中启动，导入应用程序，并将组件交互暴露回 MCP 服务器。

## 前置条件

- **Xvfb** 已安装（`Xvfb` 二进制文件在 PATH 中）。运行 `scripts/check-prerequisites.sh` 验证。
- 应用程序组件必须通过 `setObjectName()` 设置**对象名称**才能通过名称定位。
- 应用程序必须使用 `QApplication`（或 `QGuiApplication`）— 而不仅仅是裸 Qt 导入。

## 设置对象名称（大多数工具的必需步骤）

如果没有对象名称，只有基于坐标的交互（`click_at`）和 `list_all_widgets` 可用。为所有交互元素添加名称：

```python
# Python/PySide6
self.calculate_btn = QPushButton("Calculate")
self.calculate_btn.setObjectName("calculate_btn")

self.result_label = QLabel("")
self.result_label.setObjectName("result_label")

self.input_field = QLineEdit()
self.input_field.setObjectName("input_field")
```

```cpp
// C++ 等效
QPushButton *btn = new QPushButton("Calculate");
btn->setObjectName("calculate_btn");
```

## 可用的 MCP 工具（共 15 个）

**完整的参数类型、返回模式和错误处理** — 参见 [references/mcp-tools-reference.md](references/mcp-tools-reference.md)。

按类别快速参考：
- **应用生命周期**：`launch_app`、`get_app_status`、`wait_for_idle`、`close_app`
- **发现**：`find_widgets`、`list_all_widgets`、`get_widget_info`、`list_actions`
- **命名交互**（需要 `setObjectName`）：`click_widget`、`hover_widget`、`type_text`、`press_key`、`trigger_action`
- **坐标交互**：`click_at`
- **视觉捕获**：`capture_screenshot`

## 标准工作流程

### 1. 启动应用

```
launch_app(script_path="/path/to/project/main.py")
# 或模块模式：
launch_app(module="myapp.main", working_dir="/path/to/project")
```

继续之前等待 `success: true`。如果 `success: false`，检查 `get_app_status` 中的 `stderr`。

### 2. 发现组件

```
find_widgets("*")            → 列出所有命名组件
list_all_widgets()           → 列出所有组件（包括未命名的，含坐标）
list_actions()               → 列出所有菜单/工具栏操作
```

在编写测试场景之前使用发现功能 — 它揭示了实际可用的内容。

### 3. 交互

```
click_widget("calculate_btn")
wait_for_idle()              → 让 Qt 处理点击事件
type_text("42", widget_name="input_field")
press_key("Enter")
```

始终在触发异步处理或动画的操作后调用 `wait_for_idle()`。

### 4. 验证状态

```
get_widget_info("result_label")   → 检查文本、可见性、启用状态
capture_screenshot()              → 视觉确认
```

### 5. 关闭

```
close_app()
```

## 典型可视化测试会话

```
1. launch_app(script_path="main.py")
2. find_widgets("*")                    → 发现组件名称
3. click_widget("open_file_btn")
4. wait_for_idle()
5. capture_screenshot() → 保存到 tests/reports/
6. get_widget_info("file_path_label")   → 验证文件已加载
7. type_text("42", widget_name="amount_input")
8. click_widget("calculate_btn")
9. wait_for_idle()
10. get_widget_info("result_display")   → 断言结果
11. capture_screenshot() → 记录最终状态
12. close_app()
```

## 常见失败模式

| 症状 | 可能原因 | 修复 |
|---|---|---|
| `launch_app` 返回 `success: false` | 应用导入错误，缺少依赖项 | 检查 `get_app_status` 中的 `stderr` |
| 组件按名称找不到 | 未调用 `setObjectName()` | 为组件添加名称；使用 `list_all_widgets` 获取坐标 |
| 连接被拒绝 | 应用启动后崩溃 | 调用 `get_app_status` 查看退出码和 `stderr` |
| 点击无效 | 事件尚未处理 | 点击后添加 `wait_for_idle()` |
| 截图是黑的 | Xvfb 未运行 / 显示未设置 | 使用 `scripts/check-prerequisites.sh` 检查前置条件 |

## 编写 Markdown 测试报告

`gui-tester` agent 将报告保存到 `tests/reports/gui-YYYY-MM-DD-HH-MM.md`。

**完整报告格式和模板** — 参见 [references/test-report-template.md](references/test-report-template.md)。

## 其他资源

- **`references/mcp-tools-reference.md`** — 所有 15 个 MCP 工具的完整参数类型、返回模式和错误处理

## 示例

- **`examples/visual_test_session.py`** — 完整 Qt Pilot 会话的带注释演练：启动 → 发现 → 交互 → 验证 → 截图 → 关闭 → 报告
