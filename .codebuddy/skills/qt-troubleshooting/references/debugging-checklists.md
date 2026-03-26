# Qt 调试检查清单

## 崩溃问题检查清单

### 开始之前
- [ ] 收集完整的错误信息/堆栈跟踪
- [ ] 确认 Qt 版本和编译器版本
- [ ] 确认是 Debug 还是 Release 构建

### 堆栈分析
- [ ] 堆栈是否完整？（Debug 构建）
- [ ] 崩溃发生在哪一行代码？
- [ ] 崩溃时的调用链？

### 对象生命周期
- [ ] 是否有对象被 delete 后继续访问？
- [ ] 是否使用了 `deleteLater()` 代替直接 `delete`？
- [ ] 指针删除后是否置为 `nullptr`？
- [ ] 是否使用了 `QPointer` 保护指针？

### 线程安全
- [ ] 崩溃是否在多线程代码中？
- [ ] 是否有跨线程访问 Qt 对象？
- [ ] 信号槽连接是否正确指定了连接类型？

### 内存错误
- [ ] 是否有数组越界访问？
- [ ] 是否有空指针解引用？
- [ ] ASAN/UBSAN 有什么输出？

### 常见陷阱
```
⚠️ 陷阱：delete 后未置空
void MyClass::closeEvent(QCloseEvent *event) {
    delete m_dialog;     // 对话框被删除
    m_dialog->show();   // 💥 崩溃！野指针访问
}

// ✅ 正确做法
void MyClass::closeEvent(QCloseEvent *event) {
    delete m_dialog;
    m_dialog = nullptr; // 防止野指针
}
```

## Widget/UI 问题检查清单

### 可见性
- [ ] `isVisible()` 返回什么？
- [ ] `size()` 和 `geometry()` 返回什么？
- [ ] 父 widget 是否可见？
- [ ] 是否在 `show()` 之后创建的？（事件循环退出后）

### 层级关系
- [ ] parent/child 关系正确？
- [ ] 使用 `dumpObjectTree()` 查看 widget 树
- [ ] 是否有 widget 被隐藏或透明？

### 样式
- [ ] `styleSheet()` 内容正确？
- [ ] 尝试强制样式：`widget->setStyleSheet("background: lime;")`
- [ ] 样式优先级是否正确？
- [ ] 动态属性是否设置？

### 布局
- [ ] layout 是否 addWidget？
- [ ] layout 的 margins 和 spacing？
- [ ] `update()` 或 `resize()` 触发？

### 诊断代码
```cpp
// Widget 诊断输出
qDebug() << "=== Widget Diagnostics ===";
qDebug() << "Class:" << widget->metaObject()->className();
qDebug() << "ObjectName:" << widget->objectName();
qDebug() << "isVisible:" << widget->isVisible();
qDebug() << "size:" << widget->size();
qDebug() << "geometry:" << widget->geometry();
qDebug() << "parent:" << widget->parentWidget();
qDebug() << "windowFlags:" << widget->windowFlags();

// 强制重绘测试
widget->setStyleSheet("background: lime;");
widget->repaint();

// Widget 树
void dumpWidgetTree(const QWidget *w, int indent = 0) {
    qDebug().noquote() << QString("  ").repeated(indent)
                      << w->metaObject()->className()
                      << w->objectName();
    for (auto *child : w->children()) {
        if (auto *cw = qobject_cast<const QWidget*>(child))
            dumpWidgetTree(cw, indent + 1);
    }
}
```

## 信号槽问题检查清单

### 连接检查
- [ ] `connect()` 返回值是 `true`？
- [ ] 检查运行时警告：`QObject::connect: ...`
- [ ] 信号和槽的签名是否匹配？

### Q_OBJECT
- [ ] 类声明中是否有 `Q_OBJECT` 宏？
- [ ] moc 文件是否生成？（检查 build 目录）
- [ ] metaObject() 是否有效？

### 线程问题
- [ ] 连接是否跨线程？
- [ ] 是否需要 `Qt::QueuedConnection`？
- [ ] 队列连接时，参数类型是否可拷贝？

### 调试连接
```cpp
// 调试信号触发
connect(sender, &Sender::signal, [](auto&&...args) {
    qDebug() << "SIGNAL FIRED with args:" << args...;
});

// 调试槽调用
class DebugReceiver : public QObject {
    Q_OBJECT
public slots:
    void onSignal(int value) {
        qDebug() << "SLOT CALLED with value:" << value;
    }
};
```

### 签名不匹配示例
```cpp
// ❌ 错误：参数类型不匹配
 signals:
    void valueChanged(int);

// 槽函数签名不同
private slots:
    void onValueChanged(double); // double vs int

// ✅ 正确：签名一致
private slots:
    void onValueChanged(int);
```

## 内存问题检查清单

### 泄漏检测
- [ ] 使用 ASAN：`-DCMAKE_CXX_FLAGS="-fsanitize=address"`
- [ ] 使用 Valgrind：`valgrind --leak-check=full ./app`
- [ ] 检查 QObject 对象计数

### 常见泄漏模式
```cpp
// ⚠️ 模式1：new 后未 delete
class MyClass {
    QNetworkAccessManager *m_manager; // 未在析构函数中 delete
};

// ✅ 正确：使用智能指针或正确管理生命周期
class MyClass {
    std::unique_ptr<QNetworkAccessManager> m_manager;
};

// ⚠️ 模式2：容器中的 QObject
class MyClass {
    QList<QWidget*> m_widgets; // 需要正确清理
};

// ✅ 正确：清理容器
MyClass::~MyClass() {
    qDeleteAll(m_widgets);
    m_widgets.clear();
}
```

### ASAN 配置
```cmake
# CMakeLists.txt
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address -fsanitize=leak")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address")
endif()
```

### 对象树诊断
```cpp
// 诊断活跃的 QObject
qDebug() << "Active QObjects by class:"
         << QObject::staticMetaObject.className();

// 转储对象树
QObject *root = qApp;
root->dumpObjectTree();

// 检查对象父子关系
qDebug() << "Parent:" << obj->parent();
qDebug() << "Children count:" << obj->children().size();
```

## 性能问题检查清单

### CPU 问题
- [ ] 热点在哪里？（perf/BPF 分析）
- [ ] 是否在主线程有阻塞调用？
- [ ] 是否有不必要的重绘？

### 内存问题
- [ ] 内存是否持续增长？
- [ ] 是否有大对象频繁分配/释放？
- [ ] 内存碎片化？

### UI 响应
- [ ] `processEvents()` 调用频率？
- [ ] 是否有耗时操作在主线程？
- [ ] 动画是否卡顿？

### 诊断工具
```bash
# perf 记录
perf record -g ./myapp
perf report

# 内存采样
valgrind --tool=massif ./myapp
ms_print massif.out.*
```

## 多线程问题检查清单

### 线程亲和性
- [ ] Qt 对象是否在正确线程创建？
- [ ] 是否跨线程访问 Qt 对象？
- [ ] `moveToThread()` 是否正确使用？

### 信号槽跨线程
```cpp
// ✅ 推荐：显式指定连接类型
connect(worker, &Worker::result,
        this, &MyClass::onResult,
        Qt::QueuedConnection);

// ✅ 或使用 Qt::AutoConnection（默认）
// 跨线程自动使用 QueuedConnection
```

### QObject 线程限制
```cpp
// ⚠️ 错误：父对象在主线程，子对象在工作线程
QObject *parent = new QObject(); // 主线程
QObject *child = new QObject(parent); // 工作线程创建
// 错误：Cannot create children for a parent in a different thread

// ✅ 正确：无父对象
QObject *child = new QObject(); // 工作线程，无父
child->moveToThread(workerThread);
```

### 常见错误
```
QObject: Cannot create children for a parent in a different thread
→ 子对象创建线程与父对象不同
→ 解决：在子对象线程创建，或无父创建后 moveToThread
```

## 配置与环境检查清单

### Qt 配置
- [ ] `QT_LOGGING_RULES` 设置正确？
- [ ] Qt 警告是否显示？
- [ ] Qt Debug 库是否正确链接？

### 环境变量
```bash
# 显示所有 Qt 调试信息
export QT_LOGGING_RULES="*.debug=true"

# 显示特定类别
export QT_LOGGING_RULES="qt.qpa.*=true;qt.widgets.*=true"

# Offscreen 模式（无显示器）
export QT_QPA_PLATFORM=offscreen
```

### CMake 配置
```cmake
# Debug 构建
cmake -B build -DCMAKE_BUILD_TYPE=Debug

# 带符号
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo

# Sanitizers
cmake -B build -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_FLAGS="-fsanitize=address"
```
