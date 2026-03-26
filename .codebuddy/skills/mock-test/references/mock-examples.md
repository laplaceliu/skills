# Mock 测试完整代码示例

## 示例 1：温度传感器服务（含异步信号）

### 场景描述
`TemperatureSensor` 读取串口数据，解析温度帧，发出 `temperatureReady(double)` 信号。测试覆盖：正常帧、超范围温度、校验错误、串口断连。

### 接口文件

```cpp
// ISerialDevice.h
#pragma once
#include <QObject>
#include <QByteArray>
#include <QString>

class ISerialDevice : public QObject {
    Q_OBJECT
public:
    virtual ~ISerialDevice() = default;
    virtual bool open(const QString& port) = 0;
    virtual void close() = 0;
    virtual QByteArray readFrame() = 0;

signals:
    void frameReady();
    void deviceError(int code);
};
```

### 被测类

```cpp
// TemperatureSensor.h
#pragma once
#include <QObject>
#include "ISerialDevice.h"

class TemperatureSensor : public QObject {
    Q_OBJECT
public:
    explicit TemperatureSensor(ISerialDevice* device, QObject* parent = nullptr);
    bool startReading(const QString& port);
    double lastTemperature() const { return m_lastTemp; }

signals:
    void temperatureReady(double celsius);
    void sensorError(const QString& message);

private slots:
    void onFrameReady();
    void onDeviceError(int code);

private:
    ISerialDevice* m_device;
    double m_lastTemp = 0.0;

    // 帧格式: [0xAA, 0x01, highByte, lowByte, checksum]
    static double parseFrame(const QByteArray& frame);
    static bool validateChecksum(const QByteArray& frame);
};

// TemperatureSensor.cpp
#include "TemperatureSensor.h"

TemperatureSensor::TemperatureSensor(ISerialDevice* device, QObject* parent)
    : QObject(parent), m_device(device) {
    connect(m_device, &ISerialDevice::frameReady,
            this, &TemperatureSensor::onFrameReady);
    connect(m_device, &ISerialDevice::deviceError,
            this, &TemperatureSensor::onDeviceError);
}

bool TemperatureSensor::startReading(const QString& port) {
    return m_device->open(port);
}

void TemperatureSensor::onFrameReady() {
    QByteArray frame = m_device->readFrame();
    if (frame.size() != 5 || !validateChecksum(frame)) {
        emit sensorError("Invalid frame");
        return;
    }
    double temp = parseFrame(frame);
    if (temp < -40.0 || temp > 125.0) {
        emit sensorError("Temperature out of range");
        return;
    }
    m_lastTemp = temp;
    emit temperatureReady(temp);
}

void TemperatureSensor::onDeviceError(int code) {
    emit sensorError(QString("Device error: %1").arg(code));
}

double TemperatureSensor::parseFrame(const QByteArray& frame) {
    int raw = (static_cast<quint8>(frame[2]) << 8) | static_cast<quint8>(frame[3]);
    return raw / 10.0;
}

bool TemperatureSensor::validateChecksum(const QByteArray& frame) {
    quint8 sum = 0;
    for (int i = 0; i < 4; ++i) sum += static_cast<quint8>(frame[i]);
    return (sum & 0xFF) == static_cast<quint8>(frame[4]);
}
```

### Mock 文件

```cpp
// MockSerialDevice.h
#pragma once
#include <gmock/gmock.h>
#include "ISerialDevice.h"

class MockSerialDevice : public ISerialDevice {
    Q_OBJECT
public:
    MOCK_METHOD(bool, open, (const QString& port), (override));
    MOCK_METHOD(void, close, (), (override));
    MOCK_METHOD(QByteArray, readFrame, (), (override));

    void triggerFrame(const QByteArray& frame) {
        ON_CALL(*this, readFrame()).WillByDefault(::testing::Return(frame));
        emit frameReady();
    }

    void triggerError(int code) {
        emit deviceError(code);
    }
};
```

### 测试文件

```cpp
// test_temperature_sensor.cpp
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include <QCoreApplication>
#include <QSignalSpy>
#include "MockSerialDevice.h"
#include "TemperatureSensor.h"

using ::testing::Return;
using ::testing::_;

class TemperatureSensorTest : public ::testing::Test {
protected:
    void SetUp() override {
        sut = std::make_unique<TemperatureSensor>(&mockDevice);
    }

    ::testing::NiceMock<MockSerialDevice> mockDevice;
    std::unique_ptr<TemperatureSensor> sut;

    // 辅助：构造合法温度帧
    static QByteArray makeFrame(double celsius) {
        int raw = static_cast<int>(celsius * 10);
        QByteArray frame(5, 0);
        frame[0] = 0xAA;
        frame[1] = 0x01;
        frame[2] = (raw >> 8) & 0xFF;
        frame[3] = raw & 0xFF;
        quint8 sum = 0;
        for (int i = 0; i < 4; ++i) sum += static_cast<quint8>(frame[i]);
        frame[4] = sum;
        return frame;
    }
};

// ---- 正常路径 ----

TEST_F(TemperatureSensorTest, emitsTemperatureReady_WhenValidFrameReceived) {
    QSignalSpy spy(sut.get(), &TemperatureSensor::temperatureReady);

    mockDevice.triggerFrame(makeFrame(25.3));

    QTRY_COMPARE(spy.count(), 1);
    EXPECT_NEAR(spy.first().first().toDouble(), 25.3, 0.01);
    EXPECT_NEAR(sut->lastTemperature(), 25.3, 0.01);
}

TEST_F(TemperatureSensorTest, startsReading_WhenPortOpensSuccessfully) {
    EXPECT_CALL(mockDevice, open(QString("/dev/ttyUSB0"))).WillOnce(Return(true));
    EXPECT_TRUE(sut->startReading("/dev/ttyUSB0"));
}

// ---- 边界情况 ----

TEST_F(TemperatureSensorTest, acceptsMinimumTemperature) {
    QSignalSpy tempSpy(sut.get(), &TemperatureSensor::temperatureReady);
    mockDevice.triggerFrame(makeFrame(-40.0));
    QTRY_COMPARE(tempSpy.count(), 1);
    EXPECT_NEAR(tempSpy.first().first().toDouble(), -40.0, 0.01);
}

TEST_F(TemperatureSensorTest, acceptsMaximumTemperature) {
    QSignalSpy tempSpy(sut.get(), &TemperatureSensor::temperatureReady);
    mockDevice.triggerFrame(makeFrame(125.0));
    QTRY_COMPARE(tempSpy.count(), 1);
    EXPECT_NEAR(tempSpy.first().first().toDouble(), 125.0, 0.01);
}

// ---- 异常路径 ----

TEST_F(TemperatureSensorTest, emitsSensorError_WhenChecksumInvalid) {
    QSignalSpy errorSpy(sut.get(), &TemperatureSensor::sensorError);
    QSignalSpy tempSpy(sut.get(), &TemperatureSensor::temperatureReady);

    QByteArray badFrame = makeFrame(25.3);
    badFrame[4] = 0x00;  // 破坏校验和

    mockDevice.triggerFrame(badFrame);

    QTRY_COMPARE(errorSpy.count(), 1);
    EXPECT_EQ(tempSpy.count(), 0);
    EXPECT_THAT(errorSpy.first().first().toString().toStdString(),
                ::testing::HasSubstr("Invalid"));
}

TEST_F(TemperatureSensorTest, emitsSensorError_WhenTemperatureOutOfRange) {
    QSignalSpy errorSpy(sut.get(), &TemperatureSensor::sensorError);

    mockDevice.triggerFrame(makeFrame(150.0));  // 超出上限 125°C

    QTRY_COMPARE(errorSpy.count(), 1);
}

TEST_F(TemperatureSensorTest, emitsSensorError_WhenDeviceDisconnects) {
    QSignalSpy errorSpy(sut.get(), &TemperatureSensor::sensorError);

    mockDevice.triggerError(5);  // 错误代码 5 = 设备断连

    QTRY_COMPARE(errorSpy.count(), 1);
    EXPECT_THAT(errorSpy.first().first().toString().toStdString(),
                ::testing::HasSubstr("5"));
}

// ---- 数据驱动测试 ----

struct TempTestCase { double input; bool valid; };

class TemperatureRangeTest
    : public TemperatureSensorTest,
      public ::testing::WithParamInterface<TempTestCase> {};

TEST_P(TemperatureRangeTest, validatesRangeCorrectly) {
    auto [temp, shouldBeValid] = GetParam();
    QSignalSpy tempSpy(sut.get(), &TemperatureSensor::temperatureReady);
    QSignalSpy errSpy(sut.get(), &TemperatureSensor::sensorError);

    mockDevice.triggerFrame(makeFrame(temp));

    if (shouldBeValid) {
        QTRY_COMPARE(tempSpy.count(), 1);
        EXPECT_EQ(errSpy.count(), 0);
    } else {
        QTRY_COMPARE(errSpy.count(), 1);
        EXPECT_EQ(tempSpy.count(), 0);
    }
}

INSTANTIATE_TEST_SUITE_P(
    TemperatureBoundaries,
    TemperatureRangeTest,
    ::testing::Values(
        TempTestCase{-41.0, false},  // 低于下限
        TempTestCase{-40.0, true},   // 下限
        TempTestCase{0.0,   true},   // 零度
        TempTestCase{25.3,  true},   // 正常室温
        TempTestCase{125.0, true},   // 上限
        TempTestCase{125.1, false}   // 超出上限
    )
);
```

### CMakeLists.txt

```cmake
# tests/CMakeLists.txt
find_package(Qt6 REQUIRED COMPONENTS Core Test)
find_package(GTest REQUIRED)
set(CMAKE_AUTOMOC ON)

add_executable(test_temperature_sensor
    test_temperature_sensor.cpp
    ${CMAKE_SOURCE_DIR}/src/TemperatureSensor.cpp  # 被测文件
)

target_include_directories(test_temperature_sensor PRIVATE
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/tests/mocks
)

target_link_libraries(test_temperature_sensor
    PRIVATE
        Qt6::Core
        Qt6::Test
        GTest::gtest_main
        GTest::gmock
)

add_test(NAME test_temperature_sensor
    COMMAND test_temperature_sensor
        --gtest_output=xml:${CMAKE_BINARY_DIR}/test_results/test_temperature_sensor.xml
)
```

---

## 示例 2：HTTP API 客户端（含 JSON 解析）

### 场景描述
`WeatherClient` 调用 HTTP API 获取天气数据，解析 JSON，更新内部状态并发出信号。

### 接口与被测类

```cpp
// IHttpClient.h
class IHttpClient {
public:
    struct Response {
        int statusCode;
        QByteArray body;
        bool isSuccess() const { return statusCode >= 200 && statusCode < 300; }
    };

    virtual ~IHttpClient() = default;
    virtual void get(const QString& url,
                     std::function<void(const Response&)> callback) = 0;
};

// WeatherClient.h
class WeatherData {
public:
    QString city;
    double temperature = 0.0;
    QString condition;
};

class WeatherClient : public QObject {
    Q_OBJECT
public:
    explicit WeatherClient(IHttpClient* http, QObject* parent = nullptr);
    void fetchWeather(const QString& city);
    WeatherData currentWeather() const { return m_current; }

signals:
    void weatherUpdated(const WeatherData& data);
    void fetchFailed(int statusCode, const QString& reason);

private:
    IHttpClient* m_http;
    WeatherData m_current;
};
```

### Mock 文件

```cpp
// MockHttpClient.h
#include <gmock/gmock.h>
#include "IHttpClient.h"

class MockHttpClient : public IHttpClient {
public:
    MOCK_METHOD(void, get,
                (const QString& url,
                 std::function<void(const Response&)> callback),
                (override));

    // 便捷方法：设置成功响应
    void willRespondWith(int statusCode, const QByteArray& body) {
        ON_CALL(*this, get(_, _))
            .WillByDefault([statusCode, body](
                const QString&, std::function<void(const Response&)> cb) {
                cb({statusCode, body});
            });
    }
};
```

### 测试文件

```cpp
// test_weather_client.cpp
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include <QSignalSpy>
#include "MockHttpClient.h"
#include "WeatherClient.h"

using ::testing::_;

class WeatherClientTest : public ::testing::Test {
protected:
    void SetUp() override {
        sut = std::make_unique<WeatherClient>(&mockHttp);
    }

    ::testing::NiceMock<MockHttpClient> mockHttp;
    std::unique_ptr<WeatherClient> sut;
};

TEST_F(WeatherClientTest, updatesWeatherData_WhenApiReturns200) {
    // 示例响应数据
    QByteArray response = R"({
        "city": "Beijing",
        "temperature": 18.5,
        "condition": "Sunny"
    })";
    mockHttp.willRespondWith(200, response);

    QSignalSpy spy(sut.get(), &WeatherClient::weatherUpdated);

    sut->fetchWeather("Beijing");

    QTRY_COMPARE(spy.count(), 1);
    WeatherData data = spy.first().first().value<WeatherData>();
    EXPECT_EQ(data.city, "Beijing");
    EXPECT_NEAR(data.temperature, 18.5, 0.01);
    EXPECT_EQ(data.condition, "Sunny");
}

TEST_F(WeatherClientTest, emitsFetchFailed_WhenApiReturns404) {
    mockHttp.willRespondWith(404, R"({"error": "City not found"})");

    QSignalSpy failSpy(sut.get(), &WeatherClient::fetchFailed);
    QSignalSpy successSpy(sut.get(), &WeatherClient::weatherUpdated);

    sut->fetchWeather("UnknownCity");

    QTRY_COMPARE(failSpy.count(), 1);
    EXPECT_EQ(failSpy.first().first().toInt(), 404);
    EXPECT_EQ(successSpy.count(), 0);
}

TEST_F(WeatherClientTest, emitsFetchFailed_WhenNetworkUnavailable) {
    mockHttp.willRespondWith(0, QByteArray{});  // 0 = 无网络

    QSignalSpy failSpy(sut.get(), &WeatherClient::fetchFailed);
    sut->fetchWeather("Beijing");

    QTRY_COMPARE(failSpy.count(), 1);
    EXPECT_THAT(failSpy.first().at(1).toString().toStdString(),
                ::testing::HasSubstr("network"));
}

TEST_F(WeatherClientTest, requestsCorrectUrl_ForGivenCity) {
    EXPECT_CALL(mockHttp, get(
        ::testing::HasSubstr("Beijing"),  // URL 包含城市名
        _
    )).WillOnce([](const QString&, std::function<void(IHttpClient::Response)> cb) {
        cb({200, R"({"city":"Beijing","temperature":20,"condition":"Cloudy"})"});
    });

    sut->fetchWeather("Beijing");
}
```

---

## 示例 3：带事务的用户仓库

### 场景描述
`UserRepository` 执行数据库 CRUD 操作，失败时自动回滚事务。

### 测试文件

```cpp
// test_user_repository.cpp
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "MockDatabase.h"  // 来自 qt-mock-patterns.md
#include "UserRepository.h"

using ::testing::Return;
using ::testing::HasSubstr;
using ::testing::_;
using ::testing::InSequence;

class UserRepositoryTest : public ::testing::Test {
protected:
    void SetUp() override {
        ON_CALL(mockDb, isOpen()).WillByDefault(Return(true));
        sut = std::make_unique<UserRepository>(&mockDb);
    }

    ::testing::StrictMock<MockDatabase> mockDb;
    std::unique_ptr<UserRepository> sut;
};

// ---- 成功路径 ----

TEST_F(UserRepositoryTest, savesUserWithTransaction_WhenAllSucceeds) {
    InSequence seq;  // 验证调用顺序

    EXPECT_CALL(mockDb, beginTransaction()).WillOnce(Return(true));
    EXPECT_CALL(mockDb, execute(HasSubstr("INSERT INTO users"), _))
        .WillOnce(Return(true));
    EXPECT_CALL(mockDb, commit()).WillOnce(Return(true));

    User user{.id = 0, .name = "Bob", .email = "bob@test.com"};
    EXPECT_TRUE(sut->save(user));
}

TEST_F(UserRepositoryTest, findsUserById_WhenExists) {
    QVariantMap row{{"id", 42}, {"name", "Alice"}, {"email", "alice@test.com"}};
    EXPECT_CALL(mockDb, queryOne(HasSubstr("WHERE id ="),
                                 ::testing::ElementsAre(QVariant(42))))
        .WillOnce(Return(row));

    auto user = sut->findById(42);

    ASSERT_TRUE(user.has_value());
    EXPECT_EQ(user->id, 42);
    EXPECT_EQ(user->name, "Alice");
}

// ---- 事务回滚 ----

TEST_F(UserRepositoryTest, rollsBack_WhenInsertFails) {
    InSequence seq;

    EXPECT_CALL(mockDb, beginTransaction()).WillOnce(Return(true));
    EXPECT_CALL(mockDb, execute(HasSubstr("INSERT"), _)).WillOnce(Return(false));
    EXPECT_CALL(mockDb, lastError())
        .WillOnce(Return(QString("UNIQUE constraint failed: users.email")));
    EXPECT_CALL(mockDb, rollback()).WillOnce(Return(true));
    EXPECT_CALL(mockDb, commit()).Times(0);  // 绝不提交

    User user{.name = "Duplicate", .email = "alice@test.com"};
    EXPECT_FALSE(sut->save(user));
    EXPECT_THAT(sut->lastError().toStdString(), HasSubstr("UNIQUE"));
}

TEST_F(UserRepositoryTest, rollsBack_WhenTransactionBeginFails) {
    EXPECT_CALL(mockDb, beginTransaction()).WillOnce(Return(false));
    EXPECT_CALL(mockDb, execute(_, _)).Times(0);  // 不执行任何 SQL

    User user{.name = "Test", .email = "t@test.com"};
    EXPECT_FALSE(sut->save(user));
}

// ---- 查询结果处理 ----

TEST_F(UserRepositoryTest, returnsEmpty_WhenUserNotFound) {
    EXPECT_CALL(mockDb, queryOne(_, _)).WillOnce(Return(QVariantMap{}));

    auto user = sut->findById(999);
    EXPECT_FALSE(user.has_value());
}

TEST_F(UserRepositoryTest, returnsAllUsers_WhenTableHasData) {
    QList<QVariantMap> rows = {
        {{"id", 1}, {"name", "Alice"}, {"email", "a@t.com"}},
        {{"id", 2}, {"name", "Bob"},   {"email", "b@t.com"}},
    };
    EXPECT_CALL(mockDb, queryAll(HasSubstr("SELECT"), _))
        .WillOnce(Return(rows));

    auto users = sut->findAll();

    ASSERT_EQ(users.size(), 2);
    EXPECT_EQ(users[0].name, "Alice");
    EXPECT_EQ(users[1].name, "Bob");
}
```

---

## 示例 4：接口提取重构（先重构再测试）

### 场景：现有代码无法测试

```cpp
// 现有代码（难以测试——内部 new）
class OrderProcessor {
public:
    bool submitOrder(int userId, double amount) {
        PaymentGateway gateway;  // ← 内部 new，无法替换
        return gateway.charge(userId, amount);
    }
};
```

### 重构步骤

**步骤 1：提取接口**

```cpp
// IPaymentGateway.h（新增）
class IPaymentGateway {
public:
    virtual ~IPaymentGateway() = default;
    virtual bool charge(int userId, double amount) = 0;
};

// PaymentGateway.h（改造为实现接口）
class PaymentGateway : public IPaymentGateway {
public:
    bool charge(int userId, double amount) override { /* 真实实现 */ }
};
```

**步骤 2：改造被测类（构造函数注入）**

```cpp
// OrderProcessor.h（重构后）
class OrderProcessor {
public:
    explicit OrderProcessor(IPaymentGateway* gateway)
        : m_gateway(gateway) {}  // 通过构造函数注入

    bool submitOrder(int userId, double amount) {
        return m_gateway->charge(userId, amount);
    }

private:
    IPaymentGateway* m_gateway;
};
```

**步骤 3：编写 Mock 和测试**

```cpp
// MockPaymentGateway.h
class MockPaymentGateway : public IPaymentGateway {
public:
    MOCK_METHOD(bool, charge, (int userId, double amount), (override));
};

// test_order_processor.cpp
TEST(OrderProcessorTest, submitsOrderSuccessfully) {
    MockPaymentGateway mockGateway;
    OrderProcessor sut(&mockGateway);

    EXPECT_CALL(mockGateway, charge(42, 100.0)).WillOnce(Return(true));

    EXPECT_TRUE(sut.submitOrder(42, 100.0));
}

TEST(OrderProcessorTest, returnsFailure_WhenGatewayRejects) {
    MockPaymentGateway mockGateway;
    OrderProcessor sut(&mockGateway);

    EXPECT_CALL(mockGateway, charge(_, _)).WillOnce(Return(false));

    EXPECT_FALSE(sut.submitOrder(42, -1.0));
}
```

---

## 快速检查清单

在提交 Mock 测试代码前确认：

```
接口设计
□ 被依赖类有纯虚接口（或已提取）
□ 接口中只包含被测代码实际需要的方法
□ Qt 的 QObject 子接口继承自 QObject

Mock 实现
□ MockXxx 继承接口，所有纯虚函数都有 MOCK_METHOD
□ MOCK_METHOD 签名（const/noexcept）与接口完全一致
□ Qt 信号发射用辅助方法 simulate*() 或 trigger*()

测试用例
□ 每个测试函数只测一个行为（单一断言方向）
□ 使用用户提供的示例数据（不用 42、"test" 等占位符）
□ 有正常路径 + 至少一个异常路径
□ 异步测试用 QSignalSpy + QTRY_*，不用 QTest::qWait

CMake 配置
□ Qt6::Test 已链接（支持 QSignalSpy）
□ GTest::gmock 已链接
□ AUTOMOC ON（如 Mock 类有 Q_OBJECT）
□ 添加了 add_test() 配置
```
