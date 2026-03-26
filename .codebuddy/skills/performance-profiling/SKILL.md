---
name: performance-profiling
description: |
  C++/Qt 性能剖析与优化指南。
  触发条件: 性能优化、CPU 热点分析、内存泄漏检测、锁竞争诊断、
  BPF 性能工具、profiling、perf、火焰图、内存分析、并发分析、
  Qt GUI 性能优化、C++ 性能调优、延迟分析、吞吐量优化。
  不触发条件: 嵌入式开发、Web 开发、纯算法实现不涉及性能者。
license: MIT
metadata:
  category: performance
  version: "1.0.0"
  platforms:
    - ubuntu-20.04
    - ubuntu-22.04
    - arm64
    - x86_64
  sources:
    - BPF Performance Tools (Brendan Gregg)
    - Linux Performance Analysis (Netflix/Brendan Gregg)
    - Intel VTune Profiler Documentation
    - Qt Performance Optimization Guide
    - GCC/Clang Profiling Documentation
---

# C++/Qt 性能剖析与优化实践

## 强制工作流 — 按顺序执行以下步骤

**当此技能被触发时，在编写任何优化代码前必须遵循此工作流。**

### 第 0 步: 收集需求

在开始性能优化之前，请用户明确（或从上下文中推断）:

1. **目标平台**: Ubuntu 20.04/22.04，架构 arm64/x86_64
2. **被测应用**: C++ 原生还是 Qt 应用？可执行文件路径或构建方式
3. **性能问题类型**: CPU 热点、内存泄漏、锁竞争、启动慢、响应延迟、吞吐量不足
4. **性能指标目标**: 延迟 < X ms、吞吐量 > Y QPS、内存 < Z MB
5. **约束条件**: 是否需要实时性？是否有多线程？是否有 GUI 交互？

如果用户已在请求中说明这些，跳过询问直接继续。

### 第 1 步: 测量基准

根据问题类型，选择合适的剖析工具并建立基准:

| 问题类型 | 推荐工具 | 快速命令 |
|----------|----------|----------|
| CPU 热点 | perf, gprof | `perf record -g ./app; perf report` |
| 内存泄漏 | valgrind, AddressSanitizer | `valgrind --leak-check=full ./app` |
| 锁竞争 | perf, BPF tools | `perf lock record ./app` |
| 系统调用 | strace, bpftrace | `strace -c ./app` |
| Qt GUI 响应 | Qt Creator Analyzer | `qmlprofiler ./app` |
| 网络延迟 | tcpdump, bpftrace | `bpftrace -e 'tracepoint:net:*'` |

**必须先建立基准数据，再进行任何优化。**

### 第 2 步: 定位瓶颈

使用剖析数据定位真正的性能瓶颈:

1. **CPU 热点**: 找出消耗最多 CPU 周期的函数
2. **调用链**: 理解热点的调用路径
3. **分支预测**: 识别频繁 mispredict 的分支
4. **缓存命中率**: 检查 L1/L2/L3 cache hit/miss
5. **内存分配**: 识别高频率的 malloc/free 调用

### 第 3 步: 分析与决策

根据瓶颈数据做出优化决策:

| 瓶颈类型 | 可能的优化策略 |
|----------|----------------|
| 计算密集 | SIMD、向量化、算法优化、编译器优化选项 |
| 内存访问 | 缓存友好数据结构、预取、内存池 |
| 锁竞争 | 减小临界区、无锁数据结构、读写锁分离 |
| 系统调用 | 批量操作、异步 I/O、内存映射 |
| 内存分配 | 对象池、arena 分配器、避免频繁分配 |
| Qt 渲染 | 减少重绘、视图懒加载、图形批量绘制 |

### 第 4 步: 实施优化

按优先级实施优化措施:

1. **算法/架构级优化** — 收益最大，优先实施
2. **内存布局优化** — 缓存友好设计
3. **并发优化** — 减少锁粒度、无锁编程
4. **编译器优化** — 合理使用 -O2/-O3、LTO
5. **Qt 特定优化** — GUI 渲染、模型优化

### 第 5 步: 验证效果

优化后必须验证:

1. **重新测量**: 使用相同工具重新剖析
2. **回归测试**: 确保功能正确性未受影响
3. **对比基准**: 与优化前数据对比
4. **压力测试**: 确认高负载下表现稳定

### 第 6 步: 移交摘要

向用户提供简要摘要:

- **瓶颈分析**: 发现的主要性能问题
- **优化措施**: 实施的改进项
- **性能提升**: 优化前后对比数据
- **后续建议**: 进一步优化的可能方向

---

## 适用范围

**使用此技能的情况:**
- C++ 应用程序性能优化
- Qt GUI 应用程序性能调优
- Linux 系统性能分析 (CPU、内存、I/O)
- 使用 BPF 工具进行动态追踪
- 内存泄漏和内存错误检测
- 锁竞争和并发性能分析
- 启动性能优化
- 实时性能优化

**不适用的情况:**
- 嵌入式裸机开发 (使用 embedded-dev skill)
- Web 应用后端性能 (使用 fullstack-dev skill)
- 数据库调优 (DBA 范畴)
- 网络协议优化 (需要专业网络知识)

---

## 快速开始 — 性能剖析清单

### CPU 热点分析

```bash
# 1. 使用 perf 采样 (需要 debug symbols)
sudo perf record -g -F 999 ./your_application --args
# Ctrl+C 停止

# 2. 查看报告
sudo perf report

# 3. 生成火焰图 (需要火焰图工具)
sudo perf script | ./FlameGraph/stackcollapse-perf.pl | ./FlameGraph/flamegraph.pl > profile.svg
```

### 内存分析

```bash
# 1. AddressSanitizer (编译时启用)
g++ -fsanitize=address -g app.cpp -o app
./app

# 2. Valgrind 内存泄漏检测
valgrind --leak-check=full --show-leak-kinds=all ./app

# 3. 堆内存分析
valgrind --tool=massif ./app
# 查看结果
valgrind --tool=massif --stacks=yes ./app
ms_print massif.out.*
```

### BPF 性能工具

```bash
# 1. 安装 bpftrace 和 BCC 工具
sudo apt install bpftrace linux-tools-$(uname -r)

# 2. CPU 热点 (bpftrace one-liners)
sudo bpftrace -e 'profile:hz:99 { @[comm, ustack, kstack] = count(); }'

# 3. 内存分配追踪
sudo bpftrace -e 'malloc { @[ustack] = quantize(sizelo); }'

# 4. 磁盘 I/O 分析
sudo bpftrace -e 'tracepoint:block:block_rq_insert { @[comm] = count(); }'
```

---

## 快速导航

| 需要… | 跳转到 |
|-------|--------|
| 理解性能优化方法论 | [1. 性能优化方法论](#1-性能优化方法论-关键) |
| 使用 perf 工具 | [2. perf 性能剖析](#2-perf-性能剖析-高) |
| 使用 BPF 工具 | [3. BPF-性能工具](#3-bpf-性能工具-高) |
| 检测内存问题 | [4. 内存分析](#4-内存分析-高) |
| 分析锁竞争 | [5. 并发与锁分析](#5-并发与锁分析-高) |
| Qt GUI 性能优化 | [6. Qt-性能优化](#6-qt-性能优化-高) |
| C++ 编译优化 | [7. 编译器优化选项](#7-编译器优化选项-中等) |
| 生成火焰图 | [8. 火焰图](#8-火焰图-中等) |
| BPF 工具详解 | [references/bpf-tools-guide.md](references/bpf-tools-guide.md) |
| 剖析技术参考 | [references/profiling-techniques.md](references/profiling-techniques.md) |
| Qt 性能优化 | [references/qt-performance-optimization.md](references/qt-performance-optimization.md) |
| 内存分析工具 | [references/memory-analysis.md](references/memory-analysis.md) |

---

## 核心原则 (10 条铁律)

```
1. 先测量，后优化 — 使用 profiling 工具定位瓶颈，不凭猜测
2. 优化收益最大的热点 — 80% 的时间花在 20% 的代码上
3. 每次优化后重新测量 — 确保优化有效，避免退化
4. 从算法/架构层开始 — 优于局部代码优化
5. 保持代码可读性 — 必要时加注释解释优化动机
6. 测量真实工作负载 — synthetic benchmark 不可靠
7. 关注 Amdahl 定律 — 并行化收益受串行部分限制
8. 考虑缓存效应 — 内存布局对性能影响巨大
9. 了解硬件特性 — SIMD、向量化、分支预测
10. 回归测试必须通过 — 性能提升不能牺牲正确性
```

---

## 1. 性能优化方法论 (关键)

### 性能问题分类

```
性能问题类型
├── CPU 密集型
│   ├── 计算热点 (算术运算、加密、压缩)
│   ├── 分支预测失败
│   └── 函数调用开销
├── 内存密集型
│   ├── 内存分配/释放
│   ├── 缓存未命中
│   └── 内存带宽瓶颈
├── I/O 密集型
│   ├── 磁盘 I/O
│   ├── 网络 I/O
│   └── 系统调用
└── 并发/锁竞争
    ├── 锁粒度过大
    ├── 伪共享 (false sharing)
    └── 死锁/活锁
```

### 优化层次

```
优化层次 (从上到下收益递增)
Level 6: 硬件升级
Level 5: 编译器选项 (-O3, -march=native)
Level 4: 源码优化 (算法、数据结构)
Level 3: 并发优化 (多线程、无锁)
Level 2: 内存布局 (缓存友好、内存池)
Level 1: 系统级优化 (I/O 模型、系统调优)
```

### 性能剖析方法

```cpp
// 性能测量辅助类
class ScopedTimer {
public:
    explicit ScopedTimer(const char* name) : name_(name), start_(std::chrono::high_resolution_clock::now()) {}
    ~ScopedTimer() {
        auto duration = std::chrono::high_resolution_clock::now() - start_;
        std::cout << name_ << ": " << std::chrono::duration<double, std::milli>(duration).count() << " ms\n";
    }
private:
    const char* name_;
    std::chrono::time_point<std::chrono::high_resolution_clock> start_;
};

// 使用示例
void critical_function() {
    ScopedTimer timer("critical_function");
    // ... 待测代码 ...
}

// 推荐: 使用更精确的性能计数器
#ifdef __linux__
    #include <perf_event.h>
    #include <sys/ioctl.h>

    class PerfCounter {
    public:
        void start() {
            fd_ = perf_event_open(&pe_, 0, -1, -1, 0);
            ioctl(fd_, PERF_EVENT_IOC_RESET, 0);
            ioctl(fd_, PERF_EVENT_IOC_ENABLE, 0);
        }

        long long stop() {
            ioctl(fd_, PERF_EVENT_IOC_DISABLE, 0);
            read(fd_, &count_, sizeof(count_));
            close(fd_);
            return count_;
        }
    private:
        int fd_;
        struct perf_event_attr pe_ = {
            .type = PERF_TYPE_HARDWARE,
            .config = PERF_COUNT_HW_CPU_CYCLES,
            .size = sizeof(pe_),
            .disabled = 1,
            .exclude_kernel = 1,
        };
        long long count_;
    };
#endif
```

---

## 2. perf 性能剖析 (高)

### perf 安装与基础使用

```bash
# 安装
sudo apt install linux-tools-common linux-tools-$(uname -r)

# 基础命令
perf list                    # 列出可用事件
perf stat ./app             # 统计总体性能
perf record -g ./app        # 记录采样数据
perf report                 # 查看报告
perf annotate               # 查看源码注释
```

### perf stat 统计命令

```bash
# 总体性能统计
perf stat -e cycles,instructions,cache-references,cache-misses ./app

# 特定事件统计
perf stat -e 'syscalls:sys_enter_*' ./app

# 多核统计
perf stat -a -e cycles ./app

# 指定架构
perf stat --arch=arm64 ./app
```

### CPU 热点分析

```bash
# 1. 记录采样 (999Hz 采样率)
sudo perf record -g -F 999 ./app --args

# 2. 按 CPU 热点排序
perf report --stdio --sort=ccomm,overhead

# 3. 特定符号分析
perf report --stdio -g graph --symbol-filter=hot_function

# 4. 注释源码
perf annotate --stdio
```

### 缓存分析

```bash
# 缓存命中率
perf stat -e cache-references,cache-misses ./app

# LLC (Last Level Cache)
perf stat -e LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses ./app

# TLB 分析
perf stat -e dTLB-loads,dTLB-misses,iTLB-loads,iTLB-misses ./app
```

### 进程/线程分析

```bash
# 分析特定 PID
sudo perf record -g -p <pid>

# 分析特定线程
sudo perf record -g -t <tid>

# 分析子进程
sudo perf record -g -- ./app
```

### perf 脚本与数据导出

```bash
# 导出采样数据
perf script > perf.trace

# 生成调用图
perf script --itrace=i1000g | ./FlameGraph/stackcollapse-perf.pl > stacks.out

# 分析特定时间范围
perf script --start 1000000000 --end 2000000000
```

---

## 3. BPF 性能工具 (高)

### BPF 工具概述

```
BPF 工具类型
├── BCC (BPF Compiler Collection)
│   ├── execsnoop    # 追踪 execve 调用
│   ├── opensnoop   # 追踪 open 调用
│   ├── biolatency  # 磁盘 I/O 延迟
│   ├── funclatency # 函数延迟
│   └── argdist     # 参数分布
├── bpftrace
│   ├── 高级语言编写自定义工具
│   └── one-liners 快速分析
└── perf 的 BPF 后端
    └── perf inject --jit
```

### BCC 工具使用

```bash
# 安装 BCC
sudo apt install bpfcc-tools

# 常用 BCC 工具 (Ubuntu 上命令带 -bpfcc 后缀)
sudo execsnoop-bpfcc      # 追踪程序执行
sudo opensnoop-bpfcc      # 追踪文件打开
sudo biolatency-bpfcc     # I/O 延迟分布
sudo cachestat-bpfcc      # 页缓存统计
sudo funclatency-bpfcc    # 函数延迟
sudo profile-bpfcc        # CPU 采样
```

### bpftrace 快速入门

```bash
# bpftrace 语法
bpftrace -e 'probe { action }'

# 列出可用探针
bpftrace -l

# 追踪进程创建
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%s\n", comm); }'

# CPU 热点采样 (每 99Hz)
sudo bpftrace -e 'profile:hz:99 { @[ustack, kstack] = count(); }'
```

### bpftrace 高级用法

```bash
# 追踪函数调用耗时
sudo bpftrace -e '
    uprobe:/path/to/libfoo.so:foo_function {
        @start[pid] = nsecs;
    }
    uretprobe:/path/to/libfoo.so:foo_function {
        printf("Duration: %d ns\n", nsecs - @start[pid]);
        delete(@start[pid]);
    }
'

# 内存分配追踪
sudo bpftrace -e '
    malloc {
        @[ustack, arg0] = quantize(arg1);
    }
    free {
        @[ustack] = count();
    }
'

# 系统调用延迟
sudo bpftrace -e '
    syscall:* {
        @[comm, probe] = hist(elapsed);
    }
'
```

### BPF 追踪 Qt 应用

```bash
# 追踪 Qt 函数调用
sudo bpftrace -e '
    uprobe:*QWidget*:paintEvent {
        @[comm, ustack] = count();
    }
'

# 追踪 Qt 事件处理
sudo bpftrace -e '
    tracepoint:qt:qt_event_process {
        @[comm] = hist(elapsed);
    }
'

# 追踪 Qt 信号发射
sudo bpftrace -e '
    usdt:QCoreApplication:* {
        printf("%s\n", probe);
    }
'
```

---

## 4. 内存分析 (高)

### AddressSanitizer (ASan)

```bash
# 编译时启用 ASan
g++ -fsanitize=address -g -O1 app.cpp -o app

# 运行并检测内存错误
./app

# ASan 可以检测:
# - 越界访问 (buffer overflow)
# - 释放后使用 (use after free)
# - 双重释放 (double free)
# - 内存泄漏 (leaked memory)
```

### MemorySanitizer (MSan) - 仅 Clang

```bash
# 检测未初始化内存读取
clang++ -fsanitize=memory -g -O1 app.cpp -o app
./app
```

### Valgrind 工具链

```bash
# 安装
sudo apt install valgrind

# 内存泄漏检测
valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./app

# 堆分析
valgrind --tool=massif ./app
ms_print massif.out.* | less

# 缓存模拟
valgrind --tool=cachegrind ./app
cg_annotate cachegrind.out.*

# 分支预测模拟
valgrind --tool=branchgrind ./app
```

### 内存泄漏检测示例

```cpp
// 使用智能指针减少内存泄漏
#include <memory>

class HeavyResource {
public:
    HeavyResource() { std::cout << "Allocated\n"; }
    ~HeavyResource() { std::cout << "Released\n"; }
};

// 使用 unique_ptr 替代原始指针
std::unique_ptr<HeavyResource> create_resource() {
    return std::make_unique<HeavyResource>();
}

// 使用 shared_ptr 并设置删除器
std::shared_ptr<FILE> open_file(const char* path) {
    return std::shared_ptr<FILE>(fopen(path, "r"), fclose);
}
```

### 内存分配追踪

```bash
# 使用 bpftrace 追踪 malloc/free
sudo bpftrace -e '
   龟 = /malloc/ { @[ustack] = count(); }
    free = /free/ { @[ustack] = count(); }
'

# 追踪高频率分配点
sudo bpftrace -e '
    malloc {
        if (arg1 > 1024) {
            @[ustack, comm] = count();
        }
    }
'

# 堆大小变化追踪
sudo bpftrace -e '
    /pid == $1/ {
        @heap_size = heap_size(b excitations);
    }
' $(pgrep -o app_name)
```

---

## 5. 并发与锁分析 (高)

### 锁竞争分析

```bash
# perf lock 分析
sudo perf lock record ./app
sudo perf lock report

# 分析锁等待时间
perf stat -e lock:lock_acquire,lock:lock_release ./app
```

### 伪共享检测

```cpp
// 伪共享示例: 同一缓存行的不同变量被不同线程修改
struct CriticalData {
    alignas(64) int counter_a;  // 独占缓存行
    alignas(64) int counter_b;  // 独占缓存行
};

// 错误示例: 同一缓存行
struct BadData {
    int counter_a;
    int counter_b;  // 仍在同一缓存行 (x86 64字节)
};
```

### 无锁编程模式

```cpp
// 无锁环形缓冲区 (单生产者单消费者)
template<typename T, size_t N>
class LockFreeRingBuffer {
public:
    static_assert((N & (N - 1)) == 0, "N must be power of 2");

    bool push(T item) {
        size_t prod_pos = prod_pos_.load(std::memory_order_relaxed);
        size_t next_pos = (prod_pos + 1) & (N - 1);
        if (next_pos == cons_pos_.load(std::memory_order_acquire)) {
            return false;  // 缓冲区满
        }
        buffer_[prod_pos] = std::move(item);
        prod_pos_.store(next_pos, std::memory_order_release);
        return true;
    }

    bool pop(T& item) {
        size_t cons_pos = cons_pos_.load(std::memory_order_relaxed);
        if (cons_pos == prod_pos_.load(std::memory_order_acquire)) {
            return false;  // 缓冲区空
        }
        item = std::move(buffer_[cons_pos]);
        cons_pos_.store((cons_pos + 1) & (N - 1), std::memory_order_release);
        return true;
    }

private:
    std::atomic<size_t> prod_pos_{0};
    std::atomic<size_t> cons_pos_{0};
    alignas(64) std::array<T, N> buffer_;
};
```

### 线程局部存储 (TLS)

```cpp
// GCC/Clang 线程局部存储
thread_local int tls_counter = 0;
std::atomic<int> global_counter;

// 替代全局变量的锁保护
thread_local std::vector<double> tls_buffer;  // 每线程独立缓冲区
```

### 并发性能优化清单

```
✓ 减小临界区 — 只保护必要操作
✓ 使用细粒度锁 — 减少争用
✓ 读写锁分离 — 读多写少场景
✓ 无锁数据结构 — 对高并发场景
✓ 避免伪共享 — 使用 alignas(64)
✓ 线程局部存储 — 减少共享
✓ 原子操作替代锁 — 简单操作
✓ 批量操作 — 减少同步开销
```

---

## 6. Qt 性能优化 (高)

### Qt Profiler 使用

```bash
# Qt Creator 内置分析器
# 1. 在 Qt Creator 中: 分析 → QML Profiler
# 2. 命令行使用 qmlprofiler
qmlprofiler --tracepoints ./your_qt_app

# 记录完整跟踪数据
qmlprofiler -record -output trace.qtd
```

### QML 性能优化

```cpp
// 1. 使用懒加载
Loader {
    active: isVisible
    sourceComponent: heavyComponent
}

// 2. 使用 Item 作为根节点 (比 Window 快)
Item {
    // ...
}

// 3. 避免频繁重绘
Rectangle {
    color: themeColor  // 缓存颜色
    border.width: 1    // 固定边框
}

// 4. 使用 Canvas 批量绘制
Canvas {
    onPaint: {
        var ctx = getContext("2d");
        ctx.beginPath();
        // 批量绘制
        ctx.fill();
    }
}
```

### Qt 模型/视图优化

```cpp
// 1. 大数据集使用 QAbstractItemModel::canFetchMore
bool MyModel::canFetchMore(const QModelIndex& parent) const {
    return !hasAllData && parent == QModelIndex();
}

// 2. 实现批量更新
void MyModel::addItems(const QVector<Item>& items) {
    beginInsertRows(QModelIndex(), rowCount(), rowCount() + items.size() - 1);
    // 添加数据
    endInsertRows();
}

// 3. 使用 QSortFilterProxyModel 过滤
class MyProxyModel : public QSortFilterProxyModel {
    bool filterAcceptsRow(int sourceRow, const QModelIndex& sourceParent) const override {
        // 自定义过滤逻辑
    }
};
```

### Qt 图形渲染优化

```cpp
// 1. 使用 QGraphicsObject 替代 QQuickItem
// 2. 启用 ItemCoordinateCache
Rectangle {
    layer.enabled: true
    layer.smooth: false  // 禁用平滑 (提升性能)
}

// 3. 使用 ShaderEffect 硬件加速
ShaderEffect {
    fragmentShader: "
        varying vec2 qt_TexCoord0;
        uniform sampler2D qt_Texture;
        void main() {
            gl_FragColor = texture2D(qt_TexCoord0);
        }
    "
}

// 4. 减少绑定数量
Binding on width { when: isVisible; value: parent.width }
```

### Qt 内存优化

```cpp
// 1. 使用 QStringLiteral 避免运行时复制
void processString(const QString& str) {
    if (str == QStringLiteral("hello")) {  // 编译时比较
        // ...
    }
}

// 2. 合理使用隐式共享
QString name = "Large text";  // 共享数据
QString subname = name.mid(5);  // 延迟复制
// subname 实际共享 name 的数据，直到修改

// 3. 使用 QCache 缓存
QCache<QString, PixmapItem> pixmapCache(100);  // 最多 100 项
```

---

## 7. 编译器优化选项 (中等)

### GCC/Clang 优化级别

```bash
# -O0: 无优化 (调试)
# -O1: 基本优化
# -O2: 常用优化 (默认)
# -O3: 激进优化
# -Os: 空间优化
# -Ofast: 激进浮点优化 (可能违反标准)

// 推荐 C++ 性能优化选项
g++ -O3 -march=native -mtune=native \
    -flto -ffast-math \
    -funroll-loops \
    app.cpp -o app
```

### 架构特定优化

```bash
# x86_64 优化
g++ -O3 -march=x86-64-v3 -mtune=generic app.cpp -o app

# ARM64 优化
g++ -O3 -march=armv8-a -mtune=generic app.cpp -o app

# 检测 CPU 支持的架构
cat /proc/cpuinfo | grep -o 'avx[^ ]*'
lscpu | grep Architecture
```

### LTO (链接时优化)

```bash
# 启用 LTO
g++ -O3 -flto app.cpp -o app

# Thin LTO (减少内存使用)
g++ -O3 -flto=thin app.cpp -o app

# CMake 中启用 LTO
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
```

### 常用优化选项详解

```bash
# 循环优化
-ffast-math           # 快速浮点 (可能不精确)
-funroll-loops       # 展开循环
-floop-nest-optimize # 循环嵌套优化

# 内联优化
-finline-functions   # 内联简单函数
-finline-limit=N     # 内联函数大小限制

# 代码生成
-fPIC                # 位置无关代码
-fomit-frame-pointer # 释放帧指针 (增加寄存器)

# 分支预测
-fbranch-probabilities # 使用分支概率信息
```

### Profile-Guided Optimization (PGO)

```bash
# 1. 编译时插入插桩
g++ -O3 -fprofile-generate app.cpp -o app_profile

# 2. 运行代表性工作负载
./app_profile < representative_input

# 3. 使用生成的 .gcda 文件重编译
g++ -O3 -fprofile-use app.cpp -o app_optimized
```

---

## 8. 火焰图 (中等)

### 火焰图工具安装

```bash
# 克隆火焰图工具
git clone https://github.com/brendangregg/FlameGraph.git
export PATH=$PATH:~/FlameGraph

# 必需工具
sudo apt install perf linux-tools-$(uname -r) bpfcc-tools
```

### 生成 CPU 火焰图

```bash
# 方法 1: 使用 perf 生成
sudo perf record -F 99 -g -p $(pgrep -o app_name) -- sleep 60
sudo perf script | ./stackcollapse-perf.pl | ./flamegraph.pl > cpu.svg

# 方法 2: 使用 bpftrace
sudo bpftrace -e '
    profile:hz:99 /comm == "app_name"/ {
        @[ustack] = count();
    }
' -d | ./FlameGraph/stackcollapse-bpftrace.pl | ./FlameGraph/flamegraph.pl > app.svg

# 方法 3: JavaScript/V8 火焰图
sudo perf record -F 99 -g -p $(pgrep -o node) -- sleep 30
sudo perf script --no-inline | ./FlameGraph/stackcollapse-perf.pl | ./flameGraph/flamegraph.pl --color=js > node.svg
```

### 生成内存火焰图

```bash
# 使用 bpftrace 追踪 malloc
sudo bpftrace -e '
    malloc {
        @[ustack, arg1] = hist(arg1);
    }
' --pid=$(pgrep app_name) -d | ./FlameGraph/stackcollapse-bpftrace.pl | \
    ./FlameGraph/flamegraph.pl --color=mem > mem.svg

# 使用 valgrind + 火焰图
valgrind --tool=massif --pages-as-heap=yes ./app
ms_print massif.out.* | ./FlameGraph/massif-visualizer.pl > mem.svg
```

### 解读火焰图

```
火焰图解读
├── 横向: 函数占用宽度 = 样本中出现频率
├── 纵向: 调用栈深度 (顶层是叶子函数)
├── 颜色: 通常相同 (CPU 时间)，可按类型着色
│   ├── 红色: 内核态时间
│   ├── 橙色: 系统调用
│   ├── 绿色: 用户态时间
│   └── 蓝色: I/O 等待
└── 点击: 可下钻查看细节

"平顶" = 热点函数
"尖峰" = 单一热点调用路径
```

---

## 反模式

| # | 不要 | 要做 |
|---|------|------|
| 1 | 凭猜测优化 | 先用 profiling 工具定位瓶颈 |
| 2 | 优化无关紧要的代码 | 聚焦 20% 的热点代码 |
| 3 | 过早优化 | 保持代码可读性，等性能需求明确再优化 |
| 4 | 只看平均延迟 | 关注 P99/P999 延迟 |
| 5 | 忽视内存分配 | 使用内存池、对象复用 |
| 6 | 全局锁保护一切 | 使用细粒度锁或无锁结构 |
| 7 | 忽略缓存效应 | 设计缓存友好的数据结构和访问模式 |
| 8 | 迷信 benchmark | 用真实工作负载测试 |
| 9 | 跳过回归测试 | 确保优化不破坏功能 |
| 10 | 单方面优化 | 系统地分析 CPU/内存/I/O/锁 |

---

## 常见问题

### 问题 1: "perf record 权限不足"

```bash
# 检查权限
cat /proc/sys/kernel/perf_event_paranoid
# 值 > 1 表示受限

# 临时解除限制
sudo sh -c 'echo -1 > /proc/sys/kernel/perf_event_paranoid'

# 永久设置 (编辑 /etc/sysctl.conf)
kernel.perf_event_paranoid = -1
```

### 问题 2: "bpftrace 提示缺少调试信息"

```bash
# Ubuntu 安装 debug symbols
sudo apt install linux-image-$(uname -r)-dbgsym

# 或者使用 apt sources.list.d
echo 'deb http://ddebs.ubuntu.com $(lsb_release -cs) main' | \
    sudo tee /etc/apt/sources.list.d/ddebs.list
sudo apt update
sudo apt install linux-image-$(uname -r)-dbgsym
```

### 问题 3: "Qt 应用在 profiling 时行为异常"

```bash
# Qt 性能分析可能影响应用行为
# 使用 Release 构架 + Debug symbols
cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo

# 避免 QML Profiler 干扰
# 使用外部 perf/bpftrace 而非 Qt Creator 内部分析器
```

### 问题 4: "内存分析工具开销太大"

```bash
# ASan 降低开销
# -O2 替代 -O0
# 使用 production 模式
g++ -fsanitize=address -g -O2 app.cpp -o app

# Valgrind 使用轻量工具
valgrind --tool=exp-dhat ./app  # DHAT 轻量堆分析
```

---

## 参考文档

此技能包含专业主题的深度参考。需要详细指导时阅读相关参考。

| 需要… | 参考 |
|-------|------|
| BPF 工具详解 | [references/bpf-tools-guide.md](references/bpf-tools-guide.md) |
| 性能剖析技术 | [references/profiling-techniques.md](references/profiling-techniques.md) |
| Qt 性能优化 | [references/qt-performance-optimization.md](references/qt-performance-optimization.md) |
| 内存分析工具 | [references/memory-analysis.md](references/memory-analysis.md) |
