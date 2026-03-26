# Qt 性能优化参考

## 目录

1. [Qt Profiler 使用](#qt-profiler-使用)
2. [QML 性能优化](#qml-性能优化)
3. [Qt Model/View 优化](#qt-modelview-优化)
4. [Qt 图形渲染优化](#qt-图形渲染优化)
5. [Qt 内存优化](#qt-内存优化)
6. [Qt 网络优化](#qt-网络优化)

---

## Qt Profiler 使用

### Qt Creator 分析器

Qt Creator 内置多种分析工具:

```
分析菜单
├── QML Profiler          # QML 运行时分析
├── CPU Usage Analyzer    # CPU 使用分析
├── Memory Usage Analyzer # 内存分析
└── Memory Analyzer       # 内存泄漏检测 (Valgrind)
```

### QML Profiler 使用

```bash
# 命令行启动 QML Profiler
qmlprofiler ./myapp

# 录制跟踪数据
qmlprofiler -record -output trace.qmlp

# 指定跟踪点
qmlprofiler --tracepoints ./myapp
```

### QML Profiler 视图解读

```
QML Profiler 视图
├── Timeline View         # 时间线视图
│   ├── JavaScript       # JS 执行时间
│   ├── Scene Graph      # 场景图渲染
│   ├── Pixmap Cache     # 图片缓存
│   └── Memory           # 内存使用
├── Flame Graph View     # 火焰图视图
└── Quick Seeker         # 快速定位
```

### CPU Usage Analyzer

```bash
# 使用 Linux Perf 收集数据
# 在 Qt Creator 中: 分析 → CPU Usage Analyzer → Start

# 或命令行
perf record -g -F 999 -p $(pgrep myapp) -- sleep 30
perf report
```

---

## QML 性能优化

### QML 性能黄金法则

```
QML 性能黄金法则
1. 减少绑定数量
2. 避免不必要的重绘
3. 使用懒加载
4. 批量更新
5. 避免 JavaScript 密集操作
6. 使用 C++ 加速关键路径
```

### 绑定优化

```qml
// 错误: 复杂绑定在每帧更新
Rectangle {
    width: parent.width - 20  // 每次父宽度变化都重新计算
    color: someVar > 10 ? "red" : "blue"
}

// 正确: 使用简单的属性绑定
Rectangle {
    anchors.margins: 10
    color: condition ? "red" : "blue"
}

// 正确: 使用函数缓存
Rectangle {
    width: calculateWidth()  // 函数每帧调用
    // 改用:
    property int computedWidth: calculateWidth()
    width: computedWidth  // 只计算一次，除非依赖变化
}
```

### 懒加载

```qml
// 使用 Loader 懒加载组件
Loader {
    id: heavyLoader
    active: false  // 默认不加载
    sourceComponent: HeavyComponent {}
}

// 在需要时加载
MouseArea {
    onClicked: heavyLoader.active = true
}

// 或异步加载
Loader {
    asynchronous: true
    source: "HeavyComponent.qml"
}
```

### 列表优化

```qml
// 使用 ListView 而非 Repeater (大列表)
ListView {
    model: largeModel
    delegate: delegateItem
    cacheBuffer: 50  // 缓存缓冲区
}

// 懒加载列表项
ListView {
    model: hugeListModel

    delegate: Item {
        opacity: Loader {
            anchors.fill: parent
            active: ListView.isCurrentItem || ListView.view.isAtBounds(index)
            sourceComponent: delegateContent
        }
    }
}
```

### 信号处理优化

```qml
// 错误: 在组件内处理信号
MouseArea {
    onClicked: doHeavyWork()
}

// 正确: 使用 Connections 在外部处理
Connections {
    target: mouseArea
    onClicked: doHeavyWork()
}

// 正确: 使用 WorkerScript 后台处理
WorkerScript {
    source: "workerscript.js"
    onMessage: resultReady(messageObject)
}
```

---

## Qt Model/View 优化

### 数据模型优化

```cpp
// 优化 1: 使用 QAbstractTableModel 而非 QAbstractListModel
// 当数据是表格结构时

// 优化 2: 实现批量更新
void MyModel::addItems(const QVector<MyItem>& items) {
    beginInsertRows(QModelIndex(), rowCount(), rowCount() + items.size() - 1);
    // 批量添加
    items_.append(items);
    endInsertRows();
}

// 优化 3: 使用 canFetchMore 实现分页加载
bool MyModel::canFetchMore(const QModelIndex& parent) const {
    if (parent == QModelIndex() && !allDataLoaded_) {
        return true;
    }
    return false;
}

void MyModel::fetchMore(const QModelIndex& parent) {
    if (parent != QModelIndex()) return;

    int remainder = totalItems_ - items_.size();
    int fetch = qMin(100, remainder);

    beginInsertRows(QModelIndex(), items_.size(), items_.size() + fetch - 1);
    loadMoreData(fetch);
    endInsertRows();
}
```

### 代理项优化

```cpp
// 优化委托绘制
class EfficientDelegate : public QStyledItemDelegate {
public:
    void paint(QPainter* painter, const QStyleOptionViewItem& option,
               const QModelIndex& index) const override {
        // 避免创建新对象
        // 复用已有的 painter 状态

        // 绘制背景
        if (option.state & QStyle::State_Selected) {
            painter->fillRect(option.rect, option.palette.highlight());
        }

        // 绘制文本
        QRect textRect = option.rect.adjusted(4, 0, -4, 0);
        painter->drawText(textRect, Qt::AlignVCenter | Qt::AlignLeft,
                         index.data().toString());
    }
};
```

### 视图优化

```cpp
// 使用 QSortFilterProxyModel 过滤 (避免修改原始模型)
class MyProxyModel : public QSortFilterProxyModel {
protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override {
        // 本地过滤，不触发源模型重载
        QModelIndex index = sourceModel()->index(sourceRow, 0, sourceParent);
        return sourceModel()->data(index).toString().contains(filterRegExp());
    }
};

// 视图配置优化
void setupListView(QListView* view) {
    view->setUniformItemSizes(true);  // 假设所有项大小相同
    view->setLayoutMode(QListView::Batched);  // 批量布局
    view->setBatchSize(100);  // 批量大小
    view->setVerticalScrollMode(QListView::ScrollPerPixel);  // 像素滚动
}
```

---

## Qt 图形渲染优化

### 场景图渲染优化

```
场景图渲染流程
QML → QQuickItem → Scene Graph → OpenGL/Vulkan/Metal → 屏幕
         ↓
    渲染优化点
    ├── 减少 Item 数量
    ├── 避免频繁重绘
    ├── 使用 Batch 绘制
    └── 优化着色器
```

### 减少重绘

```cpp
// 重写 itemChange 精细控制
class OptimizedItem : public QQuickItem {
protected:
    QSGNode* updatePaintNode(QSGNode* oldNode, UpdatePaintNodeData* data) override {
        // 只在数据真正变化时更新
        if (dataChanged_) {
            // 重建节点
            dataChanged_ = false;
        }
        return oldNode;
    }

    void itemChange(ItemChange change, const ItemChangeData& value) override {
        if (change == ItemOpacityChange || change == ItemVisibleHasChanged) {
            update();  // 显式更新
        }
        QQuickItem::itemChange(change, value);
    }
};
```

### 使用 Batch 绘制

```cpp
// 批量绘制多个相同项
Canvas {
    id: canvas
    property var items: []

    onPaint: {
        var ctx = getContext("2d");
        ctx.beginPath();
        for (var i = 0; i < items.length; i++) {
            // 统一绘制相同颜色的项
            ctx.fillRect(items[i].x, items[i].y,
                         items[i].width, items[i].height);
        }
        ctx.fill();
    }
}
```

### 图形缓存

```qml
// 层缓存
Rectangle {
    layer.enabled: true
    layer.smooth: false  // 关闭平滑
    layer.format: ShaderEffectSource.RGB16  // 减少内存
}

// 使用缓存图片
Image {
    source: "generated_image.png"
    cache: true
}
```

### 着色器优化

```qml
// 使用 ShaderEffect
ShaderEffect {
    property var source: imageSource
    fragmentShader: "
        varying vec2 qt_TexCoord0;
        uniform sampler2D source;

        void main() {
            vec4 color = texture2D(source, qt_TexCoord0);
            // 简单处理，减少计算
            gl_FragColor = color.rgba;
        }
    "
}

// 避免片段着色器中的分支
// 在 C++ 中预处理着色器参数
```

---

## Qt 内存优化

### QString 优化

```cpp
// 使用 QStringLiteral 避免运行时复制
void processString() {
    // 错误: 每次调用创建 QString
    if (str == "hello") { }

    // 正确: 使用 QStringLiteral
    if (str == QStringLiteral("hello")) { }

    // 更好: 预计算哈希
    static const QString kHello = QStringLiteral("hello");
    if (str == kHello) { }
}

// 字符串拼接优化
QString buildPath(const QString& dir, const QString& file) {
    // 使用 QDir::filePath 或直接拼接
    return dir + QLatin1Char('/') + file;  // 快于 QString::append
}
```

### 容器优化

```cpp
// 使用 reserve 预分配
QStringList list;
list.reserve(1000);
for (int i = 0; i < 1000; ++i) {
    list.append(QString::number(i));
}

// 正确选择容器
QVector<T> v;        // QML 友好，连续内存
QList<T> l;          // 指针列表，插入 O(1)
QStringList sl;      // 字符串列表

// QMap vs QHash
QHash<int, QString> hash;  // 更快，整数键
QMap<int, QString> map;   // 有序，范围查询
```

### 隐式共享

```cpp
// QString, QByteArray, QVector 使用隐式共享 (写时复制)
QString s1 = "large string";  // 共享数据
QString s2 = s1;             // 仍共享，未复制
s2[0] = 'L';                 // 此时才复制 (深拷贝)

// 避免不必要的复制
void processString(const QString& str);  // 传 const 引用

// 使用 std::move 转移所有权
QString getString() {
    QString s = "temporary";
    return std::move(s);  // 避免复制
}
```

### 图片内存管理

```cpp
// 使用 QQuickImageProvider 懒加载
class AsyncImageProvider : public QQuickAsyncImageProvider {
    QQuickImageResponse* requestImageResponse(const QString& id,
                                               const QSize& requestedSize) override {
        auto response = new AsyncImageResponse(id, requestedSize);
        // 异步加载
        return response;
    }
};

// 大图片使用下采样
QImage largeImage("large.png");
QImage scaled = largeImage.scaled(maxWidth, maxHeight,
                                  Qt::KeepAspectRatio,
                                  Qt::SmoothTransformation);
```

---

## Qt 网络优化

### 网络请求优化

```cpp
// 使用批量请求
class BatchRequestManager : public QObject {
public:
    void addRequest(const QString& url) {
        pendingUrls_.append(url);
        if (!active_) processNext();
    }

private:
    void processNext() {
        if (pendingUrls_.isEmpty()) return;
        active_ = true;
        QString url = pendingUrls_.takeFirst();
        makeRequest(url);
    }

    void onFinished() {
        active_ = false;
        processNext();  // 处理下一个
    }
};

// 使用 HTTP/2
QNetworkRequest request(url);
request.setAttribute(QNetworkRequest::Http2AllowedAttribute, true);
```

### 数据解析优化

```cpp
// 使用 QJsonDocument 解析
QByteArray jsonData = reply->readAll();
QJsonDocument doc = QJsonDocument::fromJson(jsonData);

// 对于大 JSON 使用流式解析
QJsonObject obj = doc.object();
// 处理数据

// 二进制协议更快
// 使用 QDataStream 或 Protocol Buffers
```

### 连接池

```cpp
// 复用网络管理器
class NetworkManager : public QObject {
    static NetworkManager* instance() {
        static NetworkManager inst;
        return &inst;
    }

    QNetworkAccessManager* getManager() {
        if (!manager_) {
            manager_ = new QNetworkAccessManager(this);
            manager_->setNetworkAccessible(QNetworkAccessManager::Accessible);
        }
        return manager_;
    }

private:
    QNetworkAccessManager* manager_ = nullptr;
};
```

---

## Qt 性能反模式

```
Qt 性能反模式
├── 在 QML 中做复杂计算              → 使用 C++ Worker
├── 每帧更新绑定                    → 使用行为或状态
├── 创建大量短期对象                → 对象池
├── 不必要的视图重绘                 → 优化代理或缓存
├── 阻塞主线程                      → 异步或线程
├── 频繁创建/销毁 QML 项            → 使用 Loader 复用
├── 在循环中创建 QML 项            → 使用 ListView
├── 使用 QQmlPropertyMap 频繁更新   → 使用直接绑定
└── 不必要的材质更改                 → 批量相同材质
```
