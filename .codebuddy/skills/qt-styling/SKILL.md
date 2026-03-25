---
name: qt-styling
description: >
  Qt C++ 样式表（QSS）与主题定制 —— 自定义控件外观、深色/浅色模式、颜色调色板和平台一致样式。适用于应用自定义样式、实现深色模式、为主题设置应用程序、设置特定控件状态样式，或覆盖平台默认样式。

  触发词："stylesheet"、"QSS"、"theme"、"dark mode"、"custom widget appearance"、"style widget"、"QPalette"、"widget color"、"hover style"、"disabled style"、"app theme"、"visual style"
version: 1.0.0
---

## Qt C++ 样式表（QSS）

### 应用样式表（Applying Stylesheets）

```cpp
// 全局应用（影响所有控件）
qApp->setStyleSheet(R"(
    QWidget {
        font-family: "Inter", "Segoe UI", sans-serif;
        font-size: 13px;
    }
    QPushButton {
        background-color: #0078d4;
        color: white;
        border: none;
        border-radius: 4px;
        padding: 6px 16px;
        min-width: 80px;
    }
    QPushButton:hover {
        background-color: #106ebe;
    }
    QPushButton:pressed {
        background-color: #005a9e;
    }
    QPushButton:disabled {
        background-color: #cccccc;
        color: #888888;
    }
)");

// 单个控件（覆盖全局样式表）
myButton->setStyleSheet("background-color: #e74c3c; color: white;");
```

### QSS 选择器语法

```css
/* 类型选择器 */
QPushButton { ... }

/* 类选择器（使用 setProperty 设置自定义类） */
QPushButton[class="danger"] { background-color: #e74c3c; }

/* 对象名称选择器 */
QPushButton#submitBtn { font-weight: bold; }

/* 子选择器 —— 仅限直接子元素 */
QDialog > QPushButton { margin: 4px; }

/* 后代选择器 */
QGroupBox QPushButton { padding: 4px; }

/* 伪状态 */
QLineEdit:focus { border: 2px solid #0078d4; }
QCheckBox:checked { color: #0078d4; }
QListWidget::item:selected { background: #0078d4; color: white; }

/* 子控件 */
QComboBox::drop-down { border: none; width: 20px; }
QScrollBar::handle:vertical { background: #888; border-radius: 4px; }
```

### 深色/浅色模式

**检测系统偏好：**
```cpp
#include <QStyleHints>
#include <QPalette>

bool isDarkMode() {
    QPalette palette = qApp->palette();
    return palette.color(QPalette::ColorRole::Window).lightness() < 128;
}
```

**通过 QPalette 以编程方式应用深色主题（无需样式表）：**
```cpp
#include <QPalette>
#include <QColor>

void applyDarkPalette(QApplication *app) {
    QPalette palette;
    palette.setColor(QPalette::ColorRole::Window,          QColor(32, 32, 32));
    palette.setColor(QPalette::ColorRole::WindowText,       QColor(220, 220, 220));
    palette.setColor(QPalette::ColorRole::Base,             QColor(25, 25, 25));
    palette.setColor(QPalette::ColorRole::AlternateBase,    QColor(40, 40, 40));
    palette.setColor(QPalette::ColorRole::Text,             QColor(220, 220, 220));
    palette.setColor(QPalette::ColorRole::Button,           QColor(48, 48, 48));
    palette.setColor(QPalette::ColorRole::ButtonText,       QColor(220, 220, 220));
    palette.setColor(QPalette::ColorRole::Highlight,       QColor(0, 120, 212));
    palette.setColor(QPalette::ColorRole::HighlightedText,  Qt::GlobalColor::white);
    palette.setColor(QPalette::ColorRole::Link,             QColor(64, 160, 255));
    app->setPalette(palette);
}
```

**基于 QSS 的主题切换：**
```cpp
class ThemeManager : public QObject {
    Q_OBJECT
public:
    explicit ThemeManager(QApplication *app, QObject *parent = nullptr)
        : QObject(parent)
        , m_app(app)
    {}

    void applyTheme(const QString &theme) {  // "light" | "dark"
        QString path = QString(":/themes/%1.qss").arg(theme);
        QFile file(path);
        if (file.open(QFile::OpenModeFlag::ReadOnly)) {
            m_app->setStyleSheet(QString::fromUtf8(file.readAll()));
            file.close();
        }
    }

private:
    QApplication *m_app;
};
```

为便于维护，从文件或资源加载 QSS——内联字符串在规则较多时会变得难以管理。

### 基于动态属性的样式

设置自定义属性以在不创建子类的情况下切换样式：

```cpp
// 将按钮标记为 "primary"
btn->setProperty("variant", "primary");
btn->style()->unpolish(btn);   // 强制重新评估样式
btn->style()->polish(btn);

// QSS 规则
R"(
    QPushButton[variant="primary"] {
        background: #0078d4;
        color: white;
        font-weight: bold;
    }
    QPushButton[variant="danger"] {
        background: #d32f2f;
        color: white;
    }
)"
```

更改属性后始终调用 `unpolish` + `polish`—— Qt 会缓存样式结果，否则不会重新评估。

### Fusion 平台融合样式

为获得一致的跨平台外观，强制使用 Fusion 样式：
```cpp
#include <QStyleFactory>

qApp->setStyle(QStyleFactory::create("Fusion"));
```

Fusion 在 Windows、macOS 和 Linux 上的渲染效果相同。在应用自定义 QSS 时将其作为基础，因为原生样式（Windows11、macOS）会部分忽略 QSS 规则。

### QSS 局限性

- QSS 没有变量或继承 —— 使用 C++ 来模板化样式表字符串
- 并非所有子控件都可样式化 —— 一些复杂控件（QCalendarWidget、QMdiArea）的 QSS 支持有限
- `QGroupBox` 上的 `border-radius` 需要设置 `background-color`，否则会被忽略
- `margin` 和 `padding` 与 `border` 相互作用 —— 在某些情况下盒模型与 CSS 不同
