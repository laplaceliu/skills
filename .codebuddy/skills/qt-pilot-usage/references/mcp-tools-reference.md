# Qt Pilot MCP 工具参考

捆绑的 Qt Pilot MCP 服务器 (`mcp/qt-pilot/main.py`) 暴露的所有 15 个工具。

## 应用生命周期

### launch_app

通过 Xvfb 无头启动 PySide6 应用程序。

```json
{
  "tool": "launch_app",
  "arguments": {
    "script_path": "/abs/path/to/main.py",
    "module": "myapp.main",
    "working_dir": "/abs/path/to/project",
    "python_paths": ["/extra/path"],
    "timeout": 10
  }
}
```

- 使用 `script_path` **或** `module` — 不要两者同时使用。
- `module` 模式需要 `working_dir`。
- `python_paths` 添加到 harness 内的 `sys.path` — 对 monorepos 有用。
- `timeout`: 等待应用窗口出现的时间 (秒，默认 10)。

返回值:
```json
{"success": true, "message": "App launched successfully", "socket_path": "/tmp/qt_gui_tester_xxx.sock", "display": ":99"}
```

### get_app_status

检查应用是否仍在运行，并获取任何 stderr 输出。

返回值:
```json
{
  "running": true,
  "exit_code": null,
  "stderr": "",
  "display": ":99",
  "socket_path": "/tmp/qt_gui_tester_xxx.sock"
}
```

如果 `running: false`，`exit_code` 和 `stderr` 解释应用停止的原因。当其他工具调用返回"App has exited"错误时检查此。

### wait_for_idle

等待 Qt 事件队列排空 — 在任何触发异步处理、动画或信号链的操作之后调用。

```json
{"tool": "wait_for_idle", "arguments": {"timeout": 5.0}}
```

返回 `{"success": true, "message": "App is idle"}` 或超时返回 `{"success": false, "message": "Wait failed"}`。

### close_app

尝试优雅关闭 (发送 quit 命令)，然后终止 Xvfb。

返回值: `{"success": true, "message": "App closed"}`

---

## 组件发现

### find_widgets

列出匹配 glob 模式的有名称组件。

```json
{"tool": "find_widgets", "arguments": {"name_pattern": "*btn*"}}
```

返回值:
```json
{
  "success": true,
  "count": 3,
  "widgets": [
    {"name": "calculate_btn", "type": "QPushButton"},
    {"name": "clear_btn", "type": "QPushButton"},
    {"name": "cancel_btn", "type": "QPushButton"}
  ]
}
```

使用 `"*"` 列出所有有名称的组件。组件名称是通过 `setObjectName()` 设置的值。

### list_all_widgets

列出所有组件，包括无名称的组件，并提供屏幕坐标。

```json
{"tool": "list_all_widgets", "arguments": {"include_invisible": false}}
```

返回值:
```json
{
  "success": true,
  "count": 12,
  "widgets": [
    {
      "name": "calculate_btn",
      "type": "QPushButton",
      "text": "Calculate",
      "x": 120, "y": 45, "width": 80, "height": 30,
      "visible": true,
      "enabled": true
    }
  ]
}
```

对于没有设置 `setObjectName()` 的应用使用此 — 使用 `click_at` 通过坐标交互。

### get_widget_info

获取特定有名称组件的详细信息。

```json
{"tool": "get_widget_info", "arguments": {"widget_name": "result_label"}}
```

返回值:
```json
{
  "success": true,
  "info": {
    "name": "result_label",
    "type": "QLabel",
    "text": "42.0",
    "x": 10, "y": 80, "width": 200, "height": 24,
    "visible": true,
    "enabled": true,
    "checked": null
  }
}
```

`text` 字段适用于 QLabel、QPushButton、QLineEdit、QCheckBox。`checked` 适用于 QCheckBox、QRadioButton。

### list_actions

列出应用程序中注册的所有 QAction (菜单、工具栏、快捷键)。

返回值:
```json
{
  "success": true,
  "count": 5,
  "actions": [
    {
      "name": "action_save",
      "text": "Save",
      "shortcut": "Ctrl+S",
      "enabled": true,
      "checked": false
    }
  ]
}
```

---

## 有名称组件交互

### click_widget

```json
{"tool": "click_widget", "arguments": {"widget_name": "calculate_btn", "button": "left"}}
```

`button`: `"left"` (默认)、`"right"` 或 `"middle"`。

### hover_widget

```json
{"tool": "hover_widget", "arguments": {"widget_name": "tooltip_target"}}
```

用于测试工具提示显示或悬停触发行为。

### type_text

```json
{"tool": "type_text", "arguments": {"text": "hello world", "widget_name": "input_field"}}
```

`widget_name` 是可选的 — 如果省略则输入到当前焦点的组件。发送单独的按键事件，而非剪贴板粘贴，因此输入掩码和验证器会生效。

### press_key

```json
{
  "tool": "press_key",
  "arguments": {
    "key": "Return",
    "modifiers": ["Ctrl", "Shift"]
  }
}
```

键名: `"Return"`、`"Escape"`、`"Tab"`、`"Backspace"`、`"Delete"`、`"Space"`、`"F1"`–`"F12"`、`"Up"`、`"Down"`、`"Left"`、`"Right"`、`"Home"`、`"End"`、单个字符 `"A"`–`"Z"`、`"0"`–`"9"`。

修饰符: `"Ctrl"`、`"Shift"`、`"Alt"`、`"Meta"` (Meta = Windows 键 / macOS 上的 Cmd 键)。

### trigger_action

直接触发 QAction 而无需导航菜单 — 用于测试菜单项正确工作。

```json
{"tool": "trigger_action", "arguments": {"action_name": "action_save"}}
```

Action 名称来自 QAction 上的 `setObjectName()`，或来自 `list_actions`。

---

## 坐标交互

### click_at

在屏幕坐标处点击。当组件没有对象名称时使用。

```json
{"tool": "click_at", "arguments": {"x": 150, "y": 87, "button": "left"}}
```

返回值:
```json
{"success": true, "message": "Clicked at (150, 87) on QPushButton"}
```

首先从 `list_all_widgets` 获取坐标。

---

## 可视捕获

### capture_screenshot

```json
{"tool": "capture_screenshot", "arguments": {"output_path": "/tmp/screenshot_001.png"}}
```

`output_path` 是可选的 — 如果省略则创建临时文件。

返回值:
```json
{"success": true, "path": "/tmp/screenshot_001.png", "message": "Screenshot saved to /tmp/screenshot_001.png"}
```

Claude 然后可以读取图像文件来直观检查 UI 状态。

---

## 错误响应模式

所有工具调用在失败时返回 `success: false`:

```json
{"success": false, "message": "Widget 'calculate_btn' not found"}
{"success": false, "error": "App has exited (code: 1)\nstderr: ..."}
```

当 `success: false` 时:
1. 检查 `message` 或 `error` 字段
2. 调用 `get_app_status` 查看应用是否崩溃
3. 调用 `find_widgets("*")` 验证组件名称
4. 如果组件名称未出现在 find_widgets 中，调用 `list_all_widgets`
