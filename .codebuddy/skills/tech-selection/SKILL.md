---
name: tech-selection
description: |
  C++/Qt 技术栈下的技术选型指南。
  触发条件: 用户需要在新旧技术之间做选择、需要评估库/框架的性能和资源占用、
  需要编写 benchmark 测试、需要生成技术对比报告。
  不触发条件: 纯编码任务、调试请求、已确定技术栈的小任务。
license: MIT
metadata:
  category: technology-selection
  version: "1.0.0"
  tech_stack:
    - C++11
    - Qt
    - qmake
    - CMake
sources:
  - 嵌入式系统性能优化
  - C++ 基准测试最佳实践
  - 技术选型方法论
---

# 技术选型与对比

## 技术栈聚焦

> **重要**: 本 skill 默认在 **C++11 / Qt** 技术栈下工作。
> - 默认语言: C++11
> - 默认 GUI: Qt Widgets / Qt Quick/QML
> - 默认构建: qmake + CMake 混合
> - 默认平台: Linux / Windows / macOS / 嵌入式 Linux / RTOS

---

## 强制工作流 — 按顺序执行以下步骤

**当此技能被触发时，必须遵循此工作流。**

### 第 0 步: 收集目标平台信息（交互式提问）

**必须向用户确认以下关键信息**：

| 维度 | 澄清问题 | 目的 |
|------|----------|------|
| **目标操作系统** | 目标平台是 Linux/Windows/macOS/嵌入式 Linux/RTOS/RTOS-XXX？ | 确定交叉编译需求 |
| **CPU 架构** | 目标架构是 x86_64/ARM Cortex-M/ARM Cortex-A/RISC-V/其他？ | 确定编译器选项和优化参数 |
| **内存限制** | 可用 RAM 最大多少？是否有 MMU？Flash/ROM 最大多少？ | 评估 footprint 约束 |
| **存储限制** | 程序存储空间上限？是否需要 OTA 更新？ | 评估库大小 |
| **性能要求** | 实时性要求？最大延迟容忍？CPU 主频和核心数？ | 确定性能基准线 |
| **网络需求** | 需要 TCP/UDP/HTTP/MQTT/其他协议？ | 确定网络库需求 |
| **现有工具链** | 已有 GCC/Clang/IAR/Keil/其他工具链？ | 确定编译环境 |
| **许可证约束** | 对开源库许可证有特殊要求？（GPL/LGPL/MIT/商业） | 评估许可证风险 |

**提问模板**：
```
目标平台硬件限制调查：

1. 操作系统：
   □ Linux (桌面/服务器)
   □ Linux (嵌入式，如 Buildroot/Yocto)
   □ Windows
   □ macOS
   □ RTOS (FreeRTOS/RT-Thread/Zephyr/其他)
   □ 无操作系统 (裸机)

2. CPU 架构：
   □ x86_64
   □ ARM Cortex-M (M0/M3/M4/M7)
   □ ARM Cortex-A (A7/A8/A9/A53/A72)
   □ RISC-V
   □ 其他: _______

3. 内存限制：
   □ RAM: _______ MB/KB
   □ Flash/ROM: _______ MB/KB
   □ 是否有 MMU: □ 有 □ 无

4. 性能要求：
   □ 实时性要求: □ 硬实时 □ 软实时 □ 无实时要求
   □ 最大延迟容忍: _______ ms
   □ CPU 主频: _______ MHz，核心数: _______

5. 编译工具链（已有）：
   □ GCC
   □ Clang
   □ IAR
   □ Keil MDK
   □ 其他: _______

6. 许可证要求：
   □ 无限制 (MIT/BSD)
   □ 需要 LGPL (允许动态链接)
   □ 需要纯商业许可
   □ 其他: _______
```

### 第 1 步: 确定选型主题与候选方案

#### 1.1 明确选型主题

与用户确认需要对比的技术领域：

| 选型领域 | 示例 |
|----------|------|
| **网络通信** | HTTP 库 (QHttpServer/libcurl/asio)、MQTT 客户端、WebSocket |
| **数据序列化** | JSON (Qt JSON/nlohmann/json/rapidjson)、Protocol Buffers、MessagePack |
| **数据库** | SQLite/MySQL/PostgreSQL、ORM 框架 |
| **日志** | spdlog/Qt Logging/log4cpp |
| **异步编程** | Qt Signals/Slots、std::async、asio、线程池方案 |
| **GUI 框架** | Qt Widgets/Qt Quick/QML、自定义渲染方案 |
| **RTOS** | FreeRTOS/RT-Thread/Zephyr |
| **构建系统** | qmake/CMake/SCon |
| **单元测试** | Google Test/Qt Test/Catch2 |
| **内存管理** | 内存池、对象池、allocator 选择 |
| **加密库** | OpenSSL/mbedTLS/libsodium |
| **压缩库** | zlib/lz4/zstd |

#### 1.2 搜索候选方案（网络搜索）

使用 `web_search` 工具搜索候选技术方案：

```
搜索策略：
1. "[技术领域] C++ 库对比 2024/2025"
2. "[技术领域] C++ 嵌入式 性能 benchmark"
3. "[具体库名] vs [竞品] performance comparison"
4. "[具体库名] memory footprint embedded"
5. "[具体库名] Qt integration"

示例搜索：
- "Qt HTTP server library comparison benchmark"
- "C++ JSON library benchmark embedded systems"
- "SQLite vs MySQL embedded footprint comparison"
```

**搜索结果处理**：
1. 记录每个候选方案的：名称、版本、许可证、Star 数、最近更新时间
2. 提取关键信息：性能数据、内存占用、平台支持情况
3. 筛选出 2-4 个最有竞争力的候选方案进行深入对比

### 第 2 步: 搭建测试环境

#### 2.1 生成环境搭建脚本

为每个候选方案生成 `setup_*.sh` 脚本：

** Conan 包管理脚本示例**：
```bash
#!/bin/bash
# setup_conan_dependencies.sh - Conan 包管理环境搭建

set -e

# 安装 Conan (如果未安装)
if ! command -v conan &> /dev/null; then
    pip install conan
    conan profile detect --force
fi

# 创建构建目录
mkdir -p build && cd build

# 配置 Qt 网络库候选方案
conan install .. \
    -s os=Linux \
    -s arch=x86_64 \
    -s compiler=gcc \
    -s compiler.version=11 \
    -s compiler.libcxx=libstdc++11 \
    -o qtf_http:with_ssl=true \
    -o libcurl:with_ssl=openssl

# 备选方案：nlohmann/json
# conan install .. -o nlohmann_json/version=3.10.5

# 备选方案：rapidjson
# conan install .. -o rapidjson/version=1.1.0
```

** CMake + vcpkg 脚本示例**：
```bash
#!/bin/bash
# setup_vcpkg_dependencies.sh - vcpkg 环境搭建

set -e

# 安装 vcpkg (如果未安装)
if [ ! -d "../vcpkg" ]; then
    git clone https://github.com/Microsoft/vcpkg.git
    ./vcpkg/bootstrap-vcpkg.sh
fi

export VCPKG_ROOT=../vcpkg

# 安装候选库
vcpkg install \
    qtf-http \
    nlohmann-json \
    rapidjson \
    --triplet x64-linux-release

# 备选：静态链接以测试 footprint
# vcpkg install qtf-http --triplet x64-linux-static
```

#### 2.2 生成 benchmark 测试代码

**基准测试代码结构**：
```
benchmark/
├── CMakeLists.txt
├── common/
│   ├── Stopwatch.h          # 高精度计时器
│   ├── MemoryTracker.h      # 内存追踪
│   └── TestFixture.h        # 测试夹具
├── suites/
│   ├── json_serialization/  # JSON 序列化测试
│   ├── http_client/         # HTTP 客户端测试
│   ├── database/             # 数据库操作测试
│   └── threading/            # 线程/并发测试
└── main.cpp
```

**Stopwatch.h 示例**：
```cpp
// 高精度计时器，用于 benchmark
#ifndef STOPWATCH_H
#define STOPWATCH_H

#include <chrono>
#include <cstdint>

class Stopwatch {
public:
    using Clock = std::chrono::high_resolution_clock;
    using TimePoint = Clock::time_point;
    using Duration = std::chrono::duration<double, std::micro>;

    void start() { start_ = Clock::now(); }
    void stop() { end_ = Clock::now(); }

    double elapsedMicros() const {
        return std::chrono::duration_cast<Duration>(end_ - start_).count();
    }

    double elapsedMillis() const {
        return elapsedMicros() / 1000.0;
    }

    static TimePoint now() { return Clock::now(); }

private:
    TimePoint start_;
    TimePoint end_;
};

// RAII 风格的自动计时器
class ScopedTimer {
public:
    explicit ScopedTimer(const char* name, double* result)
        : name_(name), result_(result), sw_() {
        sw_.start();
    }

    ~ScopedTimer() {
        sw_.stop();
        *result_ = sw_.elapsedMicros();
    }

private:
    const char* name_;
    double* result_;
    Stopwatch sw_;
};

#endif // STOPWATCH_H
```

**MemoryTracker.h 示例**：
```cpp
// 内存占用追踪器
#ifndef MEMORY_TRACKER_H
#define MEMORY_TRACKER_H

#include <cstdint>
#include <cstdlib>
#include <cstring>

#if defined(__linux__) || defined(__APPLE__)
#include <sys/resource.h>
#endif

class MemoryTracker {
public:
    struct MemoryUsage {
        uint64_t rss;       // Resident Set Size (KB)
        uint64_t vsz;       // Virtual Memory Size (KB)
        uint64_t heapUsed;  // 堆已分配 (如果跟踪)
        uint64_t peakRss;   // 峰值 RSS
    };

    static MemoryUsage current() {
        MemoryUsage usage = {0, 0, 0, 0};

#if defined(__linux__)
        FILE* fp = fopen("/proc/self/status", "r");
        if (fp) {
            char line[256];
            while (fgets(line, sizeof(line), fp)) {
                if (strncmp(line, "VmRSS:", 6) == 0) {
                    sscanf(line + 6, "%lu", &usage.rss);
                } else if (strncmp(line, "VmSize:", 7) == 0) {
                    sscanf(line + 7, "%lu", &usage.vsz);
                } else if (strncmp(line, "VmPeak:", 7) == 0) {
                    sscanf(line + 7, "%lu", &usage.peakRss);
                }
            }
            fclose(fp);
        }
#elif defined(__APPLE__)
        struct rusage ru;
        getrusage(RUSAGE_SELF, &ru);
        usage.rss = ru.ru_maxrss / 1024;  // macOS 返回的是 bytes
#endif

        return usage;
    }

    static void printDelta(const MemoryUsage& before, const MemoryUsage& after) {
        printf("Memory Delta:\n");
        printf("  RSS:   %+ld KB (%+.2f MB)\n",
               (long)(after.rss - before.rss),
               (after.rss - before.rss) / 1024.0);
        printf("  Peak:  %lu KB\n", after.peakRss);
    }
};

#endif // MEMORY_TRACKER_H
```

#### 2.3 生成 Footprint 测试代码

**静态分析脚本**：
```bash
#!/bin/bash
# analyze_footprint.sh - 分析库的静态 footprint

set -e

LIB_NAME=$1
BUILD_DIR=${2:-build}

echo "============================================"
echo "Footprint Analysis: $LIB_NAME"
echo "============================================"

# 1. 库文件大小
echo -e "\n[1] Library File Size:"
if [ -f "$BUILD_DIR/lib${LIB_NAME}.a" ]; then
    ls -lh "$BUILD_DIR/lib${LIB_NAME}.a"
    size "$BUILD_DIR/lib${LIB_NAME}.a" 2>/dev/null || true
fi

# 2. 符号分析
echo -e "\n[2] Symbol Analysis:"
if [ -f "$BUILD_DIR/lib${LIB_NAME}.a" ]; then
    echo "Total symbols: $(nm -C "$BUILD_DIR/lib${LIB_NAME}.a" 2>/dev/null | wc -l)"
    echo "Functions: $(nm -C "$BUILD_DIR/lib${LIB_NAME}.a" 2>/dev/null | grep ' T ' | wc -l)"
    echo "Data: $(nm -C "$BUILD_DIR/lib${LIB_NAME}.a" 2>/dev/null | grep ' D ' | wc -l)"
fi

# 3. 链接后的可执行文件大小
echo -e "\n[3] Linked Executable Size:"
if [ -f "$BUILD_DIR/benchmark_${LIB_NAME}" ]; then
    ls -lh "$BUILD_DIR/benchmark_${LIB_NAME}"
    size "$BUILD_DIR/benchmark_${LIB_NAME}" 2>/dev/null || true
fi

# 4. 代码段大小（strip 后）
echo -e "\n[4] Stripped Binary Size:"
if [ -f "$BUILD_DIR/benchmark_${LIB_NAME}" ]; then
    strip "$BUILD_DIR/benchmark_${LIB_NAME}" -o "$BUILD_DIR/benchmark_${LIB_NAME}_stripped"
    ls -lh "$BUILD_DIR/benchmark_${LIB_NAME}_stripped"
fi
```

**运行时 Footprint 测试**：
```cpp
// footprint_test.cpp - 运行时内存占用测试
#include "MemoryTracker.h"
#include <iostream>
#include <vector>
#include <string>

// 测试不同数据规模的内存占用
void testJsonFootprint(const std::string& jsonLib) {
    std::cout << "\n=== JSON Library Footprint Test ===" << std::endl;

    auto before = MemoryTracker::current();

    // 模拟不同数据规模
    std::vector<size_t> testSizes = {100, 1000, 10000, 100000};

    for (size_t size : testSizes) {
        auto memBefore = MemoryTracker::current();

        // 创建测试 JSON
        // ... (调用各库的 API)

        auto memAfter = MemoryTracker::current();

        std::cout << "Data size: " << size << " items" << std::endl;
        std::cout << "  Memory delta: " << (memAfter.rss - memBefore.rss) << " KB" << std::endl;
    }

    auto after = MemoryTracker::current();
    MemoryTracker::printDelta(before, after);
}
```

### 第 3 步: 执行测试并收集数据

#### 3.1 Benchmark 测试执行

```bash
#!/bin/bash
# run_benchmarks.sh - 执行所有 benchmark 测试

set -e

BUILD_DIR=build/release
RESULTS_DIR=results/$(date +%Y%m%d_%H%M%S)

mkdir -p "$RESULTS_DIR"

# 编译所有候选方案
for lib in qtf_http libcurl asio; do
    echo "Building $lib..."
    mkdir -p "$BUILD_DIR/$lib"
    cd "$BUILD_DIR/$lib"
    cmake ../../benchmark -DLIB=$lib
    make -j$(nproc)
done

# 运行测试
cd "$BUILD_DIR"
for lib in qtf_http libcurl asio; do
    echo "Running benchmark for $lib..."
    ./benchmark_${lib} --output-json > "$RESULTS_DIR/${lib}_results.json"
done

# 生成汇总报告
python3 ../../scripts/summarize_results.py "$RESULTS_DIR"
```

#### 3.2 测试项目清单

| 测试类别 | 测试项 | 指标 |
|----------|--------|------|
| **性能测试** | 序列化/反序列化速度 | 操作耗时 (μs) |
| **性能测试** | HTTP 请求响应时间 | 延迟 (ms) |
| **性能测试** | 并发吞吐量 | QPS / 带宽 |
| **性能测试** | 启动时间 | 冷启动耗时 (ms) |
| **Footprint 测试** | 静态库大小 | .a 文件大小 (KB) |
| **Footprint 测试** | 链接后二进制大小 | 可执行文件大小 (KB) |
| **Footprint 测试** | 运行时内存峰值 | RSS (KB) |
| **Footprint 测试** | 栈使用量 | 栈深度 (bytes) |
| **可用性测试** | API 友好度 | 主观评分 (1-5) |
| **可用性测试** | 文档完整度 | 文档页数、示例数量 |
| **可用性测试** | 编译难度 | 头文件依赖数量 |
| **兼容性测试** | 平台支持 | 支持的平台数量 |
| **兼容性测试** | 编译器支持 | GCC/Clang/MSVC 版本 |
| **活跃度** | GitHub Star | 最近更新时间 |

### 第 4 步: 生成对比报告

#### 4.1 报告结构

```
技术选型对比报告
├── 1. 概述
│   ├── 选型目标
│   ├── 候选方案一览
│   └── 测试环境
├── 2. 性能对比
│   ├── 表格汇总
│   └── 图表分析
├── 3. Footprint 对比
│   ├── 静态大小对比
│   └── 运行时内存对比
├── 4. 其他维度对比
│   ├── API 易用性
│   ├── 文档质量
│   └── 许可证
├── 5. 综合评分
│   └── 加权得分表
├── 6. 结论与建议
│   ├── 推荐方案
│   └── 风险提示
└── 附录
    ├── A. 测试代码
    ├── B. 原始数据
    └── C. 图表生成代码
```

#### 4.2 对比报告模板

```markdown
# [技术领域] 选型对比报告

**项目**: [项目名称]
**选型目标**: [要解决的问题]
**日期**: YYYY-MM-DD
**技术栈**: C++11 / Qt

---

## 1. 概述

### 1.1 候选方案

| 方案 | 版本 | 许可证 | GitHub |
|------|------|--------|--------|
| 方案 A | x.y.z | MIT | star数 |
| 方案 B | x.y.z | LGPL | star数 |
| 方案 C | x.y.z | Apache 2.0 | star数 |

### 1.2 测试环境

| 项目 | 配置 |
|------|------|
| 操作系统 | Ubuntu 22.04 LTS |
| CPU | Intel Core i7-10700 @ 2.9GHz |
| 内存 | 32 GB DDR4 |
| 编译器 | GCC 11.4.0 / Clang 15.0.0 |
| CMake | 3.25.0 |
| Qt 版本 | 6.5.0 |

---

## 2. 性能对比

### 2.1 综合性能得分

| 测试项 | 方案 A | 方案 B | 方案 C | 单位 |
|--------|--------|--------|--------|------|
| JSON 序列化 (小) | 120 | 85 | 95 | μs |
| JSON 反序列化 (小) | 110 | 78 | 88 | μs |
| JSON 序列化 (大) | 1200 | 850 | 980 | μs |
| JSON 反序列化 (大) | 1150 | 820 | 950 | μs |
| 内存分配次数 | 150 | 45 | 80 | 次/操作 |

**评分规则**: 数值越低越好。最佳 = 100 分。

| 测试项 | 方案 A | 方案 B | 方案 C |
|--------|--------|--------|--------|
| 综合得分 | 72 | **95** | 85 |

### 2.2 性能雷达图

雷达图由 Python 代码生成（参见[附录 C](#附录-c-图表生成代码)）。

**数据格式**（JSON）：
```json
{
  "categories": ["序列化速度", "反序列化速度", "内存效率", "并发性能", "启动时间"],
  "series": [
    {"name": "方案 A", "values": [72, 68, 75, 70, 80]},
    {"name": "方案 B", "values": [95, 92, 88, 90, 85]},
    {"name": "方案 C", "values": [85, 82, 70, 78, 75]}
  ]
}
```

---

## 3. Footprint 对比

### 3.1 静态库大小

| 方案 | 库文件 (.a) | 纯代码段 (.text) | 初始化数据 (.data) | 总计 |
|------|-------------|------------------|---------------------|------|
| 方案 A | 850 KB | 420 KB | 35 KB | **495 KB** |
| 方案 B | 1.2 MB | 680 KB | 52 KB | 732 KB |
| 方案 C | 620 KB | 310 KB | 28 KB | **338 KB** |

### 3.2 运行时内存峰值

| 方案 | 空载 RSS | 10K 数据 RSS | 100K 数据 RSS | 峰值 |
|------|----------|--------------|---------------|------|
| 方案 A | 1.2 MB | 3.5 MB | 18.2 MB | 19.8 MB |
| 方案 B | 0.8 MB | 2.1 MB | 12.5 MB | **13.2 MB** |
| 方案 C | 1.5 MB | 4.2 MB | 22.0 MB | 24.5 MB |

---

## 4. 其他维度对比

### 4.1 定性评分 (1-5 分)

| 维度 | 方案 A | 方案 B | 方案 C |
|------|--------|--------|--------|
| API 易用性 | 4 | **5** | 3 |
| 文档完整度 | 4 | **5** | 4 |
| Qt 集成度 | **5** | 3 | 2 |
| 编译难度 | 4 | 3 | **5** |
| 社区活跃度 | 4 | **5** | 4 |
| 长期维护性 | 4 | **5** | 4 |
| **平均分** | 4.17 | **4.33** | 3.67 |

### 4.2 许可证信息（仅供参考，不计入评分）

| 方案 | 许可证 | 说明 |
|------|--------|------|
| 方案 A | MIT | 允许商业使用、静态链接 |
| 方案 B | LGPL 2.1 | 动态链接可商用，静态链接需开源 |
| 方案 C | Apache 2.0 | 允许商业使用，需保留版权声明 |

---

## 5. 综合评分

### 5.1 权重配置

| 维度 | 权重 | 说明 |
|------|------|------|
| 性能 | 35% | benchmark 实测数据 |
| Footprint | 30% | 库大小 + 运行时内存 |
| 易用性 | 20% | API 设计、文档质量 |
| Qt 集成 | 15% | 与现有 Qt 代码的兼容性 |

### 5.2 加权得分

| 方案 | 性能 (×0.35) | Footprint (×0.30) | 易用性 (×0.20) | Qt集成 (×0.15) | **总分** |
|------|--------------|-------------------|----------------|----------------|----------|
| 方案 A | 25.2 | 22.5 | 8.3 | 7.5 | **63.5** |
| 方案 B | **33.3** | **25.5** | **8.7** | 4.5 | **72.0** |
| 方案 C | 29.8 | 18.0 | 7.3 | 3.0 | 58.1 |

### 5.3 综合得分图表

图表由 Python 代码生成（参见[附录 C](#附录-c-图表生成代码)）。

**数据格式**（JSON）：
```json
{
  "title": "技术选型综合得分对比",
  "categories": ["方案 A", "方案 B", "方案 C"],
  "scores": [63.5, 72.0, 58.1],
  "best": "方案 B"
}
```

---

## 6. 结论与建议

### 6.1 推荐方案

🥇 **方案 B** - 综合得分最高 (72.0 分)

**优势**:
- 性能最佳，特别是在大数据量场景
- 运行时内存占用最低
- 文档完善，API 设计优雅
- 社区活跃，长期维护有保障

**劣势**:
- Qt 集成度不如方案 A

### 6.2 备选方案

🥈 **方案 A** - 如项目需要更好的 Qt 集成度

### 6.3 风险提示

| 风险 | 等级 | 应对措施 |
|------|------|----------|
| 方案 B 作者停止维护 | ⚠️ 低 | 定期关注项目活跃度，选择活跃的 fork 作为备选 |
```

---

## 快速导航

| 需要… | 跳转到 |
|-------|--------|
| 收集平台信息 | [第 0 步](#第-0-步-收集目标平台信息交互式提问) |
| 搜索候选方案 | [第 1 步](#第-1-步-确定选型主题与候选方案) |
| 搭建测试环境 | [第 2 步](#第-2-步-搭建测试环境) |
| 执行 benchmark | [第 3 步](#第-3-步-执行测试并收集数据) |
| 生成对比报告 | [第 4 步](#第-4-步-生成对比报告) |
| Benchmark 指南 | [references/benchmarking-guide.md](references/benchmarking-guide.md) |
| 报告模板 | [references/report-templates.md](references/report-templates.md) |

---

## 核心原则 (6 条铁律)

```
1. 先明确约束条件（内存/性能/平台），再搜索候选方案
2. 用数据说话——所有结论必须有 benchmark 结果支撑
3. Footprint 测试要覆盖空载、典型负载、最大负载
4. 候选方案控制在 2-4 个，深入对比优于广泛浅测
5. 报告要包含原始数据，结论要说明适用场景
6. 选型不是一次性决策——记录假设条件，方便后续复盘
```

---

## 反模式

| # | 不要 | 要做 |
|---|------|------|
| 1 | 凭直觉选型 | 基于 benchmark 数据决策 |
| 2 | 只测性能 | 同时测 Footprint |
| 3 | 只看官方数据 | 自行验证，独立测试 |
| 4 | 选择最新的 | 选择最稳定的、长期维护的 |
| 5 | 忽略约束条件 | 明确评估平台/资源限制 |
| 6 | 一人决策 | 团队评审 |

---

## 参考文档

| 需要… | 参考 |
|-------|------|
| Benchmark 编写指南 | [references/benchmarking-guide.md](references/benchmarking-guide.md) |
| 报告模板 | [references/report-templates.md](references/report-templates.md) |
| 图表生成器 | [scripts/chart_generator.py](scripts/chart_generator.py) |

---

## 附录: 图表生成

技术选型报告中的图表由 Python + matplotlib 生成。

### 依赖安装

```bash
pip install matplotlib numpy
```

### 图表生成器使用

图表生成器位于 `scripts/chart_generator.py`。

**使用方式**:

```bash
# 生成雷达图
python scripts/chart_generator.py --radar performance_data.json

# 生成综合得分柱状图
python scripts/chart_generator.py --bar scores_data.json

# 生成分组柱状图
python scripts/chart_generator.py --grouped multi_dim_data.json

# 生成 Footprint 对比图
python scripts/chart_generator.py --footprint memory_data.json
```

**数据格式示例** (`scores_data.json`):
```json
{
  "title": "技术选型综合得分对比",
  "categories": ["方案 A", "方案 B", "方案 C"],
  "scores": [63.5, 72.0, 58.1],
  "best": "方案 B"
}
```

**雷达图数据格式**:
```json
{
  "title": "性能雷达图",
  "categories": ["序列化速度", "反序列化速度", "HTTP响应", "内存效率"],
  "series": [
    {"name": "方案 A", "values": [72, 70, 75, 68]},
    {"name": "方案 B", "values": [95, 92, 88, 98]},
    {"name": "方案 C", "values": [85, 82, 78, 65]}
  ]
}
```

**在 Markdown 中嵌入图表**:
```markdown
![性能雷达图](charts/radar_chart.png)
![综合得分](charts/bar_chart.png)
```
