# 板级支持包 (BSP) 开发指南

## 概述

BSP (Board Support Package) 是嵌入式系统中最底层、最硬件相关的软件层。它负责：
- 硬件初始化
- 时钟配置
- 中断向量表设置
- 外设驱动程序接口
- 内存布局配置

## BSP 开发流程

```
1. 阅读硬件文档
   ├── 数据手册 (芯片特性、电气参数)
   ├── 参考手册 (寄存器定义、时序)
   └── 原理图 (引脚连接)
   │
2. 创建项目结构
   ├── bsp/
   │   ├── board.cpp
   │   ├── clock_config.cpp
   │   ├── interrupt.cpp
   │   └── startup.cpp
   ├── hal/
   └── linkerscript.ld
   │
3. 实现启动代码
   │
4. 配置时钟树
   │
5. 配置外设初始化
   │
6. 测试验证
```

## 启动代码

### ARM Cortex-M 启动序列

```cpp
// startup.cpp
extern "C" {
    // 声明 linker script 符号
    extern uint32_t _estack;      // 栈顶
    extern uint32_t _sidata;      // .data 初始值
    extern uint32_t _sdata;       // .data 起始
    extern uint32_t _edata;       // .data 结束
    extern uint32_t _sbss;        // .bss 起始
    extern uint32_t _ebss;        // .bss 结束
}

// 复位处理
void Reset_Handler() {
    // 复制 .data 到 RAM
    uint32_t* src = &_sidata;
    uint32_t* dest = &_sdata;
    while (dest < &_edata) {
        *dest++ = *src++;
    }

    // 零初始化 .bss
    dest = &_sbss;
    while (dest < &_ebss) {
        *dest++ = 0;
    }

    // 调用系统初始化
    SystemInit();

    // 调用 main
    main();

    // 如果 main 返回，停在此处
    while (true) {}
}

// 默认中断处理
void Default_Handler() {
    while (true) {}
}

// 中断向量表
__attribute__((section(".vector_table")))
void (* const vector_table[])() = {
    (void (*)( ))((uint32_t)&_estack),    // 栈顶
    Reset_Handler,                         // 复位
    NMI_Handler,
    HardFault_Handler,
    // ... 其他中断
};
```

## 时钟配置

### STM32 时钟树

```cpp
// clock_config.cpp
void SystemClock_Config() {
    RCC_OscInitTypeDef RCC_OscInitStruct = {};
    RCC_ClkInitTypeDef RCC_ClkInitStruct = {};

    // 1. 配置 PLL
    RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSE;
    RCC_OscInitStruct.HSEState = RCC_HSE_ON;
    RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
    RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSE;
    RCC_OscInitStruct.PLL.PLLM = 8;
    RCC_OscInitStruct.PLL.PLLN = 336;
    RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV2;  // 168MHz
    RCC_OscInitStruct.PLL.PLLQ = 7;
    HAL_RCC_OscConfig(&RCC_OscInitStruct);

    // 2. 配置总线分频
    RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK | RCC_CLOCKTYPE_SYSCLK |
                                   RCC_CLOCKTYPE_PCLK1 | RCC_CLOCKTYPE_PCLK2;
    RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
    RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;   // 168MHz
    RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV4;    // 42MHz
    RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;    // 84MHz
    HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_5);
}
```

## 中断配置

### 中断优先级组

```cpp
void Interrupt_Config() {
    // 4 位抢占优先级，0 位子优先级
    HAL_NVIC_SetPriorityGrouping(NVIC_PRIORITYGROUP_4);

    // 配置优先级示例
    // 高优先级 (0-1): 定时器、SPI 传输完成
    // 中优先级 (2-4): UART、EXTI
    // 低优先级 (5-15): DMA、空闲任务

    NVIC_SetPriority(TIM2_IRQn, 1);      // 高
    NVIC_EnableIRQ(TIM2_IRQn);

    NVIC_SetPriority(USART1_IRQn, 3);    // 中
    NVIC_EnableIRQ(USART1_IRQn);
}
```

## 引脚配置

### 引脚复用与配置

```cpp
void GPIO_Config() {
    // 使能 GPIO 时钟
    __HAL_RCC_GPIOA_CLK_ENABLE();
    __HAL_RCC_GPIOB_CLK_ENABLE();

    // 配置 UART TX (复用推挽输出)
    GPIO_InitTypeDef GPIO_InitStruct = {};
    GPIO_InitStruct.Pin = GPIO_PIN_9;
    GPIO_InitStruct.Mode = GPIO_MODE_AF_PP;
    GPIO_InitStruct.Pull = GPIO_PULLUP;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
    GPIO_InitStruct.Alternate = GPIO_AF7_USART1;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);

    // 配置 LED (通用推挽输出)
    GPIO_InitStruct.Pin = GPIO_PIN_5;
    GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
    GPIO_InitStruct.Pull = GPIO_NOPULL;
    GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
    HAL_GPIO_Init(GPIOA, &GPIO_InitStruct);
}
```

## 链接脚本

### 典型链接脚本

```ld
/*
 * STM32F407VG 链接脚本
 * Flash: 1MB @ 0x08000000
 * RAM: 192KB @ 0x20000000
 * CCM: 64KB @ 0x10000000
 */

ENTRY(Reset_Handler)

MEMORY
{
    FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 1024K
    RAM (rwx)   : ORIGIN = 0x20000000, LENGTH = 192K
    CCMRAM (rwx): ORIGIN = 0x10000000, LENGTH = 64K
}

_stack_size = 0x400;  /* 1KB 栈空间 */

SECTIONS
{
    /* 代码段 */
    .text : {
        . = ALIGN(4);
        _stext = .;
        KEEP(*(.vector_table))
        *(.text*)
        *(.rodata*)
        . = ALIGN(4);
        _etext = .;
    } > FLASH

    /* 只读数据段 */
    .rodata : {
        . = ALIGN(4);
        *(.rodata*)
        . = ALIGN(4);
    } > FLASH

    /* 数据段 (需要从 Flash 复制到 RAM) */
    .data : {
        . = ALIGN(4);
        _sdata = .;
        *(.data*)
        . = ALIGN(4);
        _edata = .;
    } > RAM AT > FLASH

    /* BSS 段 (零初始化) */
    .bss : {
        . = ALIGN(4);
        _sbss = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _ebss = .;
    } > RAM

    /* 堆 */
    .heap : {
        . = ALIGN(8);
        _heap_start = .;
        . = . + 0x2000;  /* 8KB 堆 */
        _heap_end = .;
    } > RAM

    /* 栈 */
    .stack : {
        . = ALIGN(8);
        . = . + _stack_size;
        _estack = .;
    } > CCMRAM
}
```

## BSP 验证清单

- [ ] 启动代码正确复制 .data 和清零 .bss
- [ ] 时钟配置符合数据手册规格
- [ ] 中断向量表正确放置在 Flash 起始
- [ ] 所有使用的 GPIO 引脚正确配置
- [ ] 外设时钟已使能
- [ ] 链接脚本内存布局正确
- [ ] 栈大小足够
- [ ] 串口调试输出正常
- [ ] 看门狗正确配置
