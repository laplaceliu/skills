---
name: qt-threading
description: >
  Qt C++ 线程模式 —— QThread、QRunnable、QThreadPool，以及 GUI 应用程序的线程安全。适用于运行后台任务、在长时间操作期间保持 UI 响应、管理工作线程、使用线程池，或调试竞态条件和死锁。

  触发词："QThread"、"worker"、"background task"、"thread safety"、"UI freezing"、"long operation"、"QRunnable"、"QThreadPool"、"thread pool"、"concurrent"、"responsive UI"、"blocking the event loop"
version: 1.0.0
---

## Qt C++ 线程（Qt Threading）

### 黄金法则（The Golden Rule）

**永远不要从非主线程更新 UI 控件。** 所有控件操作必须在主（GUI）线程上进行。使用信号将结果从工作线程传回。

### 模式一：Worker 对象 + QThread（适用于有状态 Worker）

将 `QObject` 子类移动到 `QThread`。Worker 的槽在线程的事件循环中执行。

```cpp
// datfetcher.h
#pragma once
#include <QObject>
#include <QVariantMap>
#include <QString>

class DataFetcher : public QObject {
    Q_OBJECT
public:
    explicit DataFetcher(const QString &url, QObject *parent = nullptr);
    bool isCancelled() const { return m_cancelled; }

public slots:
    void fetch();
    void cancel();

signals:
    void resultReady(const QVariantMap &data);
    void errorOccurred(const QString &error);
    void progressUpdated(int percent);
    void finished();

private:
    QString m_url;
    std::atomic<bool> m_cancelled{false};
};
```

```cpp
// datafetcher.cpp
#include "datafetcher.h"
#include <QThread>
#include <QDebug>

DataFetcher::DataFetcher(const QString &url, QObject *parent)
    : QObject(parent)
    , m_url(url)
{}

void DataFetcher::fetch() {
    qDebug() << "Starting fetch from:" << m_url;

    try {
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
        result["url"] = m_url;
        result["status"] = "success";
        emit resultReady(result);
    } catch (const std::exception &e) {
        emit errorOccurred(QString("Exception: %1").arg(e.what()));
    }

    emit finished();
}

void DataFetcher::cancel() {
    m_cancelled = true;
}
```

```cpp
// mainwindow.cpp
void MainWindow::startFetch(const QString &url) {
    QThread *thread = new QThread(this);
    DataFetcher *fetcher = new DataFetcher(url);
    fetcher->moveToThread(thread);

    // 在启动前接线 —— 所有连接都是原子建立的
    connect(thread, &QThread::started, fetcher, &DataFetcher::fetch);
    connect(fetcher, &DataFetcher::resultReady, this, &MainWindow::onResult);
    connect(fetcher, &DataFetcher::errorOccurred, this, &MainWindow::onError);
    connect(fetcher, &DataFetcher::progressUpdated,
            progressBar, &QProgressBar::setValue);
    connect(fetcher, &DataFetcher::finished, thread, &QThread::quit);
    connect(fetcher, &DataFetcher::finished, fetcher, &QObject::deleteLater);
    connect(thread, &QThread::finished, thread, &QObject::deleteLater);

    thread->start();
    cancelButton->setEnabled(true);
}

void MainWindow::onResult(const QVariantMap &data) {
    statusLabel->setText("Completed: " + data.value("url").toString());
    cancelButton->setEnabled(false);
}
```

`finished → deleteLater` 链确保 Qt 在完成时清理 worker 和线程对象，防止内存泄漏。

### 模式二：QRunnable + QThreadPool（fire-and-forget 任务）

适用于不需要取消或每实例状态的任务：

```cpp
// Processtask.h
#pragma once
#include <QRunnable>
#include <QVariantMap>

class WorkerSignals : public QObject {
    Q_OBJECT
public:
    explicit WorkerSignals(QObject *parent = nullptr) : QObject(parent) {}

signals:
    void finished();
    void resultReady(const QVariantMap &result);
    void errorOccurred(const QString &error);
};

class ProcessTask : public QRunnable {
    Q_OBJECT
public:
    explicit ProcessTask(const QList<QVariant> &data);

    WorkerSignals *signals() { return m_signals; }

    void run() override;

private:
    QList<QVariant> m_data;
    WorkerSignals *m_signals = nullptr;
};

ProcessTask::ProcessTask(const QList<QVariant> &data)
    : QRunnable()
    , m_data(data)
    , m_signals(new WorkerSignals())
{
    setAutoDelete(true);  // 池在 run() 后删除任务
}

void ProcessTask::run() {
    try {
        QVariantMap result;
        result["items_processed"] = m_data.size();
        result["status"] = "success";
        emit m_signals->resultReady(result);
    } catch (const std::exception &e) {
        emit m_signals->errorOccurred(QString("Exception: %1").arg(e.what()));
    }
    emit m_signals->finished();
}
```

```cpp
// 用法
QThreadPool *pool = QThreadPool::globalInstance();
ProcessTask *task = new ProcessTask(myData);
connect(task->signals(), &WorkerSignals::resultReady,
        this, &MainWindow::onResult);
pool->start(task);

// 限制线程数
pool->setMaxThreadCount(4);
```

### 模式三：使用 QTimer 的简单后台任务

适用于不需要单独线程的周期性、轻量级任务：

```cpp
#include <QTimer>

// 在构造函数或 setupUi() 中
m_timer = new QTimer(this);
connect(m_timer, &QTimer::timeout, this, &MainWindow::checkStatus);
m_timer->start(500);  // 每 500ms 轮询，不阻塞

// 单次触发 —— 2 秒后触发一次
QTimer::singleShot(2000, this, &MainWindow::delayedInit);
```

### 线程安全：共享数据

Qt 容器不是线程安全的。使用互斥锁或原子操作：

```cpp
#include <QMutex>
#include <QMutexLocker>

class SafeDataStore : public QObject {
    Q_OBJECT
public:
    explicit SafeDataStore(QObject *parent = nullptr) : QObject(parent) {}

    void append(const QVariant &item) {
        QMutexLocker locker(&m_mutex);
        m_data.append(item);
        emit dataUpdated();  // 安全 —— 发射信号是线程安全的
    }

    QList<QVariant> snapshot() const {
        QMutexLocker locker(&m_mutex);
        return m_data;
    }

signals:
    void dataUpdated();

private:
    mutable QMutex m_mutex;
    QList<QVariant> m_data;
};
```

**发射信号是线程安全的。** 当发射器和接收器在不同线程时，`Qt::AutoConnection` 自动将槽调用排队。

### QThread 生命周期管理

```cpp
// 方法 1：父子关系自动清理
QThread *thread = new QThread(this);  // mainwindow 是父对象
// thread 会在 mainwindow 销毁时自动销毁

// 方法 2：显式管理
connect(thread, &QThread::finished, thread, &QThread::deleteLater);
connect(this, &MainWindow::destroyed, thread, &QThread::quit);

// 方法 3：智能指针（Qt 6）
connect(thread, &QThread::finished, thread, [thread]() {
    thread.deleteLater();
});
```

### 调试线程问题

**UI 冻结（响应卡顿）：** 主线程上正在运行阻塞调用。常见原因：网络请求、文件 I/O、大计算。移到 `QRunnable` 或工作 `QThread`。

**崩溃并显示 "QObject: Cannot create children for a parent that is in a different thread"：** 在工作线程中创建的 `QObject` 有一个由主线程拥有的父对象。创建无父对象的对象并使用 `moveToThread` 或 `deleteLater`。

**信号发出但槽从未被调用：** 验证 `moveToThread` 在 `start()` 之前发生。验证接收者的线程有正在运行的事件循环（`QThread::exec()` 或 `QThread::start()`）。

**竞态条件：** 在槽中读取可变共享状态时永远不要不加锁。优先使用信号参数传递数据（按值复制）而不是共享可变对象。
