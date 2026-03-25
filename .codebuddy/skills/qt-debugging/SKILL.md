---
name: qt-debugging
description: >
  诊断和修复 Qt C++ 应用程序问题 — 崩溃、事件循环问题、widget 渲染失败、段错误和常见运行时错误。当 Qt 崩溃、widget 不显示、事件循环冻结、信号未连接或应用程序意外退出时使用此技能。

  触发短语："Qt error"、"crash"、"segfault"、"widget not showing"、"event loop"、"app exits unexpectedly"、"Qt warning"、"QPainter error"、"assertion failed"、"QObject destroyed"、"application not responding"
version: 1.0.0
---

## Qt C++ 调试

### 诊断方法

1. **阅读完整的 Qt 警告输出** — Qt 在崩溃前会打印可操作的警告
2. **对失败类型进行分类**（参见下面的类别）
3. **隔离** — 用最小测试用例重现
4. **使用 `QT_QPA_PLATFORM=offscreen` 或 GDB 进行调试**

### 启用详细 Qt 输出

```bash
# 显示所有 Qt 调试/警告消息
export QT_LOGGING_RULES="*.debug=true"
./myapp

# 过滤到特定类别
export QT_LOGGING_RULES="qt.qpa.*=true;qt.widgets.*=true"
```

```cpp
// C++：设置日志规则
#include <QLoggingCategory>
#include <QCoreApplication>

int main(int argc, char *argv[]) {
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QLoggingCategory::setFilterRules("qt.widgets.*=true");

    QApplication app(argc, argv);
    // ...
}
```

```cpp
// C++：安装消息处理程序以捕获 Qt 输出
#include <QMessageLogContext>
#include <QDebug>

void customMessageHandler(QtMsgType type,
                          const QMessageLogContext &context,
                          const QString &msg) {
    QByteArray localMsg = msg.toLocal8Bit();
    const char *file = context.file ? context.file : "";
    const char *function = context.function ? context.function : "";
    switch (type) {
    case QtDebugMsg:
        fprintf(stderr, "Debug: %s (%s:%u, %s)\n",
                localMsg.constData(), file, context.line, function);
        break;
    case QtWarningMsg:
        fprintf(stderr, "Warning: %s (%s:%u, %s)\n",
                localMsg.constData(), file, context.line, function);
        break;
    case QtCriticalMsg:
        fprintf(stderr, "Critical: %s (%s:%u, %s)\n",
                localMsg.constData(), file, context.line, function);
        break;
    case QtFatalMsg:
        fprintf(stderr, "Fatal: %s (%s:%u, %s)\n",
                localMsg.constData(), file, context.line, function);
        abort();
    }
}

// 在 main() 中设置
qInstallMessageHandler(customMessageHandler);
```

### 常见失败类别

#### Widget 从不显示

- 未在顶级 widget 上调用 `show()`
- 父 widget 未显示（子级继承可见性）
- `setFixedSize(0, 0)` 或零内容边距导致其折叠
- widget 在 `app.exec()` 返回后创建（事件循环退出后）
- `setVisible(false)` 仍然生效

```cpp
// 诊断
qDebug() << widget->isVisible()
         << widget->size()
         << widget->parentWidget();
```

#### 访问 Widget 时崩溃/段错误

- Widget 被删除后仍然访问
- 常见原因：`delete` 之后继续使用指针
- 修复：使用智能指针或 `deleteLater()`，并在删除后设置指针为 `nullptr`

```cpp
// 错误 — 野指针，delete 后继续使用
void MyWindow::closeEvent(QCloseEvent *event) {
    delete m_settingsDialog;  // 对话框被删除
    m_settingsDialog->show();  // 崩溃！使用了野指针
}

// 正确
void MyWindow::closeEvent(QCloseEvent *event) {
    delete m_settingsDialog;
    m_settingsDialog = nullptr;  // 防止使用野指针
}
```

```cpp
// 推荐：使用 QPointer 自动处理
QPointer<QDialog> m_settingsDialog;

void MyWindow::onSettingsClicked() {
    if (m_settingsDialog) {
        m_settingsDialog->show();
        m_settingsDialog->raise();
        m_settingsDialog->activateWindow();
    } else {
        m_settingsDialog = new SettingsDialog(this);
        m_settingsDialog->show();
    }
}
```

#### "QObject: Cannot create children for a parent in a different thread"

- 具有父级的 `QObject` 正在非主线程中创建
- 修复：创建时无父级，然后使用 `moveToThread` 或 `deleteLater` 进行清理

```cpp
// 错误
QObject *obj = new QObject(parentInMainThread);  // 父对象在主线程

// 正确：在目标线程中创建
QObject *worker = new QObject();  // 无父对象
worker->moveToThread(workerThread);
```

#### "QPixmap: Must construct a QGuiApplication before a QPaintDevice"

- `QPixmap`、`QImage` 或 `QIcon` 在 `QApplication` 存在之前创建
- 修复：将所有 Qt 对象构造移动到 `QApplication app(argc, argv)` 之后

#### 事件循环冻结/UI 无响应

- 主线程上有阻塞调用（I/O、`sleep`、重计算）
- 修复：移动到 `QRunnable`/`QThread`（参见 `qt-threading` 技能）

```cpp
// 快速诊断：添加到慢代码路径
QCoreApplication::processEvents();  // 临时解除阻塞 — 确认事件循环卡住
```

#### 信号已连接但从未触发

1. 验证发送者对象仍然存活
2. 添加调试连接：
```cpp
connect(sender, &Sender::signal, [](auto &&...args) {
    qDebug() << "SIGNAL FIRED" << args...;
});
```
3. 检查信号类型签名是否匹配
4. 验证 `Q_OBJECT` 存在且 moc 已运行（添加后重新构建）

### 内存/资源泄漏检测

```cpp
// 使用 ASAN 检测内存错误
// cmake -DCMAKE_CXX_FLAGS="-fsanitize=address -fsanitize=leak"
// 或者使用 Valgrind
// valgrind --leak-check=full ./myapp

// 跟踪活动的 QObject 计数（调试构建）
qDebug() << "Active objects:" << QObject::staticMetaObject.className();
```

### 有用的诊断模式

```cpp
// 转储完整的 widget 树
void dumpWidgetTree(const QWidget *widget, int indent = 0) {
    qDebug().noquote() << QString("  ").repeated(indent)
                       << widget->objectName() << ":"
                       << widget->metaObject()->className();

    for (auto *child : widget->children()) {
        if (auto *childWidget = qobject_cast<const QWidget*>(child)) {
            dumpWidgetTree(childWidget, indent + 1);
        }
    }
}

// 检查事件循环是否正在运行
qDebug() << "Event loop level:" << QCoreApplication::eventLoopLevel();

// 强制同步绘制（调试绘制问题）
widget->repaint();  // 同步 vs update() 延迟
```

### QSS/样式调试

```cpp
// 打印 widget 的有效样式表
qDebug() << widget->styleSheet();

// 检查样式规则是否正在应用
// 添加唯一的背景以进行隔离
widget->setStyleSheet("background: lime;");  // 可见指示器

// 属性更改后强制重新评估
widget->style()->unpolish(widget);
widget->style()->polish(widget);
widget->update();
```

### GDB/LLDB 调试技巧

```bash
# 启用 Qt 调试符号
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo

# 在 GDB 中打印 Qt 对象
(gdb) print *widget
(gdb) print widget->metaObject()->className()

# 设置断点在 Qt 信号/槽
(gdb) break 'QObject::qt_metacall'

# 常见问题：段错误
(gdb) bt  # 查看完整堆栈跟踪
(gdb) frame 2  # 切换到崩溃发生的帧
```

### ASAN 配置示例

```cmake
# CMakeLists.txt
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address -fsanitize=leak")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address")
endif()
```

```bash
# 构建并运行
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
./build/myapp  # ASAN 会报告内存错误
```
