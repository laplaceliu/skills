---
name: qt-signals-slots
description: >
  Qt C++ 信号与槽（Signals and Slots）—— 核心的对象间通信机制。适用于连接信号与槽、定义自定义信号、调试断开连接的信号、对象间传递数据，或安全处理跨线程通信。

  触发词："connect signal"、"custom signal"、"slot not firing"、"disconnect signal"、"cross-thread signal"、"signal not working"、"emit signal"、"define signal"、"QObject signal"
version: 1.0.0
---

## 信号与槽（Signals and Slots）

### 定义自定义信号

**C++ / Qt：**
```cpp
class DataProcessor : public QObject {
    Q_OBJECT  // 必填 —— 启用信号/槽功能
public:
    explicit DataProcessor(QObject *parent = nullptr);
    void process(const QList<QVariant> &data);

signals:
    void processingStarted();
    void dataReady(const QList<QVariant> &data);
    void progressUpdated(int percent);
    void errorOccurred(const QString &message);
};
```

`Q_OBJECT` 宏在每个使用信号/槽的 `QObject` 子类中是强制的。缺少它会导致在某些配置下运行时失败，且不会有编译错误。

### 连接信号

**新式语法（推荐使用）：**
```cpp
// 直接连接方法
connect(button, &QPushButton::clicked, this, &MainWindow::onButtonClicked);

// 使用 Lambda 进行简单转换
connect(slider, &QSlider::valueChanged, this, [this](int v) {
    label->setText(QString::number(v));
});

// 跨对象连接
connect(processor, &DataProcessor::dataReady,
        tableWidget, &QTableWidget::setRowCount);
connect(processor, &DataProcessor::errorOccurred,
        statusBar, &QStatusBar::showMessage);
```

在新式 C++ 代码中，永远不要使用旧式的 `SLOT()` 宏——它们会绕过类型检查，并在名称不匹配时静默失败。

### 连接类型

| 类型 | 适用场景 |
|------|---------|
| `Qt::AutoConnection`（默认） | 同一或不同线程 —— 自动选择 |
| `Qt::DirectConnection` | 强制同线程，同步执行 |
| `Qt::QueuedConnection` | 跨线程，或推迟到下一次事件循环迭代 |
| `Qt::BlockingQueuedConnection` | 跨线程，调用方阻塞直到槽执行完成（存在死锁风险） |

```cpp
// 显式使用队列连接以确保线程安全
connect(worker, &Worker::resultReady,
        this, &MainWindow::onResult,
        Qt::QueuedConnection);
```

### 跨线程信号（安全模式）

Qt 信号是从工作线程向 UI 线程通信的唯一安全方式。

```cpp
// worker.h
#pragma once
#include <QObject>
#include <QVariantMap>

class Worker : public QObject {
    Q_OBJECT
public:
    explicit Worker(QObject *parent = nullptr);

public slots:
    void doWork(const QString &parameter);
    void cancel();

signals:
    void resultReady(const QVariantMap &result);
    void errorOccurred(const QString &error);
    void progressUpdated(int percent);
    void finished();
};

// worker.cpp
#include "worker.h"
#include <QThread>
#include <QDebug>

Worker::Worker(QObject *parent) : QObject(parent) {}

void Worker::doWork(const QString &parameter) {
    qDebug() << "Starting work:" << parameter;

    for (int i = 0; i <= 100; i += 10) {
        if (m_cancelled) {
            emit errorOccurred("Cancelled");
            emit finished();
            return;
        }
        emit progressUpdated(i);
        QThread::msleep(100);  // 模拟工作
    }

    QVariantMap result;
    result["status"] = "success";
    result["data"] = parameter;
    emit resultReady(result);
    emit finished();
}

void Worker::cancel() {
    m_cancelled = true;
}

// mainwindow.cpp
void MainWindow::startWork() {
    QThread *thread = new QThread(this);
    Worker *worker = new Worker();
    worker->moveToThread(thread);

    // 在启动线程前连接
    connect(thread, &QThread::started, worker, &Worker::doWork);
    connect(worker, &Worker::resultReady, this, &MainWindow::onResult);
    connect(worker, &Worker::errorOccurred, this, &MainWindow::onError);
    connect(worker, &Worker::progressUpdated,
            progressBar, &QProgressBar::setValue);
    connect(worker, &Worker::finished, thread, &QThread::quit);
    connect(worker, &Worker::finished, worker, &QObject::deleteLater);
    connect(thread, &QThread::finished, thread, &QObject::deleteLater);

    thread->start();
}
```

`finished → deleteLater` 链确保 Qt 在完成时清理 worker 和线程对象，防止内存泄漏。

### 断开连接

```cpp
// 断开特定连接
disconnect(button, &QPushButton::clicked, this, &MainWindow::onClick);

// 断开所有连接到特定信号
disconnect(button, &QPushButton::clicked, nullptr, nullptr);

// 断开所有连接
disconnect(sender, nullptr, nullptr, nullptr);
```

### 调试断开的信号

当信号没有触发时，检查清单：
1. 确认发出信号的对象仍然存活（没有被过早删除）
2. 验证 `connect()` 被调用且返回成功
3. 检查信号类型是否匹配
4. 验证 `Q_OBJECT` 存在且 `moc` 已运行（添加后重新构建）
5. 对于跨线程：验证 `moveToThread` 在线程启动之前发生
6. 添加调试连接：
```cpp
connect(sender, &Sender::signal, [](auto &&...args) {
    qDebug() << "SIGNAL FIRED:" << args...;
});
```

### 信号重载

当信号有多个重载时，使用 `qOverload` 或 `QOverload`：
```cpp
// QSpinBox 有两个 valueChanged 信号重载
connect(spinBox,
        qOverload<int>(&QSpinBox::valueChanged),
        this,
        &MyWidget::onValueChanged);
```
