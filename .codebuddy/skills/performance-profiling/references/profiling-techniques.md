# 性能剖析技术参考

## 目录

1. [perf 高级用法](#perf-高级用法)
2. [火焰图生成](#火焰图生成)
3. [多核分析](#多核分析)
4. [微基准测试](#微基准测试)
5. [延迟分析](#延迟分析)

---

## perf 高级用法

### perf 数据流

```
perf record → perf.data
     ↓
perf report → 文本报告
     ↓
perf script → perf 脚本
     ↓
FlameGraph → SVG 火焰图
```

### 事件类型

```bash
# 硬件事件 (需要 root)
perf list hw
# 常用:
# - cycles: CPU 周期
# - instructions: 指令数
# - cache-references: 缓存引用
# - cache-misses: 缓存未命中
# - branches: 分支数
# - branch-misses: 分支预测失败

# 软件事件
perf list sw
# - cpu-clock: CPU 时钟
# - task-clock: 任务时钟
# - page-faults: 页错误
# - context-switches: 上下文切换
# - cpu-migrations: CPU 迁移

# 追踪点
perf list 'syscalls:*'
perf list 'block:*'
perf list 'sched:*'
```

### 高级采样

```bash
# 采样特定事件
perf record -e cache-misses -F 999 ./app

# 采样特定符号 (需要 debug symbols)
perf record -e cycles -g --call-graph dwarf ./app

# 采样特定 CPU
perf record -e cycles -C 0,1 ./app

# 采样特定进程/线程
perf record -p <pid> -g -- sleep 30
perf record -t <tid> -g -- sleep 30

# 排除内核
perf record -g --exclude-kernel ./app

# 排除 idle
perf record -g --exclude-idle ./app
```

### perf annotate

```bash
# 查看源码注释
perf annotate --stdio

# 查看特定符号
perf annotate --stdio --symbol=hot_function

# 显示汇编和源码
perf annotate --stdio --disasm=hot_function

# 输出示例
# Percent | Source code & Disassembly of a.out for cycles:ppp (2517 samples)
#         :        void hot_loop() {
#     0.00 :        push   %r15
#     0.00 :        push   %r14
#     0.00 :        push   %r13
#    10.23 :        mov    (%rsi),%r13
#         :           for (int i = 0; i < N; ++i) {
#    89.77 :        add    $0x1,%r13d
#    ...
```

### perf diff

```bash
# 比较两次采样的差异
perf record -g -o perf1.data ./app_before
perf record -g -o perf2.data ./app_after

perf diff perf1.data perf2.data
```

### perf timechart

```bash
# 生成时间图表
perf timechart record -- ./app
perf timechart output.svg
```

---

## 火焰图生成

### 工具安装

```bash
# 克隆火焰图仓库
git clone https://github.com/brendangregg/FlameGraph.git
cd FlameGraph

# 必需工具
sudo apt install perf  # Linux perf
```

### CPU 火焰图生成流程

```bash
# 1. perf 采样 (99Hz, 30秒)
sudo perf record -F 99 -g -p $(pgrep -o app_name) -- sleep 30

# 2. 生成调用栈折叠文件
sudo perf script > perf.unfold

# 3. 折叠调用栈
./stackcollapse-perf.pl perf.unfold > perf.folded

# 4. 生成火焰图
./flamegraph.pl perf.folded > perf.svg

# 一行命令
sudo perf script | ./stackcollapse-perf.pl | ./flamegraph.pl > perf.svg
```

### 火焰图类型

| 类型 | 命令 | 用途 |
|------|------|------|
| CPU | `flamegraph.pl` | CPU 时间分布 |
| Memory | `flamegraph.pl --color=mem` | 内存分配 |
| Off-CPU | `flamegraph.pl --color=io` | I/O 和等待时间 |
| JavaScript | `flamegraph.pl --color=js` | JavaScript V8 |
| Differential | `difffolded.pl` | 优化前后对比 |

### 微优化对比火焰图

```bash
# 采样优化前
perf record -F 99 -g -o before.data ./app -- workload
perf script -i before.data > before.unfold
./stackcollapse-perf.pl before.unfold > before.folded

# 采样优化后
perf record -F 99 -g -o after.data ./app -- workload
perf script -i after.data > after.unfold
./stackcollapse-perf.pl after.unfold > after.folded

# 生成对比
./difffolded.pl before.folded after.folded | ./flamegraph.pl --negate > diff.svg
```

### 热力图火焰图

```bash
# 生成带时间轴的火焰图
perf record -F 99 -g -p $(pgrep app_name) -- sleep 60

# 使用 --time 选项切片
perf script --time 0-10 > segment1.unfold
perf script --time 10-20 > segment2.unfold

./stackcollapse-perf.pl segment1.unfold > segment1.folded
./flamegraph.pl segment1.folded > segment1.svg
```

---

## 多核分析

### 观察 CPU 负载分布

```bash
# 查看 CPU 利用率
mpstat -P ALL 1

# 查看每个核心的负载
top -H

# perf 统计每个 CPU
perf stat -a -e cycles sleep 10
```

### 绑定线程到 CPU

```bash
# taskset 绑定
taskset -c 0 ./app  # 绑定到 CPU 0
taskset -c 0-3 ./app  # 绑定到 CPU 0-3

# numactl 绑定到 NUMA 节点
numactl --cpunodebind=0 --membind=0 ./app

# 运行时查看
ps -eo pid,psr,comm | grep app
```

### 伪共享检测

```bash
# perf 检查缓存未命中
perf stat -e cache-references,cache-misses -M all ./app

# 硬件缓存事件
perf stat -e LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses ./app

# 伪共享特征: 高 cache-miss 但代码访问的内存不多
```

### 内存带宽分析

```bash
# 内存带宽工具
perf stat -e 'mem_load_retired:*,mem_stores_retired:*' ./app

# 或使用 likwid
sudo apt install likwid
likwid-bench -t stream -w N:1000000
```

---

## 微基准测试

### Google Benchmark 框架

```cpp
#include <benchmark/benchmark.h>

static void BM_StringCreation(benchmark::State& state) {
    for (auto _ : state) {
        std::string empty_string;
    }
}
BENCHMARK(BM_StringCreation);

static void BM_StringCopy(benchmark::State& state) {
    std::string x = "hello";
    for (auto _ : state) {
        std::string copy = x;
    }
}
BENCHMARK(BM_StringCopy);

BENCHMARK_MAIN();
```

### 编译运行

```bash
# 编译 (需要 CMake)
g++ -std=c++17 -O3 -isystem include benchmarks.cpp -o benchmark
./benchmark

# 输出格式选项
./benchmark --benchmark_format=console
./benchmark --benchmark_format=json
./benchmark --benchmark_format=csv

# 常用选项
./benchmark --benchmark_min_time=5    # 最小运行时间
./benchmark --benchmark_filter=BM_String  # 过滤
./benchmark --benchmark_repetitions=10  # 重复次数
```

### 内存分配基准

```cpp
static void BM_Allocate(benchmark::State& state) {
    for (auto _ : state) {
        auto* p = new char[64];
        benchmark::DoNotOptimize(p);
        delete[] p;
    }
}
BENCHMARK(BM_Allocate);

static void BM_PoolAllocate(benchmark::State& state) {
    MemoryPool pool(1024);
    for (auto _ : state) {
        auto* p = pool.allocate(64);
        benchmark::DoNotOptimize(p);
        pool.deallocate(p);
    }
}
BENCHMARK(BM_PoolAllocate);
```

### 避免编译器优化

```cpp
// 阻止编译器优化
benchmark::DoNotOptimize(variable);

// 阻止内存优化
benchmark::ClobberMemory();

// 强制使用变量
volatile int x = 0;
```

---

## 延迟分析

### 延迟类型

| 类型 | 说明 | 工具 |
|------|------|------|
| 尾延迟 | P99/P999 延迟 | histogram |
| 队列延迟 | 等待处理的时间 | tracing |
| 服务延迟 | 实际处理时间 | tracing |
| 总延迟 | 队列 + 服务 | end-to-end |

### 延迟直方图

```cpp
#include <hdr_histogram.h>

struct LatencyRecorder {
    // HDRHistogram: 支持高动态范围
    hdr_histogram* histogram;

    void init() {
        hdr_init(1, 10000000, 3, &histogram);  // 1us - 10s, 3 位有效数字
    }

    void record(int64_t us) {
        hdr_record_value(histogram, us);
    }

    void print() {
        printf("p50: %lld us\n", hdr_value_at_percentile(histogram, 50.0));
        printf("p99: %lld us\n", hdr_value_at_percentile(histogram, 99.0));
        printf("p999: %lld us\n", hdr_value_at_percentile(histogram, 99.9));
    }
};
```

### 延迟追踪 (bpftrace)

```bpftrace
// 追踪函数延迟
kprobe:do_sys_open
{
    @start[pid] = nsecs;
}

kretprobe:do_sys_open
/comm == "app_name"/
{
    $lat = (nsecs - @start[pid]) / 1000;
    @open_latency = hist($lat);
    delete(@start[pid]);
}
```

### 抖动 (Jitter) 分析

```cpp
// 计算延迟抖动
class JitterCalculator {
public:
    void add(int64_t latency_us) {
        if (last_) {
            int64_t diff = std::abs(latency_us - *last_);
            histogram_.add(diff);
        }
        last_ = latency_us;
    }

    int64_t p99_jitter() {
        return histogram_.percentile(99.0);
    }

private:
    std::optional<int64_t> last_;
    Histogram histogram_;
};
```

### 实时延迟监控

```bash
# 使用 bpftrace 实时监控延迟
sudo bpftrace -e '
    kprobe:do_sys_open,
    kretprobe:do_sys_open
    /comm == "app_name"/
    {
        if (probename == "do_sys_open") {
            @start[pid] = nsecs;
        } else {
            $lat = (nsecs - @start[pid]) / 1000;
            @["open"] = hist($lat);
            delete(@start[pid]);
        }
    }
'

# 使用 BCC funclatency
sudo funclatency-bpfcc -u -I libc.so.6 malloc -p $(pgrep app_name)
```

---

## 常用命令速查

| 任务 | 命令 |
|------|------|
| CPU 热点 | `perf record -g -F 99 ./app; perf report` |
| 内存泄漏 | `valgrind --leak-check=full ./app` |
| 锁竞争 | `perf lock record ./app; perf lock report` |
| 系统调用 | `strace -c ./app` |
| I/O 延迟 | `sudo biolatency-bpfcc` |
| 火焰图 | `perf script \| ./FlameGraph/stackcollapse-perf.pl \| ./flamegraph.pl` |
| 内存分配 | `bpftrace -e 'malloc { @[ustack] = hist(arg0); }'` |
| 启动分析 | `perf record -g -F 99 -- ./app; perf report --stdio --sort=dso` |
