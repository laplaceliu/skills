# 主流 MCU 开发指南

## ARM Cortex-M 系列

### Cortex-M0/M0+

**特点:**
- 入门级 32 位处理器
- 最精简的指令集 (Thumb only)
- 冯·诺依曼架构
- 无 DSP 指令

**代表芯片:**
- STM32F0 系列
- NXP LPC800
- AT91SAM D20

**适用场景:** 简单控制、成本敏感应用

### Cortex-M3

**特点:**
- 高性能
- 分支预测
- 硬件除法
- 调试增强

**代表芯片:**
- STM32F1 系列
- TI Tiva C
- NXP LPC1700

**适用场景:** 工业控制、消费电子

### Cortex-M4

**特点:**
- DSP 指令
- 单精度浮点 (可选)
- 增强调试

**代表芯片:**
- STM32F3/F4 系列
- TI MSP432
- NXP LPC4000

**适用场景:** 电机控制、音频处理、信号处理

### Cortex-M7

**特点:**
- 高性能 6 级流水线
- 双精度浮点 (可选)
- 指令/数据缓存 (可选)
- TCM (紧耦合内存)

**代表芯片:**
- STM32F7/H7 系列
- NXP i.MX RT

**适用场景:** 高性能控制、图形处理、通信

## STM32 开发指南

### STM32 系列对比

| 系列 | 内核 | 主频 | Flash | RAM | 特点 |
|------|------|------|-------|-----|------|
| STM32F0 | M0 | 48MHz | 16-256KB | 4-32KB | 入门级 |
| STM32F1 | M3 | 72MHz | 64-512KB | 20-96KB | 基础型 |
| STM32F4 | M4 | 180MHz | 512-2MB | 128-384KB | 高性能 |
| STM32F7 | M7 | 216MHz | 512-2MB | 320-512KB | 旗舰级 |
| STM32H7 | M7 | 480MHz | 128KB-2MB | 1-2MB | 双核可选 |
| STM32L4 | M4 | 80MHz | 128KB-1MB | 32-320KB | 超低功耗 |
| STM32WB | M4+M0 | 64MHz | 256KB-1MB | 192-256KB | 蓝牙+Thread |

### STM32 开发环境

```bash
# STM32CubeMX 项目生成 + Makefile
# 1. 使用 CubeMX 生成配置
# 2. 选择 Makefile 作为工具链
# 3. 添加应用代码

# 编译
make -C Build

# 使用 OpenOCD 烧录
openocd -f interface/stlink.cfg -f target/stm32f4.cfg \
    -c "program Build/*.elf verify reset exit"

# 使用 STM32CubeProgrammer
STM32_Programmer_CLI -c port=SWD -w Build/firmware.bin 0x08000000
```

### STM32 外设配置示例

```cpp
// UART 配置
void MX_USART1_UART_Init() {
    huart1.Instance = USART1;
    huart1.Init.BaudRate = 115200;
    huart1.Init.WordLength = UART_WORDLENGTH_8B;
    huart1.Init.StopBits = UART_STOPBITS_1;
    huart1.Init.Parity = UART_PARITY_NONE;
    huart1.Init.Mode = UART_MODE_TX_RX;
    huart1.Init.HwFlowCtl = UART_HWCONTROL_NONE;
    huart1.Init.OverSampling = UART_OVERSAMPLING_16;
    HAL_UART_Init(&huart1);
}

// I2C 配置
void MX_I2C1_Init() {
    hi2c1.Instance = I2C1;
    hi2c1.Init.ClockSpeed = 400000;       // 400KHz Fast Mode
    hi2c1.Init.DutyCycle = I2C_DUTYCYCLE_2;
    hi2c1.Init.OwnAddress1 = 0;
    hi2c1.Init.AddressingMode = I2C_ADDRESSINGMODE_7BIT;
    hi2c1.Init.DualAddressMode = I2C_DUALADDRESSMODE_DISABLE;
    hi2c1.Init.OwnAddress2 = 0;
    hi2c1.Init.GeneralCallMode = I2C_GENERALCALL_MODE_DISABLE;
    hi2c1.Init.NoStretchMode = I2C_NOSTRETCH_DISABLE;
    HAL_I2C_Init(&hi2c1);
}

// SPI 配置
void MX_SPI1_Init() {
    hspi1.Instance = SPI1;
    hspi1.Init.Mode = SPI_MODE_MASTER;
    hspi1.Init.Direction = SPI_DIRECTION_2LINES;
    hspi1.Init.DataSize = SPI_DATASIZE_8BIT;
    hspi1.Init.CLKPolarity = SPI_POLARITY_LOW;
    hspi1.Init.CLKPhase = SPI_PHASE_1EDGE;
    hspi1.Init.NSS = SPI_NSS_SOFT;
    hspi1.Init.BaudRatePrescaler = SPI_BAUDRATEPRESCALER_8;
    hspi1.Init.FirstBit = SPI_FIRSTBIT_MSB;
    hspi1.Init.TIMode = SPI_TIMODE_DISABLE;
    hspi1.Init.CRCCalculation = SPI_CRCCALCULATION_DISABLE;
    hspi1.Init.CRCPolynomial = 10;
    HAL_SPI_Init(&hspi1);
}
```

## ESP32 开发指南

### ESP32 系列

| 芯片 | 内核 | 主频 | WiFi | Bluetooth | RAM | Flash |
|------|------|------|------|-----------|-----|-------|
| ESP32 | Dual Xtensa | 240MHz | 802.11 b/g/n | 4.2 BLE | 520KB | 外置 |
| ESP32-S2 | Single Xtensa | 240MHz | 802.11 b/g/n | 无 | 320KB | 外置 |
| ESP32-S3 | Dual Xtensa | 240MHz | 802.11 b/g/n | 5.0 BLE | 512KB | 外置 |
| ESP32-C3 | RISC-V | 160MHz | 802.11 b/g/n | 5.0 BLE | 400KB | 外置 |
| ESP32-C6 | RISC-V | 160MHz | 802.11 ax | 5.0 BLE | 512KB | 外置 |
| ESP32-H2 | RISC-V | 32MHz | 无 | 5.0 BLE | 256KB | 外置 |

### ESP-IDF 项目结构

```
my_esp32_project/
├── main/
│   ├── CMakeLists.txt
│   ├── main.cpp          # 应用入口
│   └── component.mk
├── components/
│   ├── driver/           # 驱动组件
│   └── app/              # 应用组件
├── CMakeLists.txt         # 项目 CMake
├── Kconfig               # 配置选项
└── sdkconfig             # SDK 配置
```

### ESP32 外设示例

```cpp
#include "driver/gpio.h"
#include "driver/uart.h"
#include "esp_log.h"

static const char* TAG = "APP";

// GPIO 输出
void gpio_init() {
    gpio_config_t io_conf = {};
    io_conf.pin_bit_mask = (1ULL << GPIO_NUM_2);
    io_conf.mode = GPIO_MODE_OUTPUT;
    io_conf.pull_up_en = GPIO_PULLUP_DISABLE;
    io_conf.pull_down_en = GPIO_PULLDOWN_DISABLE;
    io_conf.intr_type = GPIO_INTR_DISABLE;
    gpio_config(&io_conf);
}

// UART 配置
void uart_init() {
    uart_config_t uart_config = {
        .baud_rate = 115200,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
    };

    ESP_ERROR_CHECK(uart_param_config(UART_NUM_0, &uart_config));
    ESP_ERROR_CHECK(uart_set_pin(UART_NUM_0, GPIO_NUM_1, GPIO_NUM_3,
                                   UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE));
    ESP_ERROR_CHECK(uart_driver_install(UART_NUM_0, 256, 0, 0, NULL, 0));
}

// WiFi 连接
void wifi_init_sta() {
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    wifi_config_t wifi_config = {};
    strcpy((char*)wifi_config.sta.ssid, "SSID");
    strcpy((char*)wifi_config.sta.password, "PASSWORD");

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "WiFi started");
}
```

## RISC-V 嵌入式

### 主流 RISC-V MCU

| 芯片 | 主频 | RAM | Flash | 特点 |
|------|------|-----|-------|------|
| GD32VF103 | 108MHz | 32KB | 128KB | 兆易创新，性能接近 STM32F103 |
| CH32V103 | 72MHz | 20KB | 64KB | 沁涌，超低成本 |
| BL602/BL702 | 125MHz | 32KB | 4MB | 博流，WiFi+BLE |
| HPM6750 | 600MHz+ | 256KB | 外置 | 先楫高性能 |

### GD32VF103 (Nuclei)

```cpp
#include "gd32vf103.h"

// GPIO 配置
void gpio_init() {
    // 使能 GPIOA 时钟
    rcu_periph_clock_enable(RCU_GPIOA);

    // 配置 PA1 为输出
    gpio_init(GPIOA, GPIO_MODE_OUT_50MHZ, GPIO_PUPD_NONE, GPIO_PIN_1);
}

// 延时函数
void delay_ms(uint32_t ms) {
    // 使用定时器或 systick
    uint64_t end = get_timer_value() + ms * (get_timer_freq() / 1000);
    while (get_timer_value() < end) {}
}

// 中断处理
void eclic_msip_handler(void) {
    // 外部中断处理
}
```

## MCU 选择决策树

```
需要选择 MCU?
│
├─ 成本敏感，简单控制
│   └─ Cortex-M0/M0+ (STM32F0, LPC800)
│
├─ 通用控制，性价比
│   └─ Cortex-M3 (STM32F1, LPC1700)
│
├─ 需要 DSP/浮点
│   └─ Cortex-M4 (STM32F3/F4, MSP432)
│
├─ 高性能，图形
│   └─ Cortex-M7 (STM32F7/H7, i.MX RT)
│
├─ 低功耗，电池供电
│   └─ Cortex-M4 L-series (STM32L4/L5)
│
├─ 需要无线连接
│   ├─ WiFi/BLE → ESP32
│   ├─ BLE → STM32WB, nRF52
│   └─ 专有 RF → 各厂商
│
└─ 需要 RISC-V
    ├─ 通用 → GD32VF103
    └─ 超低成本 → CH32V103
```
