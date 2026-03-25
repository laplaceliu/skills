# 调试工具链

## 硬件调试器

### JTAG vs SWD

| 特性 | JTAG | SWD |
|------|------|-----|
| 引脚数 | 4-5 (TCK, TMS, TDI, Tdo, TRST) | 2 (SWCLK, SWDIO) |
| 速度 | 较快 | 稍慢但足够 |
| 调试能力 | 完整 | 完整 (ARM Cortex-M) |
| 兼容性 | 通用 | 仅 ARM Cortex-M |
| 面积占用 | 较大 | 最小 |

### 常见调试器

| 调试器 | 接口 | 芯片支持 | 价格 | 特点 |
|--------|------|----------|------|------|
| ST-Link V2 | SWD | STM32 | 低 | 便宜实用 |
| J-Link | JTAG/SWD | 广泛 | 中高 | 高速、专业 |
| CMSIS-DAP | JTAG/SWD | ARM | 低 | 开源、通用 |
| Black Magic Probe | JTAG/SWD | ARM | 中 | 开源固件 |
| FTDI + OpenOCD | JTAG | 可配置 | 低 | 灵活、DIY |

### ST-Link 使用

```bash
# 安装 OpenOCD
brew install openocd

# 连接 ST-Link
# ST-Link V2 引脚:
#  - SWCLK -> TCK (pin 20)
#  - SWDIO -> TMS (pin 18)
#  - GND   -> GND (pin 25)
#  - 3.3V  -> VCC (pin 2)  (可选)

# 启动 OpenOCD 服务
openocd -f interface/stlink.cfg -f target/stm32f4.cfg

# GDB 连接
arm-none-eabi-gdb Build/project.elf
(gdb) target remote localhost:3333
(gdb) load          # 烧录固件
(gdb) monitor reset # 复位目标
(gdb) continue      # 运行
```

### J-Link 使用

```bash
# 安装 J-Link 软件
# 连接后使用 J-Link GDB Server
JLinkGDBServer -if SWD -device STM32F407VG

# 或使用 SEGGER 命令行
JLink.exe -device STM32F407VG -if SWD -speed 4000

# GDB 连接
arm-none-eabi-gdb Build/project.elf
(gdb) target remote localhost:2331
(gdb) monitor reset
(gdb) load
(gdb) continue
```

## 软件调试

### GDB 常用命令

```bash
# 加载符号文件
file Build/project.elf

# 连接到远程目标
target remote localhost:3333

# 断点
break main           # 在 main 函数处打断点
break sensor.cpp:42   # 在指定文件和行号打断点
break *0x08001234    # 在指定地址打断点
info breakpoints     # 查看所有断点
delete 1             # 删除断点 1

# 执行控制
continue (c)          # 继续运行
step (s)              # 单步进入
next (n)              # 单步跳过
finish                # 运行到函数返回
until (u) 100         # 运行到行 100

# 查看内存和寄存器
x/16xb 0x20000000    # 查看 16 字节，十六进制
x/4xw 0x08000000      # 查看 4 个 32 位字
info registers        # 查看所有寄存器
print variable_name   # 打印变量值
print *ptr           # 打印指针指向的值
display variable      # 每次停止时显示变量

# 修改内存和寄存器
set var x = 10       # 修改变量值
set {int}0x20000000 = 5  # 直接修改内存

# 监视点
watch variable        # 变量改变时停止
watch *ptr            # 地址内容改变时停止
info watchpoints      # 查看所有监视点

# 栈跟踪
backtrace (bt)        # 查看调用栈
frame 1               # 切换到帧 1
info locals           # 查看当前帧的局部变量
```

### GDB 脚本自动化

```gdb
# commands.gdb
# 连接到目标并烧录
target remote localhost:3333
monitor reset halt
load

# 设置断点
break main
break HardFault_Handler
break assert_failed

# 运行到 main
continue
break if (counter > 100)

# 记录执行
set pagination off
set logging file debug.log
set logging overwrite on
set logging on

# 打印寄存器状态
define hook-stop
    info registers
    x/16xb $sp
end
```

### 高级调试技术

```bash
# 1. 条件断点
break sensor.cpp:50 if error_count > 10

# 2. 硬件断点 (Flash 中使用)
break sensor.cpp:50
# GDB 自动使用硬件断点调试 Flash

# 3. 追踪记录
record full  # 开启反向执行
reverse-step  # 反向单步

# 4. 内存访问监控
watch *0x20000010
info watchpoints

# 5. 多线程调试
info threads
thread 2          # 切换到线程 2
thread apply all bt  # 所有线程栈跟踪
```

## OpenOCD 配置

### 配置文件

```bash
# stlink.cfg - ST-Link 接口配置
# 来自 /usr/local/share/openocd/scripts/interface/stlink.cfg

# stm32f4.cfg - STM32F4 目标配置
# 来自 /usr/local/share/openocd/scripts/target/stm32f4.cfg

# 自定义 OpenOCD 启动脚本
# startup.cfg
init
reset halt

# 配置 Flash 写算法
flash bank flash0 stm32f2x 0x08000000 0 0 0 $_TARGETNAME
```

### OpenOCD 常用命令

```bash
# 重启并暂停
openocd -f interface/stlink.cfg -f target/stm32f4.cfg \
    -c "init; reset halt"

# 烧录固件
openocd -f interface/stlink.cfg -f target/stm32f4.cfg \
    -c "program Build/firmware.elf verify reset exit"

# 烧录二进制
openocd -f interface/stlink.cfg -f target/stm32f4.cfg \
    -c "program Build/firmware.bin 0x08000000 verify reset exit"

# 烧录后运行
openocd -f interface/stlink.cfg -f target/stm32f4.cfg \
    -c "init; reset halt; program Build/firmware.elf verify; reset run"
```

## 串口调试

### 使用 minicom

```bash
# macOS
brew install minicom

# 连接串口
minicom -D /dev/tty.usbserial-A50285  # 查看具体设备
minicom -D /dev/tty.usbserial-A50285 -b 115200

# 常用快捷键
# Ctrl+A Z     - 帮助
# Ctrl+A X     - 退出
# Ctrl+A E     - 开关回显
# Ctrl+A R     - 开关 RTS
```

### 使用 screen

```bash
screen /dev/tty.usbserial-A50285 115200

# 退出
# Ctrl+A K
```

### 使用 picocom

```bash
picocom -b 115200 -D /dev/tty.usbserial-A50285

# 退出
# Ctrl+A Ctrl+Q
```

## 性能分析

### 使用 ITM 和 SWO

```cpp
// 在目标代码中添加 ITM 追踪
#include "itm.h"

// ITM 端口 0 发送字符
void ITM_SendChar(char c) {
    if ((ITM->TCR & ITM_TCR_ITMENA_Msk) && (ITM->TER & (1UL << 0))) {
        ITM->PORT[0].u8 = c;
    }
}

// 发送字符串
void ITM_SendString(const char* str) {
    while (*str) {
        ITM_SendChar(*str++);
    }
}

// 使用
ITM_SendString("Hello ARM\r\n");
```

### 使用 SEGGER SystemView

```cpp
#include "SEGGER_SYSVIEW.h"

void some_function() {
    SEGGER_SYSVIEW_RecordEnter();

    // 函数逻辑

    SEGGER_SYSVIEW_RecordExit();
}
```

## 调试清单

- [ ] 调试器连接正确 (SWD/JTAG)
- [ ] 目标板供电正常
- [ ] 链接脚本正确 (Flash/RAM 地址)
- [ ] 固件符号文件 (.elf) 可用
- [ ] 串口调试连接正常 (如使用)
- [ ] OpenOCD/GDB 配置正确
