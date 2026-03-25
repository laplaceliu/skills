---
name: qt-model-view
description: >
  Qt 模型/视图架构（Model/View Architecture）— QAbstractItemModel、表格/列表/树视图、项目代理（item delegates）和代理模型（proxy models）。适用于：显示表格数据、构建带自定义项目的列表、实现树结构、创建可排序/可筛选的表格，或编写自定义项目代理。

  触发词："QAbstractItemModel"、"table view"、"list model"、"QTableView"、"QListView"、"tree view"、"item delegate"、"sort table"、"filter model"、"QSortFilterProxyModel"、"custom model"、"model data"
version: 1.0.0
---

## Qt 模型/视图架构（Model/View Architecture）

### 架构概述

```
数据源 ──→ 模型 ──→ [代理模型] ──→ 视图 ──→ 代理（渲染单元格）
                ↕                            ↕
             QAbstractItemModel         QAbstractItemView
```

将数据（模型）与呈现（视图）分离。代理负责每个单元格的绘制和编辑。代理模型在不修改源模型的情况下叠加转换（排序、筛选）。

### 选择模型基类

| 基类 | 适用场景 |
|------------|-------------|
| `QStringListModel` | 简单的字符串列表 |
| `QStandardItemModel` | 快速原型或小数据集 |
| `QAbstractListModel` | 单列自定义列表 |
| `QAbstractTableModel` | 自定义表格（行 × 列） |
| `QAbstractItemModel` | 带父/子关系的树结构 |

对于任何非简单的场景，应子类化 `QAbstractTableModel` 或 `QAbstractListModel` — `QStandardItemModel` 对大数据集性能较差，且可测试性不佳。

### 自定义表格模型

```python
from PySide6.QtCore import QAbstractTableModel, QModelIndex, Qt
from PySide6.QtGui import QColor

class PersonTableModel(QAbstractTableModel):
    HEADERS = ["Name", "Age", "Email"]

    def __init__(self, data: list[dict], parent=None) -> None:
        super().__init__(parent)
        self._data = data

    # --- 必须重写的方法 ---

    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:
        return 0 if parent.isValid() else len(self._data)

    def columnCount(self, parent: QModelIndex = QModelIndex()) -> int:
        return 0 if parent.isValid() else len(self.HEADERS)

    def data(self, index: QModelIndex, role: int = Qt.ItemDataRole.DisplayRole) -> object:
        if not index.isValid():
            return None
        row, col = index.row(), index.column()
        item = self._data[row]

        match role:
            case Qt.ItemDataRole.DisplayRole:
                return str(item[self.HEADERS[col].lower()])
            case Qt.ItemDataRole.BackgroundRole if item.get("active") is False:
                return QColor("#f5f5f5")
            case Qt.ItemDataRole.ToolTipRole:
                return f"Row {row}: {item}"
            case _:
                return None

    def headerData(self, section: int, orientation: Qt.Orientation, role: int = Qt.ItemDataRole.DisplayRole) -> object:
        if role == Qt.ItemDataRole.DisplayRole and orientation == Qt.Orientation.Horizontal:
            return self.HEADERS[section]
        return None

    # --- 支持数据修改 ---

    def setData(self, index: QModelIndex, value: object, role: int = Qt.ItemDataRole.EditRole) -> bool:
        if not index.isValid() or role != Qt.ItemDataRole.EditRole:
            return False
        self._data[index.row()][self.HEADERS[index.column()].lower()] = value
        self.dataChanged.emit(index, index, [role])
        return True

    def flags(self, index: QModelIndex) -> Qt.ItemFlag:
        base = super().flags(index)
        return base | Qt.ItemFlag.ItemIsEditable

    # --- 批量更新（正确的重置模式）---

    def replace_all(self, new_data: list[dict]) -> None:
        self.beginResetModel()
        self._data = new_data
        self.endResetModel()

    def append_row(self, item: dict) -> None:
        pos = len(self._data)
        self.beginInsertRows(QModelIndex(), pos, pos)
        self._data.append(item)
        self.endInsertRows()
```

始终使用 `begin*/end*` 方法（如 `beginInsertRows`、`beginRemoveRows`、`beginResetModel`）包裹数据修改操作。跳过这些调用会导致视图与模型失去同步。

### 将模型连接到视图

```python
from PySide6.QtWidgets import QTableView

model = PersonTableModel(people_data)
view = QTableView()
view.setModel(model)

# 调优
view.horizontalHeader().setStretchLastSection(True)
view.setSelectionBehavior(QTableView.SelectionBehavior.SelectRows)
view.setSortingEnabled(True)   # 自定义模型需要 QSortFilterProxyModel
view.resizeColumnsToContents()
```

### 使用 QSortFilterProxyModel 进行排序和筛选

```python
from PySide6.QtCore import QSortFilterProxyModel, Qt

source_model = PersonTableModel(data)
proxy = QSortFilterProxyModel()
proxy.setSourceModel(source_model)
proxy.setFilterCaseSensitivity(Qt.CaseSensitivity.CaseInsensitive)
proxy.setFilterKeyColumn(0)   # 在"Name"列上筛选

view.setModel(proxy)
view.setSortingEnabled(True)

# 从搜索框动态筛选
# setFilterRegularExpression 是新代码的首选（内部使用 QRegularExpression）
search_box.textChanged.connect(proxy.setFilterRegularExpression)

# 要高效修改多个筛选参数，使用 beginFilterChange/endFilterChange
# 而不是在每次更改后调用 invalidateFilter()
```

要实现自定义筛选逻辑，请子类化 `QSortFilterProxyModel` 并重写 `filterAcceptsRow`。

### 自定义项目代理（Item Delegate）

使用代理来渲染非文本数据（进度条、图标、自定义组件）：

```python
from PySide6.QtWidgets import QStyledItemDelegate, QStyleOptionViewItem, QApplication
from PySide6.QtGui import QPainter
from PySide6.QtCore import QRect, Qt

class ProgressDelegate(QStyledItemDelegate):
    def paint(self, painter: QPainter, option: QStyleOptionViewItem, index: QModelIndex) -> None:
        value = index.data(Qt.ItemDataRole.DisplayRole)
        if not isinstance(value, int):
            super().paint(painter, option, index)
            return
        # 使用样式绘制进度条
        opt = QStyleOptionProgressBar()
        opt.rect = option.rect.adjusted(2, 4, -2, -4)
        opt.minimum = 0
        opt.maximum = 100
        opt.progress = value
        opt.text = f"{value}%"
        opt.textVisible = True
        QApplication.style().drawControl(QStyle.ControlElement.CE_ProgressBar, opt, painter)

view.setItemDelegateForColumn(2, ProgressDelegate(view))
```

### 关键规则

- 永远不要直接从模型外部访问 `self._data` — 应始终通过模型 API
- `rowCount()` 和 `columnCount()` 在 `parent.isValid()` 时必须返回 0（Qt 树契约，即使对表格也适用）
- `dataChanged` 必须使用精确的更改索引范围发出 — 不必要地发出整个模型会导致完全视图重绘
- 对于大数据集（>10k 行），考虑通过 `canFetchMore()` / `fetchMore()` 实现懒加载
