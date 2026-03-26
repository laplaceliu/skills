---
name: mock-test
description: >
  当用户请求"编写 mock 测试"、"添加 mock"、"创建 GMock"、"如何 mock 依赖"、
  "如何隔离测试"、"Mock 对象"、"伪造依赖"、"stub"、"fake"、"测试替身"、
  "mock 网络请求"、"mock 数据库"、"mock Qt 信号"、"mock 接口"时使用此技能。
  同时支持"数据仿真"、"仿真器"、"模拟传感器数据"、"模拟设备行为"、
  "模拟时序数据"、"仿真数据流"、"生成测试数据"、"回放真实数据"等场景。
  面向 C++/Qt 项目，使用 Google Mock (GMock) + QTest 组合方案。
  当用户请求"mock 某个类"、"隔离单元测试"、"添加测试替身"、"写测试但不依赖真实服务"时也会激活。
license: MIT
metadata:
  category: testing
  version: "1.1.0"
  targets: C++/Qt
  frameworks: [Google Mock, QTest, Qt Test]
---

# Mock 测试技能（C++/Qt Mock Test）

面向 **C++/Qt 项目**的 Mock 测试专家技能。使用 **Google Mock (GMock) + QTest** 组合，支持接口隔离、信号/槽替身、异步测试、数据库/网络 Mock，以及**数据仿真**（时序数据流、状态机设备行为、噪声注入、数据回放）等场景。

---

## 强制工作流 — 按顺序执行以下步骤

**当此技能被触发时，在编写任何代码前必须遵循此工作流。**

### 第 0 步：理解项目结构

在提问用户之前，**先主动探索项目**：

1. **读取项目根目录**结构（`list_dir` / `search_file`）
2. **识别构建系统**：CMake (`CMakeLists.txt`) 或 qmake (`.pro`)
3. **查找现有测试**：搜索 `test_*.cpp`、`*_test.cpp`、`*Test.cpp`、`tests/` 目录
4. **查找接口/抽象类**：搜索含 `virtual` 的头文件或 `I`前缀类
5. **识别依赖项**：查看 CMakeLists.txt 中的 `find_package`、`target_link_libraries`
6. **查找示例数据结构**：搜索现有的 `.h` 头文件了解数据类型

探索完成后，向用户汇报发现，然后进行第 1 步的交互式问询。

---

### 第 1 步：交互式场景收集

逐一向用户提问（发现可推断的信息时跳过）：

#### 1.1 被测目标
```
您想对哪个类/模块写 Mock 测试？请提供：
  - 类名（例如：PaymentService、NetworkManager）
  - 所在文件路径（如果已知）
```

#### 1.2 依赖关系
```
这个类依赖哪些外部资源？（多选）
  □ 网络请求（HTTP/WebSocket/QNetworkAccessManager）
  □ 数据库 / 本地文件（SQLite/QFile/QSettings）
  □ 硬件设备（串口/GPIO/传感器）
  □ Qt 信号发射方（其他 QObject 发出的信号）
  □ 第三方库（请告知库名）
  □ 其他 C++ 接口/抽象类
```

#### 1.3 测试场景
```
您想验证哪些行为？（描述 1-3 个关键场景）
例如：
  - "当网络超时时，界面显示错误提示"
  - "收到传感器数据后，计算正确的平均值并发出 dataReady 信号"
  - "数据库写入失败时，事务应该回滚"
```

#### 1.4 示例数据收集
```
请提供测试时使用的示例数据：
  - 正常情况的输入值（成功路径）
  - 边界/异常情况的输入值（错误路径）
  - 期望的输出/状态

格式举例（可以是任意形式，不必是代码）：
  正常：userId=42, data={"temperature": 25.3}  →  返回 true, 发出 dataReady 信号
  异常：userId=-1, data={}  →  返回 false, errorMessage 不为空
```

#### 1.5 数据仿真需求（按需询问）

**如果被测代码涉及连续数据流、硬件设备或时序行为，额外询问：**

```
您的测试是否需要「数据仿真」？（模拟真实设备持续产生数据的过程）

仿真类型（多选）：
  □ A. 周期性数据流  — 每隔固定时间推送一帧（传感器采样、心跳包）
  □ B. 状态机设备    — 设备有多个状态（初始化→运行→故障→恢复）
  □ C. 带噪声/抖动的数据 — 在正常值上叠加随机扰动（模拟真实传感器）
  □ D. 历史数据回放  — 把录制的真实数据文件回放给被测代码
  □ E. 故障注入      — 在特定时刻插入错误帧、超时、丢包等故障
  □ F. 协议帧序列    — 按协议规范依次发送握手→数据→结束帧

如选择了以上任一项，请补充：
  - 数据频率（如 100ms/帧、10Hz）
  - 典型数值范围（如 温度 -10~50°C、电压 0~5V）
  - 故障时机（如 第 5 帧后断连、随机 1% 概率丢包）
  - 是否有真实设备产生的录制数据文件可供回放？
```

#### 1.6 现有接口确认
```
被依赖的类是否已有纯虚接口（抽象类）？
  A. 已有接口（请提供接口文件路径或内容）
  B. 有具体类但无接口（需要先提取接口）
  C. 不确定（我来帮您搜索）
```

---

### 第 2 步：架构分析与 Mock 策略决策

根据收集到的信息，输出分析表格：

| 被依赖项 | Mock 策略 | 原因 |
|---------|---------|------|
| `QNetworkAccessManager` | GMock + 接口封装 | Qt 类不可直接 mock，需包装 |
| `IDatabase` (已有接口) | 直接 GMock | 有纯虚接口，可直接使用 |
| `QSerialPort` | Fake 实现 | 硬件设备，使用 Fake Object |
| `SensorService` (具体类) | 先提取 `ISensorService` 接口，再 GMock | 需要重构才能测试 |

**如果用户选择了数据仿真，额外输出仿真策略表：**

| 仿真类型 | 推荐实现方式 | 核心工具 |
|---------|------------|---------|
| 周期性数据流 | `SimulatorFake` + `QTimer` 定时发信号 | `QTimer`、`QSignalSpy` |
| 状态机设备 | 带状态枚举的 `StatefulFake`，每次调用推进状态 | `enum class State`、`ON_CALL` 序列 |
| 带噪声数据 | `NoisyFake`，在基值上叠加正态分布随机扰动 | `std::normal_distribution`、`<random>` |
| 历史数据回放 | `ReplayFake`，从文件/列表按序读取预录帧 | `QFile`/`std::deque`、`WillOnce` 序列 |
| 故障注入 | `FaultInjectorFake`，按计划在第 N 帧注入错误 | `std::map<int, FaultType>` |
| 协议帧序列 | `ProtocolFake`，按有限状态机依次发送不同类型帧 | `enum Stage`、`WillRepeatedly` + `Invoke` |

说明选择依据（1 句话），并确认用户同意后进入第 3 步。

---

### 第 3 步：代码生成

按以下顺序生成代码：

#### 3.1 接口提取（如需要）
如果被依赖类没有接口，先生成抽象接口：
```cpp
// IXxx.h — 提取的纯虚接口
class IXxx {
public:
    virtual ~IXxx() = default;
    // 仅包含测试中需要的方法
    virtual ReturnType methodName(Args...) = 0;
};
```

#### 3.2 Mock 类生成
```cpp
// MockXxx.h — Google Mock 实现
#include <gmock/gmock.h>
#include "IXxx.h"

class MockXxx : public IXxx {
public:
    MOCK_METHOD(ReturnType, methodName, (Args...), (override));
};
```

#### 3.3 测试用例生成
使用用户提供的**示例数据**填充测试用例：
```cpp
// test_xxx.cpp
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include <QTest>
#include "MockXxx.h"
#include "ClassUnderTest.h"

using ::testing::Return;
using ::testing::Eq;
using ::testing::_;

class XxxTest : public ::testing::Test {
protected:
    MockXxx mockXxx;
    ClassUnderTest sut{&mockXxx};  // 依赖注入
};

// 正常路径测试（使用用户提供的示例数据）
TEST_F(XxxTest, 场景名称_正常路径) {
    // Arrange — 使用示例数据配置期望
    EXPECT_CALL(mockXxx, methodName(示例输入))
        .WillOnce(Return(示例返回值));

    // Act
    auto result = sut.doSomething(示例输入);

    // Assert
    EXPECT_EQ(result, 期望输出);
}

// 异常路径测试
TEST_F(XxxTest, 场景名称_异常路径) {
    EXPECT_CALL(mockXxx, methodName(_))
        .WillOnce(Return(错误返回值));

    auto result = sut.doSomething(异常输入);

    EXPECT_FALSE(result.isValid());
    EXPECT_THAT(result.errorMessage(), Not(IsEmpty()));
}
```

#### 3.4 CMake 集成
```cmake
# tests/CMakeLists.txt
find_package(GTest REQUIRED)
find_package(Qt6 REQUIRED COMPONENTS Test Core)

add_executable(test_xxx test_xxx.cpp)
target_link_libraries(test_xxx
    PRIVATE
        GTest::gtest_main
        GTest::gmock
        Qt6::Test
        Qt6::Core
        myapp_lib  # 被测代码提取为静态库
)
add_test(NAME test_xxx COMMAND test_xxx --gtest_output=xml:test_xxx.xml)
```

#### 3.5 数据仿真代码生成（如需要）

**当用户选择了数据仿真类型时，按对应模板生成仿真器类。**

**A. 周期性数据流仿真器（SimulatorFake）**
```cpp
// SimulatedSensor.h — 用 QTimer 定时产生数据，替代真实硬件
class SimulatedSensor : public ISensor {
    Q_OBJECT
public:
    // intervalMs: 采样间隔；values: 预设数据序列（循环播放）
    SimulatedSensor(int intervalMs, QList<double> values, QObject* parent = nullptr)
        : ISensor(parent), m_values(values) {
        connect(&m_timer, &QTimer::timeout, this, &SimulatedSensor::onTick);
        m_timer.setInterval(intervalMs);
    }

    void start() override { m_index = 0; m_timer.start(); }
    void stop()  override { m_timer.stop(); }
    bool isRunning() const override { return m_timer.isActive(); }

private slots:
    void onTick() {
        double val = m_values[m_index % m_values.size()];
        ++m_index;
        emit dataReady(val);  // ISensor 的信号
    }

private:
    QTimer  m_timer;
    QList<double> m_values;
    int m_index = 0;
};

// 测试用法
TEST_F(DataProcessorTest, computesAverageOverFiveSamples) {
    // 用用户提供的示例数据构造仿真器
    SimulatedSensor sim(50 /*ms*/, {10.0, 12.0, 11.0, 13.0, 10.0});
    DataProcessor sut(&sim);
    QSignalSpy spy(&sut, &DataProcessor::averageReady);

    sim.start();
    QTRY_COMPARE_WITH_TIMEOUT(spy.count(), 1, 2000);

    EXPECT_NEAR(spy.first().first().toDouble(), 11.2, 0.01);
}
```

**B. 状态机设备仿真器（StatefulFake）**
```cpp
// StatefulDeviceFake.h — 模拟有状态的设备（如：离线→连接中→在线→故障）
class StatefulDeviceFake : public IDevice {
    Q_OBJECT
public:
    enum class State { Offline, Connecting, Online, Fault };

    // 预设状态转换序列，每次 connect() 调用推进到下一个状态
    explicit StatefulDeviceFake(QList<State> stateSequence)
        : m_states(stateSequence) {}

    bool connect() override {
        if (m_step >= m_states.size()) return false;
        State s = m_states[m_step++];
        switch (s) {
            case State::Online:      emit connected(); return true;
            case State::Connecting:  emit statusChanged("connecting"); return true;
            case State::Fault:       emit errorOccurred("device fault"); return false;
            case State::Offline:     return false;
        }
        return false;
    }

    void disconnect() override { emit disconnected(); }
    State currentState() const { return m_step > 0 ? m_states[m_step-1] : State::Offline; }

private:
    QList<State> m_states;
    int m_step = 0;
};

// 测试用法：验证重连逻辑
TEST_F(ConnectionManagerTest, retriesConnection_ThenSucceeds) {
    using S = StatefulDeviceFake::State;
    StatefulDeviceFake fake({S::Fault, S::Connecting, S::Online});
    ConnectionManager sut(&fake);

    QSignalSpy spy(&sut, &ConnectionManager::connected);
    sut.connectWithRetry(3 /*maxRetries*/);

    QTRY_COMPARE(spy.count(), 1);
}
```

**C. 带噪声的数据仿真器（NoisyFake）**
```cpp
// NoisyDataSource.h — 在基准值上叠加正态分布噪声
#include <random>

class NoisyDataSource : public IDataSource {
public:
    // baseValue: 基准值；noiseSigma: 噪声标准差；seed: 固定随机种子保证可重复
    NoisyDataSource(double baseValue, double noiseSigma, unsigned seed = 42)
        : m_dist(baseValue, noiseSigma), m_rng(seed) {}

    double read() override {
        return m_dist(m_rng);  // 每次调用返回带噪声的值
    }

    // 注入单次异常峰值（用于测试抗干扰能力）
    void injectSpike(double spikeValue, int afterCallCount) {
        m_spike = {afterCallCount, spikeValue};
    }

private:
    std::normal_distribution<double> m_dist;
    std::mt19937 m_rng;
    std::optional<std::pair<int, double>> m_spike;
    int m_callCount = 0;
};

// 测试用法：验证滤波器能抑制噪声
TEST_F(FilterTest, outputsStableValue_UnderNoisyInput) {
    NoisyDataSource src(25.0 /*基准°C*/, 0.5 /*σ=0.5°C*/);
    LowPassFilter sut(&src, 0.1 /*alpha*/);

    for (int i = 0; i < 100; ++i) sut.update();

    // 滤波后应接近基准值，误差 < 0.2°C
    EXPECT_NEAR(sut.output(), 25.0, 0.2);
}
```

**D. 历史数据回放仿真器（ReplayFake）**
```cpp
// ReplayDataSource.h — 从预录文件/列表按序回放数据
class ReplayDataSource : public IDataSource {
public:
    // 从 QList 构造（适合小规模测试数据）
    explicit ReplayDataSource(QList<QByteArray> frames)
        : m_frames(std::move(frames)) {}

    // 从文件构造（每行一帧十六进制，适合真实设备录制数据）
    static ReplayDataSource fromFile(const QString& path) {
        QFile f(path);
        f.open(QIODevice::ReadOnly | QIODevice::Text);
        QList<QByteArray> frames;
        while (!f.atEnd())
            frames.append(QByteArray::fromHex(f.readLine().trimmed()));
        return ReplayDataSource(frames);
    }

    QByteArray readFrame() override {
        if (m_index >= m_frames.size()) {
            emit endOfData();
            return {};
        }
        return m_frames[m_index++];
    }

    bool hasMore() const override { return m_index < m_frames.size(); }
    int  totalFrames() const { return m_frames.size(); }
    int  playedFrames() const { return m_index; }

    // 重置回放位置
    void reset() { m_index = 0; }

signals:
    void endOfData();

private:
    QList<QByteArray> m_frames;
    int m_index = 0;
};

// 测试用法：用真实录制数据验证解析器
TEST_F(ProtocolParserTest, parsesAllFrames_FromRealCapture) {
    // 用户提供的录制数据（或内联小规模数据）
    auto replay = ReplayDataSource::fromFile("testdata/capture_2026_03_01.hex");
    ProtocolParser sut(&replay);

    int parsedCount = 0;
    connect(&sut, &ProtocolParser::frameParsed,
            [&]() { ++parsedCount; });

    while (replay.hasMore()) sut.processNext();

    EXPECT_EQ(parsedCount, replay.totalFrames());
    EXPECT_EQ(sut.errorCount(), 0);
}
```

**E. 故障注入仿真器（FaultInjectorFake）**
```cpp
// FaultInjector.h — 在特定帧号注入故障，测试容错逻辑
class FaultInjector : public IDataSource {
public:
    enum class FaultType { Timeout, Checksum, Disconnect, GarbageData };

    explicit FaultInjector(IDataSource* real) : m_real(real) {}

    // 在第 frameIndex 帧注入指定故障
    void injectAt(int frameIndex, FaultType fault) {
        m_faults[frameIndex] = fault;
    }

    QByteArray readFrame() override {
        int idx = m_callCount++;
        if (m_faults.contains(idx)) {
            switch (m_faults[idx]) {
                case FaultType::Timeout:      QThread::msleep(5000); return {};
                case FaultType::Checksum:     { auto f = m_real->readFrame(); f[f.size()-1] ^= 0xFF; return f; }
                case FaultType::Disconnect:   emit deviceDisconnected(); return {};
                case FaultType::GarbageData:  return QByteArray(10, 0xFF);
            }
        }
        return m_real->readFrame();
    }

signals:
    void deviceDisconnected();

private:
    IDataSource* m_real;
    QMap<int, FaultType> m_faults;
    int m_callCount = 0;
};

// 测试用法：验证在第3帧校验错误后系统能恢复
TEST_F(ResilientReaderTest, recoversAfterChecksumError) {
    FakeDataSource baseSource(normalFrames);
    FaultInjector injector(&baseSource);
    injector.injectAt(3, FaultInjector::FaultType::Checksum);

    ResilientReader sut(&injector);
    QSignalSpy errSpy(&sut, &ResilientReader::frameError);
    QSignalSpy okSpy(&sut, &ResilientReader::frameReceived);

    for (int i = 0; i < 6; ++i) sut.readNext();

    EXPECT_EQ(errSpy.count(), 1);   // 第3帧报错
    EXPECT_EQ(okSpy.count(), 5);    // 其余5帧正常
}
```

参阅 [references/data-simulation.md](references/data-simulation.md) 获取更多仿真模式和高级用法。

---

### 第 4 步：验证清单

代码生成后，检查以下项目：

- [ ] 所有 `MOCK_METHOD` 签名与接口方法完全一致（含 `const`、`noexcept`）
- [ ] 被测类通过构造函数或 setter 接受依赖（依赖注入）
- [ ] 每个 `EXPECT_CALL` 都有明确的调用次数期望（避免只写 `_`）
- [ ] 正常路径和异常路径都有测试用例
- [ ] CMakeLists.txt 中 GTest/GMock 已正确链接
- [ ] Qt 信号测试使用了 `QSignalSpy`
- [ ] 异步测试使用了 `QTRY_VERIFY` 或 `QEventLoop`
- [ ] **（数据仿真）** 仿真器使用固定随机种子（`seed=42`），保证测试可重复
- [ ] **（数据仿真）** 周期仿真器在 `TearDown` 中调用了 `stop()`，避免测试间干扰
- [ ] **（数据仿真）** 回放仿真器的测试数据文件已提交到 `tests/testdata/` 目录

---

### 第 5 步：移交摘要

向用户提供：

- **生成的文件列表**（路径 + 用途）
- **如何运行测试**（cmake + ctest 命令）
- **依赖安装说明**（如何添加 GTest/GMock）
- **注意事项**（如需要重构的代码、Qt 特殊限制）

---

## 核心原则（6 条铁律）

```
1. 永远通过接口 Mock，绝不 Mock 具体类（无法 mock Qt 具体类）
2. Mock 只设置测试所需的期望，不过度指定
3. 每个测试只测一个行为（单一职责）
4. 示例数据驱动测试用例，不使用魔法数字
5. Qt 异步测试必须用 QSignalSpy 或 QTRY_*，绝不用 QTest::qWait 轮询
6. 被测类通过依赖注入接受依赖，不在内部 new 具体对象
```

---

## 快速导航

| 需要… | 跳转到 |
|------|--------|
| GMock 宏完整参考 | [references/mock-frameworks.md](references/mock-frameworks.md) |
| Qt 特定 Mock 模式 | [references/qt-mock-patterns.md](references/qt-mock-patterns.md) |
| 完整代码示例 | [references/mock-examples.md](references/mock-examples.md) |
| 数据仿真（仿真器/回放/噪声/故障注入） | [references/data-simulation.md](references/data-simulation.md) |

---

## GMock 快速参考

### MOCK_METHOD 语法

```cpp
// 基本形式
MOCK_METHOD(返回类型, 方法名, (参数列表), (限定符));

// 示例
MOCK_METHOD(bool, connect, (const QString& host, int port), (override));
MOCK_METHOD(void, sendData, (const QByteArray& data), (override));
MOCK_METHOD(int, getValue, (), (const, override));
MOCK_METHOD(void, process, (int id), (noexcept, override));
```

### 期望设置（EXPECT_CALL）

```cpp
// 精确匹配
EXPECT_CALL(mock, method(42, "hello")).WillOnce(Return(true));

// 任意参数
EXPECT_CALL(mock, method(_, _)).WillRepeatedly(Return(false));

// 调用次数
EXPECT_CALL(mock, method(_)).Times(3);
EXPECT_CALL(mock, method(_)).Times(AtLeast(1));
EXPECT_CALL(mock, method(_)).Times(Between(1, 3));

// 多次调用不同返回值
EXPECT_CALL(mock, read())
    .WillOnce(Return(data1))
    .WillOnce(Return(data2))
    .WillRepeatedly(Return(QByteArray{}));

// 副作用（触发回调）
EXPECT_CALL(mock, connect(_, _))
    .WillOnce(DoAll(SaveArg<0>(&capturedHost), Return(true)));
```

### 匹配器（Matchers）

```cpp
// 值匹配
EXPECT_CALL(mock, method(Eq(42)));           // 等于
EXPECT_CALL(mock, method(Ne(0)));            // 不等于
EXPECT_CALL(mock, method(Gt(10)));           // 大于
EXPECT_CALL(mock, method(AllOf(Gt(0), Lt(100)))); // 范围

// 字符串
EXPECT_CALL(mock, method(StrEq("hello")));
EXPECT_CALL(mock, method(StartsWith("http")));
EXPECT_CALL(mock, method(HasSubstr("error")));

// 容器
EXPECT_CALL(mock, method(IsEmpty()));
EXPECT_CALL(mock, method(SizeIs(3)));
EXPECT_CALL(mock, method(ElementsAre(1, 2, 3)));

// Qt 类型（需自定义，见 references/qt-mock-patterns.md）
```

---

## Qt 信号/槽 Mock 模式

### QSignalSpy — 监听信号

```cpp
#include <QSignalSpy>

// 监听信号
QSignalSpy spy(&sut, &ClassUnderTest::dataReady);

// 触发被测逻辑
sut.processData(inputData);

// 验证信号
QCOMPARE(spy.count(), 1);                           // 信号触发次数
QList<QVariant> args = spy.takeFirst();             // 取第一次触发的参数
QCOMPARE(args.at(0).toInt(), expectedValue);        // 验证参数
```

### 等待异步信号（QTRY_*）

```cpp
// 等待最多 5 秒，直到信号被触发
QTRY_COMPARE(spy.count(), 1);
QTRY_VERIFY(!spy.isEmpty());

// 自定义超时
QTRY_COMPARE_WITH_TIMEOUT(spy.count(), 1, 10000);  // 10 秒
```

### Mock 发出信号的对象

当被 mock 的接口需要发出 Qt 信号时，使用 `Invoke` 触发：

```cpp
class IDataSource : public QObject {
    Q_OBJECT
public:
    virtual ~IDataSource() = default;
    virtual void startReading() = 0;
signals:
    void dataReceived(const QByteArray& data);
};

class MockDataSource : public IDataSource {
public:
    MOCK_METHOD(void, startReading, (), (override));

    // 在测试中手动发出信号
    void emitData(const QByteArray& data) {
        emit dataReceived(data);
    }
};

// 测试中使用
TEST_F(MyTest, handlesIncomingData) {
    MockDataSource mockSource;
    MyProcessor sut(&mockSource);

    QSignalSpy spy(&sut, &MyProcessor::processedDataReady);

    // 模拟数据到达
    mockSource.emitData(QByteArray("test data"));

    QTRY_COMPARE(spy.count(), 1);
}
```

---

## 依赖注入模式（C++）

### 构造函数注入（推荐）

```cpp
// 生产代码
class PaymentService {
public:
    explicit PaymentService(IPaymentGateway* gateway, IDatabase* db)
        : m_gateway(gateway), m_db(db) {}

private:
    IPaymentGateway* m_gateway;
    IDatabase* m_db;
};

// 测试代码
TEST_F(PaymentServiceTest, chargesSuccessfully) {
    MockPaymentGateway mockGateway;
    MockDatabase mockDb;
    PaymentService sut(&mockGateway, &mockDb);  // 注入 mock
    // ...
}
```

### Setter 注入（适合已有代码改造）

```cpp
class DataProcessor {
public:
    void setSource(IDataSource* source) { m_source = source; }
    void setStorage(IStorage* storage) { m_storage = storage; }
private:
    IDataSource* m_source = nullptr;
    IStorage* m_storage = nullptr;
};
```

### 工厂注入（运行时决定实现）

```cpp
class DeviceManager {
public:
    using DeviceFactory = std::function<std::unique_ptr<IDevice>()>;
    explicit DeviceManager(DeviceFactory factory) : m_factory(std::move(factory)) {}
private:
    DeviceFactory m_factory;
};

// 测试：注入产生 mock 的工厂
TEST(DeviceManagerTest, createsDeviceOnDemand) {
    MockDevice* mockDevice = new MockDevice();
    DeviceManager sut([&mockDevice]() {
        return std::unique_ptr<IDevice>(mockDevice);
    });
}
```

---

## 常见场景速查

### 场景 A：Mock 网络请求

参阅 [references/qt-mock-patterns.md](references/qt-mock-patterns.md#mock-网络请求)

### 场景 B：Mock 数据库/文件 I/O

参阅 [references/qt-mock-patterns.md](references/qt-mock-patterns.md#mock-数据库)

### 场景C：Mock 硬件设备（串口/传感器）

参阅 [references/qt-mock-patterns.md](references/qt-mock-patterns.md#mock-硬件设备)

### 场景 D：Mock Qt Model（`QAbstractItemModel`）

参阅 [references/qt-mock-patterns.md](references/qt-mock-patterns.md#mock-qt-model)

### 场景 E：完整端到端示例

参阅 [references/mock-examples.md](references/mock-examples.md)

### 场景 F：数据仿真（持续数据流/状态机/噪声/回放/故障注入）

参阅 [references/data-simulation.md](references/data-simulation.md)

---

## 反模式

| # | 不要 | 要做 |
|---|------|------|
| 1 | Mock 具体的 Qt 类（`QNetworkAccessManager`） | 提取接口，Mock 接口 |
| 2 | 用 `QTest::qWait(1000)` 等待异步 | 用 `QSignalSpy` + `QTRY_VERIFY` |
| 3 | 在一个测试里 Mock 太多依赖 | 每测试只 Mock 最小依赖集 |
| 4 | 不设置 `Times()` 期望 | 明确指定调用次数 |
| 5 | 在被测类内部 `new` 依赖对象 | 通过构造函数注入 |
| 6 | Mock 数据结构（值对象） | 只 Mock 服务/行为类 |
| 7 | 忽略 `MOCK_METHOD` 的 `const` 限定 | 签名必须与接口完全一致 |
| 8 | 在 Mock 中实现业务逻辑 | Mock 应只返回配置好的值 |
| 9 | 仿真器使用 `std::rand()` 不固定种子 | 用 `std::mt19937(42)` 固定种子，保证可重复 |
| 10 | 周期仿真器在测试结束后未停止 | `TearDown` 中调用 `simulator.stop()` |
| 11 | 回放数据直接硬编码在测试里（超过 10 帧）| 存入 `tests/testdata/*.hex` 文件回放 |
| 12 | 用真实时间等待仿真器完成（`sleep(5)`） | 用 `QTRY_COMPARE_WITH_TIMEOUT` 事件驱动等待 |
