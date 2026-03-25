---
name: embedded-dev
description: |
  C++ 嵌入式系统开发指南。
  触发条件: 开发嵌入式系统、编写 MCU 程序、移植 RTOS、编写硬件驱动、
  调试裸机程序、交叉编译、C++ 嵌入式开发、STM32 开发、ARM Cortex-M 开发、
  板级支持包 (BSP)、外设驱动开发 (GPIO、UART、I2C、SPI、ADC)、
  低功耗设计、中断处理、嵌入式调试 (JTAG/SWD)、RTOS 应用开发。
  不触发条件: 纯桌面应用开发、Web 开发、移动端开发。
license: MIT
metadata:
  category: embedded-systems
  version: "1.0.0"
  sources:
    - MISRA C++ (汽车电子编码标准)
    - JSF C++ (航空航天 C++ 编码标准)
    - AUTOSAR C++ (汽车开放系统架构)
    - Embedded C++ Coding Standard (Barr Group)
    - RTOS Development Guidelines
    - ARM CMSIS Documentation
    - STM32 HAL/LL Driver Documentation
---

# C++ 嵌入式开发实践

## 强制工作流 — 按顺序执行以下步骤

**当此技能被触发时，在编写任何代码前必须遵循此工作流。**

### 第 0 步: 收集需求

在开始嵌入式项目之前，请用户明确（或从上下文中推断）:

1. **目标硬件**: MCU 型号、架构 (ARM Cortex-M、RISC-V、AVR、ESP32 等)
2. **开发环境**: IDE (Keil、IAR、STM32CubeIDE)、交叉编译工具链
3. **RTOS 需求**: 是否使用 RTOS? 如需 — FreeRTOS、RT-Thread、Zephyr 还是裸机?
4. **外设清单**: 需要使用的外设 (GPIO、UART、I2C、SPI、ADC、DMA、PWM 等)
5. **实时性要求**: 硬实时 vs 软实时、确定性与延迟要求
6. **资源约束**: Flash/RAM 大小、功耗预算、温度范围

如果用户已在请求中说明这些，跳过询问直接继续。

### 第 1 步: 架构决策

根据需求，在编码前做出并说明以下决策:

| 决策项 | 选项 | 参考 |
|--------|------|------|
| 项目结构 | 特性优先 vs 分层优先 | [第 1 节](#1-项目结构与分层-关键) |
| 驱动模型 | 裸机驱动 vs HAL vs LL | [第 4 节](#4-外设驱动开发-高) |
| 内存管理 | 静态分配 vs 动态分配 | [第 3 节](#3-内存管理与资源约束-关键) |
| 中断模型 | 传统中断 vs RTOS 中断 | [第 5 节](#5-中断处理与实时性-高) |
| 错误处理 | 错误码 vs 异常 | [第 6 节](#6-错误处理与防御性编程-高) |

简要解释每个选择 (每项 1 句话)。

### 第 2 步: 使用清单搭建项目

使用下方合适的清单。确保所有勾选项都已实现 — 不要跳过任何一项。

### 第 3 步: 按模式实现

编写代码时遵循本文档中的模式。实现各部分时引用具体章节。

### 第 4 步: 测试与验证

实现完成后，在声称完成前运行以下检查:

1. **编译检查**: 确保无警告编译通过
   ```bash
   # 使用交叉编译工具链
   cmake -B build -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi.cmake
   cmake --build build
   ```
2. **静态分析**: 运行静态分析工具检查代码质量
   ```bash
   # 使用 clang-tidy 或专有静态分析工具
   clang-tidy -checks='*' source/*.cpp
   ```
3. **单元测试**: 在主机上运行可测试模块的单元测试
   ```bash
   # 主机端测试
   cmake -B host-build -DCMAKE_TOOLCHAIN_FILE=cmake/host.cmake
   ctest --output-on-failure
   ```
4. **目标板验证**: 在目标硬件上验证关键功能
   - GPIO 翻转测试
   - 外设通信测试 (UART、SPI、I2C)
   - 中断响应时间测量
   - 内存使用验证

如有任何检查失败，先修复问题再继续。

### 第 5 步: 移交摘要

向用户提供简要摘要:

- **已完成**: 实现的功能和外设列表
- **如何烧录**: 烧录工具和命令
- **缺失项/后续步骤**: 任何延期项目、已知限制或建议改进
- **关键文件**: 用户应了解的最重要的文件列表

---

## 适用范围

**使用此技能的情况:**
- 开发嵌入式系统 (MCU、RTOS)
- 编写硬件驱动 (GPIO、UART、I2C、SPI、ADC 等)
- 交叉编译 C++ 代码到嵌入式平台
- 板级支持包 (BSP) 开发
- 嵌入式调试 (JTAG/SWD)
- 低功耗设计实现
- 嵌入式 C++ 编码规范实践
- RTOS 应用开发

**不适用的情况:**
- 纯桌面应用开发
- Web/移动端开发
- 高性能计算 (HPC) 开发

---

## 快速开始 — 新嵌入式项目清单

- [ ] 使用**分层模块化**结构搭建项目
- [ ] 配置**交叉编译工具链** (ARM GCC、Clang/RISC-V 等)
- [ ] 定义**外设抽象层** (HAL/LL 或自定义)
- [ ] 添加**硬件抽象层** (HAL) 接口
- [ ] 配置**链接脚本** (Flash、RAM 布局)
- [ ] 实现**启动代码** (复位向量、初始化)
- [ ] 所有外设的**初始化序列** (时钟、GPIO、外设)
- [ ] 添加**看门狗** (防止系统死锁)
- [ ] 配置**中断向量表**
- [ ] 添加**串口调试**输出 (用于开发调试)
- [ ] 实现**内存保护** (MPU 配置，如适用)
- [ ] 提交 `.example` 配置文件 (不含真实硬件参数)

## 快速开始 — 嵌入式驱动开发清单

- [ ] 阅读芯片**数据手册**和**参考手册**
- [ ] 实现**外设初始化**函数
- [ ] 实现**读写操作**函数
- [ ] 实现**中断处理**函数 (如需要)
- [ ] 添加**DMA 支持** (如需要高性能)
- [ ] 实现**省电模式**切换
- [ ] 添加**状态标志**和**错误处理**
- [ ] 编写**单元测试** (可在主机运行部分)
- [ ] 验证**时序**和**电气特性**

---

## 快速导航

| 需要… | 跳转到 |
|-------|--------|
| 组织项目文件夹 | [1. 项目结构与分层](#1-项目结构与分层-关键) |
| 管理配置与硬件参数 | [2. 配置与环境](#2-配置与环境-关键) |
| 处理内存与资源约束 | [3. 内存管理与资源约束](#3-内存管理与资源约束-关键) |
| 编写外设驱动 | [4. 外设驱动开发](#4-外设驱动开发-高) |
| 处理中断与实时性 | [5. 中断处理与实时性](#5-中断处理与实时性-高) |
| 错误处理与防御性编程 | [6. 错误处理与防御性编程](#6-错误处理与防御性编程-高) |
| 调试嵌入式系统 | [7. 调试与测试](#7-调试与测试-高) |
| 低功耗设计 | [8. 低功耗设计](#8-低功耗设计-中等) |
| RTOS 应用开发 | [9. RTOS 应用开发](#9-rtos-应用开发-中等) |
| 生产部署与固件更新 | [10. 生产与固件更新](#10-生产与固件更新-中等) |
| 嵌入式编码规范 | [11. 编码规范](#11-编码规范-关键) |
| 性能优化 | [12. 性能优化](#12-性能优化-中等) |
| BSP 开发 | [references/bsp-development.md](references/bsp-development.md) |
| RTOS 选择与移植 | [references/rtos-guide.md](references/rtos-guide.md) |
| 主流 MCU 开发指南 | [references/mcu-development.md](references/mcu-development.md) |

---

## 核心原则 (10 条铁律)

```
1. 嵌入式 C++ 是 C++ 的子集 — 禁用运行时类型信息 (RTTI) 和异常
2. 始终使用静态内存分配 — 禁止 malloc/new (除非有充分的理由和内存保护)
3. 所有外设访问必须通过抽象层 — 不直接操作寄存器
4. 中断处理函数应尽可能短 — 只做必要操作，复杂逻辑放到主循环
5. 所有配置通过结构化配置块 — 不散布 magic numbers
6. 每个错误都有状态码或标志 — 绝不能静默失败
7. 启用编译器的所有警告 — 把警告当错误处理
8. 代码必须能在主机上编译和测试 — 分离硬件相关代码
9. 测量性能和内存使用 — 不凭猜测做优化
10. 编写可读的寄存器配置代码 — 使用有意义的命名和注释
```

---

## 1. 项目结构与分层 (关键)

### 分层架构

```
嵌入式项目结构                    说明
src/
  main.cpp                         应用入口
  app/
    application.cpp                应用逻辑
    task_manager.cpp              任务管理
  bsp/
    board.cpp                      板级初始化
    clock_config.cpp               时钟配置
  hal/
    gpio.cpp                       GPIO 抽象
    uart.cpp                       UART 抽象
    spi.cpp                        SPI 抽象
    i2c.cpp                        I2C 抽象
    adc.cpp                        ADC 抽象
    timer.cpp                      定时器抽象
  drivers/
    sensor_driver.cpp              传感器驱动
    display_driver.cpp             显示驱动
    communication_driver.cpp       通信驱动
  rtos/
    freertos_wrapper.cpp           RTOS 抽象
  utils/
    ring_buffer.cpp                环形缓冲区
    fixed_pool.cpp                 固定内存池
    crc.cpp                        CRC 校验
  config/
    platform_config.hpp            平台配置
    peripheral_config.hpp          外设配置
tests/
  host_tests/                      主机端单元测试
  target_tests/                    目标板集成测试
cmake/
  arm-none-eabi.cmake              交叉编译工具链
  host.cmake                       主机编译工具链
  partitions.cmake                 Flash/RAM 分区
ld/
  linker_script.ld                链接脚本
```

### 分层职责

| 层 | 职责 | 绝不 |
|-----|------|------|
| 应用层 (app/) | 业务逻辑、状态机、任务编排 | 直接操作外设、直接访问硬件 |
| BSP 层 (bsp/) | 板级初始化、时钟配置、引脚复用 | 业务逻辑 |
| HAL 层 (hal/) | 外设抽象、统一接口、寄存器操作 | 业务逻辑、高层协议 |
| 驱动层 (drivers/) | 器件驱动、传感器协议、通信协议 | 直接操作 CPU 寄存器 |
| 工具层 (utils/) | 通用数据结构、算法、辅助函数 | 硬件相关代码 |

### 依赖注入 (嵌入式 C++)

```cpp
// 通过接口抽象硬件依赖
class IGpio {
public:
    virtual ~IGpio() = default;
    virtual void write(bool state) = 0;
    virtual bool read() const = 0;
    virtual void toggle() = 0;
};

// 具体实现
class Stm32Gpio : public IGpio {
public:
    explicit Stm32Gpio(GPIO_TypeDef* port, uint16_t pin) : port_(port), pin_(pin) {}
    void write(bool state) override {
        HAL_GPIO_WritePin(port_, pin_, state ? GPIO_PIN_SET : GPIO_PIN_RESET);
    }
    // ...
private:
    GPIO_TypeDef* port_;
    uint16_t pin_;
};

// 依赖注入
class LedBlinker {
public:
    explicit LedBlinker(IGpio& led) : led_(led) {}  // 注入接口
    void blink() { led_.toggle(); }
private:
    IGpio& led_;  // 引用而非指针，确保非空
};
```

---

## 2. 配置与环境 (关键)

### 集中式、类型化配置

```cpp
// config/clock_config.hpp
struct ClockConfig {
    uint32_t sysclk_hz = 168'000'000;    // 系统时钟
    uint32_t hclk_hz = 168'000'000;       // AHB 总线
    uint32_t pclk1_hz = 42'000'000;       // APB1 总线
    uint32_t pclk2_hz = 84'000'000;       // APB2 总线
};

// config/pin_config.hpp
struct PinConfig {
    GPIO_TypeDef* port;
    uint16_t pin;
    GPIO_Mode_TypeDef mode;
    GPIO_OType_TypeDef otype;
    GPIO_PuPd_TypeDef pupd;
    uint8_t af;  // 复用功能
};

// 外设配置示例
struct UartConfig {
    USART_TypeDef* instance;
    uint32_t baudrate;
    WordLengthTypeDef word_length;
    StopBitsTypeDef stop_bits;
    ParityTypeDef parity;
    PinConfig tx_pin;
    PinConfig rx_pin;
};
```

### 规则

```
所有硬件配置集中在配置头文件
使用有意义的枚举替代 magic numbers
使用结构体组织相关配置参数
链接脚本必须与配置匹配
提交带示例值的 .example 配置文件

绝不直接操作寄存器 (通过 HAL/LL 或抽象层)
绝不散布 magic numbers
绝不硬编码硬件参数在业务代码中
绝不在多处定义同一配置
```

---

## 3. 内存管理与资源约束 (关键)

### 静态内存分配 (首选)

```cpp
// 静态分配 — 编译时确定，无动态分配开销
class SensorManager {
private:
    // 固定大小的缓冲区
    static constexpr size_t MAX_SAMPLES = 256;
    float samples_[MAX_SAMPLES] {};  // 零初始化
    size_t head_ = 0;
    size_t count_ = 0;

    // 禁止动态分配
    void* operator new(size_t) = delete;
    void operator delete(void*) = delete;
};
```

### 固定内存池

```cpp
// 固定大小内存池 — 嵌入式友好的动态分配替代
template<typename T, size_t N>
class FixedPool {
public:
    FixedPool() { pool_.fill(nullptr); }
    ~FixedPool() { /* 确保所有对象已归还 */ }

    T* allocate() {
        for (size_t i = 0; i < N; ++i) {
            if (!pool_[i]) {
                pool_[i] = this;
                return new (&storage_[i]) T();
            }
        }
        return nullptr;  // 池已满
    }

    void deallocate(T* ptr) {
        if (ptr) {
            ptr->~T();
            size_t idx = (static_cast<char*>(static_cast<void*>(ptr)) - storage_) / sizeof(T);
            pool_[idx] = nullptr;
        }
    }

private:
    alignas(T) char storage_[sizeof(T) * N];
    std::atomic<bool> pool_[N];
};
```

### 环形缓冲区

```cpp
template<typename T, size_t N>
class RingBuffer {
public:
    static_assert((N & (N - 1)) == 0, "N must be power of 2");

    bool write(T item) {
        if (full()) return false;
        buffer_[head_] = item;
        head_ = (head_ + 1) & (N - 1);  // 位与替代模运算
        return true;
    }

    bool read(T& item) {
        if (empty()) return false;
        item = buffer_[tail_];
        tail_ = (tail_ + 1) & (N - 1);
        return true;
    }

    bool empty() const { return head_ == tail_; }
    bool full() const { return ((head_ + 1) & (N - 1)) == tail_; }
    size_t size() const { return (head_ - tail_) & (N - 1); }

private:
    T buffer_[N];
    volatile size_t head_ = 0;  // volatile 防止编译器优化
    volatile size_t tail_ = 0;
};
```

### 内存布局

```ld
/* 链接脚本示例 */
MEMORY
{
    FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 1024K
    RAM (rwx)   : ORIGIN = 0x20000000, LENGTH = 192K
    CCMRAM (rwx): ORIGIN = 0x10000000, LENGTH = 64K
}

SECTIONS
{
    .text : {
        . = ALIGN(4);
        _stext = .;
        *(.vector_table)
        *(.text*)
        *(.rodata*)
        . = ALIGN(4);
        _etext = .;
    } > FLASH

    .data : {
        . = ALIGN(4);
        _sdata = .;
        *(.data*)
        . = ALIGN(4);
        _edata = .;
    } > RAM AT > FLASH

    .bss : {
        . = ALIGN(4);
        _sbss = .;
        *(.bss*)
        . = ALIGN(4);
        _ebss = .;
    } > RAM
}
```

### 规则

```
嵌入式 C++ 禁用 RTTI (typeid, dynamic_cast)
嵌入式 C++ 禁用异常 (noexcept 全部函数)
优先静态内存分配，禁止 malloc/new (除非有充分理由)
使用内存池管理固定大小对象的分配
使用栈时注意深度，避免大对象在栈上
关注 Flash 和 RAM 使用，测量实际占用

绝不使用 std::vector::push_back (可能触发动态分配)
绝不使用 std::string (使用固定长度 char 数组)
绝不使用 printf 族函数 (使用轻量级替代品或格式化库)
```

---

## 4. 外设驱动开发 (高)

### GPIO 驱动

```cpp
// gpio_driver.hpp
class GpioDriver {
public:
    enum class State { Low, High };
    enum class Mode { Input, Output, Alternate, Analog };
    enum class Pull { None, Up, Down };

    struct Config {
        GPIO_TypeDef* port;
        uint16_t pin;
        Mode mode;
        Pull pull = Pull::None;
        State initial_state = State::Low;
        uint8_t alternate_function = 0;
    };

    explicit GpioDriver(const Config& config);
    void write(State state);
    State read() const;
    void toggle();
    void set_mode(Mode mode);
    void enable_interrupt(Priority priority, Handler handler);

private:
    GPIO_TypeDef* const port_;
    const uint16_t pin_;
};


// gpio_driver.cpp
GpioDriver::GpioDriver(const Config& config)
    : port_(config.port), pin_(config.pin)
{
    __HAL_RCC_GPIOx_CLK_ENABLE(config.port);  // 使能时钟

    GPIO_InitTypeDef init = {};
    init.Pin = pin_;
    init.Mode = static_cast<uint32_t>(config.mode);
    init.Pull = static_cast<uint32_t>(config.pull);
    init.Alternate = config.alternate_function;
    HAL_GPIO_Init(port_, &init);

    if (config.mode == Mode::Output) {
        write(config.initial_state);
    }
}

void GpioDriver::toggle() {
    HAL_GPIO_TogglePin(port_, pin_);
}
```

### UART 驱动

```cpp
// uart_driver.hpp
class UartDriver {
public:
    using RxHandler = std::function<void(const uint8_t*, size_t)>;
    using ErrorHandler = std::function<void(UART_HandleTypeDef*)>;

    struct Config {
        USART_TypeDef* instance;
        uint32_t baudrate;
        WordLengthTypeDef word_length;
        StopBitsTypeDef stop_bits;
        ParityTypeDef parity;
        PinConfig tx_pin;
        PinConfig rx_pin;
        RxHandler rx_handler;
        ErrorHandler error_handler;
    };

    explicit UartDriver(const Config& config);
    bool write(const uint8_t* data, size_t length);
    bool write_byte(uint8_t byte);
    size_t available() const;
    void flush();

private:
    UART_HandleTypeDef huart_;
    RingBuffer<uint8_t, 256> rx_buffer_;
    StaticTask_t rx_task_block_;
    StackType_t rx_task_stack_[256];
};
```

### SPI 驱动

```cpp
// spi_driver.hpp
class SpiDriver {
public:
    enum class Mode { SPI_MODE_0, SPI_MODE_1, SPI_MODE_2, SPI_MODE_3 };
    enum class DataSize { Bits_8, Bits_16 };

    struct Config {
        SPI_TypeDef* instance;
        uint32_t baudrate_prescaler;
        Mode mode;
        DataSize data_size;
        PinConfig sck_pin;
        PinConfig mosi_pin;
        PinConfig miso_pin;
        PinConfig nss_pin;  // 可选
    };

    explicit SpiDriver(const Config& config);
    bool transfer(const uint8_t* tx_data, uint8_t* rx_data, size_t length);
    bool write(uint8_t address, const uint8_t* data, size_t length);
    bool read(uint8_t address, uint8_t* data, size_t length);

private:
    SPI_HandleTypeDef hspi_;
};

// SPI 传输实现
bool SpiDriver::transfer(const uint8_t* tx_data, uint8_t* rx_data, size_t length) {
    HAL_SPI_TransmitReceive(&hspi_, tx_data, rx_data, length, HAL_MAX_DELAY);
    return hspi_.ErrorCode == HAL_SPI_ERROR_NONE;
}
```

### I2C 驱动

```cpp
// i2c_driver.hpp
class I2cDriver {
public:
    struct Config {
        I2C_TypeDef* instance;
        uint32_t clock_speed;
        PinConfig scl_pin;
        PinConfig sda_pin;
    };

    explicit I2cDriver(const Config& config);
    bool write(uint8_t device_address, uint8_t register_address, const uint8_t* data, size_t length);
    bool read(uint8_t device_address, uint8_t register_address, uint8_t* data, size_t length);
    bool probe(uint8_t device_address);  // 检测设备是否存在

private:
    I2C_HandleTypeDef hi2c_;
};

// I2C 读写实现
bool I2cDriver::write(uint8_t device_address, uint8_t register_address,
                      const uint8_t* data, size_t length) {
    uint8_t tx_buffer[256];
    tx_buffer[0] = register_address;
    std::memcpy(&tx_buffer[1], data, length);

    return HAL_I2C_Master_Transmit(&hi2c_, device_address << 1,
                                   tx_buffer, length + 1, HAL_MAX_DELAY) == HAL_OK;
}
```

### 驱动开发规则

```
阅读芯片数据手册和参考手册
使用芯片厂商提供的 HAL/LL 库
实现标准化的初始化和配置接口
添加超时机制防止死锁
实现错误处理和恢复机制
记录外设状态便于调试

绝不直接操作寄存器 (通过 HAL)
绝不省略外设时钟使能
绝不省略引脚复用配置
绝不省略中断优先级配置
```

---

## 5. 中断处理与实时性 (高)

### 中断处理函数规范

```cpp
// 中断处理应尽可能短
extern "C" void USART1_IRQHandler() {
    // 职责: 只做必要的操作
    // 1. 读取数据到缓冲区
    // 2. 设置标志位
    // 3. 发送信号量/通知任务

    uint32_t interrupt_source = USART1->SR;
    if (interrupt_source & USART_SR_RXNE) {
        uint8_t data = USART1->DR;
        rx_buffer_.write(data);  // 写入环形缓冲区
        // 绝不在此做复杂处理
    }
}

// 复杂处理放到主循环或 RTOS 任务
void UartTask::run() {
    while (true) {
        uint8_t data;
        while (rx_buffer_.read(data)) {  // 非阻塞检查
            process_byte(data);  // 主循环中处理
        }
        delay_ms(10);
    }
}
```

### 中断优先级配置

```cpp
// 使用 CMSIS-Core 的优先级定义
constexpr IRQn_Type kUartIrqn = USART1_IRQn;
constexpr IRQn_Type kTimerIrqn = TIM2_IRQn;
constexpr IRQn_Type kExtiIrqn = EXTI15_10_IRQn;

// 配置优先级组
void interrupt_init() {
    NVIC_SetPriorityGrouping(NVIC_PRIORITYGROUP_4);  // 4 位抢占, 0 位子优先级

    // UART 中断 - 中等优先级
    NVIC_SetPriority(kUartIrqn, 5);
    NVIC_EnableIRQ(kUartIrqn);

    // 定时器中断 - 高优先级
    NVIC_SetPriority(kTimerIrqn, 2);
    NVIC_EnableIRQ(kTimerIrqn);
}
```

### 实时性设计

```cpp
// 确定性响应 - 使用状态机替代复杂计算
class MotorController {
public:
    enum class State { Idle, Accelerating, Running, Decelerating, Fault };

    void update() {  // 固定周期调用，如 1kHz
        switch (state_) {
            case State::Accelerating:
                if (current_rpm_ < target_rpm_) {
                    current_rpm_ += acceleration_;
                } else {
                    state_ = State::Running;
                }
                break;
            // ... 其他状态
        }
        update_pwm();  // 确定性操作
    }

private:
    volatile State state_;  // volatile 防止编译器优化
    uint32_t current_rpm_;
    uint32_t target_rpm_;
    uint32_t acceleration_;
};
```

### 中断规则

```
中断处理函数 (ISR) 应尽可能短
ISR 中禁止耗时操作 (禁止浮点运算、禁止互斥锁、禁止系统调用)
使用volatile 修饰共享变量
使用原子操作或临界区保护共享数据
为每个中断配置合适的优先级
始终在链接脚本中正确放置中断向量表

ISR 中绝不大量数据处理 (只做标记，实际处理放主循环)
ISR 中禁止调用会阻塞的函数
ISR 中禁止使用 printf (使用轻量级日志)
中断服务程序必须可重入
```

---

## 6. 错误处理与防御性编程 (高)

### 错误码枚举

```cpp
// error_codes.hpp
namespace ErrorCode {
enum class Code : uint32_t {
    None = 0,
    // 系统错误
    SystemInitFailed = 0x1000,
    SystemClockFailed,
    SystemWatchdogFailed,

    // 外设错误
    PeriphInitFailed = 0x2000,
    PeriphTimeout,
    PeriphNotReady,
    PeriphBusy,

    // 驱动错误
    DriverNotFound = 0x3000,
    DriverBusy,
    DriverCrcError,
    DriverProtocolError,

    // 传感器错误
    SensorNotFound = 0x4000,
    SensorCrcError,
    SensorTimeout,
    SensorOutOfRange,

    // 应用错误
    AppInvalidState = 0x5000,
    AppBufferFull,
    AppBufferEmpty,
};
}

// 错误结构
struct Error {
    ErrorCode::Code code = ErrorCode::Code::None;
    uint32_t context = 0;  // 附加上下文，如地址、行号
    uint32_t timestamp = 0;

    bool ok() const { return code == ErrorCode::Code::None; }
    explicit operator bool() const { return !ok(); }
};

// 错误处理宏
#define ERROR_WITH_CONTEXT(code, ctx) \
    Error { ErrorCode::Code::code, ctx, get_system_tick() }
```

### 驱动错误处理

```cpp
// 带超时的操作
template<typename Operation>
ErrorCode::Code with_timeout(Operation&& op, uint32_t timeout_ms) {
    uint32_t start = get_tick_ms();
    while (!get_flag()) {
        if (get_tick_ms() - start > timeout_ms) {
            return ErrorCode::Code::PeriphTimeout;
        }
       喂狗();  // 防止在此期间看门狗复位
    }
    return op();
}

// 使用示例
ErrorCode::Code SensorDriver::read(float& value) {
    auto result = with_timeout([this, &value]() -> ErrorCode::Code {
        if (!write_register(CMD_READ_SENSOR)) {
            return ErrorCode::Code::DriverProtocolError;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
        uint8_t data[4];
        if (!read_bytes(data, sizeof(data))) {
            return ErrorCode::Code::DriverCrcError;
        }
        if (!verify_crc(data, sizeof(data))) {
            return ErrorCode::Code::SensorCrcError;
        }
        value = decode_value(data);
        return ErrorCode::Code::None;
    }, 100);  // 100ms 超时

    return result;
}
```

### 防御性编程

```cpp
// 参数验证
class GpioDriver {
public:
    ErrorCode::Code write(bool state) {
        if (port_ == nullptr) {
            return ErrorCode::Code::PeriphNotReady;
        }
        if (state != false && state != true) {
            return ErrorCode::Code::AppInvalidState;  // 参数越界
        }
        HAL_GPIO_WritePin(port_, pin_, state ? GPIO_PIN_SET : GPIO_PIN_RESET);
        return ErrorCode::Code::None;
    }
};

// 状态验证
class StateMachine {
public:
    ErrorCode::Code handle_event(Event event) {
        if (current_state_ == State::Fault) {
            return ErrorCode::Code::AppInvalidState;  // 故障状态下忽略事件
        }
        // 处理事件...
        return ErrorCode::Code::None;
    }
};
```

### 错误处理规则

```
使用错误码而非异常 (嵌入式禁用异常)
为每个模块定义标准化的错误码
所有可能失败的函数必须返回错误码
使用静态分析工具检测未处理的返回值
记录错误便于调试 (环形日志缓冲区)

绝不使用 try-catch (嵌入式禁用异常)
绝不忽略错误返回值
绝不使用 assert 处理运行时错误 (仅用于开发阶段)
绝不返回通用错误码 (使用明确的错误分类)
```

---

## 7. 调试与测试 (高)

### 调试接口

```cpp
// 轻量级日志输出
class DebugLogger {
public:
    enum class Level { Debug, Info, Warn, Error };

    void log(Level level, const char* fmt, ...) {
        if (level < min_level_) return;

        va_list args;
        va_start(args, fmt);
        char buffer[256];
        vsnprintf(buffer, sizeof(buffer), fmt, args);
        va_end(args);

        output(buffer);  // UART 输出或其他方式
    }

    void set_level(Level level) { min_level_ = level; }

private:
    Level min_level_ = Level::Info;
    virtual void output(const char* message) = 0;
};

class UartLogger : public DebugLogger {
private:
    void output(const char* message) override {
        uart_.write_string("[LOG] ");
        uart_.write_string(message);
        uart_.write_string("\r\n");
    }
};

// 使用日志宏
#define LOG_DEBUG(fmt, ...) log(Level::Debug, fmt, ##__VA_ARGS__)
#define LOG_INFO(fmt, ...)  log(Level::Info, fmt, ##__VA_ARGS__)
#define LOG_WARN(fmt, ...)  log(Level::Warn, fmt, ##__VA_ARGS__)
#define LOG_ERROR(fmt, ...)  log(Level::Error, fmt, ##__VA_ARGS__)
```

### 断言框架

```cpp
// 开发阶段断言 (生产环境禁用)
#ifdef NDEBUG
    #define ASSERT(expr) ((void)0)
    #define ASSERT_MSG(expr, msg) ((void)0)
#else
    #define ASSERT(expr) \
        do { if (!(expr)) { fault_handler(__FILE__, __LINE__, #expr); } } while(0)
    #define ASSERT_MSG(expr, msg) \
        do { if (!(expr)) { fault_handler(__FILE__, __LINE__, msg); } } while(0)
#endif

void fault_handler(const char* file, int line, const char* expr) {
    LOG_ERROR("ASSERTION FAILED: %s at %s:%d", expr, file, line);
    // 可选: 进入调试模式或复位系统
    while (true) {}  // 停止
}
```

### 单元测试 (主机端)

```cpp
// tests/host/test_ring_buffer.cpp
#ifdef TEST_ON_HOST
#include <gtest/gtest.h>
#include "ring_buffer.cpp"  // 直接包含实现

TEST(RingBufferTest, WriteRead) {
    RingBuffer<uint8_t, 8> buffer;
    uint8_t value;

    EXPECT_TRUE(buffer.empty());
    EXPECT_FALSE(buffer.full());

    EXPECT_TRUE(buffer.write(42));
    EXPECT_FALSE(buffer.empty());

    EXPECT_TRUE(buffer.read(value));
    EXPECT_EQ(value, 42);
    EXPECT_TRUE(buffer.empty());
}

TEST(RingBufferTest, WrapAround) {
    RingBuffer<uint8_t, 4> buffer;
    uint8_t value;

    buffer.write(1);
    buffer.write(2);
    buffer.write(3);
    buffer.write(4);
    EXPECT_TRUE(buffer.full());

    buffer.read(value);  EXPECT_EQ(value, 1);
    buffer.write(5);     // 覆盖
    EXPECT_TRUE(buffer.full());

    buffer.read(value); EXPECT_EQ(value, 2);
    buffer.read(value); EXPECT_EQ(value, 3);
    buffer.read(value); EXPECT_EQ(value, 5);
}
#endif
```

### 调试规则

```
使用串口日志而非 JTAG 调试 (成本低、随时可用)
使用断言捕获开发阶段的逻辑错误
使用错误码处理运行时可预期的错误
保留最近 N 条日志用于故障分析
定期运行静态分析工具

绝不使用 printf 族函数 (开销大，使用轻量级日志)
断言仅用于开发阶段，生产环境禁用
绝不使用调试器做关键逻辑验证 (日志更可靠)
```

---

## 8. 低功耗设计 (中等)

### 功耗模式

```cpp
// power_manager.hpp
class PowerManager {
public:
    enum class Mode {
        Run,       // 全速运行
        Sleep,     // 睡眠模式 (CPU 停止，外设运行)
        Stop,      // 停止模式 (所有时钟停止，RAM 保留)
        Standby    // 待机模式 (RAM 丢失，需要完整初始化)
    };

    void set_mode(Mode mode) {
        mode_ = mode;
        switch (mode) {
            case Mode::Run:
                HAL_PWREx_EnableLowPowerRunMode();
                break;
            case Mode::Sleep:
                HAL_PWR_EnterSLEEPMode(PWR_MAINREGULATOR_ON, PWR_SLEEPENTRY_WFI);
                break;
            case Mode::Stop:
                HAL_PWREx_EnterSTOP2Mode();
                break;
            case Mode::Standby:
                HAL_PWR_EnterSTANDBYMode();
                break;
        }
    }

private:
    Mode mode_ = Mode::Run;
};
```

### 动态频率调整

```cpp
// 动态电压频率调整 (DVFS)
class ClockManager {
public:
    void set_sysclk(uint32_t freq_hz) {
        if (freq_hz == current_freq_) return;

        if (freq_hz < current_freq_) {
            // 降频前先降低电压
            set_voltage(get_voltage_for_freq(freq_hz));
            change_sysclk(freq_hz);
        } else {
            // 升频前先提高电压
            set_voltage(get_voltage_for_freq(freq_hz));
            change_sysclk(freq_hz);
        }
        current_freq_ = freq_hz;
    }

private:
    uint32_t current_freq_;
};
```

### 低功耗规则

```
识别功耗热点 (CPU、射频、电机驱动等)
使用低功耗模式延长电池寿命
使用 DMA 减少 CPU 活跃时间
批量处理数据，减少唤醒次数
使用事件驱动架构而非轮询

绝不不必要的全速运行
绝不轮询等待外设 (使用中断)
绝不保持未使用的外设时钟开启
```

---

## 9. RTOS 应用开发 (中等)

### FreeRTOS 任务创建

```cpp
// 静态分配任务栈 (推荐，避免堆碎片)
StackType_t task_stack[configMINIMAL_STACK_SIZE];
StaticTask_t task_buffer;

void TaskFunction(void* params) {
    while (true) {
        // 任务逻辑
        delay_ms(100);
    }
}

// 创建任务
xTaskCreateStatic(
    TaskFunction,           // 任务函数
    "TaskName",              // 任务名称
    configMINIMAL_STACK_SIZE, // 栈大小
    nullptr,                 // 参数
    1,                       // 优先级
    task_stack,              // 栈缓冲区
    &task_buffer             // TCB 缓冲区
);
```

### 任务间通信

```cpp
// 队列通信
QueueHandle_t data_queue;

void ProducerTask(void* params) {
    SensorData data;
    while (true) {
        if (read_sensor(data)) {
            xQueueSend(data_queue, &data, pdMS_TO_TICKS(10));
        }
        delay_ms(100);
    }
}

void ConsumerTask(void* params) {
    SensorData data;
    while (true) {
        if (xQueueReceive(data_queue, &data, pdMS_TO_TICKS(100)) == pdTRUE) {
            process_data(data);
        }
    }
}

// 二值信号量 (用于中断与任务同步)
SemaphoreHandle_t interrupt_sem;

void IRQHandler() {
    BaseType_t higher_priority_woken = pdFALSE;
    xSemaphoreGiveFromISR(interrupt_sem, &higher_priority_woken);
    portYIELD_FROM_ISR(higher_priority_woken);
}
```

### RTOS 规则

```
任务栈大小使用静态分配
使用信号量/队列进行任务间通信
中断中禁止使用 RTOS API (使用 FromISR 版本)
所有 RTOS 对象在启动调度器前创建
使用看门狗监控任务是否死锁

ISR 中绝不能调用会阻塞的 RTOS 函数
绝不创建过多任务 (每个任务都有栈开销)
绝不忽略优先级反转问题
```

---

## 10. 生产与固件更新 (中等)

### 固件版本管理

```cpp
// firmware_info.hpp
struct FirmwareInfo {
    static constexpr uint32_t magic = 0xDEADBEEF;
    uint32_t magic_number;
    uint32_t version;
    uint32_t build_timestamp;
    uint32_t git_commit_hash;
    uint32_t crc32;
    uint32_t app_start;
    uint32_t app_size;
    uint32_t ota_start;  // OTA 区域起始
    uint32_t ota_size;
} __attribute__((packed));

extern const FirmwareInfo firmware_info;
```

### Bootloader 设计

```cpp
// 简单 bootloader 流程
void bootloader_main() {
    // 1. 检查应用区是否有效
    if (is_app_valid()) {
        // 2. 跳转到应用
        jump_to_app();
    } else {
        // 3. 进入恢复模式或等待固件更新
        enter_recovery_mode();
    }
}

bool is_app_valid() {
    const FirmwareInfo* info = (const FirmwareInfo*)APP_ADDRESS;
    if (info->magic_number != FirmwareInfo::magic) return false;
    if (info->crc32 != calculate_crc(APP_ADDRESS + sizeof(FirmwareInfo), info->app_size)) {
        return false;
    }
    return true;
}
```

### OTA 更新

```cpp
// OTA 更新流程
class OtaUpdater {
public:
    enum class Status { Idle, Downloading, Verifying, Flashing, Completed, Failed };

    ErrorCode::Code start_update(const uint8_t* data, size_t length) {
        if (status_ != Status::Idle) return ErrorCode::Code::AppInvalidState;

        // 1. 写入 OTA 区域
        flash_.write(OTA_ADDRESS, data, length);

        // 2. 验证 CRC
        if (!verify_crc()) {
            status_ = Status::Failed;
            return ErrorCode::Code::DriverCrcError;
        }

        // 3. 更新启动参数
        set_boot_flag(OTA_ADDRESS);

        // 4. 重启
        reset();

        return ErrorCode::Code::None;
    }

private:
    Flash& flash_;
    volatile Status status_ = Status::Idle;
};
```

### 生产规则

```
固件包含版本信息和 CRC 校验
实现安全启动 (Secure Boot)
实现 OTA 安全更新 (签名验证)
分离 Bootloader 和 Application
保留恢复模式应对更新失败

绝不跳过固件完整性校验
绝不实现过于复杂的更新机制
```

---

## 11. 编码规范 (关键)

### 命名规范

```cpp
// 类型名: PascalCase
class SensorDriver {};
struct ConfigParams {};
enum class ErrorCode {};

// 变量名: snake_case
uint32_t sensor_reading;
bool is_initialized;
static constexpr size_t kMaxBufferSize = 256;  // 常量加 k 前缀

// 函数名: PascalCase 或 snake_case
void InitializeSensor();
void read_sensor_data();

// 枚举值: k + PascalCase 或 全大写
enum class State { kIdle, kRunning, kFault };  // 推荐
enum class Mode { IDLE, RUNNING, FAULT };       // 也可接受

// 私有成员变量: trailing underscore
class SensorDriver {
private:
    UART_HandleTypeDef uart_;
    uint8_t buffer_[256];
};
```

### 嵌入式 C++ 子集

```cpp
// 可用特性
- 类、继承、虚函数 (但禁用 RTTI)
- 模板 (编译时多态)
- constexpr (编译时计算)
- static_assert (编译时断言)
- std::array (固定大小，替代 std::vector)
- std::optional (可选值，无异常)
- RAII (但需谨慎，禁用动态分配)

禁用特性:
= 异常
= RTTI (typeid, dynamic_cast)
= 运行时类型信息
= dynamic memory (new, delete, malloc)
= std::function (可能使用动态分配)
= std::vector::push_back (可能触发动态分配)
```

### 注释规范

```cpp
/**
 * @brief 配置 GPIO 输出
 * @param port GPIO 端口基地址
 * @param pin 引脚号 (0-15)
 * @param initial_state 初始输出状态
 * @return 错误码
 * @note 此函数会启用 GPIO 时钟
 */
ErrorCode::Code configure_gpio_output(GPIO_TypeDef* port, uint16_t pin, bool initial_state);

/**
 * @brief 读取 ADC 值
 * @return ADC 原始读数 (0-4095 for 12-bit ADC)
 * @retval ErrorCode::None 成功
 * @retval ErrorCode::PeriphNotReady ADC 未就绪
 */
uint16_t read_adc();
```

### 编码规范规则

```
所有代码必须能编译无警告
遵循 MISRA C++ 或 JSF C++ 编码标准 (安全关键系统)
使用 const 和 constexpr 尽可能多
使用 static_assert 进行编译时断言
使用 RAII 管理资源 (需注意动态分配禁止)
代码审查必须覆盖所有变更

绝不使用 using namespace std;
绝不使用 typedef (使用 using 别名)
绝不省略大括号 (即使单行语句)
绝不省略大括号
绝不使用 using std::min 等
```

---

## 12. 性能优化 (中等)

### 性能测量

```cpp
// 性能测量工具
class PerformanceProfiler {
public:
    void begin(const char* name) {
        names_[count_] = name;
        start_times_[count_] = get_cycle_count();
    }

    void end() {
        uint64_t cycles = get_cycle_count() - start_times_[count_];
        durations_[count_] = cycles;
        count_++;
    }

    void print_report() {
        for (size_t i = 0; i < count_; i++) {
            LOG_INFO("%s: %llu cycles", names_[i], durations_[i]);
        }
    }

private:
    static constexpr size_t MAX_SAMPLES = 32;
    const char* names_[MAX_SAMPLES];
    uint64_t start_times_[MAX_SAMPLES];
    uint64_t durations_[MAX_SAMPLES];
    size_t count_ = 0;
};

// 使用
void critical_function() {
    profiler.begin("critical_function");
    // ... 操作 ...
    profiler.end();
}
```

### 常见优化

```cpp
// 1. 位操作替代乘除法
uint32_t multiply_by_4(uint32_t x) { return x << 2; }
uint32_t divide_by_2(uint32_t x) { return x >> 1; }

// 2. 查表替代计算
constexpr uint16_t SINE_TABLE[] = { /* 预计算正弦值 */ };
uint16_t fast_sin(uint8_t angle) { return SINE_TABLE[angle]; }

// 3. 循环展开
for (size_t i = 0; i < N; i += 4) {
    process(data[i]);
    process(data[i+1]);
    process(data[i+2]);
    process(data[i+3]);
}

// 4. 使用 DMA 替代 CPU 搬运数据
HAL_SPI_TransmitReceive_DMA(&hspi, tx_buf, rx_buf, length);  // DMA 传输
```

### 优化规则

```
先测量，后优化 (使用 Profiler)
优先算法优化，再考虑汇编优化
使用编译器优化选项 (-O2, -O3)
使用链接时优化 (LTO)
使用 DMA 减少 CPU 干预
使用 I/D Cache 优化 (如适用)

绝不凭猜测优化
绝不过早优化 (保持代码可读)
绝不牺牲可维护性换性能
绝不忽略编译器优化报告
```

---

## 反模式

| # | 不要 | 要做 |
|---|------|------|
| 1 | 直接操作寄存器 | 通过 HAL/LL 抽象层 |
| 2 | 使用 malloc/new | 静态分配或固定内存池 |
| 3 | 使用异常 | 错误码 |
| 4 | 使用 RTTI | 编译时多态或枚举 |
| 5 | printf 调试 | 轻量级日志或断点 |
| 6 | 轮询等待外设 | 中断驱动 |
| 7 | 大栈变量 | 静态分配或降低栈深度 |
| 8 | 魔法数字 | 具名常量或枚举 |
| 9 | 忽略编译器警告 | 把警告当错误 |
| 10 | 裸机指针 | 智能指针或引用 (无动态分配) |
| 11 | 中断中做复杂处理 | 标记+主循环处理 |
| 12 | 无看门狗 | 启用并定期喂狗 |
| 13 | 跳过数据手册 | 仔细阅读参考手册 |
| 14 | 直接复制示例代码 | 理解并适配项目 |
| 15 | 忽略堆栈溢出 | 配置和验证栈大小 |

---

## 常见问题

### 问题 1: "应该用裸机还是 RTOS?"

**规则:** 如果系统满足以下条件，选择裸机:
- 任务少 (< 3 个独立任务)
- 实时性要求简单
- 资源极度受限 ( < 16KB RAM)
- 硬件简单

否则，使用 RTOS。

### 问题 2: "如何选择 MCU?"

**考虑因素:**
| 因素 | 说明 |
|------|------|
| 内核 | ARM Cortex-M0/M3/M4/M7, RISC-V |
| 主频 | 影响处理能力和功耗 |
| RAM/Flash | 根据代码和数据量选择 |
| 外设 | UART、SPI、I2C、USB、CAN 等 |
| 功耗 | 电池供电需要低功耗型号 |
| 生态 | 工具链、调试器、社区支持 |
| 成本 | 量产成本、许可费用 |

### 问题 3: "如何处理内存不足?"

**解决策略:**
1. 使用 static 分配替代栈分配
2. 减少任务数量和栈大小
3. 优化数据结构大小
4. 使用位域压缩数据
5. 将数据移到 Flash (const) 或 EEPROM
6. 实现内存池复用

---

## 参考文档

此技能包含专业主题的深度参考。需要详细指导时阅读相关参考。

| 需要… | 参考 |
|-------|------|
| 板级支持包 (BSP) 开发 | [references/bsp-development.md](references/bsp-development.md) |
| RTOS 选择与移植 | [references/rtos-guide.md](references/rtos-guide.md) |
| 主流 MCU 开发指南 | [references/mcu-development.md](references/mcu-development.md) |
| 编码标准 (MISRA C++) | [references/misra-cpp.md](references/misra-cpp.md) |
| 调试工具链 | [references/debugging-tools.md](references/debugging-tools.md) |
| 内存优化策略 | [references/memory-optimization.md](references/memory-optimization.md) |
| 嵌入式测试策略 | [references/embedded-testing.md](references/embedded-testing.md) |
| Bootloader 与 OTA 更新 | [references/bootloader-ota.md](references/bootloader-ota.md) |
