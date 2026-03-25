# 嵌入式内存优化指南

## 概述

嵌入式系统的内存资源极其有限，内存优化是嵌入式开发的核心技能。本文档涵盖 Flash、RAM 和栈的优化策略。

## 内存分析

### 编译时内存分析

```bash
# 使用 GCC 工具链分析
arm-none-eabi-size Build/firmware.elf

# 输出示例:
#    text    data     bss     dec     hex filename
#   32768    1024    8192   41984    a3e0 firmware.elf
#
# text  = 代码段 (Flash)
# data  = 初始化数据段 (Flash + RAM)
# bss   = 未初始化数据段 (RAM)
# RAM 使用 = data + bss
# Flash 使用 = text + data

# 详细段分析
arm-none-eabi-nm -S --size-sort Build/firmware.elf | grep -E '^[0-9a-f]+ [0-9a-f]+'

# 生成 map 文件
arm-none-eabi-objdump -h Build/firmware.elf

# 查看符号大小
arm-none-eabi-nm -S Build/firmware.elf | sort -k2 -n -r | head -20
```

### 链接脚本符号

```cpp
// 使用链接脚本符号在运行时监控内存
extern "C" {
    extern uint32_t _stext;     // 代码段起始
    extern uint32_t _etext;     // 代码段结束
    extern uint32_t _sdata;     // 数据段起始
    extern uint32_t _edata;     // 数据段结束
    extern uint32_t _sbss;      // BSS 段起始
    extern uint32_t _ebss;      // BSS 段结束
    extern uint32_t _estack;    // 栈顶
}

size_t get_flash_used() {
    return (size_t)(&_etext - &_stext) + (size_t)(&_edata - &_sdata);
}

size_t get_ram_used() {
    return (size_t)(&_edata - &_sdata) + (size_t)(&_ebss - &_sbss);
}

size_t get_stack_remaining() {
    volatile uint32_t sp;
    __asm volatile ("mov %0, sp" : "=r" (sp));
    return (size_t)(&_estack) - sp;
}
```

## Flash 优化

### 代码大小优化

```cpp
// 1. 使用编译器优化选项
// -Os: 优化代码大小
// -flto: 链接时优化
// -ffunction-sections -fdata-sections: 每个函数/数据独立段
// -Wl,--gc-sections: 删除未使用的段

// CMakeLists.txt
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Os -flto -ffunction-sections -fdata-sections")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,--gc-sections")

// 2. 使用内联函数替代宏
// 不好: 宏展开多次
#define MAX(a, b) ((a) > (b) ? (a) : (b))

// 好: 静态内联，只有一份代码
static inline int max(int a, int b) {
    return a > b ? a : b;
}

// 3. 使用模板替代重复代码
template<typename T>
inline T clamp(T value, T min_val, T max_val) {
    if (value < min_val) return min_val;
    if (value > max_val) return max_val;
    return value;
}

// 使用时编译器生成特定类型的代码
int16_t x = clamp(raw_value, (int16_t)-100, (int16_t)100);
```

### 常量数据优化

```cpp
// 1. 将常量数据放入 Flash
// 不好: 常量数组在 RAM 中
const uint16_t sine_table[] = { /* 100 个值 */ };  // 默认在 RAM

// 好: 使用 PROGMEM 或 section 属性
const uint16_t sine_table[] __attribute__((section(".rodata"))) = { /* ... */ };

// 或使用 ARM 特定的 PROGMEM
#define PROGMEM __attribute__((section(".rodata")))
const uint16_t sine_table[] PROGMEM = { /* ... */ };

// 2. 使用查表替代计算
// 不好: 运行时计算
float sine(float angle) {
    return sinf(angle);  // 需要 libm，代码大
}

// 好: 查表 (Flash 中)
constexpr uint16_t SINE_TABLE[] = {
    0, 100, 200, 300, /* ... 预计算值 */
};

int16_t fast_sine(uint8_t angle_index) {
    return SINE_TABLE[angle_index % 256];
}

// 3. 字符串优化
// 不好: 字符串在 RAM 中
const char* error_message = "Sensor not found";  // RAM 中

// 好: 字符串在 Flash 中
const char error_message[] PROGMEM = "Sensor not found";
// 或使用 printf 的 PSTR 宏
printf_P(PSTR("Error: %d\n"), error_code);
```

### 函数优化

```cpp
// 1. 避免重复函数实例化
// 不好: 每个编译单元都有函数副本
// file1.cpp
void helper() { /* ... */ }

// file2.cpp
void helper() { /* ... */ }  // 重复

// 好: 使用 inline 或放在头文件
// helper.hpp
inline void helper() { /* ... */ }

// 2. 使用弱符号避免必须函数
// 默认实现
__attribute__((weak)) void custom_handler() {
    // 默认空实现
}

// 用户可以覆盖
void custom_handler() {
    // 用户实现
}

// 3. 函数指针表替代 switch
// 不好: 大型 switch
void process_command(int cmd) {
    switch (cmd) {
        case 1: cmd1(); break;
        case 2: cmd2(); break;
        // ... 每个分支都编译为跳转表
    }
}

// 好: 函数指针数组
using CommandHandler = void(*)();
constexpr CommandHandler handlers[] = {
    cmd1, cmd2, cmd3, cmd4, /* ... */
};

void process_command(int cmd) {
    if (cmd < sizeof(handlers) / sizeof(handlers[0])) {
        handlers[cmd]();
    }
}
```

## RAM 优化

### 数据结构优化

```cpp
// 1. 使用最小数据类型
// 不好: 过大的类型
struct SensorData {
    float timestamp;      // 32 位
    int value;            // 32 位
    bool active;          // 8 位 (实际只用 1 位)
};

// 好: 精确的类型
struct SensorData {
    uint32_t timestamp;   // 32 位
    int16_t value;        // 16 位 (如果范围允许)
    bool active : 1;      // 位域
    uint8_t reserved : 7; // 填充位
} __attribute__((packed));  // 防止对齐填充

// 2. 使用 union 共享内存
union DataBuffer {
    uint8_t bytes[64];
    uint16_t words[32];
    struct {
        uint8_t header;
        uint8_t payload[62];
        uint8_t checksum;
    } frame;
};

// 3. 避免内存对齐浪费
// 不好: 未对齐导致填充
struct BadLayout {
    uint8_t a;    // 1 字节
    // 3 字节填充
    uint32_t b;   // 4 字节
    uint8_t c;    // 1 字节
    // 3 字节填充
    uint32_t d;   // 4 字节
};  // 总共 16 字节

// 好: 手动排序减少填充
struct GoodLayout {
    uint32_t b;   // 4 字节
    uint32_t d;   // 4 字节
    uint8_t a;    // 1 字节
    uint8_t c;    // 1 字节
    // 2 字节填充 (如果需要)
};  // 总共 12 字节
```

### 缓冲区优化

```cpp
// 1. 使用环形缓冲区
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
    
private:
    T buffer_[N];
    volatile size_t head_ = 0;
    volatile size_t tail_ = 0;
};

// 2. 双缓冲区
template<typename T, size_t N>
class DoubleBuffer {
public:
    T* get_write_buffer() {
        return buffers_[write_index_];
    }
    
    T* get_read_buffer() {
        return buffers_[1 - write_index_];
    }
    
    void swap() {
        write_index_ = 1 - write_index_;
    }
    
private:
    T buffers_[2][N];
    volatile size_t write_index_ = 0;
};

// 3. 内存池
template<typename T, size_t N>
class MemoryPool {
public:
    T* allocate() {
        for (size_t i = 0; i < N; ++i) {
            if (!used_[i]) {
                used_[i] = true;
                return &storage_[i];
            }
        }
        return nullptr;
    }
    
    void deallocate(T* ptr) {
        size_t index = ptr - storage_;
        if (index < N) {
            used_[index] = false;
        }
    }
    
private:
    alignas(T) uint8_t storage_[sizeof(T) * N];
    bool used_[N] = {false};
};
```

### 栈优化

```cpp
// 1. 避免大栈对象
// 不好: 大数组在栈上
void process() {
    uint8_t buffer[4096];  // 在栈上分配 4KB
    // ...
}

// 好: 使用静态分配
void process() {
    static uint8_t buffer[4096];  // 在 .bss 段
    // ...
}

// 或使用内存池
void process() {
    MemoryPool<uint8_t, 4096> pool;
    uint8_t* buffer = pool.allocate();
    // ...
    pool.deallocate(buffer);
}

// 2. 减少函数调用深度
// 不好: 深层递归
int factorial(int n) {
    if (n <= 1) return 1;
    return n * factorial(n - 1);  // 栈深度 = n
}

// 好: 迭代实现
int factorial(int n) {
    int result = 1;
    for (int i = 2; i <= n; ++i) {
        result *= i;
    }
    return result;  // 栈深度 = 1
}

// 3. 栈使用分析
// 使用静态分析工具
// arm-none-eabi-gcc -fstack-usage source.cpp
// 生成 .su 文件，显示每个函数的栈使用

// 运行时栈检测
#ifdef ENABLE_STACK_CHECKING
void check_stack() {
    volatile uint32_t sp;
    __asm volatile ("mov %0, sp" : "=r" (sp));
    
    uint32_t remaining = sp - (uint32_t)&_estack + STACK_SIZE;
    if (remaining < STACK_WARNING_THRESHOLD) {
        log_warning("Stack low: %u bytes remaining", remaining);
    }
}
#endif
```

## 堆管理

### 避免堆碎片

```cpp
// 1. 禁止动态分配 (推荐)
void* operator new(size_t) = delete;
void operator delete(void*) = delete;
void* operator new[](size_t) = delete;
void operator delete[](void*) = delete;

// 2. 如果必须使用堆，使用固定大小块分配器
class FixedBlockAllocator {
public:
    FixedBlockAllocator(uint8_t* memory, size_t block_size, size_t num_blocks)
        : memory_(memory), block_size_(block_size), num_blocks_(num_blocks) {
        // 初始化空闲链表
        for (size_t i = 0; i < num_blocks_; ++i) {
            free_list_[i] = i;
        }
        free_count_ = num_blocks_;
    }
    
    void* allocate() {
        if (free_count_ == 0) return nullptr;
        
        size_t index = free_list_[--free_count_];
        return memory_ + index * block_size_;
    }
    
    void deallocate(void* ptr) {
        if (ptr == nullptr) return;
        
        size_t index = ((uint8_t*)ptr - memory_) / block_size_;
        if (index < num_blocks_) {
            free_list_[free_count_++] = index;
        }
    }
    
private:
    uint8_t* memory_;
    size_t block_size_;
    size_t num_blocks_;
    size_t free_list_[128];  // 假设最多 128 个块
    size_t free_count_;
};

// 3. 替代 new 的静态工厂模式
class Sensor {
public:
    static Sensor* create() {
        for (size_t i = 0; i < MAX_INSTANCES; ++i) {
            if (!instances_[i].used_) {
                instances_[i].used_ = true;
                return &instances_[i].instance_;
            }
        }
        return nullptr;
    }
    
    static void destroy(Sensor* ptr) {
        for (size_t i = 0; i < MAX_INSTANCES; ++i) {
            if (&instances_[i].instance_ == ptr) {
                instances_[i].used_ = false;
                return;
            }
        }
    }
    
private:
    Sensor() = default;
    
    struct InstanceSlot {
        Sensor instance_;
        bool used_ = false;
    };
    
    static InstanceSlot instances_[MAX_INSTANCES];
    static constexpr size_t MAX_INSTANCES = 16;
};
```

## 内存映射优化

### 多内存区域利用

```cpp
// 1. CCMRAM (Core Coupled Memory) - 仅 CPU 可访问
// 链接脚本:
// CCMRAM (rwx): ORIGIN = 0x10000000, LENGTH = 64K

// 将关键数据放入 CCMRAM (无 DMA 访问)
__attribute__((section(".ccmram"))) uint8_t dma_buffer[1024];  // 错误！DMA 无法访问
__attribute__((section(".ccmram"))) uint8_t stack_buffer[256]; // 正确：CPU 栈使用

// 2. 外部 SRAM/SDRAM
// 链接脚本:
// SDRAM (rwx): ORIGIN = 0xC0000000, LENGTH = 8M

// 大缓冲区放入外部 SDRAM
__attribute__((section(".sdram"))) uint8_t frame_buffer[800 * 600 * 2];

// 3. 备份 SRAM (RTC 域)
// 链接脚本:
// BKPRAM (rwx): ORIGIN = 0x40024000, LENGTH = 4K

// 断电保持的数据
__attribute__((section(".bkpram"))) struct {
    uint32_t magic;
    uint32_t counter;
    uint8_t config[128];
} backup_data;
```

## 内存优化清单

### 编译时检查

- [ ] 启用 `-Os` 优化代码大小
- [ ] 启用 `-flto` 链接时优化
- [ ] 启用 `-ffunction-sections -fdata-sections`
- [ ] 启用 `-Wl,--gc-sections` 删除未使用代码
- [ ] 检查 `.map` 文件找出大符号
- [ ] 使用 `-fstack-usage` 分析栈使用

### 运行时监控

- [ ] 实现 `get_stack_remaining()` 监控栈使用
- [ ] 实现 `get_heap_remaining()` 监控堆使用 (如使用)
- [ ] 在关键任务中检查内存状态
- [ ] 记录峰值内存使用
- [ ] 设置内存低水位告警

### 设计阶段

- [ ] 选择最小够用的数据类型
- [ ] 合理组织结构体布局
- [ ] 使用静态分配替代动态分配
- [ ] 避免深递归和大栈对象
- [ ] 使用查表替代计算
- [ ] 将常量数据放入 Flash
