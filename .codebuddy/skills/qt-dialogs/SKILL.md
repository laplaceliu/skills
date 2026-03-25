---
name: qt-dialogs
description: >
  Qt 对话框模式 — QDialog、QMessageBox、QFileDialog、QInputDialog 以及自定义模态/非模态对话框。当需要创建确认提示、文件选择器、设置对话框、自定义数据输入对话框或向导式多步对话框时使用此技能。

  触发短语："dialog"、"QMessageBox"、"QFileDialog"、"QInputDialog"、"modal"、"modeless"、"settings dialog"、"confirm dialog"、"custom dialog"、"file picker"、"wizard"、"popup"
version: 1.0.0
---

## Qt 对话框模式

### QMessageBox — 标准提示

```python
from PySide6.QtWidgets import QMessageBox

# 确认对话框
def confirm_delete(parent, item_name: str) -> bool:
    result = QMessageBox.question(
        parent,
        "Confirm Delete",
        f"Delete '{item_name}'? This cannot be undone.",
        QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No,
        QMessageBox.StandardButton.No,   # 默认按钮
    )
    return result == QMessageBox.StandardButton.Yes

# 错误
QMessageBox.critical(parent, "Error", f"Failed to save: {error}")

# 警告
QMessageBox.warning(parent, "Warning", "File already exists. Overwrite?")

# 信息
QMessageBox.information(parent, "Done", "Export completed successfully.")

# 自定义按钮
msg = QMessageBox(parent)
msg.setWindowTitle("Unsaved Changes")
msg.setText("You have unsaved changes.")
msg.setInformativeText("Do you want to save before closing?")
save_btn = msg.addButton("Save", QMessageBox.ButtonRole.AcceptRole)
discard_btn = msg.addButton("Discard", QMessageBox.ButtonRole.DestructiveRole)
msg.addButton(QMessageBox.StandardButton.Cancel)
msg.exec()
if msg.clickedButton() is save_btn:
    self._save()
elif msg.clickedButton() is discard_btn:
    pass  # 丢弃
# 否则：取消 — 不做任何事
```

### QFileDialog — 文件和目录选择器

```python
from PySide6.QtWidgets import QFileDialog
from pathlib import Path

# 打开单个文件
path, _ = QFileDialog.getOpenFileName(
    parent,
    "Open File",
    str(Path.home()),
    "CSV Files (*.csv);;Text Files (*.txt);;All Files (*)",
)
if path:
    self._load(Path(path))

# 打开多个文件
paths, _ = QFileDialog.getOpenFileNames(parent, "Select Images", "", "Images (*.png *.jpg *.svg)")

# 保存文件
path, _ = QFileDialog.getSaveFileName(
    parent, "Save As", "export.csv", "CSV (*.csv)"
)
if path:
    self._export(Path(path))

# 选择目录
directory = QFileDialog.getExistingDirectory(parent, "Select Output Folder")
```

过滤器字符串格式为 `"Description (*.ext *.ext2);;Description2 (*.ext3)"`。

### 自定义 QDialog

```python
from PySide6.QtWidgets import (
    QDialog, QDialogButtonBox, QFormLayout, QLineEdit, QVBoxLayout
)
from PySide6.QtCore import Qt

class AddPersonDialog(QDialog):
    def __init__(self, parent=None) -> None:
        super().__init__(parent)
        self.setWindowTitle("Add Person")
        self.setModal(True)
        self.setMinimumWidth(300)
        self._setup_ui()

    def _setup_ui(self) -> None:
        layout = QVBoxLayout(self)

        form = QFormLayout()
        self._name_edit = QLineEdit()
        self._name_edit.setPlaceholderText("Full name")
        self._email_edit = QLineEdit()
        self._email_edit.setPlaceholderText("email@example.com")
        form.addRow("Name:", self._name_edit)
        form.addRow("Email:", self._email_edit)
        layout.addLayout(form)

        # 标准确定/取消按钮
        buttons = QDialogButtonBox(
            QDialogButtonBox.StandardButton.Ok | QDialogButtonBox.StandardButton.Cancel
        )
        buttons.accepted.connect(self._on_accept)
        buttons.rejected.connect(self.reject)
        layout.addWidget(buttons)

    def _on_accept(self) -> None:
        if not self._name_edit.text().strip():
            QMessageBox.warning(self, "Validation", "Name is required.")
            return
        self.accept()   # 关闭对话框并返回 QDialog.Accepted

    def name(self) -> str:
        return self._name_edit.text().strip()

    def email(self) -> str:
        return self._email_edit.text().strip()

# 用法
dialog = AddPersonDialog(self)
if dialog.exec() == QDialog.DialogCode.Accepted:
    self._model.add_person(dialog.name(), dialog.email())
```

使用 `QDialogButtonBox` 获取标准按钮 — 它遵守平台按钮顺序约定（OK/取消 vs 取消/OK）。

### 模态 vs 非模态

```python
# 模态 — 阻止对父窗口的输入
dialog.setModal(True)
dialog.exec()      # 阻塞直到关闭

# 非模态 — 用户可以与父窗口交互
dialog.setModal(False)
dialog.show()      # 非阻塞
dialog.raise_()    # 带到前面
dialog.activateWindow()
```

对于非模态对话框，请保留引用以防止垃圾回收：

```python
self._settings_dialog = SettingsDialog(self)
self._settings_dialog.show()
```

### 设置对话框模式

设置对话框应该实时应用更改（更改时）或在明确点击确定时应用：

```python
class SettingsDialog(QDialog):
    settings_changed = Signal(dict)

    def __init__(self, settings: dict, parent=None) -> None:
        super().__init__(parent)
        self._original = dict(settings)
        self._current = dict(settings)
        self._setup_ui(settings)

    def _on_change(self) -> None:
        self._current["theme"] = self._theme_combo.currentText()
        self.settings_changed.emit(self._current)   # 实时预览

    def reject(self) -> None:
        self.settings_changed.emit(self._original)  # 取消时恢复
        super().reject()
```
