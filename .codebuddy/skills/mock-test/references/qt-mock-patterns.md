# Qt 特定 Mock 模式

## 重要限制：Qt 类不可直接 Mock

Qt 的大部分类（`QNetworkAccessManager`、`QSqlDatabase`、`QSerialPort` 等）：
- 不继承纯虚接口
- 内部有复杂的私有实现（d-pointer）
- 无法通过 GMock 直接 Mock

**解决方案：始终通过接口层包装 Qt 类。**

---

## Mock 网络请求

### 接口设计

```cpp
// INetworkManager.h
#pragma once
#include <QObject>
#include <QByteArray>
#include <QUrl>
#include <functional>

class INetworkManager : public QObject {
    Q_OBJECT
public:
    virtual ~INetworkManager() = default;
    virtual void get(const QUrl& url,
                     std::function<void(int statusCode, const QByteArray& body)> callback) = 0;
    virtual void post(const QUrl& url, const QByteArray& body,
                      std::function<void(int statusCode, const QByteArray& body)> callback) = 0;
};
```

### 真实实现

```cpp
// QtNetworkManager.h
#include "INetworkManager.h"
#include <QNetworkAccessManager>

class QtNetworkManager : public INetworkManager {
    Q_OBJECT
public:
    explicit QtNetworkManager(QObject* parent = nullptr)
        : INetworkManager(parent), m_nam(new QNetworkAccessManager(this)) {}

    void get(const QUrl& url,
             std::function<void(int, const QByteArray&)> callback) override {
        auto* reply = m_nam->get(QNetworkRequest(url));
        connect(reply, &QNetworkReply::finished, this, [reply, callback]() {
            callback(reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt(),
                     reply->readAll());
            reply->deleteLater();
        });
    }

    void post(const QUrl& url, const QByteArray& body,
              std::function<void(int, const QByteArray&)> callback) override {
        QNetworkRequest req(url);
        req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
        auto* reply = m_nam->post(req, body);
        connect(reply, &QNetworkReply::finished, this, [reply, callback]() {
            callback(reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt(),
                     reply->readAll());
            reply->deleteLater();
        });
    }

private:
    QNetworkAccessManager* m_nam;
};
```

### Mock 实现

```cpp
// MockNetworkManager.h
#include <gmock/gmock.h>
#include "INetworkManager.h"

class MockNetworkManager : public INetworkManager {
    Q_OBJECT
public:
    MOCK_METHOD(void, get,
                (const QUrl& url,
                 std::function<void(int, const QByteArray&)> callback),
                (override));
    MOCK_METHOD(void, post,
                (const QUrl& url, const QByteArray& body,
                 std::function<void(int, const QByteArray&)> callback),
                (override));

    // 辅助方法：模拟成功响应
    void simulateSuccess(const QByteArray& responseBody) {
        ON_CALL(*this, get(_, _))
            .WillByDefault([responseBody](const QUrl&,
                            std::function<void(int, const QByteArray&)> cb) {
                cb(200, responseBody);
            });
    }

    // 辅助方法：模拟网络失败
    void simulateNetworkError() {
        ON_CALL(*this, get(_, _))
            .WillByDefault([](const QUrl&,
                              std::function<void(int, const QByteArray&)> cb) {
                cb(0, QByteArray{});  // 0 = 网络层错误
            });
    }
};
```

### 测试示例

```cpp
TEST_F(WeatherServiceTest, displaysCityTemperature_WhenFetchSucceeds) {
    QByteArray fakeResponse = R"({"temperature": 25.3, "city": "Beijing"})";

    EXPECT_CALL(mockNetwork, get(QUrl("https://api.weather.com/current"), _))
        .WillOnce([&fakeResponse](const QUrl&,
                   std::function<void(int, const QByteArray&)> cb) {
            cb(200, fakeResponse);
        });

    sut->fetchWeather("Beijing");

    EXPECT_DOUBLE_EQ(sut->currentTemperature(), 25.3);
    EXPECT_EQ(sut->currentCity(), QString("Beijing"));
}

TEST_F(WeatherServiceTest, showsError_WhenNetworkFails) {
    EXPECT_CALL(mockNetwork, get(_, _))
        .WillOnce([](const QUrl&, std::function<void(int, const QByteArray&)> cb) {
            cb(503, QByteArray{});
        });

    QSignalSpy spy(sut.get(), &WeatherService::errorOccurred);
    sut->fetchWeather("Beijing");

    EXPECT_EQ(spy.count(), 1);
    EXPECT_THAT(spy.first().first().toString().toStdString(),
                HasSubstr("503"));
}
```

---

## Mock 数据库

### 接口设计

```cpp
// IDatabase.h
#pragma once
#include <QVariant>
#include <QVariantList>
#include <QVariantMap>
#include <QString>

class IDatabase {
public:
    virtual ~IDatabase() = default;
    virtual bool open() = 0;
    virtual void close() = 0;
    virtual bool execute(const QString& sql, const QVariantList& params = {}) = 0;
    virtual QVariantMap queryOne(const QString& sql, const QVariantList& params = {}) = 0;
    virtual QList<QVariantMap> queryAll(const QString& sql, const QVariantList& params = {}) = 0;
    virtual bool beginTransaction() = 0;
    virtual bool commit() = 0;
    virtual bool rollback() = 0;
    virtual QString lastError() const = 0;
};
```

### Mock 实现

```cpp
// MockDatabase.h
#include <gmock/gmock.h>
#include "IDatabase.h"

class MockDatabase : public IDatabase {
public:
    MOCK_METHOD(bool, open, (), (override));
    MOCK_METHOD(void, close, (), (override));
    MOCK_METHOD(bool, execute, (const QString& sql, const QVariantList& params), (override));
    MOCK_METHOD(QVariantMap, queryOne,
                (const QString& sql, const QVariantList& params), (override));
    MOCK_METHOD(QList<QVariantMap>, queryAll,
                (const QString& sql, const QVariantList& params), (override));
    MOCK_METHOD(bool, beginTransaction, (), (override));
    MOCK_METHOD(bool, commit, (), (override));
    MOCK_METHOD(bool, rollback, (), (override));
    MOCK_METHOD(QString, lastError, (), (const, override));
};
```

### 测试示例：事务回滚

```cpp
TEST_F(UserRepositoryTest, rollsBackTransaction_WhenInsertFails) {
    EXPECT_CALL(mockDb, beginTransaction()).WillOnce(Return(true));
    EXPECT_CALL(mockDb, execute(HasSubstr("INSERT"), _))
        .WillOnce(Return(false));  // 模拟插入失败
    EXPECT_CALL(mockDb, lastError())
        .WillOnce(Return(QString("UNIQUE constraint failed")));
    EXPECT_CALL(mockDb, rollback()).Times(1);
    EXPECT_CALL(mockDb, commit()).Times(0);  // 不应该提交

    User user{.name = "Alice", .email = "alice@example.com"};
    EXPECT_FALSE(sut->save(user));
    EXPECT_THAT(sut->lastError().toStdString(), HasSubstr("UNIQUE"));
}
```

---

## Mock 硬件设备（串口/传感器）

### 接口设计（串口示例）

```cpp
// ISerialPort.h
#pragma once
#include <QObject>
#include <QByteArray>

class ISerialPort : public QObject {
    Q_OBJECT
public:
    virtual ~ISerialPort() = default;
    virtual bool open(const QString& portName, int baudRate) = 0;
    virtual void close() = 0;
    virtual bool isOpen() const = 0;
    virtual qint64 write(const QByteArray& data) = 0;
    virtual QByteArray readAll() = 0;
    virtual QString errorString() const = 0;

signals:
    void readyRead();
    void errorOccurred(int errorCode, const QString& errorString);
};
```

### Mock 实现（含信号发射）

```cpp
// MockSerialPort.h
#include <gmock/gmock.h>
#include "ISerialPort.h"

class MockSerialPort : public ISerialPort {
    Q_OBJECT
public:
    MOCK_METHOD(bool, open, (const QString& portName, int baudRate), (override));
    MOCK_METHOD(void, close, (), (override));
    MOCK_METHOD(bool, isOpen, (), (const, override));
    MOCK_METHOD(qint64, write, (const QByteArray& data), (override));
    MOCK_METHOD(QByteArray, readAll, (), (override));
    MOCK_METHOD(QString, errorString, (), (const, override));

    // 模拟数据到达
    void simulateDataReceived(const QByteArray& data) {
        ON_CALL(*this, readAll()).WillByDefault(Return(data));
        emit readyRead();
    }

    // 模拟设备错误
    void simulateError(int code, const QString& msg) {
        emit errorOccurred(code, msg);
    }
};
```

### 测试示例：处理串口数据

```cpp
class ProtocolParserTest : public ::testing::Test {
protected:
    void SetUp() override {
        sut = std::make_unique<ProtocolParser>(&mockPort);
    }

    MockSerialPort mockPort;
    std::unique_ptr<ProtocolParser> sut;
};

TEST_F(ProtocolParserTest, parsesTemperatureFrame_WhenValidDataReceived) {
    // 示例数据：温度帧格式 [0xAA, 0x01, 高字节, 低字节, 校验和]
    QByteArray validFrame = QByteArray::fromHex("AA01009C31");  // 温度 15.6°C

    QSignalSpy spy(sut.get(), &ProtocolParser::temperatureUpdated);

    // 模拟串口数据到达
    EXPECT_CALL(mockPort, readAll()).WillOnce(Return(validFrame));
    mockPort.simulateDataReceived(validFrame);

    QTRY_COMPARE(spy.count(), 1);
    EXPECT_NEAR(spy.first().first().toDouble(), 15.6, 0.1);
}

TEST_F(ProtocolParserTest, ignoresInvalidFrame_WhenChecksumMismatch) {
    QByteArray corruptFrame = QByteArray::fromHex("AA01009C00");  // 错误校验和

    QSignalSpy spy(sut.get(), &ProtocolParser::temperatureUpdated);

    EXPECT_CALL(mockPort, readAll()).WillOnce(Return(corruptFrame));
    mockPort.simulateDataReceived(corruptFrame);

    QTest::qWait(100);
    EXPECT_EQ(spy.count(), 0);  // 不应触发信号
}
```

---

## Mock Qt Model

### 测试 Model/View 场景

```cpp
// IDataModel.h — 自定义模型接口
class IDataModel : public QAbstractTableModel {
    Q_OBJECT
public:
    virtual ~IDataModel() = default;
    virtual void reload() = 0;
    virtual bool removeRow(int row) = 0;
};

// MockDataModel.h
class MockDataModel : public IDataModel {
    Q_OBJECT
public:
    MOCK_METHOD(void, reload, (), (override));
    MOCK_METHOD(bool, removeRow, (int row), (override));

    // 必须实现 QAbstractTableModel 的纯虚函数
    int rowCount(const QModelIndex& = {}) const override { return m_rows; }
    int columnCount(const QModelIndex& = {}) const override { return m_cols; }
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override {
        Q_UNUSED(index); Q_UNUSED(role);
        return QVariant{};
    }

    // 辅助：设置模型维度
    void setSize(int rows, int cols) { m_rows = rows; m_cols = cols; }

private:
    int m_rows = 0;
    int m_cols = 0;
};
```

### 测试 View 响应 Model 变化

```cpp
TEST_F(TableViewTest, refreshesView_WhenModelReloaded) {
    MockDataModel mockModel;
    mockModel.setSize(3, 4);
    MyTableView sut(&mockModel);

    // 模拟数据更新
    EXPECT_CALL(mockModel, reload()).Times(1);
    emit mockModel.modelReset();  // 触发 QAbstractItemModel 信号

    EXPECT_EQ(sut.rowCount(), 3);
}
```

---

## Mock QSettings / 配置

```cpp
// IAppSettings.h
class IAppSettings {
public:
    virtual ~IAppSettings() = default;
    virtual QVariant value(const QString& key, const QVariant& defaultValue = {}) const = 0;
    virtual void setValue(const QString& key, const QVariant& value) = 0;
    virtual bool contains(const QString& key) const = 0;
    virtual void sync() = 0;
};

// MockAppSettings.h
class MockAppSettings : public IAppSettings {
public:
    MOCK_METHOD(QVariant, value,
                (const QString& key, const QVariant& defaultValue), (const, override));
    MOCK_METHOD(void, setValue, (const QString& key, const QVariant& value), (override));
    MOCK_METHOD(bool, contains, (const QString& key), (const, override));
    MOCK_METHOD(void, sync, (), (override));
};

// 测试
TEST_F(AppConfigTest, loadsTimeoutFromSettings) {
    EXPECT_CALL(mockSettings, value(QString("network/timeout"), _))
        .WillOnce(Return(QVariant(5000)));

    sut->loadConfig();

    EXPECT_EQ(sut->networkTimeout(), 5000);
}
```

---

## QSignalSpy 高级用法

### 多信号监听

```cpp
// 监听多个信号
QSignalSpy successSpy(&sut, &Service::succeeded);
QSignalSpy errorSpy(&sut, &Service::failed);

sut->doSomething(validInput);

EXPECT_EQ(successSpy.count(), 1);
EXPECT_EQ(errorSpy.count(), 0);  // 不应触发错误信号
```

### 信号参数验证

```cpp
QSignalSpy spy(&sut, &DataService::dataLoaded);

sut->loadUser(42);

QTRY_COMPARE(spy.count(), 1);
QList<QVariant> args = spy.at(0);  // 第一次触发的参数列表

// 验证各个参数
EXPECT_EQ(args.at(0).toInt(), 42);          // 第一个参数：userId
EXPECT_EQ(args.at(1).toString(), "Alice");  // 第二个参数：userName
```

### 信号触发顺序验证

```cpp
// 验证信号按特定顺序触发
bool loadingStartedFirst = false;
bool dataLoadedAfter = false;

connect(&sut, &Service::loadingStarted, [&]() {
    loadingStartedFirst = !dataLoadedAfter;
});
connect(&sut, &Service::dataLoaded, [&]() {
    dataLoadedAfter = loadingStartedFirst;
});

sut->fetchData();

QTRY_VERIFY(dataLoadedAfter);
EXPECT_TRUE(loadingStartedFirst);
```

---

## 异步 Qt 测试模式

### 方案 A：QSignalSpy + QTRY_* （推荐）

```cpp
QSignalSpy spy(&sut, &AsyncService::completed);
sut->startAsync(inputData);
QTRY_COMPARE(spy.count(), 1);  // 自动等待最多 5 秒
```

### 方案 B：QEventLoop 手动等待

```cpp
QEventLoop loop;
connect(&sut, &AsyncService::completed, &loop, &QEventLoop::quit);
sut->startAsync(inputData);
QTimer::singleShot(5000, &loop, &QEventLoop::quit);  // 超时保护
loop.exec();

EXPECT_EQ(sut->result(), expectedResult);
```

### 方案 C：同步化 Mock（适合单元测试）

让 Mock 同步调用回调，避免事件循环依赖：

```cpp
// Mock 的异步接口同步执行
EXPECT_CALL(mockWorker, processAsync(inputData, _))
    .WillOnce([](const QByteArray& data,
                 std::function<void(QByteArray)> callback) {
        callback(transformedData);  // 立即同步调用，无需等待
    });

sut->triggerProcessing(inputData);
// 不需要 QTRY_*，因为 mock 是同步的
EXPECT_EQ(sut->processedData(), transformedData);
```

---

## Fake Object 模式（替代 Mock）

当接口过于复杂或需要真实行为时，使用 Fake（轻量级内存实现）：

```cpp
// FakeDatabase.h — 用内存 map 模拟数据库
class FakeDatabase : public IDatabase {
public:
    bool open() override { m_open = true; return true; }
    void close() override { m_open = false; }
    bool isOpen() const override { return m_open; }

    bool execute(const QString& sql, const QVariantList& params) override {
        // 简单解析 INSERT/UPDATE/DELETE
        if (sql.startsWith("INSERT INTO users")) {
            m_users[params.at(0).toInt()] = {
                {"id", params.at(0)}, {"name", params.at(1)}
            };
            return true;
        }
        return false;
    }

    QVariantMap queryOne(const QString& sql, const QVariantList& params) override {
        if (sql.contains("WHERE id =")) {
            int id = params.first().toInt();
            return m_users.value(id, QVariantMap{});
        }
        return {};
    }

    // 测试辅助：预置数据
    void seedUser(int id, const QString& name) {
        m_users[id] = {{"id", id}, {"name", name}};
    }

    QString lastError() const override { return m_lastError; }

private:
    bool m_open = false;
    QString m_lastError;
    QMap<int, QVariantMap> m_users;
};
```

### 何时用 Fake vs Mock

| 情况 | 使用 Fake | 使用 Mock |
|------|---------|---------|
| 接口方法多（> 10 个） | ✓ | 每个都要 MOCK_METHOD 太繁琐 |
| 需要真实状态逻辑 | ✓ | Mock 只返回固定值 |
| 需要验证具体调用参数 | | ✓ |
| 需要验证调用次数 | | ✓ |
| 需要模拟不同错误场景 | | ✓ |
| 多个测试共用同一"内存数据库" | ✓ | |

---

## CMake：GMock + Qt 联合配置

```cmake
# tests/CMakeLists.txt
cmake_minimum_required(VERSION 3.16)

find_package(Qt6 REQUIRED COMPONENTS Core Test Widgets)
find_package(GTest REQUIRED)

# Qt MOC 自动处理（Mock 类需要 Q_OBJECT 时必须开启）
set(CMAKE_AUTOMOC ON)

# 测试辅助函数
function(add_qt_gtest name)
    add_executable(${name} ${ARGN})
    target_link_libraries(${name}
        PRIVATE
            Qt6::Core
            Qt6::Test       # QSignalSpy、QTest::qWait
            GTest::gtest_main
            GTest::gmock
            myapp_lib       # 被测代码库
    )
    # Qt 测试需要事件循环支持
    target_compile_definitions(${name} PRIVATE QT_TESTLIB_LIB)
    add_test(
        NAME ${name}
        COMMAND ${name} --gtest_output=xml:${CMAKE_BINARY_DIR}/test_results/${name}.xml
    )
    set_tests_properties(${name} PROPERTIES TIMEOUT 30)
endfunction()

add_qt_gtest(test_weather_service
    test_weather_service.cpp
)
add_qt_gtest(test_protocol_parser
    test_protocol_parser.cpp
)
```

### QApplication 初始化（GUI 测试需要）

```cpp
// test_main.cpp — 自定义 main 以支持 QApplication
#include <gtest/gtest.h>
#include <QApplication>

int main(int argc, char* argv[]) {
    QApplication app(argc, argv);  // 或 QCoreApplication 用于非GUI
    app.setAttribute(Qt::AA_Use96Dpi);  // CI 环境下固定 DPI

    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
```
