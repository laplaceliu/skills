# 数据仿真参考（C++/Qt）

## 概述：Mock vs Fake vs Simulator

| 类型 | 适用场景 | 核心特征 |
|------|---------|---------|
| **Mock**（GMock） | 验证交互：调用了哪个方法、传了什么参数 | 无状态，每次调用返回预设值 |
| **Fake**（轻量实现） | 替代复杂依赖（数据库、文件系统） | 有内存状态，行为真实但轻量 |
| **Simulator（仿真器）** | 模拟时序行为、持续数据流、设备状态变化 | 有时间驱动的行为，能产生连续数据 |

**选择原则：**
- 只需验证方法调用 → Mock
- 需要真实增删改查行为 → Fake
- 需要模拟持续数据流 / 设备状态机 / 时序行为 → Simulator

---

## 模式 1：周期性数据流仿真器

### 适用场景
- 传感器周期采样（温度、压力、加速度计）
- 心跳包 / Keep-alive 消息
- 定时轮询的状态更新

### 完整实现

```cpp
// SimulatedPeriodicSource.h
#pragma once
#include <QObject>
#include <QTimer>
#include <QList>

// 通用周期性数据源仿真器
// T: 数据类型（double、QByteArray、自定义 struct）
template<typename T>
class SimulatedPeriodicSource : public QObject {
    Q_OBJECT
public:
    // mode: Loop — 循环播放；OneShot — 播完停止
    enum class PlayMode { Loop, OneShot };

    SimulatedPeriodicSource(int intervalMs,
                            QList<T> dataSequence,
                            PlayMode mode = PlayMode::Loop,
                            QObject* parent = nullptr)
        : QObject(parent)
        , m_data(std::move(dataSequence))
        , m_mode(mode)
    {
        m_timer.setInterval(intervalMs);
        connect(&m_timer, &QTimer::timeout, this, &SimulatedPeriodicSource::onTick);
    }

    void start() {
        m_index = 0;
        m_emittedCount = 0;
        m_timer.start();
    }

    void stop() { m_timer.stop(); }
    bool isRunning() const { return m_timer.isActive(); }
    int emittedCount() const { return m_emittedCount; }

    // 动态注入额外数据（模拟突发数据）
    void appendData(const T& value) { m_data.append(value); }

signals:
    void dataReady(T value);
    void finished();  // OneShot 模式播完时触发

private slots:
    void onTick() {
        if (m_data.isEmpty()) return;
        emit dataReady(m_data[m_index]);
        ++m_emittedCount;
        ++m_index;
        if (m_index >= m_data.size()) {
            if (m_mode == PlayMode::OneShot) {
                m_timer.stop();
                emit finished();
            } else {
                m_index = 0;  // 循环
            }
        }
    }

    QTimer m_timer;
    QList<T> m_data;
    PlayMode m_mode;
    int m_index = 0;
    int m_emittedCount = 0;
};
```

### 测试用法

```cpp
// 测试：100ms 采样，验证5帧后的平均值
TEST_F(AveragerTest, computesAverageOverFiveSamples) {
    SimulatedPeriodicSource<double> sim(
        50,                              // 50ms 间隔
        {10.0, 20.0, 30.0, 20.0, 10.0}, // 预设数据
        SimulatedPeriodicSource<double>::PlayMode::OneShot
    );

    MovingAverager sut(5 /*窗口大小*/);
    connect(&sim, &SimulatedPeriodicSource<double>::dataReady,
            &sut, &MovingAverager::addSample);

    QSignalSpy finishedSpy(&sim, &SimulatedPeriodicSource<double>::finished);
    sim.start();

    // 等待仿真器播完（5帧 × 50ms ≈ 250ms，留余量）
    QTRY_COMPARE_WITH_TIMEOUT(finishedSpy.count(), 1, 1000);

    EXPECT_NEAR(sut.average(), 18.0, 0.01);
}
```

---

## 模式 2：状态机设备仿真器

### 适用场景
- 网络设备的连接状态（断开→握手→连接→断开）
- 硬件设备的初始化流程（上电→自检→就绪→运行）
- 协议握手序列（SYN→SYN-ACK→ACK）

### 通用状态机仿真器基类

```cpp
// StateMachineSimulator.h
#pragma once
#include <QObject>
#include <QString>
#include <QList>
#include <functional>

// 通用有限状态机仿真器
// StateEnum: 状态枚举类型
template<typename StateEnum>
class StateMachineSimulator : public QObject {
    Q_OBJECT
public:
    struct Transition {
        StateEnum from;
        StateEnum to;
        QString trigger;          // 触发此转换的事件名
        std::function<void()> onEnter;  // 进入新状态时的副作用
    };

    StateMachineSimulator(StateEnum initialState, QObject* parent = nullptr)
        : QObject(parent), m_state(initialState) {}

    // 添加状态转换规则
    void addTransition(Transition t) { m_transitions.append(t); }

    // 触发事件，返回是否成功转换
    bool trigger(const QString& event) {
        for (auto& t : m_transitions) {
            if (t.from == m_state && t.trigger == event) {
                StateEnum prev = m_state;
                m_state = t.to;
                if (t.onEnter) t.onEnter();
                emit stateChanged(prev, m_state);
                return true;
            }
        }
        return false;  // 无效的状态转换
    }

    StateEnum state() const { return m_state; }

signals:
    void stateChanged(StateEnum from, StateEnum to);

private:
    StateEnum m_state;
    QList<Transition> m_transitions;
};
```

### 具体设备仿真器示例（网络连接）

```cpp
// SimulatedNetworkDevice.h
#include "StateMachineSimulator.h"
#include "INetworkDevice.h"

class SimulatedNetworkDevice : public INetworkDevice {
    Q_OBJECT
public:
    enum class ConnState { Disconnected, Handshaking, Connected, Error };

    SimulatedNetworkDevice() : m_fsm(ConnState::Disconnected) {
        // 定义状态转换
        m_fsm.addTransition({
            ConnState::Disconnected, ConnState::Handshaking, "connect",
            [this]() { emit statusMessage("Handshaking..."); }
        });
        m_fsm.addTransition({
            ConnState::Handshaking, ConnState::Connected, "handshake_ok",
            [this]() { emit connected(); }
        });
        m_fsm.addTransition({
            ConnState::Handshaking, ConnState::Error, "handshake_fail",
            [this]() { emit errorOccurred("Handshake failed"); }
        });
        m_fsm.addTransition({
            ConnState::Connected, ConnState::Disconnected, "disconnect",
            [this]() { emit disconnected(); }
        });
        m_fsm.addTransition({
            ConnState::Error, ConnState::Disconnected, "reset",
            [this]() {}
        });
    }

    // INetworkDevice 接口实现
    bool connect(const QString& /*host*/, int /*port*/) override {
        return m_fsm.trigger("connect");
    }

    void disconnect() override { m_fsm.trigger("disconnect"); }

    bool isConnected() const override {
        return m_fsm.state() == ConnState::Connected;
    }

    // 仿真控制：让握手成功/失败
    void simulateHandshakeSuccess() { m_fsm.trigger("handshake_ok"); }
    void simulateHandshakeFailure() { m_fsm.trigger("handshake_fail"); }

    ConnState state() const { return m_fsm.state(); }

private:
    StateMachineSimulator<ConnState> m_fsm;
};

// 测试用法
TEST_F(ConnectionManagerTest, retriesAfterHandshakeFail_ThenSucceeds) {
    SimulatedNetworkDevice sim;
    ConnectionManager sut(&sim);

    QSignalSpy connSpy(&sut, &ConnectionManager::connected);
    QSignalSpy errSpy(&sut, &ConnectionManager::connectionFailed);

    sut.connectTo("192.168.1.1", 8080);
    sim.simulateHandshakeFailure();  // 第一次失败

    QTest::qWait(100);  // 等待重试逻辑
    sim.simulateHandshakeSuccess();  // 第二次成功

    QTRY_COMPARE(connSpy.count(), 1);
    EXPECT_EQ(errSpy.count(), 0);
}
```

---

## 模式 3：带噪声/随机扰动的数据仿真

### 适用场景
- 模拟真实传感器的测量误差
- 验证滤波算法、异常检测算法的鲁棒性
- 压力测试：输入随机数据时系统不崩溃

### 噪声生成器库

```cpp
// NoiseGenerator.h
#pragma once
#include <random>
#include <cmath>

class NoiseGenerator {
public:
    // seed=42: 固定种子保证测试可重复
    explicit NoiseGenerator(unsigned seed = 42) : m_rng(seed) {}

    // 正态分布噪声（模拟传感器量化误差）
    double gaussian(double mean, double sigma) {
        return std::normal_distribution<double>(mean, sigma)(m_rng);
    }

    // 均匀分布噪声
    double uniform(double min, double max) {
        return std::uniform_real_distribution<double>(min, max)(m_rng);
    }

    // 带偶发毛刺的信号（p: 毛刺概率；spike: 毛刺幅度）
    double withSpike(double base, double sigma, double p, double spike) {
        double noise = gaussian(base, sigma);
        if (std::uniform_real_distribution<double>(0, 1)(m_rng) < p)
            noise += spike;
        return noise;
    }

    // 漂移信号（随时间线性漂移）
    double drifting(double base, double sigma, double driftPerSample) {
        m_drift += driftPerSample;
        return gaussian(base + m_drift, sigma);
    }

    void resetDrift() { m_drift = 0.0; }

private:
    std::mt19937 m_rng;
    double m_drift = 0.0;
};
```

### 噪声数据源仿真器

```cpp
// NoisySensorSimulator.h
#include "NoiseGenerator.h"
#include "ISensor.h"

class NoisySensorSimulator : public ISensor {
    Q_OBJECT
public:
    struct Config {
        double baseValue   = 25.0;   // 基准值
        double noiseSigma  = 0.5;    // 噪声标准差
        double spikeProb   = 0.01;   // 毛刺概率（1%）
        double spikeAmp    = 10.0;   // 毛刺幅度
        double driftRate   = 0.0;    // 每帧漂移量（0=无漂移）
        int    intervalMs  = 100;    // 采样间隔
        unsigned seed      = 42;     // 随机种子
    };

    explicit NoisySensorSimulator(Config cfg, QObject* parent = nullptr)
        : ISensor(parent), m_cfg(cfg), m_noise(cfg.seed)
    {
        m_timer.setInterval(cfg.intervalMs);
        connect(&m_timer, &QTimer::timeout, this, &NoisySensorSimulator::onTick);
    }

    void start() override { m_timer.start(); }
    void stop()  override { m_timer.stop(); }

private slots:
    void onTick() {
        double val = (m_cfg.driftRate != 0.0)
            ? m_noise.drifting(m_cfg.baseValue, m_cfg.noiseSigma, m_cfg.driftRate)
            : m_noise.withSpike(m_cfg.baseValue, m_cfg.noiseSigma,
                                m_cfg.spikeProb, m_cfg.spikeAmp);
        emit sampleReady(val);
    }

    QTimer m_timer;
    Config m_cfg;
    NoiseGenerator m_noise;
};

// ---- 测试用法 ----

// 测试1：滤波器应能抑制噪声
TEST_F(KalmanFilterTest, convergesToBaseValue_UnderGaussianNoise) {
    NoisySensorSimulator::Config cfg;
    cfg.baseValue  = 100.0;
    cfg.noiseSigma = 5.0;
    cfg.spikeProb  = 0.0;   // 无毛刺，只测噪声抑制
    cfg.intervalMs = 10;
    cfg.seed       = 42;

    NoisySensorSimulator sim(cfg);
    KalmanFilter sut(0.1 /*Q*/, 1.0 /*R*/);
    connect(&sim, &NoisySensorSimulator::sampleReady,
            &sut, &KalmanFilter::update);

    sim.start();
    QTest::qWait(500);  // 50 帧，足够收敛
    sim.stop();

    EXPECT_NEAR(sut.estimate(), 100.0, 2.0);  // 误差 < 2
}

// 测试2：异常检测器应捕获毛刺
TEST_F(AnomalyDetectorTest, detectsSpike_InNoisySignal) {
    NoisySensorSimulator::Config cfg;
    cfg.baseValue  = 25.0;
    cfg.noiseSigma = 0.3;
    cfg.spikeProb  = 1.0;    // 100% 概率（第一帧就是毛刺，测试用）
    cfg.spikeAmp   = 20.0;   // 毛刺幅度 20°C（远超阈值）
    cfg.intervalMs = 50;
    cfg.seed       = 42;

    NoisySensorSimulator sim(cfg);
    AnomalyDetector sut(5.0 /*threshold*/);
    QSignalSpy spy(&sut, &AnomalyDetector::anomalyDetected);

    connect(&sim, &NoisySensorSimulator::sampleReady,
            &sut, &AnomalyDetector::processSample);

    sim.start();
    QTRY_COMPARE_WITH_TIMEOUT(spy.count(), 1, 500);
    sim.stop();
}
```

---

## 模式 4：历史数据回放仿真器

### 适用场景
- 用真实设备录制的数据验证解析算法
- 回归测试：确保新版本与旧版本解析结果一致
- 边界情况复现：录制触发 bug 的场景，防止回退

### 回放仿真器

```cpp
// DataReplay.h
#pragma once
#include <QObject>
#include <QByteArray>
#include <QList>
#include <QFile>
#include <QTimer>

class DataReplay : public QObject {
    Q_OBJECT
public:
    // 从十六进制文件加载（每行一帧）
    static DataReplay* fromHexFile(const QString& path, int intervalMs = 0,
                                   QObject* parent = nullptr) {
        QFile f(path);
        if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) return nullptr;
        QList<QByteArray> frames;
        while (!f.atEnd()) {
            QString line = f.readLine().trimmed();
            if (!line.isEmpty() && !line.startsWith('#'))  // 跳过注释行
                frames.append(QByteArray::fromHex(line.toUtf8()));
        }
        return new DataReplay(frames, intervalMs, parent);
    }

    // 从二进制文件加载（固定帧长）
    static DataReplay* fromBinaryFile(const QString& path, int frameSize,
                                      int intervalMs = 0, QObject* parent = nullptr) {
        QFile f(path);
        if (!f.open(QIODevice::ReadOnly)) return nullptr;
        QList<QByteArray> frames;
        while (!f.atEnd()) {
            QByteArray frame = f.read(frameSize);
            if (frame.size() == frameSize) frames.append(frame);
        }
        return new DataReplay(frames, intervalMs, parent);
    }

    // 从内联数据构造（小规模测试用）
    explicit DataReplay(QList<QByteArray> frames, int intervalMs = 0,
                        QObject* parent = nullptr)
        : QObject(parent), m_frames(std::move(frames))
    {
        if (intervalMs > 0) {
            m_timer = new QTimer(this);
            m_timer->setInterval(intervalMs);
            connect(m_timer, &QTimer::timeout, this, &DataReplay::playNext);
        }
    }

    // 立即同步回放全部（适合单元测试，无需 QEventLoop）
    void playAllSync() {
        for (const auto& frame : m_frames)
            emit frameReady(frame);
        emit replayFinished(m_frames.size());
    }

    // 定时异步回放（模拟真实数据速率）
    void startAsync() {
        if (m_timer) { m_index = 0; m_timer->start(); }
    }

    void stop() { if (m_timer) m_timer->stop(); }

    int totalFrames() const { return m_frames.size(); }

signals:
    void frameReady(const QByteArray& frame);
    void replayFinished(int totalFrames);

private slots:
    void playNext() {
        if (m_index >= m_frames.size()) {
            m_timer->stop();
            emit replayFinished(m_index);
            return;
        }
        emit frameReady(m_frames[m_index++]);
    }

    QList<QByteArray> m_frames;
    QTimer* m_timer = nullptr;
    int m_index = 0;
};
```

### 测试用法

```cpp
// 测试1：同步回放（单元测试）
TEST_F(FrameParserTest, parsesAllFrames_FromRecordedData) {
    // 内联小规模录制数据
    QList<QByteArray> capturedFrames = {
        QByteArray::fromHex("AA010063BE"),  // 帧1: 温度 9.9°C
        QByteArray::fromHex("AA0100FA4F"),  // 帧2: 温度 25.0°C
        QByteArray::fromHex("AA01004B46"),  // 帧3: 温度 7.5°C
    };
    DataReplay replay(capturedFrames);

    FrameParser sut;
    connect(&replay, &DataReplay::frameReady, &sut, &FrameParser::processFrame);

    QSignalSpy spy(&sut, &FrameParser::frameParsed);
    replay.playAllSync();  // 同步，无需等待

    ASSERT_EQ(spy.count(), 3);
    EXPECT_NEAR(spy.at(0).first().toDouble(),  9.9, 0.01);
    EXPECT_NEAR(spy.at(1).first().toDouble(), 25.0, 0.01);
    EXPECT_NEAR(spy.at(2).first().toDouble(),  7.5, 0.01);
}

// 测试2：从真实录制文件回放（回归测试）
TEST_F(FrameParserTest, matchesReferenceOutput_OnRealCapture) {
    // 测试数据文件位于 tests/testdata/capture_nominal.hex
    auto* replay = DataReplay::fromHexFile(
        QCoreApplication::applicationDirPath() + "/testdata/capture_nominal.hex"
    );
    ASSERT_NE(replay, nullptr) << "找不到录制数据文件";

    FrameParser sut;
    int parsedCount = 0;
    connect(&sut, &FrameParser::frameParsed, [&]() { ++parsedCount; });
    connect(replay, &DataReplay::frameReady, &sut, &FrameParser::processFrame);

    replay->playAllSync();

    EXPECT_EQ(parsedCount, replay->totalFrames()) << "存在未能解析的帧";
    EXPECT_EQ(sut.errorCount(), 0) << "存在解析错误";

    delete replay;
}

// 测试3：以真实速率回放，验证流量控制
TEST_F(BufferTest, doesNotOverflow_AtNominalDataRate) {
    auto* replay = DataReplay::fromHexFile("testdata/capture_10hz.hex", 100 /*10Hz*/);
    RingBuffer sut(64 /*capacity*/);
    connect(replay, &DataReplay::frameReady, &sut, &RingBuffer::push);
    QSignalSpy overflowSpy(&sut, &RingBuffer::overflow);

    QSignalSpy doneSpy(replay, &DataReplay::replayFinished);
    replay->startAsync();
    QTRY_COMPARE_WITH_TIMEOUT(doneSpy.count(), 1, 5000);

    EXPECT_EQ(overflowSpy.count(), 0);
    delete replay;
}
```

---

## 模式 5：故障注入仿真器

### 适用场景
- 验证容错逻辑（重试、超时、断线重连）
- 测试边界：特定帧序号出现校验错误
- 混沌测试：随机在 N% 的帧上注入错误

### 故障注入框架

```cpp
// FaultInjectionProxy.h
#pragma once
#include <QObject>
#include <QMap>
#include <functional>

// 代理模式：包装真实/Fake 数据源，在指定位置注入故障
template<typename Interface>
class FaultInjectionProxy : public Interface {
public:
    enum class FaultType {
        Drop,         // 丢弃此帧（返回空）
        Corrupt,      // 翻转最后一字节（破坏校验和）
        Delay,        // 阻塞 N 毫秒后返回
        Duplicate,    // 连续返回两次相同数据
        Garbage,      // 返回随机垃圾数据
    };

    explicit FaultInjectionProxy(Interface* real) : m_real(real) {}

    // 在第 frameIndex 帧注入故障
    void injectAt(int frameIndex, FaultType fault, int delayMs = 100) {
        m_schedule[frameIndex] = {fault, delayMs};
    }

    // 以概率 prob 随机注入故障（混沌测试）
    void injectRandom(double prob, FaultType fault, unsigned seed = 42) {
        m_randomFault = {prob, fault, std::mt19937(seed)};
    }

    // readFrame() 委托给真实实现，并在指定位置注入故障
    QByteArray readFrame() {
        int idx = m_callCount++;
        QByteArray frame = m_real->readFrame();

        // 检查定点故障
        if (m_schedule.contains(idx)) {
            return applyFault(frame, m_schedule[idx].type, m_schedule[idx].delayMs);
        }

        // 检查随机故障
        if (m_randomFault) {
            auto& [prob, type, rng] = *m_randomFault;
            if (std::uniform_real_distribution<double>(0, 1)(rng) < prob)
                return applyFault(frame, type, 0);
        }

        return frame;
    }

private:
    QByteArray applyFault(QByteArray frame, FaultType type, int delayMs) {
        switch (type) {
            case FaultType::Drop:
                return QByteArray{};
            case FaultType::Corrupt:
                if (!frame.isEmpty()) frame[frame.size() - 1] ^= 0xFF;
                return frame;
            case FaultType::Delay:
                QThread::msleep(delayMs);
                return frame;
            case FaultType::Duplicate:
                m_pendingDuplicate = frame;
                return frame;
            case FaultType::Garbage:
                return QByteArray(frame.size(), static_cast<char>(0xFF));
        }
        return frame;
    }

    Interface* m_real;
    struct ScheduledFault { FaultType type; int delayMs; };
    QMap<int, ScheduledFault> m_schedule;
    struct RandomFault { double prob; FaultType type; std::mt19937 rng; };
    std::optional<RandomFault> m_randomFault;
    QByteArray m_pendingDuplicate;
    int m_callCount = 0;
};
```

### 测试用法

```cpp
// 测试：系统在第3帧丢包后能恢复
TEST_F(ProtocolReceiverTest, recoversFromFrameDrop) {
    FakeDataSource base(normalFrames);
    FaultInjectionProxy<IDataSource> proxy(&base);
    proxy.injectAt(3, FaultInjectionProxy<IDataSource>::FaultType::Drop);

    ProtocolReceiver sut(&proxy);
    QSignalSpy dropSpy(&sut, &ProtocolReceiver::frameLost);
    QSignalSpy okSpy(&sut, &ProtocolReceiver::frameReceived);

    for (int i = 0; i < 6; ++i) sut.processNext();

    EXPECT_EQ(dropSpy.count(), 1);  // 第3帧丢失
    EXPECT_EQ(okSpy.count(), 5);    // 其余5帧正常
    EXPECT_FALSE(sut.isInErrorState());  // 系统已恢复
}

// 混沌测试：5% 随机丢包时，系统不崩溃
TEST_F(ProtocolReceiverTest, doesNotCrash_Under5PercentPacketLoss) {
    FakeDataSource base(generateFrames(1000));
    FaultInjectionProxy<IDataSource> proxy(&base);
    proxy.injectRandom(0.05,
        FaultInjectionProxy<IDataSource>::FaultType::Drop,
        42 /*seed*/);

    ProtocolReceiver sut(&proxy);
    EXPECT_NO_THROW({
        for (int i = 0; i < 1000; ++i) sut.processNext();
    });
    EXPECT_LT(sut.errorRate(), 0.1);  // 错误率应低于 10%
}
```

---

## 模式 6：协议帧序列仿真器

### 适用场景
- 模拟握手协议（连接建立→身份验证→数据传输→断开）
- 仿真 Modbus/CANbus/UART 协议交互
- 测试状态机驱动的通信层

```cpp
// ProtocolSessionSimulator.h
class ProtocolSessionSimulator : public IDataSource {
    Q_OBJECT
public:
    enum class Stage {
        Handshake,     // 握手阶段：发送 HELLO 帧
        Auth,          // 认证阶段：发送 AUTH 帧
        DataTransfer,  // 数据传输：循环发送数据帧
        Teardown,      // 结束阶段：发送 BYE 帧
        Done           // 会话结束
    };

    ProtocolSessionSimulator(QList<QByteArray> dataFrames)
        : m_dataFrames(std::move(dataFrames)) {}

    QByteArray readFrame() override {
        switch (m_stage) {
            case Stage::Handshake:
                m_stage = Stage::Auth;
                return buildHandshakeFrame();
            case Stage::Auth:
                m_stage = Stage::DataTransfer;
                return buildAuthFrame("test_user", "test_pass");
            case Stage::DataTransfer:
                if (m_dataIndex < m_dataFrames.size())
                    return m_dataFrames[m_dataIndex++];
                m_stage = Stage::Teardown;
                return readFrame();  // 递归进入下一阶段
            case Stage::Teardown:
                m_stage = Stage::Done;
                emit sessionEnded();
                return buildTeardownFrame();
            case Stage::Done:
                return {};
        }
        return {};
    }

    bool hasMore() const override { return m_stage != Stage::Done; }
    Stage currentStage() const { return m_stage; }

signals:
    void sessionEnded();

private:
    static QByteArray buildHandshakeFrame() {
        return QByteArray::fromHex("010000000000");  // HELLO
    }
    static QByteArray buildAuthFrame(const char* user, const char* pass) {
        QByteArray f;
        f.append('\x02');
        f.append(user); f.append('\x00');
        f.append(pass); f.append('\x00');
        return f;
    }
    static QByteArray buildTeardownFrame() {
        return QByteArray::fromHex("0F000000");  // BYE
    }

    QList<QByteArray> m_dataFrames;
    Stage m_stage = Stage::Handshake;
    int m_dataIndex = 0;
};

// 测试用法：验证完整协议会话
TEST_F(ProtocolClientTest, completesFullSession_Successfully) {
    QList<QByteArray> payload = {
        QByteArray::fromHex("030001001234"),
        QByteArray::fromHex("030002005678"),
    };
    ProtocolSessionSimulator sim(payload);
    ProtocolClient sut(&sim);

    QSignalSpy doneSpy(&sut, &ProtocolClient::sessionCompleted);
    QSignalSpy errSpy(&sut, &ProtocolClient::sessionFailed);

    sut.startSession();

    QTRY_COMPARE_WITH_TIMEOUT(doneSpy.count(), 1, 2000);
    EXPECT_EQ(errSpy.count(), 0);
    EXPECT_EQ(sut.receivedFrameCount(), payload.size());
}
```

---

## 仿真器的测试最佳实践

### 可重复性
```cpp
// ✓ 固定随机种子 — 每次运行结果完全一致
NoisyDataSource src(25.0, 0.5, 42 /*seed*/);

// ✗ 不固定种子 — 偶发失败，难以调试
NoisyDataSource src(25.0, 0.5, std::random_device{}());
```

### 清理资源
```cpp
class SimulatorTest : public ::testing::Test {
protected:
    void SetUp() override {
        sim = std::make_unique<SimulatedPeriodicSource<double>>(50, data);
    }

    void TearDown() override {
        sim->stop();  // 必须停止，否则 QTimer 在测试结束后仍会触发
    }

    std::unique_ptr<SimulatedPeriodicSource<double>> sim;
};
```

### 控制仿真速度
```cpp
// 单元测试中：用 0ms 间隔立即同步，或用 OneShot 模式
SimulatedPeriodicSource<double> sim(0 /*立即*/, data, PlayMode::OneShot);
sim.start();
// 数据同步发出，无需等待

// 集成测试中：用接近真实的速率（但缩短以减少等待时间）
SimulatedPeriodicSource<double> sim(10 /*ms，比真实100ms更快*/, data);
```

### 测试数据文件管理
```
tests/
├── testdata/                  # 仿真数据文件目录
│   ├── capture_nominal.hex    # 正常工况录制
│   ├── capture_fault.hex      # 故障场景录制
│   ├── capture_boundary.hex   # 边界值录制
│   └── README.md              # 说明每个文件的录制条件
├── CMakeLists.txt
└── test_protocol_parser.cpp
```

```cmake
# CMakeLists.txt 中复制测试数据文件
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/testdata/capture_nominal.hex
    ${CMAKE_CURRENT_BINARY_DIR}/testdata/capture_nominal.hex
    COPYONLY
)
```
