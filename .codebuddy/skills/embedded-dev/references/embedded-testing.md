# 嵌入式测试策略

## 概述

嵌入式系统测试面临独特挑战：硬件依赖、实时约束、交叉编译。本文档提供主机端测试、目标板测试和硬件在环测试的全面策略。

## 测试金字塔 (嵌入式版)

```
           ╱╲        HIL 硬件在环 (少量, 昂贵) — 真实硬件 + 外部激励
          ╱  ╲
         ╱────╲      目标板测试 (适量) — 在实际硬件上运行
        ╱      ╲
       ╱────────╲    主机端单元测试 (大量, 快) — mock 硬件依赖
      ╱__________╲
```

| 层级 | 环境 | 速度 | 测试内容 |
|------|------|------|----------|
| 单元测试 | 主机 | < 10ms | 业务逻辑、算法、协议解析 |
| 集成测试 | 主机/目标板 | 100ms-1s | 外设驱动、RTOS 任务、中断 |
| 系统测试 | 目标板 | 秒级 | 完整功能、时序、性能 |
| HIL 测试 | 真实硬件 | 分钟级 | 外部接口、极端条件、可靠性 |

## 快速开始清单

- [ ] **测试框架已配置** (GoogleTest, Catch2, Unity)
- [ ] **主机编译配置** (CMake toolchain)
- [ ] **硬件抽象层** 可 mock
- [ ] **CI 流水线** 运行主机端测试
- [ ] **覆盖率报告** 生成工具就绪
- [ ] **目标板测试框架** (可选)
- [ ] **串口测试输出** (目标板)

---

## 1. 主机端单元测试

### 测试框架选择

| 框架 | 特点 | 适用场景 |
|------|------|----------|
| GoogleTest | 功能丰富, mock 支持 | 复杂项目, C++ |
| Catch2 | 单头文件, 灵活 | 中小型项目 |
| Unity | C 语言, 轻量 | 纯 C 项目 |
| CppUTest | 嵌入式友好 | TDD 开发 |

### GoogleTest 配置

```cmake
# CMakeLists.txt
cmake_minimum_required(VERSION 3.20)
project(embedded_tests)

# 主机端测试配置
if(NOT CMAKE_CROSSCOMPILING)
    enable_testing()
    
    # GoogleTest
    include(FetchContent)
    FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG v1.14.0
    )
    FetchContent_MakeAvailable(googletest)
    
    # 测试可执行文件
    add_executable(unit_tests
        tests/test_ring_buffer.cpp
        tests/test_pid_controller.cpp
        tests/test_protocol_parser.cpp
    )
    
    target_link_libraries(unit_tests gtest_main gmock)
    
    # 包含被测代码 (硬件无关部分)
    target_include_directories(unit_tests PRIVATE
        ${CMAKE_SOURCE_DIR}/src/utils
        ${CMAKE_SOURCE_DIR}/src/app
    )
    
    # 定义测试宏
    target_compile_definitions(unit_tests PRIVATE
        TEST_ON_HOST=1
        MOCK_HARDWARE=1
    )
    
    # 注册测试
    include(GoogleTest)
    gtest_discover_tests(unit_tests)
endif()
```

### 硬件抽象 Mock

```cpp
// hal/igpio.hpp - 硬件抽象接口
class IGpio {
public:
    virtual ~IGpio() = default;
    virtual void write(bool state) = 0;
    virtual bool read() const = 0;
    virtual void toggle() = 0;
};

// hal/gpio.hpp - 真实硬件实现
class Stm32Gpio : public IGpio {
public:
    explicit Stm32Gpio(GPIO_TypeDef* port, uint16_t pin);
    void write(bool state) override {
        HAL_GPIO_WritePin(port_, pin_, state ? GPIO_PIN_SET : GPIO_PIN_RESET);
    }
    // ...
};

// tests/mocks/mock_gpio.hpp - Mock 实现
#include <gmock/gmock.h>

class MockGpio : public IGpio {
public:
    MOCK_METHOD(void, write, (bool state), (override));
    MOCK_METHOD(bool, read, (), (const, override));
    MOCK_METHOD(void, toggle, (), (override));
};

// tests/test_led_controller.cpp - 使用 Mock 测试
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "mock_gpio.hpp"
#include "led_controller.hpp"

using ::testing::_;
using ::testing::Return;

TEST(LedControllerTest, TurnOn) {
    MockGpio mock_gpio;
    LedController controller(mock_gpio);
    
    // 期望 write 被调用一次，参数为 true
    EXPECT_CALL(mock_gpio, write(true)).Times(1);
    
    controller.turn_on();
}

TEST(LedControllerTest, BlinkPattern) {
    MockGpio mock_gpio;
    LedController controller(mock_gpio);
    
    {
        ::testing::InSequence seq;
        EXPECT_CALL(mock_gpio, write(true));
        EXPECT_CALL(mock_gpio, write(false));
        EXPECT_CALL(mock_gpio, write(true));
    }
    
    controller.blink(2);
}
```

### 算法单元测试

```cpp
// utils/pid_controller.hpp
class PidController {
public:
    struct Config {
        float kp;
        float ki;
        float kd;
        float setpoint;
        float output_min;
        float output_max;
    };
    
    explicit PidController(const Config& config) : config_(config) {}
    
    float update(float measurement, float dt) {
        float error = config_.setpoint - measurement;
        
        integral_ += error * dt;
        float derivative = (error - prev_error_) / dt;
        prev_error_ = error;
        
        float output = config_.kp * error + 
                       config_.ki * integral_ + 
                       config_.kd * derivative;
        
        // 限幅
        output = clamp(output, config_.output_min, config_.output_max);
        
        return output;
    }
    
private:
    Config config_;
    float integral_ = 0.0f;
    float prev_error_ = 0.0f;
    
    static float clamp(float value, float min, float max) {
        if (value < min) return min;
        if (value > max) return max;
        return value;
    }
};

// tests/test_pid_controller.cpp
#include <gtest/gtest.h>
#include "pid_controller.hpp"

class PidControllerTest : public ::testing::Test {
protected:
    void SetUp() override {
        PidController::Config config = {
            .kp = 1.0f,
            .ki = 0.1f,
            .kd = 0.01f,
            .setpoint = 100.0f,
            .output_min = -100.0f,
            .output_max = 100.0f
        };
        controller_ = std::make_unique<PidController>(config);
    }
    
    std::unique_ptr<PidController> controller_;
};

TEST_F(PidControllerTest, OutputClamping) {
    // 测试输出限幅
    float output = controller_->update(0.0f, 0.01f);  // 大误差
    EXPECT_NEAR(output, 100.0f, 0.01f);  // 限幅到最大值
}

TEST_F(PidControllerTest, IntegralAccumulation) {
    // 测试积分累积
    float output1 = controller_->update(90.0f, 0.1f);  // error = 10
    float output2 = controller_->update(95.0f, 0.1f);  // error = 5
    
    // 积分项应该累积
    // output1 ≈ 1.0*10 + 0.1*1.0 = 11
    // output2 ≈ 1.0*5 + 0.1*1.5 = 5.15
    EXPECT_GT(output1, output2);
}

TEST_F(PidControllerTest, ReachesSetpoint) {
    // 模拟闭环控制
    float measurement = 0.0f;
    for (int i = 0; i < 100; ++i) {
        float output = controller_->update(measurement, 0.01f);
        measurement += output * 0.1f;  // 简单系统响应
    }
    
    EXPECT_NEAR(measurement, 100.0f, 5.0f);  // 接近设定点
}
```

### 协议解析测试

```cpp
// utils/protocol_parser.hpp
class ProtocolParser {
public:
    enum class State { Idle, Header, Payload, Checksum };
    
    struct Frame {
        uint8_t header;
        std::array<uint8_t, 32> payload;
        uint8_t length;
        uint8_t checksum;
        bool valid;
    };
    
    void feed(uint8_t byte) {
        switch (state_) {
            case State::Idle:
                if (byte == 0xAA) {
                    frame_.header = byte;
                    state_ = State::Header;
                }
                break;
                
            case State::Header:
                frame_.length = byte;
                payload_index_ = 0;
                state_ = State::Payload;
                break;
                
            case State::Payload:
                if (payload_index_ < frame_.length && payload_index_ < 32) {
                    frame_.payload[payload_index_++] = byte;
                }
                if (payload_index_ >= frame_.length) {
                    state_ = State::Checksum;
                }
                break;
                
            case State::Checksum:
                frame_.checksum = byte;
                frame_.valid = verify_checksum();
                state_ = State::Idle;
                break;
        }
    }
    
    const Frame& frame() const { return frame_; }
    bool has_frame() const { return frame_.valid; }
    
private:
    bool verify_checksum() {
        uint8_t sum = 0;
        for (size_t i = 0; i < frame_.length; ++i) {
            sum += frame_.payload[i];
        }
        return sum == frame_.checksum;
    }
    
    State state_ = State::Idle;
    Frame frame_{};
    size_t payload_index_ = 0;
};

// tests/test_protocol_parser.cpp
#include <gtest/gtest.h>
#include "protocol_parser.hpp"

TEST(ProtocolParserTest, ParseValidFrame) {
    ProtocolParser parser;
    
    // 构造有效帧: [0xAA][len][payload...][checksum]
    std::vector<uint8_t> frame = {
        0xAA,  // header
        0x03,  // length
        0x01, 0x02, 0x03,  // payload
        0x06   // checksum = 0x01 + 0x02 + 0x03
    };
    
    for (uint8_t byte : frame) {
        parser.feed(byte);
    }
    
    EXPECT_TRUE(parser.has_frame());
    EXPECT_EQ(parser.frame().length, 3);
    EXPECT_EQ(parser.frame().payload[0], 0x01);
}

TEST(ProtocolParserTest, RejectInvalidChecksum) {
    ProtocolParser parser;
    
    std::vector<uint8_t> frame = {
        0xAA, 0x02,
        0x10, 0x20,
        0x00  // 错误的 checksum
    };
    
    for (uint8_t byte : frame) {
        parser.feed(byte);
    }
    
    EXPECT_FALSE(parser.has_frame());
}

TEST(ProtocolParserTest, IgnoreInvalidHeader) {
    ProtocolParser parser;
    
    parser.feed(0x55);  // 无效 header
    parser.feed(0xAA);  // 有效 header
    parser.feed(0x01);  // length
    parser.feed(0x42);  // payload
    parser.feed(0x42);  // checksum
    
    EXPECT_TRUE(parser.has_frame());
}
```

---

## 2. 集成测试

### 外设驱动测试 (目标板)

```cpp
// tests/target/test_uart_driver.cpp
// 此测试在目标板上运行

#include "unity.h"
#include "uart_driver.h"
#include "board.h"

void setUp(void) {
    // 初始化 UART
    uart_init(UART1, 115200);
}

void tearDown(void) {
    // 清理
    uart_deinit(UART1);
}

void test_uart_transmit_receive(void) {
    uint8_t tx_data[] = "Hello";
    uint8_t rx_data[5] = {0};
    
    // 发送
    uart_write(UART1, tx_data, sizeof(tx_data));
    
    // 等待回环 (需要外部连接 TX-RX)
    delay_ms(10);
    
    // 接收
    size_t received = uart_read(UART1, rx_data, sizeof(rx_data), 100);
    
    TEST_ASSERT_EQUAL_UINT(5, received);
    TEST_ASSERT_EQUAL_MEMORY(tx_data, rx_data, 5);
}

void test_uart_timeout(void) {
    uint8_t rx_data[10];
    
    // 没有数据接收，应该超时
    size_t received = uart_read(UART1, rx_data, sizeof(rx_data), 100);
    
    TEST_ASSERT_EQUAL_UINT(0, received);
}

int main(void) {
    board_init();
    
    UNITY_BEGIN();
    RUN_TEST(test_uart_transmit_receive);
    RUN_TEST(test_uart_timeout);
    return UNITY_END();
}
```

### RTOS 任务测试

```cpp
// tests/target/test_rtos_tasks.cpp
#include "unity.h"
#include "FreeRTOS.h"
#include "task.h"
#include "queue.h"

static QueueHandle_t test_queue;
static int producer_count = 0;
static int consumer_count = 0;

void producer_task(void* params) {
    int value = 1;
    for (int i = 0; i < 10; ++i) {
        xQueueSend(test_queue, &value, 0);
        producer_count++;
        vTaskDelay(pdMS_TO_TICKS(10));
    }
    vTaskDelete(NULL);
}

void consumer_task(void* params) {
    int value;
    for (int i = 0; i < 10; ++i) {
        if (xQueueReceive(test_queue, &value, pdMS_TO_TICKS(100))) {
            consumer_count++;
        }
    }
    vTaskDelete(NULL);
}

void test_queue_communication(void) {
    test_queue = xQueueCreate(10, sizeof(int));
    TEST_ASSERT_NOT_NULL(test_queue);
    
    xTaskCreate(producer_task, "Producer", 128, NULL, 1, NULL);
    xTaskCreate(consumer_task, "Consumer", 128, NULL, 1, NULL);
    
    // 等待任务完成
    vTaskDelay(pdMS_TO_TICKS(500));
    
    TEST_ASSERT_EQUAL_INT(10, producer_count);
    TEST_ASSERT_EQUAL_INT(10, consumer_count);
    
    vQueueDelete(test_queue);
}

int main(void) {
    UNITY_BEGIN();
    RUN_TEST(test_queue_communication);
    return UNITY_END();
}
```

---

## 3. 系统测试

### 功能测试框架

```cpp
// tests/system/system_test_framework.hpp
#include <cstdint>
#include <cstdio>

class SystemTest {
public:
    struct Result {
        const char* name;
        bool passed;
        const char* message;
        uint32_t duration_ms;
    };
    
    virtual ~SystemTest() = default;
    virtual const char* name() const = 0;
    virtual Result run() = 0;
    
protected:
    Result make_result(bool passed, const char* message = "", uint32_t duration_ms = 0) {
        return {name(), passed, message, duration_ms};
    }
};

// 测试注册宏
#define REGISTER_TEST(TestClass) \
    static TestClass test_instance;

// 测试运行器
class TestRunner {
public:
    void register_test(SystemTest* test) {
        tests_[count_++] = test;
    }
    
    void run_all() {
        printf("Running %d system tests...\r\n", count_);
        
        int passed = 0;
        int failed = 0;
        
        for (size_t i = 0; i < count_; ++i) {
            auto result = tests_[i]->run();
            
            if (result.passed) {
                printf("[PASS] %s (%lu ms)\r\n", result.name, result.duration_ms);
                passed++;
            } else {
                printf("[FAIL] %s: %s\r\n", result.name, result.message);
                failed++;
            }
        }
        
        printf("\r\nResults: %d passed, %d failed\r\n", passed, failed);
    }
    
private:
    static constexpr size_t MAX_TESTS = 32;
    SystemTest* tests_[MAX_TESTS];
    size_t count_ = 0;
};

// 具体测试示例
class SensorReadingTest : public SystemTest {
public:
    const char* name() const override { return "Sensor Reading"; }
    
    Result run() override {
        uint32_t start = get_tick_ms();
        
        // 初始化传感器
        if (!sensor_init()) {
            return make_result(false, "Sensor init failed");
        }
        
        // 读取传感器数据
        for (int i = 0; i < 100; ++i) {
            float value;
            if (!sensor_read(&value)) {
                return make_result(false, "Sensor read failed");
            }
            
            if (value < 0.0f || value > 100.0f) {
                return make_result(false, "Sensor value out of range");
            }
        }
        
        uint32_t duration = get_tick_ms() - start;
        return make_result(true, "", duration);
    }
};
```

---

## 4. 覆盖率分析

### 主机端覆盖率 (gcov)

```cmake
# CMakeLists.txt
if(NOT CMAKE_CROSSCOMPILING)
    # 启用覆盖率
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage -fprofile-arcs -ftest-coverage")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
endif()

# 运行测试后生成覆盖率报告
# ctest
# gcov src/*.cpp
# lcov --capture --directory . --output-file coverage.info
# genhtml coverage.info --output-directory coverage_report
```

### 目标板覆盖率

```cpp
// 使用 GCC 的覆盖率插桩
// 编译时添加: -fprofile-arcs -ftest-coverage

// 注意: 目标板覆盖率需要额外的 Flash 空间存储数据
// 在程序退出或定期将覆盖率数据写入 Flash 或通过串口发送

void dump_coverage_data() {
    // GCC 覆盖率数据结构
    extern uint32_t __gcov_init;
    extern uint32_t __gcov_merge_add;
    
    // 将覆盖率数据通过串口发送
    // 需要在 PC 端接收并合并到 .gcda 文件
}
```

---

## 5. 持续集成

### GitHub Actions 配置

```yaml
# .github/workflows/test.yml
name: Embedded Tests

on: [push, pull_request]

jobs:
  host-tests:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y cmake gcc g++ lcov
    
    - name: Configure
      run: cmake -B build -DCMAKE_BUILD_TYPE=Debug
    
    - name: Build
      run: cmake --build build
    
    - name: Run tests
      working-directory: build
      run: ctest --output-on-failure
    
    - name: Generate coverage
      working-directory: build
      run: |
        lcov --capture --directory . --output-file coverage.info
        lcov --remove coverage.info '/usr/*' '*/tests/*' --output-file coverage.info
        lcov --list coverage.info
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3
      with:
        file: build/coverage.info

  firmware-build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Install ARM toolchain
      run: |
        sudo apt-get update
        sudo apt-get install -y gcc-arm-none-eabi
    
    - name: Build firmware
      run: |
        cmake -B build -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi.cmake
        cmake --build build
    
    - name: Upload firmware
      uses: actions/upload-artifact@v3
      with:
        name: firmware
        path: build/firmware.bin
```

---

## 测试清单

### 单元测试

- [ ] 业务逻辑有完整的单元测试
- [ ] 算法有边界值测试
- [ ] 协议解析有异常情况测试
- [ ] Mock 硬件依赖
- [ ] 覆盖率 ≥ 80%

### 集成测试

- [ ] 外设驱动在目标板上测试
- [ ] RTOS 任务间通信测试
- [ ] 中断处理测试
- [ ] 电源模式切换测试

### 系统测试

- [ ] 完整功能流程测试
- [ ] 性能和时序测试
- [ ] 极端条件测试 (温度、电压)
- [ ] 长期稳定性测试
