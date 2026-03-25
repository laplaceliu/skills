---
name: qt-model-view
description: >
  Qt C++ 模型/视图架构（Model/View Architecture）— QAbstractItemModel、表格/列表/树视图、项目代理（item delegates）和代理模型（proxy models）。适用于：显示表格数据、构建带自定义项目的列表、实现树结构、创建可排序/可筛选的表格，或编写自定义项目代理。

  触发词："QAbstractItemModel"、"table view"、"list model"、"QTableView"、"QListView"、"tree view"、"item delegate"、"sort table"、"filter model"、"QSortFilterProxyModel"、"custom model"、"model data"
version: 1.0.0
---

## Qt C++ 模型/视图架构（Model/View Architecture）

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

```cpp
// persontablemodel.h
#pragma once
#include <QAbstractTableModel>
#include <QModelIndex>
#include <QVariant>
#include <QVector>
#include <QHash>

class PersonTableModel : public QAbstractTableModel {
    Q_OBJECT

public:
    static const QStringList HEADERS;

    explicit PersonTableModel(QObject *parent = nullptr);
    void setData(const QVector<QHash<QString, QString>> &data);

    // --- 必须重写的方法 ---

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index,
                  int role = Qt::ItemDataRole::DisplayRole) const override;

    QVariant headerData(int section,
                        Qt::Orientation orientation,
                        int role = Qt::ItemDataRole::DisplayRole) const override;

    // --- 支持数据修改 ---

    bool setData(const QModelIndex &index,
                 const QVariant &value,
                 int role = Qt::ItemDataRole::EditRole) override;

    Qt::ItemFlags flags(const QModelIndex &index) const override;

    // --- 批量更新（正确的重置模式）---

    void replaceAll(const QVector<QHash<QString, QString>> &newData);
    void appendRow(const QHash<QString, QString> &item);

private:
    QVector<QHash<QString, QString>> m_data;
};

const QStringList PersonTableModel::HEADERS = {"Name", "Age", "Email"};
```

```cpp
// persontablemodel.cpp
#include "persontablemodel.h"

PersonTableModel::PersonTableModel(QObject *parent)
    : QAbstractTableModel(parent)
{}

void PersonTableModel::setData(const QVector<QHash<QString, QString>> &data) {
    m_data = data;
}

int PersonTableModel::rowCount(const QModelIndex &parent) const {
    if (parent.isValid())
        return 0;  // 树结构中，父节点有效时返回 0
    return m_data.size();
}

int PersonTableModel::columnCount(const QModelIndex &parent) const {
    if (parent.isValid())
        return 0;
    return HEADERS.size();
}

QVariant PersonTableModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid())
        return QVariant();

    if (index.row() >= m_data.size())
        return QVariant();

    const auto &item = m_data.at(index.row());
    const QString &key = HEADERS.at(index.column()).toLower();

    switch (role) {
    case Qt::ItemDataRole::DisplayRole:
    case Qt::ItemDataRole::EditRole:
        return item.value(key);
    case Qt::ItemDataRole::BackgroundRole:
        if (item.value("active") == "false")
            return QColor("#f5f5f5");
        break;
    case Qt::ItemDataRole::ToolTipRole:
        return QString("Row %1: %2").arg(index.row()).arg(item.value(key));
    }
    return QVariant();
}

QVariant PersonTableModel::headerData(int section,
                                      Qt::Orientation orientation,
                                      int role) const {
    if (role == Qt::ItemDataRole::DisplayRole
        && orientation == Qt::Orientation::Horizontal) {
        return HEADERS.at(section);
    }
    return QVariant();
}

bool PersonTableModel::setData(const QModelIndex &index,
                               const QVariant &value,
                               int role) {
    if (!index.isValid() || role != Qt::ItemDataRole::EditRole)
        return false;

    if (index.row() >= m_data.size())
        return false;

    QString key = HEADERS.at(index.column()).toLower();
    m_data[index.row()][key] = value.toString();

    emit dataChanged(index, index, {role});
    return true;
}

Qt::ItemFlags PersonTableModel::flags(const QModelIndex &index) const {
    Qt::ItemFlags baseFlags = QAbstractTableModel::flags(index);
    if (index.isValid())
        return baseFlags | Qt::ItemFlag::ItemIsEditable;
    return baseFlags;
}

void PersonTableModel::replaceAll(
        const QVector<QHash<QString, QString>> &newData) {
    beginResetModel();
    m_data = newData;
    endResetModel();
}

void PersonTableModel::appendRow(const QHash<QString, QString> &item) {
    int pos = m_data.size();
    beginInsertRows(QModelIndex(), pos, pos);
    m_data.append(item);
    endInsertRows();
}
```

始终使用 `begin*/end*` 方法（如 `beginInsertRows`、`beginRemoveRows`、`beginResetModel`）包裹数据修改操作。跳过这些调用会导致视图与模型失去同步。

### 将模型连接到视图

```cpp
#include <QTableView>

// 创建视图和模型
QTableView *view = new QTableView(this);
PersonTableModel *model = new PersonTableModel(this);
view->setModel(model);

// 调优
view->horizontalHeader()->setStretchLastSection(true);
view->setSelectionBehavior(QTableView::SelectionBehavior::SelectRows);
view->setSortingEnabled(true);   // 自定义模型需要 QSortFilterProxyModel
view->resizeColumnsToContents();
```

### 使用 QSortFilterProxyModel 进行排序和筛选

```cpp
#include <QSortFilterProxyModel>
#include <QLineEdit>

QSortFilterProxyModel *proxy = new QSortFilterProxyModel(this);
proxy->setSourceModel(model);
proxy->setFilterCaseSensitivity(Qt::CaseSensitivity::CaseInsensitive);
proxy->setFilterKeyColumn(0);   // 在"Name"列上筛选

view->setModel(proxy);
view->setSortingEnabled(true);

// 从搜索框动态筛选
// setFilterRegularExpression 是新代码的首选（内部使用 QRegularExpression）
connect(searchBox, &QLineEdit::textChanged,
        proxy, &QSortFilterProxyModel::setFilterRegularExpression);

// 要高效修改多个筛选参数，使用 beginFilterChange/endFilterChange
// 而不是在每次更改后调用 invalidateFilter()
```

要实现自定义筛选逻辑，请子类化 `QSortFilterProxyModel` 并重写 `filterAcceptsRow`。

### 自定义项目代理（Item Delegate）

使用代理来渲染非文本数据（进度条、图标、自定义组件）：

```cpp
// progressdelegate.h
#pragma once
#include <QStyledItemDelegate>

class ProgressDelegate : public QStyledItemDelegate {
    Q_OBJECT
public:
    explicit ProgressDelegate(QObject *parent = nullptr);

    void paint(QPainter *painter,
               const QStyleOptionViewItem &option,
               const QModelIndex &index) const override;
};
```

```cpp
// progressdelegate.cpp
#include "progressdelegate.h"
#include <QPainter>
#include <QStyleOptionProgressBar>
#include <QApplication>

ProgressDelegate::ProgressDelegate(QObject *parent)
    : QStyledItemDelegate(parent)
{}

void ProgressDelegate::paint(QPainter *painter,
                              const QStyleOptionViewItem &option,
                              const QModelIndex &index) const {
    bool ok = false;
    int value = index.data(Qt::ItemDataRole::DisplayRole).toInt(&ok);
    if (!ok) {
        QStyledItemDelegate::paint(painter, option, index);
        return;
    }

    // 使用样式绘制进度条
    QStyleOptionProgressBar progressOption;
    progressOption.rect = option.rect.adjusted(2, 4, -2, -4);
    progressOption.minimum = 0;
    progressOption.maximum = 100;
    progressOption.progress = value;
    progressOption.text = QString("%1%").arg(value);
    progressOption.textVisible = true;

    QApplication::style()->drawControl(
        QStyle::ControlElement::CE_ProgressBar,
        &progressOption,
        painter
    );
}

// 使用代理
view->setItemDelegateForColumn(2, new ProgressDelegate(view));
```

### 关键规则

- 永远不要直接从模型外部访问 `m_data` — 应始终通过模型 API
- `rowCount()` 和 `columnCount()` 在 `parent.isValid()` 时必须返回 0（Qt 树契约，即使对表格也适用）
- `dataChanged` 必须使用精确的更改索引范围发出 — 不必要地发出整个模型会导致完全视图重绘
- 对于大数据集（>10k 行），考虑通过 `canFetchMore()` / `fetchMore()` 实现懒加载
