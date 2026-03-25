---
name: qt-layouts
description: >
  Qt C++ 布局管理器 — 在容器中排列和调整 widgets 大小。当需要放置 widgets、控制调整大小行为、构建表单布局、创建分割器、嵌套容器，或调试 widgets 没有显示在预期位置时使用此技能。

  触发短语："arrange widgets"、"layout"、"resize behavior"、"QSplitter"、"center widget"、"widget not visible"、"expand to fill"、"fixed size"、"stretch factor"、"form layout"、"grid layout"、"spacing"、"margins"
version: 1.0.0
---

## Qt C++ 布局管理器

### 布局层次结构

Qt 使用附加到容器的布局对象来布局 widgets。永远不要手动调用 `setGeometry()` — 使用布局。

```
QWidget (父级)
└── QVBoxLayout（通过 setLayout 或构造函数参数附加）
    ├── QLabel
    ├── QHBoxLayout（嵌套）
    │   ├── QPushButton
    │   └── QPushButton
    └── QTextEdit
```

### 核心布局类型

| 布局 | 使用场景 |
:|--------|----------|
| `QVBoxLayout` | 垂直堆叠项目 |
| `QHBoxLayout` | 水平堆叠项目 |
| `QGridLayout` | 行/列网格 |
| `QFormLayout` | 标签 + 字段对 |
| `QStackedLayout` | 多页面，一次只显示一个 |

### 基本用法

```cpp
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QPushButton>
#include <QSizePolicy>

// mywidget.h
#pragma once
#include <QWidget>

class MyWidget : public QWidget {
    Q_OBJECT
public:
    explicit MyWidget(QWidget *parent = nullptr);

private:
    void setupUi();

    QLabel *m_statusLabel = nullptr;
};

MyWidget::MyWidget(QWidget *parent)
    : QWidget(parent)
{
    setupUi();
}

void MyWidget::setupUi() {
    // 将 widget 作为父级传递给布局 — 自动附加布局
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(12, 12, 12, 12);
    mainLayout->setSpacing(8);

    m_statusLabel = new QLabel("Hello", this);
    mainLayout->addWidget(m_statusLabel);

    // 嵌套水平行
    QHBoxLayout *buttonRow = new QHBoxLayout();
    buttonRow->addWidget(new QPushButton("OK", this));
    buttonRow->addWidget(new QPushButton("Cancel", this));
    mainLayout->addLayout(buttonRow);
}
```

将父级 widget 传递给布局构造函数（`new QVBoxLayout(this)`）— 这比单独调用 `setLayout(layout)` 更简洁，也能防止忘记附加布局。

### 拉伸和尺寸策略

**拉伸因子** 在窗口调整大小时分配额外空间：

```cpp
layout->addWidget(sidebar, 1);    // 获得额外空间的 1/4
layout->addWidget(mainArea, 3);   // 获得额外空间的 3/4
```

**尺寸策略** 控制各个 widgets 如何调整大小：

```cpp
// 扩展以填充可用的水平空间
widget->setSizePolicy(QSizePolicy::Policy::Expanding,
                      QSizePolicy::Policy::Preferred);

// 固定大小 — 永不增长或收缩
widget->setSizePolicy(QSizePolicy::Policy::Fixed,
                      QSizePolicy::Policy::Fixed);
widget->setFixedSize(200, 40);
```

常用策略：`Fixed`、`Minimum`、`Maximum`、`Preferred`、`Expanding`、`MinimumExpanding`。

**间隔器：**

```cpp
// 将按钮推到右侧
layout->addStretch();                          // 弹性间隔器
layout->addSpacing(16);                        // 固定大小间隙

// 显式间隔器
layout->addSpacerItem(new QSpacerItem(
    40, 20,
    QSizePolicy::Policy::Expanding,
    QSizePolicy::Policy::Minimum
));
```

### QGridLayout

```cpp
QGridLayout *grid = new QGridLayout(this);
grid->addWidget(new QLabel("Name:"), 0, 0);      // 行, 列
grid->addWidget(nameEdit, 0, 1);
grid->addWidget(new QLabel("Email:"), 1, 0);
grid->addWidget(emailEdit, 1, 1);
grid->addWidget(submitBtn, 2, 0, 1, 2);          // 行, 列, 行跨度, 列跨度

// 列拉伸 — 第二列占用所有额外空间
grid->setColumnStretch(0, 0);
grid->setColumnStretch(1, 1);
```

### QFormLayout

用于设置对话框和数据输入表单 — 自动处理标签对齐：

```cpp
#include <QFormLayout>

QFormLayout *form = new QFormLayout(this);
form->addRow("Username:", new QLineEdit(this));
form->addRow("Password:", new QLineEdit(this));
form->addRow("", new QPushButton("Login", this));  // 按钮行使用空标签
```

### QSplitter

```cpp
#include <QSplitter>
#include <QSettings>

QSplitter *splitter = new QSplitter(Qt::Orientation::Horizontal, this);
splitter->addWidget(sidebar);
splitter->addWidget(mainContent);
splitter->setSizes({200, 600});                   // 初始像素宽度
splitter->setStretchFactor(0, 0);                  // 侧边栏：不拉伸
splitter->setStretchFactor(1, 1);                  // 主区域：占用所有额外空间

// 持久化分割器状态
settings.setValue("splitter", splitter->saveState());
splitter->restoreState(settings.value("splitter").toByteArray());
```

### 在父级中居中 Widget

```cpp
// 通过布局
QVBoxLayout *layout = new QVBoxLayout(this);
layout->addStretch();
layout->addWidget(targetWidget, 0, Qt::AlignmentFlag::AlignHCenter);
layout->addStretch();
```

### 调试布局问题

**Widget 显示但尺寸为零：**

- 设置尺寸提示：`widget->setMinimumSize(100, 40)` 或重写 `sizeHint()`
- 检查父布局是否实际附加（`layout()` 返回非 `nullptr`）

**Widget 完全不可见：**

- 确认调用了 `show()`（或父级可见）
- 检查 `isHidden()` 和 `isVisible()`
- 确保没有 `setFixedSize(0, 0)` 或导致 widget 折叠的零边距

**布局忽略大小更改：**

- 在程序化几何更改后调用 `layout->invalidate()`
- 验证当需要扩展时尺寸策略不是 `Fixed`

**边距和间距默认值：**

- 默认内容边距：所有侧面 9px（因样式而异）
- 重置为零：`layout->setContentsMargins(0, 0, 0, 0)` 和 `layout->setSpacing(0)`
