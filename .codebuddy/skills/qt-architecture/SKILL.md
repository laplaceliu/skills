---
name: qt-architecture
description: >
  Qt C++ 应用程序架构、项目结构和入口点模式。适用于构建 Qt 应用结构、设置 QApplication、设计主窗口、在 MVC/MVP 模式之间选择、组织 src 布局，或决定如何在 GUI 应用中分离关注点。

  触发短语："structure my Qt app"、"QApplication setup"、"app entry point"、"Qt project layout"、"organize Qt code"、"Qt MVC"、"Qt MVP"、"main window architecture"、"new Qt project"
version: "1.0.0"
---

## Qt C++ 应用程序架构

### 入口点模式

每个 Qt 应用程序都需要恰好一个 `QApplication`（widgets）或 `QGuiApplication`（仅 QML）实例。在任何 widgets 之前创建它。

**标准 main.cpp：**
```cpp
#include <QApplication>
#include "mainwindow.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    app.setApplicationName("MyApp");
    app.setOrganizationName("MyOrg");
    app.setOrganizationDomain("myorg.com");
    MainWindow window;
    window.show();
    return app.exec();
}
```

使用 `setApplicationName` 和 `setOrganizationName` —— 这些值会注入 `QSettings`。

### 项目布局（C++/Qt）

使用 `src` 布局来组织代码：

```
my-qt-app/
├── src/
│   └── myapp/
│       ├── CMakeLists.txt        # 构建配置
│       ├── main.cpp               # 入口点
│       ├── mainwindow.h           # 主窗口头文件
│       ├── mainwindow.cpp          # 主窗口实现
│       ├── dialogs/               # QDialog 子类
│       │   ├── CMakeLists.txt
│       │   ├── settingsdialog.h
│       │   └── settingsdialog.cpp
│       ├── widgets/               # 自定义 QWidget 子类
│       │   ├── CMakeLists.txt
│       │   └── customwidget.h
│       ├── models/                # 数据模型
│       │   ├── CMakeLists.txt
│       │   └── personmodel.h
│       └── services/             # 业务逻辑、I/O
│           ├── CMakeLists.txt
│           └── dataservice.h
├── tests/
│   ├── CMakeLists.txt
│   ├── test_main.cpp
│   └── test_*.cpp
├── resources/
│   ├── icons/
│   └── resources.qrc
├── CMakeLists.txt               # 根级 CMake
├── cmake/
│   └── QtFeature.cmake          # 可选的 CMake 模块
└── .qt-test.json                # qt-test-suite 配置
```

保持 `dialogs/`、`widgets/`、`models/` 和 `services/` 分离。UI 代码不应包含业务逻辑。

### QMainWindow 结构

```cpp
// mainwindow.h
#pragma once
#include <QMainWindow>
#include <QWidget>
#include <QVBoxLayout>
#include <QMenuBar>
#include <QStatusBar>
#include <QLabel>

class MainWindow : public QMainWindow {
    Q_OBJECT  // 必填 —— 启用信号/槽功能

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow() override;

private slots:
    void on_actionNew_triggered();
    void on_actionOpen_triggered();
    void on_actionSave_triggered();

private:
    void setupUi();
    void setupMenu();
    void setupConnections();

    QLabel *_statusLabel = nullptr;
    QWidget *m_centralWidget = nullptr;
    QVBoxLayout *m_mainLayout = nullptr;
};
```

```cpp
// mainwindow.cpp
#include "mainwindow.h"
#include <QMessageBox>
#include <QFileDialog>
#include <QApplication>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
{
    setWindowTitle("MyApp");
    setMinimumSize(800, 600);
    setupUi();
    setupMenu();
    setupConnections();
}

MainWindow::~MainWindow() = default;

void MainWindow::setupUi() {
    m_centralWidget = new QWidget(this);
    setCentralWidget(m_centralWidget);

    m_mainLayout = new QVBoxLayout(m_centralWidget);
    m_mainLayout->setContentsMargins(12, 12, 12, 12);
    m_mainLayout->setSpacing(8);

    m_statusLabel = new QLabel("Ready", this);
    statusBar()->addWidget(m_statusLabel);
}

void MainWindow::setupMenu() {
    QMenu *fileMenu = menuBar()->addMenu(tr("&File"));

    QAction *newAction = new QAction(tr("&New"), this);
    newAction->setShortcut(QKeySequence::New);
    connect(newAction, &QAction::triggered, this, &MainWindow::on_actionNew_triggered);
    fileMenu->addAction(newAction);

    QAction *openAction = new QAction(tr("&Open..."), this);
    openAction->setShortcut(QKeySequence::Open);
    connect(openAction, &QAction::triggered, this, &MainWindow::on_actionOpen_triggered);
    fileMenu->addAction(openAction);

    fileMenu->addSeparator();

    QAction *saveAction = new QAction(tr("&Save"), this);
    saveAction->setShortcut(QKeySequence::Save);
    connect(saveAction, &QAction::triggered, this, &MainWindow::on_actionSave_triggered);
    fileMenu->addAction(saveAction);

    fileMenu->addSeparator();

    QAction *exitAction = new QAction(tr("E&xit"), this);
    exitAction->setShortcut(QKeySequence::Quit);
    connect(exitAction, &QAction::triggered, qApp, &QApplication::quit);
    fileMenu->addAction(exitAction);
}

void MainWindow::setupConnections() {
    // 连接信号与槽
}

void MainWindow::on_actionNew_triggered() {
    m_statusLabel->setText("Creating new...");
}

void MainWindow::on_actionOpen_triggered() {
    QString fileName = QFileDialog::getOpenFileName(this,
        tr("Open File"), "", tr("All Files (*)"));
    if (!fileName.isEmpty()) {
        m_statusLabel->setText("Opened: " + fileName);
    }
}

void MainWindow::on_actionSave_triggered() {
    m_statusLabel->setText("File saved");
}
```

将 `setupUi`、`setupMenu` 和 `setupConnections` 分离为独立的方法。这使得每个职责都易于查找和测试。

### 架构模式

**MVP（Model-View-Presenter，模型-视图-呈现器）** — 适用于可测试的 Qt 应用程序：
- **Model（模型）**：纯 C++ 类，不导入 Qt。持有数据和业务逻辑。
- **View（视图）**：QWidget 子类。发出用户操作的信号；接收要显示的数据。
- **Presenter（呈现器）**：在 Model 和 View 之间进行协调。包含决策逻辑。可以在没有 Qt 的情况下进行测试。

```cpp
// Presenter 拥有 view 和 model
class CalculatorPresenter : public QObject {
    Q_OBJECT

public:
    explicit CalculatorPresenter(CalculatorView *view,
                                  CalculatorModel *model,
                                  QObject *parent = nullptr);

public slots:
    void onCalculateRequested(const QString &expression);

private:
    CalculatorView *m_view;
    CalculatorModel *m_model;
};

CalculatorPresenter::CalculatorPresenter(CalculatorView *view,
                                          CalculatorModel *model,
                                          QObject *parent)
    : QObject(parent)
    , m_view(view)
    , m_model(model)
{
    connect(m_view, &CalculatorView::calculateRequested,
            this, &CalculatorPresenter::onCalculateRequested);
}

void CalculatorPresenter::onCalculateRequested(const QString &expression) {
    QString result = m_model->evaluate(expression);
    m_view->displayResult(result);
}
```

**MVC** 与 Qt 的信号与槽（signals and slots）系统配合不太自然。MVP 是惯用选择。

**对于简单的应用程序**：直接连接信号与槽是可行的。当需要可单元测试的业务逻辑时再引入 MVP。

### CMake 配置

```cmake
cmake_minimum_required(VERSION 3.16)
project(MyApp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets)

set(SOURCES
    src/myapp/main.cpp
    src/myapp/mainwindow.cpp
    src/myapp/dialogs/settingsdialog.cpp
    src/myapp/widgets/customwidget.cpp
    src/myapp/models/personmodel.cpp
)

add_executable(myapp ${SOURCES})
target_link_libraries(myapp PRIVATE Qt6::Widgets)

# 资源文件
qt_add_resources(myapp "resources"
    PREFIX "/"
    FILES
        resources/icons/app.png
        resources/icons/save.svg
)

# 测试
enable_testing()
find_package(Qt6 REQUIRED COMPONENTS Test)
add_executable(test_myapp tests/test_main.cpp tests/test_personmodel.cpp)
target_link_libraries(test_myapp PRIVATE Qt6::Test Qt6::Widgets)
```

### Qt 项目配置（.qt-test.json）

始终在项目根目录创建此文件以确保 `qt-test-suite` 兼容性：

```json
{
  "project_type": "cpp",
  "cmake_binary": "build/myapp",
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
- 使用 `Q_OBJECT` 宏在任何使用信号与槽的 QObject 子类中
- 使用新式连接语法 `connect(sender, &Sender::signal, this, &Receiver::slot)` 而非旧式 `SIGNAL()`/`SLOT()` 宏
