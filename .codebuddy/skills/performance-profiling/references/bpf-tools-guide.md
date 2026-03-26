# BPF 性能工具指南

## 目录

1. [BCC 工具详解](#bcc-工具详解)
2. [bpftrace 脚本编程](#bpftrace-脚本编程)
3. [BPF 追踪 Qt 应用](#bpf-追踪-qt-应用)
4. [高级 BPF 技术](#高级-bpf-技术)
5. [性能分析实战案例](#性能分析实战案例)

---

## BCC 工具详解

### BCC (BPF Compiler Collection) 概述

BCC 是 BPF 的高级框架，提供 Python/Lua 前端，预置大量性能分析工具。

### 安装

```bash
# Ubuntu 20.04/22.04
sudo apt install bpfcc-tools

# 工具名称规则：Ubuntu 上所有 bpfcc-tools 命令都带有 -bpfcc 后缀
# 验证安装 (列出所有工具)
dpkg -L bpfcc-tools | grep -E '/usr/(s)?bin/.*-bpfcc$'
```

### 常用 BCC 工具速查表

| 工具名称 | 功能 | 典型命令 |
|----------|------|----------|
| `opensnoop-bpfcc` | 追踪 open() 系统调用 | `sudo opensnoop-bpfcc` |
| `execsnoop-bpfcc` | 追踪 exec() 进程创建 | `sudo execsnoop-bpfcc` |
| `biolatency-bpfcc` | 磁盘 I/O 延迟分布 | `sudo biolatency-bpfcc` |
| `cachetop-bpfcc` | 页缓存命中率 | `sudo cachetop-bpfcc` |
| `cachestat-bpfcc` | 页缓存统计 | `sudo cachestat-bpfcc` |
| `funclatency-bpfcc` | 函数调用延迟 | `sudo funclatency-bpfcc vfs_read` |
| `offcputime-bpfcc` | CPU 离开时间 | `sudo offcputime-bpfcc -p PID` |
| `argdist-bpfcc` | 参数分布统计 | `sudo argdist-bpfcc -H` |
| `profile-bpfcc` | CPU 采样 | `sudo profile-bpfcc -F 99` |
| `filelife-bpfcc` | 文件生命周期 | `sudo filelife-bpfcc` |
| `fileslower-bpfcc` | 文件操作延迟 | `sudo fileslower-bpfcc 10` |
| `ext4slower-bpfcc` | ext4 文件系统延迟 | `sudo ext4slower-bpfcc 10` |

### execsnoop - 追踪进程创建

```bash
# 基础用法
sudo execsnoop-bpfcc

# 追踪特定进程
sudo execsnoop-bpfcc -t

# 追踪并显示失败
sudo execsnoop-bpfcc -x

# 输出格式
# PCOMM            PID     PPID    RET ARGS
# bash             1234    1233      0 /bin/bash -l
# app              5678    1234      0 ./app --arg1
```

### opensnoop - 追踪文件打开

```bash
# 追踪所有文件打开
sudo opensnoop-bpfcc

# 追踪特定文件
sudo opensnoop-bpfcc -f /etc/passwd

# 显示错误
sudo opensnoop-bpfcc -e

# 追踪特定进程
sudo opensnoop-bpfcc -p 1234

# 输出格式
# PID    COMM               FD ERR PATH
# 1234   app                3   0   /path/to/file
```

### biolatency - I/O 延迟分布

```bash
# 磁盘 I/O 延迟直方图
sudo biolatency-bpfcc

# 指定时间段
sudo biolatency-bpfcc 5

# 输出格式
#     usecs               : count     distribution
#         0 -> 1          : 0        |
#         2 -> 3          : 1        |
#         4 -> 7          : 5        |**
#         8 -> 15         : 128      |******
#        ...
```

### funclatency - 函数延迟

```bash
# 追踪内核函数延迟
sudo funclatency-bpfcc vfs_read

# 追踪用户态函数 (需要库符号)
sudo funclatency-bpfcc -u malloc

# 追踪特定库
sudo funclatency-bpfcc -u -I libc.so.6 malloc
```

### cachestat - 页缓存统计

```bash
# 页缓存命中率
sudo cachestat-bpfcc

# 输出格式
#     HITS   MISSES  EVICTS  HITRATIO
#   123456    78910    1234    93.74%
```

### offcputime - CPU 离开时间

```bash
# 追踪进程在 CPU 外花费的时间 (锁等待、I/O 等)
sudo offcputime-bpfcc -p $(pgrep -o app_name)

# 输出格式
#     PROCESS          FUNCTION                    TOTAL TIME (ms)
#     app              pthread_mutex_lock              1234.56
#     app              io_getevents                    89.12
```

### profile - CPU 采样

```bash
# CPU 热点采样 (BCC 版本)
sudo profile-bpfcc -F 99

# 采样特定进程
sudo profile-bpfcc -F 99 -p $(pgrep -o app_name)

# 输出 FlameGraph 格式
sudo profile-bpfcc -F 99 -f | ./FlameGraph/flamegraph.pl > profile.svg
```

### ext4slower - ext4 文件系统延迟

```bash
# 追踪 ext4 慢操作 (超过 10ms)
sudo ext4slower-bpfcc 10

# 输出格式
# TIME     COMM           PID    T BYTES   LAT(ms) FILE
# 12:34:56 app            1234   R 4096    15.23   data.bin
```

---

## bpftrace 脚本编程

### bpftrace 程序结构

```bpftrace
// 注释

// 头部: 探针定义
probe[, probe...]

// 变量声明
@variable = value;

// 操作 (每触发一次执行一次)
{ action; }

// 打印输出
// print(@variable);

// 清理
END { clear(@variable); }
```

### 探针类型

| 类型 | 语法 | 说明 |
|------|------|------|
| kprobe | `kprobe:function` | 内核函数入口 |
| kretprobe | `kretprobe:function` | 内核函数返回 |
| uprobe | `uprobe:/path:func` | 用户态函数入口 |
| uretprobe | `uretprobe:/path:func` | 用户态函数返回 |
| tracepoint | `tracepoint:category:name` | 静态追踪点 |
| USDT | `usdt:/path:name` | 用户级静态追踪 |
| profile | `profile:hz:rate` | 定时 CPU 采样 |
| hardware | `hardware:event:count` | 硬件事件 |
| software | `software:event:count` | 软件事件 |

### 变量类型

```bpftrace
// 映射 (Map) - 类似于字典
@my_map[ key1, key2 ] = count();

// 关联数组
@requests[ comm ] = sum();

// 线性直方图
@latency = hist( latency_ns );

// 统计
@count = count();

// 最大/最小值
@max_val = max( value );
@min_val = min( value );

// 堆栈轨迹
@stacks[ ustack ] = count();

// 打印标量
$n = 42;
printf( "Number: %d\n", $n );
```

### 内置变量

| 变量 | 类型 | 说明 |
|------|------|------|
| `pid` | uint64 | 进程 ID |
| `tid` | uint64 | 线程 ID |
| `comm` | char[] | 进程名 |
| `nsecs` | uint64 | 纳秒时间戳 |
| `cpu` | uint64 | CPU ID |
| `gid` | uint32 | GID |
| `uid` | uint32 | UID |
| `arg0`-`argN` | int64 | 探针参数 |
| `retval` | int64 | 函数返回值 |

### 常用内置函数

| 函数 | 说明 |
|------|------|
| `printf()` | 格式化输出 |
| `hist()` | 创建直方图 |
| `lhist()` | 创建线性直方图 |
| `count()` | 计数 |
| `sum()` | 求和 |
| `avg()` | 平均值 |
| `max()` | 最大值 |
| `min()` | 最小值 |
| `delete()` | 删除映射项 |
| `clear()` | 清空映射 |
| `exit()` | 退出 bpftrace |
| `str()` | 指针转字符串 |
| `buf()` | 读取内存缓冲区 |

### 完整示例: 追踪函数调用

```bpftrace
#!/usr/bin/bpftrace

// 追踪 malloc 调用并统计大小分布
malloc
{
    @mallocs[ustack, comm] = hist(arg0);
}

// 追踪 free 调用
free
{
    @frees[comm] = count();
}

// Ctrl+C 后输出
END
{
    printf("\n=== Top Memory Allocations ===\n");
    print(@mallocs);
    printf("\n=== Free Count by Process ===\n");
    print(@frees);
    clear(@mallocs);
    clear(@frees);
}
```

### 完整示例: 网络延迟追踪

```bpftrace
#!/usr/bin/bpftrace

// 追踪 TCP 连接建立
tracepoint:tcp:tcp_send_reset
{
    @send_reset[comm] = count();
}

tracepoint:tcp:tcp_receive_reset
{
    @recv_reset[comm] = count();
}

// 追踪 TCP 重传
tracepoint:tcp:tcp_retransmit_skb
{
    @retrans[comm] = count();
}

// 输出直方图
END
{
    printf("\n=== TCP Reset Count ===\n");
    print(@send_reset);
    print(@recv_reset);
    printf("\n=== TCP Retransmit Count ===\n");
    print(@retrans);
    clear(@send_reset);
    clear(@recv_reset);
    clear(@retrans);
}
```

---

## BPF 追踪 Qt 应用

### Qt 追踪点

Qt 应用需要启用追踪点支持:

```bash
# 编译 Qt 时启用
cmake -DQT_DEBUG_ENABLE=ON ..

# 或使用环境变量
export QT_DEBUG_ENABLE=1
./app
```

### 追踪 Qt 信号

```bpftrace
// 追踪 Qt 信号发射 (需要 Qt 调试符号)
uprobe:/usr/lib/x86_64-linux-gnu/libQt5Core.so.5:_ZN7QObjectlsEv
{
    // QObject::operator= 调用
    @qt_signal[comm] = count();
}

// 追踪 QMetaObject::activate
uprobe:*_ZN14QMetaObject8activateEP7QObjectPKS0_iPv*
{
    @qt_activate[ustack] = count();
}
```

### 追踪 Qt 事件循环

```bpftrace
// 追踪 QCoreApplication::exec
uprobe:*_ZN16QCoreApplication4execEv
{
    @eventloop_start[comm] = count();
}

// 追踪事件处理
tracepoint:qt:qt_event_process
{
    @event_process[comm] = hist(elapsed);
}
```

### 追踪 Qt 图形渲染

```bpftrace
// 追踪 QWidget::paintEvent
uprobe:*QWidget*:paintEvent
{
    @paint_events[ustack] = count();
}

// 追踪 QPainter 绘制
uprobe:*QPainter*:draw*
{
    @painter_draw[ustack] = count();
}
```

### 追踪 Qt 内存分配

```bpftrace
// 追踪 Qt 的内存分配
// Qt 使用 qmalloc/qfree 或系统 malloc

uprobe:*qmalloc*
{
    @qt_malloc[ustack, arg0] = hist(arg0);
}

uprobe:*qfree*
{
    @qt_free[ustack] = count();
}

// 也可以追踪标准 malloc/free
uprobe:*:malloc
/comm == "app_name"/
{
    @malloc_size[ustack] = hist(arg0);
}
```

---

## 高级 BPF 技术

### Attach 到进程

```bash
# 使用 -p 指定进程
sudo bpftrace -p $(pgrep app_name) -e '
    profile:hz:99 {
        @[ustack] = count();
    }
'

# 多个进程
sudo bpftrace -e '
    /regmatching/ {
        @[comm, ustack] = count();
    }
' --grep app_name
```

### 条件过滤

```bpftrace
// 只追踪大于 1KB 的分配
malloc
/arg0 > 1024/
{
    @[ustack] = count();
}

// 只追踪特定进程
malloc
/comm == "myapp"/
{
    @[ustack, arg0] = count();
}

// 只追踪特定 CPU
profile:hz:99
/cpu == 0/
{
    @[ustack] = count();
}
```

### 时间窗口

```bpftrace
// 运行 30 秒后退出
sudo bpftrace -e '...' --睲e 30

// 打印中间结果
profile:hz:99
{
    @[ustack] = count();
    if (@[ustack] > 10000) {
        print(@[ustack]);
        delete(@[ustack]);
    }
}
```

### BPF Map 操作

```bpftrace
// 创建哈希映射
@myhash[pid, comm] = count();

// 创建直方图
@latency = hist(sched_switch);

// 创建环形缓冲区 (需要 Linux 5.8+)
struct ringbuf_t {
    int id;
    int value;
} ;

// 使用
BEGIN
{
    @rb = ringbuf();
}

tracepoint:syscalls:sys_enter_read
{
    ringbuf_output(@rb, 1, 0);
}
```

### 调试 BPF 程序

```bash
# 使用 -d 显示调试信息
sudo bpftrace -d -e 'kprobe:vfs_read { printf("vfs_read called\n"); }'

# 检查探针
bpftrace -l

# 搜索探针
bpftrace -l '*malloc*'
bpftrace -l 'tracepoint:syscalls:sys_enter_*'

# 检查 bpftrace 错误
bpftrace --version
sudo bpftrace -V
```

---

## 性能分析实战案例

### 案例 1: 定位 CPU 热点

```bash
# 1. CPU 采样
sudo perf record -F 99 -g -p $(pgrep -o app_name) -- sleep 30

# 2. 生成火焰图
sudo perf script | ./stackcollapse-perf.pl | ./flamegraph.pl > cpu.svg

# 3. 用 bpftrace 深入分析
sudo bpftrace -e '
    profile:hz:99 /comm == "app_name"/ {
        @[ustack] = count();
    }
' --pid=$(pgrep app_name) -d | ./FlameGraph/stackcollapse-bpftrace.pl | \
    ./flamegraph.pl --color=js > detail.svg
```

### 案例 2: 内存泄漏检测

```bash
# 1. 基础 ASan 检测
g++ -fsanitize=address -g app.cpp -o app_asan
./app_asan

# 2. 长期内存增长追踪
sudo bpftrace -e '
    /pid == $1/ {
        @alloc = ntop(6, arg0);
        @total += arg0;
        if (@total > 100MB) {
            printf("Memory growth: %d MB\n", @total / 1024 / 1024);
        }
    }
' --pid=$(pgrep app_name)

# 3. Valgrind massif 分析
valgrind --tool=massif --pages-as-heap=yes ./app
ms_print massif.out.* | head -100
```

### 案例 3: 锁竞争分析

```bash
# 1. perf lock 分析
sudo perf lock record -p $(pgrep app_name) -- sleep 30
sudo perf lock report

# 2. offcputime 追踪
sudo offcputime-bpfcc -p $(pgrep app_name)

# 3. bpftrace 追踪锁等待
sudo bpftrace -e '
    lock:mutex_lock {
        @lock_start[arg0] = nsecs;
    }
    lock:mutex_unlock /@lock_start[arg0]/
    {
        $lat = (nsecs - @lock_start[arg0]) / 1000;
        @mutex_latency = hist($lat);
        delete(@lock_start[arg0]);
    }
'

# 4. 分析伪共享
perf stat -e cache-references,cache-misses ./app
```

### 案例 4: I/O 延迟分析

```bash
# 1. 磁盘 I/O 延迟
sudo biolatency-bpfcc

# 2. 按文件分析
sudo filelife-bpfcc

# 3. 文件系统操作
sudo fileslower-bpfcc 10

# 4. 详细追踪
sudo bpftrace -e '
    tracepoint:block:block_rq_insert
    {
        @rq_start[args->dev, args->sector] = nsecs;
    }
    tracepoint:block:block_rq_complete
    /@rq_start[args->dev, args->sector]/
    {
        $lat = (nsecs - @rq_start[args->dev, args->sector]) / 1000;
        @io_latency = hist($lat);
        delete(@rq_start[args->dev, args->sector]);
    }
'
```

---

## 参考资源

- [BCC 官方文档](https://github.com/iovisor/bcc)
- [bpftrace 参考指南](https://github.com/iovisor/bpftrace)
- [BPF Performance Tools (Brendan Gregg)](http://www.brendangregg.com/bpf-performance-tools-book.html)
- [Linux Extended BPF (eBPF)  Tracing Tools](http://www.brendangregg.com/blog/2019-01-01/learn-ebpf-tracing.html)
