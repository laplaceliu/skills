# Benchmark 编写指南

> 本指南面向 C++/Qt 技术栈，提供性能测试和 Footprint 测试的最佳实践。

---

## 1. Benchmark 原则

### 1.1 黄金法则

```
1. 可重复性：相同测试多次运行，结果应在误差范围内一致
2. 公平性：所有候选方案使用相同的测试数据、相同的测试环境
3. 隔离性：避免被其他进程干扰，关闭不必要的后台服务
4. 预热：在正式计时前进行预热，避免冷启动影响
5. 多次采样：每个测试运行多次，取中位数而非平均值
```

### 1.2 测试分类

| 类型 | 目的 | 关注指标 |
|------|------|----------|
| **性能测试** | 测量执行速度 | 耗时 (μs/ms/s)、吞吐量 (ops/s) |
| **内存测试** | 测量资源占用 | RSS、堆分配次数、峰值内存 |
| **启动测试** | 测量初始化开销 | 冷启动时间、热启动时间 |
| **并发测试** | 测量多线程表现 | 线程数、锁竞争、吞吐量扩展性 |

---

## 2. 高精度计时器实现

### 2.1 C++11 跨平台计时器

```cpp
// PrecisionTimer.hpp
#ifndef PRECISION_TIMER_HPP
#define PRECISION_TIMER_HPP

#include <chrono>
#include <type_traits>

class PrecisionTimer {
public:
    using Clock = std::chrono::high_resolution_clock;
    using TimePoint = Clock::time_point;
    using Duration = std::chrono::duration<double, std::micro>;

    PrecisionTimer() : start_(), end_(), elapsed_(0.0) {}

    void start() { start_ = Clock::now(); }
    void stop() {
        end_ = Clock::now();
        elapsed_ = std::chrono::duration_cast<Duration>(end_ - start_).count();
    }
    void reset() { elapsed_ = 0.0; }

    double elapsedMicros() const { return elapsed_; }
    double elapsedMillis() const { return elapsed_ / 1000.0; }
    double elapsedSeconds() const { return elapsed_ / 1000000.0; }

    // RAII 自动计时
    class AutoTimer {
    public:
        AutoTimer(double& result) : result_(result), timer_() {
            timer_.start();
        }
        ~AutoTimer() {
            timer_.stop();
            result_ = timer_.elapsedMicros();
        }
    private:
        double& result_;
        PrecisionTimer timer_;
    };

private:
    TimePoint start_;
    TimePoint end_;
    double elapsed_;
};

#endif // PRECISION_TIMER_HPP
```

### 2.2 Qt 专用计时器

```cpp
// QtTimer.hpp
#ifndef QT_TIMER_HPP
#define QT_TIMER_HPP

#include <QElapsedTimer>
#include <QDebug>

class QtTimer {
public:
    QtTimer() : timer_() {}

    void start() { timer_.start(); }
    qint64 elapsedNanos() const { return timer_.nsecsElapsed(); }
    double elapsedMicros() const { return timer_.nsecsElapsed() / 1000.0; }
    double elapsedMillis() const { return timer_.elapsed(); }

    template<typename Func>
    static double measure(Func&& func) {
        QElapsedTimer t;
        t.start();
        func();
        return t.nsecsElapsed() / 1000.0;  // 返回微秒
    }

private:
    QElapsedTimer timer_;
};

#endif // QT_TIMER_HPP
```

---

## 3. 内存追踪实现

### 3.1 跨平台内存追踪

```cpp
// MemoryTracker.hpp
#ifndef MEMORY_TRACKER_HPP
#define MEMORY_TRACKER_HPP

#include <cstdint>
#include <iostream>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <string>

#if defined(_WIN32) || defined(_WIN64)
#include <windows.h>
#include <psapi.h>
#pragma comment(lib, "psapi.lib")
#elif defined(__linux__)
#include <fstream>
#include <unistd.h>
#include <sys/resource.h>
#elif defined(__APPLE__)
#include <mach/mach.h>
#include <sys/resource.h>
#endif

class MemoryTracker {
public:
    struct MemorySnapshot {
        uint64_t rss;      // Resident Set Size (KB)
        uint64_t vsz;      // Virtual Memory Size (KB)
        uint64_t heapUsed; // 堆使用量 (KB)
        uint64_t peakRss;  // 峰值 RSS (KB)
    };

    static MemorySnapshot current() {
        MemorySnapshot snap = {};

#if defined(_WIN32) || defined(_WIN64)
        PROCESS_MEMORY_COUNTERS pmc;
        if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
            snap.rss = pmc.WorkingSetSize / 1024;
            snap.vsz = pmc.PagefileUsage / 1024;
            snap.peakRss = pmc.PeakWorkingSetSize / 1024;
        }
#elif defined(__linux__)
        std::ifstream statm("/proc/self/statm");
        if (statm) {
            size_t size, resident;
            statm >> size >> resident;
            snap.rss = resident * (sysconf(_SC_PAGESIZE) / 1024);
            snap.vsz = size * (sysconf(_SC_PAGESIZE) / 1024);
        }

        // 获取峰值
        std::ifstream status("/proc/self/status");
        std::string line;
        while (std::getline(status, line)) {
            if (line.compare(0, 7, "VmPeak:") == 0) {
                std::stringstream ss(line.substr(7));
                ss >> snap.peakRss;
            }
        }
#elif defined(__APPLE__)
        struct rusage usage;
        getrusage(RUSAGE_SELF, &usage);
        snap.rss = usage.ru_maxrss / 1024;  // macOS bytes -> KB
#endif
        return snap;
    }

    static void print(const MemorySnapshot& snap, std::ostream& os = std::cout) {
        os << "RSS:   " << std::setw(10) << snap.rss << " KB ("
           << std::fixed << std::setprecision(2) << snap.rss / 1024.0 << " MB)\n"
           << "VSZ:   " << std::setw(10) << snap.vsz << " KB ("
           << snap.vsz / 1024.0 << " MB)\n"
           << "Peak:  " << std::setw(10) << snap.peakRss << " KB\n";
    }

    static int64_t deltaRss(const MemorySnapshot& before, const MemorySnapshot& after) {
        return static_cast<int64_t>(after.rss) - static_cast<int64_t>(before.rss);
    }

private:
    MemoryTracker() = default;
};

#endif // MEMORY_TRACKER_HPP
```

---

## 4. JSON Benchmark 示例

### 4.1 测试代码结构

```cpp
// json_benchmark.cpp
#include "PrecisionTimer.hpp"
#include "MemoryTracker.hpp"
#include <iostream>
#include <iomanip>
#include <vector>
#include <string>
#include <cstdlib>

// ============================================================================
// 测试数据生成
// ============================================================================

std::string generateTestJson(int itemCount) {
    std::string json = "{\"items\":[";
    for (int i = 0; i < itemCount; ++i) {
        if (i > 0) json += ",";
        json += "{\"id\":" + std::to_string(i) +
                ",\"name\":\"item_" + std::to_string(i) +
                "\",\"value\":" + std::to_string(i * 100) + "}";
    }
    json += "]}";
    return json;
}

// ============================================================================
// Qt JSON Benchmark
// ============================================================================

namespace QtJsonBenchmark {
    double serialize(const std::string& data) {
        PrecisionTimer timer;
        timer.start();

        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(QByteArray::fromStdString(data));

        timer.stop();
        return timer.elapsedMicros();
    }

    double deserialize(const QJsonDocument& doc) {
        PrecisionTimer timer;
        timer.start();

        QJsonObject obj = doc.object();
        // 模拟使用
        volatile int sum = 0;
        for (auto it = obj["items"].toArray().constBegin();
             it != obj["items"].toArray().constEnd(); ++it) {
            sum += (*it).toObject()["value"].toInt();
        }

        timer.stop();
        return timer.elapsedMicros();
    }
}

// ============================================================================
// nlohmann/json Benchmark
// ============================================================================

namespace NlohmannJsonBenchmark {
    double serialize(const std::string& data) {
        PrecisionTimer timer;
        timer.start();

        auto j = nlohmann::json::parse(data);
        std::string result = j.dump();

        timer.stop();
        return timer.elapsedMicros();
    }

    double deserialize(const std::string& data) {
        PrecisionTimer timer;
        timer.start();

        auto j = nlohmann::json::parse(data);
        // 模拟使用
        volatile long long sum = 0;
        for (const auto& item : j["items"]) {
            sum += item["value"].get<int>();
        }

        timer.stop();
        return timer.elapsedMicros();
    }
}

// ============================================================================
// 主测试程序
// ============================================================================

struct BenchmarkResult {
    std::string name;
    std::vector<double> serializeTimes;
    std::vector<double> deserializeTimes;
};

void runTest(BenchmarkResult& result, const std::string& libName,
             int warmupRuns, int benchmarkRuns,
             const std::vector<size_t>& testSizes) {

    std::cout << "\n========================================\n";
    std::cout << "Testing: " << libName << "\n";
    std::cout << "========================================\n";

    for (size_t size : testSizes) {
        std::cout << "\nTest size: " << size << " items\n";

        auto jsonData = generateTestJson(size);

        // 预热
        for (int i = 0; i < warmupRuns; ++i) {
            volatile auto x = jsonData.size();
            (void)x;
        }

        // 正式测试
        double serSum = 0, deserSum = 0;
        for (int i = 0; i < benchmarkRuns; ++i) {
            double serTime, deserTime;

            if (libName == "Qt JSON") {
                serTime = QtJsonBenchmark::serialize(jsonData);
                QJsonDocument doc = QJsonDocument::fromJson(
                    QByteArray::fromStdString(jsonData));
                deserTime = QtJsonBenchmark::deserialize(doc);
            } else if (libName == "nlohmann/json") {
                serTime = NlohmannJsonBenchmark::serialize(jsonData);
                auto j = nlohmann::json::parse(jsonData);
                deserTime = NlohmannJsonBenchmark::deserialize(jsonData);
            }

            serSum += serTime;
            deserSum += deserTime;

            std::cout << "  Run " << (i + 1) << ": serialize="
                      << std::fixed << std::setprecision(2) << serTime << " μs, "
                      << "deserialize=" << deserTime << " μs\n";
        }

        double serAvg = serSum / benchmarkRuns;
        double deserAvg = deserSum / benchmarkRuns;
        std::cout << "  >>> Average: serialize=" << serAvg << " μs, "
                  << "deserialize=" << deserAvg << " μs\n";

        result.serializeTimes.push_back(serAvg);
        result.deserializeTimes.push_back(deserAvg);
    }
}

int main(int argc, char* argv[]) {
    int warmupRuns = 3;
    int benchmarkRuns = 10;
    std::vector<size_t> testSizes = {10, 100, 1000, 10000};

    // 解析命令行参数
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--warmup" && i + 1 < argc) {
            warmupRuns = std::atoi(argv[++i]);
        } else if (arg == "--runs" && i + 1 < argc) {
            benchmarkRuns = std::atoi(argv[++i]);
        }
    }

    std::cout << "========================================\n";
    std::cout << "JSON Library Benchmark\n";
    std::cout << "========================================\n";
    std::cout << "Warmup runs: " << warmupRuns << "\n";
    std::cout << "Benchmark runs: " << benchmarkRuns << "\n";

    BenchmarkResult qtResult{"Qt JSON", {}, {}};
    BenchmarkResult nlohmannResult{"nlohmann/json", {}, {}};

    runTest(qtResult, "Qt JSON", warmupRuns, benchmarkRuns, testSizes);
    runTest(nlohmannResult, "nlohmann/json", warmupRuns, benchmarkRuns, testSizes);

    // 输出汇总表格
    std::cout << "\n\n========================================\n";
    std::cout << "SUMMARY\n";
    std::cout << "========================================\n";
    std::cout << std::setw(12) << "Size"
              << std::setw(18) << "Qt JSON (ser)"
              << std::setw(18) << "nlohmann (ser)"
              << std::setw(18) << "Qt JSON (deser)"
              << std::setw(18) << "nlohmann (deser)"
              << "\n";

    for (size_t i = 0; i < testSizes.size(); ++i) {
        std::cout << std::setw(12) << testSizes[i]
                  << std::setw(18) << std::fixed << std::setprecision(2)
                  << qtResult.serializeTimes[i]
                  << std::setw(18) << nlohmannResult.serializeTimes[i]
                  << std::setw(18) << qtResult.deserializeTimes[i]
                  << std::setw(18) << nlohmannResult.deserializeTimes[i]
                  << "\n";
    }

    // JSON 输出 (便于程序解析)
    std::cout << "\n\n---\n";
    std::cout << "JSON_OUTPUT:\n";
    std::cout << "{\"results\":[";
    for (size_t i = 0; i < testSizes.size(); ++i) {
        if (i > 0) std::cout << ",";
        std::cout << "{\"size\":" << testSizes[i]
                  << ",\"qt_ser\":" << qtResult.serializeTimes[i]
                  << ",\"qt_deser\":" << qtResult.deserializeTimes[i]
                  << ",\"nlohmann_ser\":" << nlohmannResult.serializeTimes[i]
                  << ",\"nlohmann_deser\":" << nlohmannResult.deserializeTimes[i]
                  << "}";
    }
    std::cout << "]}\n";

    return 0;
}
```

### 4.2 CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.16)
project(json_benchmark CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Qt5
find_package(Qt5 COMPONENTS Core REQUIRED)

# nlohmann/json (通过 vcpkg 或 Conan)
find_path(NLOHMANN_JSON_INCLUDE_DIRS "nlohmann/json.hpp")
include_directories(${NLOHMANN_JSON_INCLUDE_DIRS})

# 源文件
set(SOURCES
    json_benchmark.cpp
)

# Qt JSON 版本
add_executable(benchmark_qt_json ${SOURCES})
target_link_libraries(benchmark_qt_json Qt5::Core)
target_compile_definitions(benchmark_qt_json USE_QT_JSON)

# nlohmann 版本
add_executable(benchmark_nlohmann ${SOURCES})
target_include_directories(benchmark_nlohmann PRIVATE ${NLOHMANN_JSON_INCLUDE_DIRS})
target_compile_definitions(benchmark_nlohmann USE_NLOHMANN_JSON)

# 测试运行脚本
add_custom_target(run_benchmarks
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/run_benchmarks.sh
    DEPENDS benchmark_qt_json benchmark_nlohmann
)
```

---

## 5. HTTP Benchmark 示例

### 5.1 Qt HTTP 服务器测试

```cpp
// http_benchmark.cpp
#include <QCoreApplication>
#include <QHttpServer>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QElapsedTimer>
#include <iostream>

class HttpBenchmark {
public:
    struct Config {
        QString host = "localhost";
        quint16 port = 8080;
        int requestCount = 1000;
        int concurrency = 10;
    };

    HttpBenchmark(const Config& cfg) : config_(cfg), manager_(nullptr) {}

    void startServer(QHttpServer* server) {
        server->route("/json", [](const QHttpServerRequest& request) {
            Q_UNUSED(request);
            QJsonObject obj;
            obj["status"] = "ok";
            obj["timestamp"] = QDateTime::currentMSecsSinceEpoch();
            obj["data"] = QJsonArray{
                QJsonObject{{"id", 1}, {"name", "item1"}},
                QJsonObject{{"id", 2}, {"name", "item2"}}
            };
            return QHttpServerResponse(obj);
        });

        server->route("/echo", [](const QHttpServerRequest& request) {
            return QHttpServerResponse(request.body());
        });
    }

    double benchmarkGet(const QString& path) {
        QElapsedTimer timer;
        timer.start();

        for (int i = 0; i < config_.requestCount; ++i) {
            QNetworkRequest request(QUrl(QString("http://%1:%2%3")
                .arg(config_.host).arg(config_.port).arg(path)));
            QNetworkReply* reply = manager_->get(request);

            // 同步等待完成
            QEventLoop loop;
            QObject::connect(reply, &QNetworkReply::finished, &loop, &QThread::quit);
            loop.exec();

            reply->deleteLater();
        }

        return timer.elapsed();  // ms
    }

    void setNetworkManager(QNetworkAccessManager* mgr) { manager_ = mgr; }

private:
    Config config_;
    QNetworkAccessManager* manager_;
};
```

### 5.2 libcurl Benchmark

```cpp
// http_benchmark_curl.cpp
#include <curl/curl.h>
#include <chrono>
#include <iostream>
#include <vector>
#include <thread>
#include <atomic>

class CurlBenchmark {
public:
    struct Config {
        std::string url = "http://localhost:8080/json";
        int requestCount = 1000;
        int concurrency = 10;
    };

    CurlBenchmark(const Config& cfg) : config_(cfg), doneCount_(0) {}

    static size_t writeCallback(void* contents, size_t size, size_t nmemb, void* userp) {
        ((std::string*)userp)->append((char*)contents, size * nmemb);
        return size * nmemb;
    }

    void worker(int requests) {
        CURL* curl = curl_easy_init();
        std::string response;

        curl_easy_setopt(curl, CURLOPT_URL, config_.url.c_str());
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, writeCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);

        for (int i = 0; i < requests; ++i) {
            response.clear();
            CURLcode res = curl_easy_perform(curl);
            if (res != CURLE_OK) {
                std::cerr << "curl error: " << curl_easy_strerror(res) << std::endl;
            }
            ++doneCount_;
        }

        curl_easy_cleanup(curl);
    }

    double run() {
        auto start = std::chrono::high_resolution_clock::now();

        int requestsPerThread = config_.requestCount / config_.concurrency;
        std::vector<std::thread> threads;

        for (int i = 0; i < config_.concurrency; ++i) {
            threads.emplace_back(&CurlBenchmark::worker, this, requestsPerThread);
        }

        for (auto& t : threads) {
            t.join();
        }

        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);

        return static_cast<double>(duration.count());
    }

    std::atomic<int> doneCount() const { return doneCount_; }

private:
    Config config_;
    std::atomic<int> doneCount_;
};

int main() {
    CurlBenchmark::Config config;
    config.url = "http://localhost:8080/json";
    config.requestCount = 1000;
    config.concurrency = 10;

    CurlBenchmark benchmark(config);

    std::cout << "Running benchmark: " << config.requestCount
              << " requests with " << config.concurrency << " threads...\n";

    double totalMs = benchmark.run();

    std::cout << "\nResults:\n";
    std::cout << "  Total time: " << totalMs << " ms\n";
    std::cout << "  Requests: " << config.requestCount << "\n";
    std::cout << "  QPS: " << (config.requestCount / (totalMs / 1000.0)) << "\n";
    std::cout << "  Avg latency: " << (totalMs / config.requestCount) << " ms\n";

    return 0;
}
```

---

## 6. Footprint 测试

### 6.1 nm + size 分析脚本

```bash
#!/bin/bash
# analyze_symbols.sh - 分析静态库的符号表

set -e

LIB=$1
OUTPUT=${2:-symbols.txt}

echo "Analyzing: $LIB"
echo "========================================" > "$OUTPUT"

# 基本信息
echo "Library Size:" >> "$OUTPUT"
ls -lh "$LIB" >> "$OUTPUT" 2>/dev/null || echo "Not found" >> "$OUTPUT"

# nm 分析
echo -e "\n\nSymbol Summary:" >> "$OUTPUT"
echo "===============" >> "$OUTPUT"
echo "Total lines: $(nm -C "$LIB" 2>/dev/null | wc -l)" >> "$OUTPUT"
echo "Functions (T): $(nm -C "$LIB" 2>/dev/null | grep ' T ' | wc -l)" >> "$OUTPUT"
echo "Data (D): $(nm -C "$LIB" 2>/dev/null | grep ' D ' | wc -l)" >> "$OUTPUT"
echo "BSS (B): $(nm -C "$LIB" 2>/dev/null | grep ' B ' | wc -l)" >> "$OUTPUT"
echo "Readonly data (R): $(nm -C "$LIB" 2>/dev/null | grep ' R ' | wc -l)" >> "$OUTPUT"

# 导出所有符号
echo -e "\n\nExported Symbols:" >> "$OUTPUT"
echo "=================" >> "$OUTPUT"
nm -C --defined-only "$LIB" 2>/dev/null >> "$OUTPUT" || true

echo "Analysis saved to: $OUTPUT"
cat "$OUTPUT"
```

### 6.2 Qt 库 Footprint 测试

```cpp
// qt_footprint_test.cpp
#include <QCoreApplication>
#include <QLibrary>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>

int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);

    qDebug() << "=== Qt Library Footprint Test ===";

    // 1. 测试 QCoreApplication 基础开销
    qDebug() << "\n[1] QCoreApplication overhead:";
    qDebug() << "    This message";

    // 2. 测试 JSON 处理内存
    qDebug() << "\n[2] JSON Memory Test:";

    QJsonObject obj;
    QJsonArray arr;

    for (int i = 0; i < 10000; ++i) {
        QJsonObject item;
        item["id"] = i;
        item["name"] = QString("item_%1").arg(i);
        item["value"] = i * 100;
        arr.append(item);
    }

    obj["items"] = arr;
    QJsonDocument doc(obj);

    qDebug() << "    JSON size:" << doc.toJson().size() << "bytes";
    qDebug() << "    Object count:" << obj.size();
    qDebug() << "    Array count:" << arr.size();

    // 3. 测试 QByteArray 内存
    qDebug() << "\n[3] QByteArray Test:";
    QByteArray ba = doc.toJson();
    qDebug() << "    ByteArray size:" << ba.size() << "bytes";

    // 4. 测试 QString 内存
    qDebug() << "\n[4] QString Test:";
    QString str = QString::fromUtf8(ba);
    qDebug() << "    QString length:" << str.length() << "chars";
    qDebug() << "    QString size:" << str.size() * 2 << "bytes (approx)";

    qDebug() << "\n=== Test Complete ===";

    return 0;
}
```

### 6.3 链接后 Binary 分析

```bash
#!/bin/bash
# link_and_analyze.sh - 链接并分析最终 binary footprint

set -e

PROJECT_NAME=$1
BUILD_TYPE=${2:-Release}

echo "========================================"
echo "Linking and Analyzing: $PROJECT_NAME"
echo "Build Type: $BUILD_TYPE"
echo "========================================"

BUILD_DIR=build/$BUILD_TYPE

# 编译
echo -e "\n[1] Building..."
cd $BUILD_DIR
make -j$(nproc) $PROJECT_NAME

# 分析最终 binary
echo -e "\n[2] Binary Size Analysis:"
ls -lh $PROJECT_NAME

echo -e "\n[3] Section Sizes:"
size -A $PROJECT_NAME

# 提取各段大小
echo -e "\n[4] Detailed Section:"
TEXT_SIZE=$(size -A $PROJECT_NAME | grep -E '^\.text' | awk '{print $2}')
DATA_SIZE=$(size -A $PROJECT_NAME | grep -E '^\.data' | awk '{print $2}')
BSS_SIZE=$(size -A $PROJECT_NAME | grep -E '^\.bss' | awk '{print $2}')

echo "  .text (code):   $TEXT_SIZE bytes"
echo "  .data (global): $DATA_SIZE bytes"
echo "  .bss (uninit):  $BSS_SIZE bytes"

# strip 后分析
echo -e "\n[5] Stripped Binary:"
STRIPPED=${PROJECT_NAME}_stripped
strip $PROJECT_NAME -o $STRIPPED
ls -lh $STRIPPED
size -A $STRIPPED

# 依赖分析
echo -e "\n[6] Dependencies (Linux):"
ldd $PROJECT_NAME 2>/dev/null || echo "Static linking or non-Linux"

echo -e "\n========================================"
echo "Analysis Complete"
echo "========================================"
```

---

## 7. 测试报告生成

### 7.1 Python 汇总脚本

```python
#!/usr/bin/env python3
# summarize_results.py - 汇总 benchmark 结果并生成 Markdown 报告

import json
import sys
import os
from datetime import datetime
from pathlib import Path

def load_results(results_dir):
    results = []
    for file in Path(results_dir).glob("*_results.json"):
        with open(file) as f:
            data = json.load(f)
            results.append(data)
    return results

def generate_table(results):
    if not results:
        return "No results found."

    # 从第一个结果获取测试项目
    test_items = list(results[0].get("tests", {}).keys())

    header = "| Test | " + " | ".join(r["name"] for r in results) + " |"
    separator = "|" + "|".join(["---"] * (len(results) + 1)) + "|"

    rows = []
    for item in test_items:
        row = [item]
        for r in results:
            val = r["tests"].get(item, {}).get("value", "N/A")
            unit = r["tests"].get(item, {}).get("unit", "")
            row.append(f"{val} {unit}")
        rows.append("| " + " | ".join(row) + " |")

    return "\n".join([header, separator] + rows)

def main():
    if len(sys.argv) < 2:
        print("Usage: summarize_results.py <results_dir>")
        sys.exit(1)

    results_dir = sys.argv[1]
    results = load_results(results_dir)

    print("========================================")
    print("Benchmark Results Summary")
    print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("========================================")

    print("\n" + generate_table(results))

    # 生成 Markdown 文件
    report_path = Path(results_dir) / "summary_report.md"
    with open(report_path, "w") as f:
        f.write(f"# Benchmark Results\n\n")
        f.write(f"Generated: {datetime.now().isoformat()}\n\n")
        f.write(generate_table(results))
        f.write("\n")

    print(f"\nReport saved to: {report_path}")

if __name__ == "__main__":
    main()
```

---

## 8. 常见陷阱与避免方法

| 陷阱 | 描述 | 避免方法 |
|------|------|----------|
| 编译器优化干扰 | 编译器可能把未使用的代码/变量优化掉 | 使用 `volatile` 或 `asm volatile` 阻止优化 |
| 缓存效应 | 第一次运行慢，后续因缓存变快 | 先预热，测多次取中位数 |
| 内存碎片 | 多次分配后内存碎片影响结果 | 每轮测试前重启进程或重置堆 |
| 后台进程干扰 | 其他进程占用 CPU/内存 | 关闭不必要进程，使用 `taskset` 绑定核心 |
| 时钟精度 | 不同平台时钟精度不同 | 使用 `high_resolution_clock`，在高精度仪器上验证 |
| 测试数据相同 | 编译器可能缓存计算结果 | 测试数据加随机因素，或每次重新生成 |
