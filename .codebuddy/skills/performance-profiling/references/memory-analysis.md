# 内存分析工具参考

## 目录

1. [AddressSanitizer (ASan)](#addresssanitizer-asan)
2. [Valgrind 工具链](#valgrind-工具链)
3. [内存泄漏检测](#内存泄漏检测)
4. [内存分配分析](#内存分配分析)
5. [实战案例](#实战案例)

---

## AddressSanitizer (ASan)

### 简介

ASan 是一个编译时插桩的内存错误检测工具，可以检测:
- 缓冲区溢出 (stack/heap/global)
- 释放后使用 (use-after-free)
- 双重释放 (double-free)
- 内存泄漏 (部分)

### 安装与使用

```bash
# GCC 内置 ASan (GCC 4.8+)
g++ -fsanitize=address -g -O1 app.cpp -o app_asan

# Clang ASan
clang++ -fsanitize=address -g -O1 app.cpp -o app_asan

# 运行
./app_asan

# 检测到错误时输出示例:
# =================================================================
# ==12345== ERROR: AddressSanitizer: heap-buffer-overflow on address 0x602000000030
# WRITE of size 4 at 0x602000000030 thread T0
#     #0 0x7ffff7a12345 in main app.cpp:15
```

### ASan 选项

```bash
# 设置符号化输出
export ASAN_OPTIONS=symbolize=1

# 检测内存泄漏 (ASan 只能检测直接泄漏)
export ASAN_OPTIONS=detect_leaks=1

# 最大泄漏数量
export ASAN_OPTIONS=max_leaks=100

# 退出时打印泄漏
export ASAN_OPTIONS=print_summary=1

# 示例
ASAN_OPTIONS=detect_leaks=1:symbolize=1 ./app_asan
```

### ASan 内存布局

```
ASan 添加 red zone (阴影内存)
+------------------+ <- 合法内存起始
|  Red Zone (16B)  |
+------------------+
|                  |
|   User Data      |
|                  |
+------------------+ <- 合法内存结束
|  Red Zone (16B)  |
+------------------+
|  Heap ( poisoned |
|   when freed)    |
+------------------+
```

### 与 CMake 集成

```cmake
# CMakeLists.txt
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address -g -O1")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -fsanitize=address")

# 或使用目标属性
add_executable(app app.cpp)
target_compile_options(app PRIVATE -fsanitize=address -g -O1)
target_link_options(app PRIVATE -fsanitize=address)
```

### ASan + Qt

```cmake
# Qt 项目使用 ASan
# Qt 自己的 debug 库可能包含 ASan，需要确保一致
# 推荐使用干净的环境

add_executable(app app.cpp)
target_link_libraries(app PRIVATE Qt5::Core Qt5::Widgets)
target_compile_options(app PRIVATE
    -fsanitize=address
    -g
    $<$<CONFIG:Release>:-O1>  # 不要在 Release 用 ASan
)
```

---

## Valgrind 工具链

### 工具概览

| 工具 | 用途 |
|------|------|
| memcheck | 内存错误检测 (默认) |
| massif | 堆内存分析 |
| cachegrind | 缓存模拟 |
| callgrind | 调用图分析 |
| helgrind | 线程错误检测 |
| drd | 数据竞争检测 |
| exp-dhat | 轻量堆分析器 |

### 安装

```bash
# Ubuntu
sudo apt install valgrind

# 验证
valgrind --version
```

### memcheck - 内存错误检测

```bash
# 基础检测
valgrind --leak-check=full ./app

# 更详细输出
valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./app

# 输出所有内存访问错误
valgrind --show-accesses=yes ./app

# 监控特定地址
valgrind --watchpoint=0x602000000030 ./app
```

### 输出解读

```
==12345== Memcheck, a memory error detector
==12345== Copyright (C) 2002-2022, and GNU GPL'd, by Julian Seward et al.

==12345== Invalid write of size 4
==12345==    at 0x123456: main (app.cpp:15)
==12345==  Address 0x602000000030 is 0 bytes inside a block of size 10 alloc'd
==12345==    at 0x123789: malloc (vg_malloc.c:123)
==12345==    by 0x123456: main (app.cpp:10)

==12345== HEAP SUMMARY:
==12345==     in use at exit: 0 bytes in 0 blocks
==12345==   total heap usage: 1 allocs, 1 frees, 10 bytes allocated

==12345== LEAK SUMMARY:
==12345==    definitely lost: 0 bytes in 0 blocks
==12345==    indirectly lost: 0 bytes in 0 blocks
==12345==      possibly lost: 0 bytes in 0 blocks
==12345==    still reachable: 1024 bytes in 1 blocks
```

### massif - 堆内存分析

```bash
# 基础用法
valgrind --tool=massif ./app
# 生成 massif.out.<pid>

# 查看结果
ms_print massif.out.12345

# 带栈跟踪
valgrind --tool=massif --stacks=yes ./app

# 堆分配
valgrind --tool=massif --pages-as-heap=yes ./app
```

### massif 输出解读

```
--------------------------------------------------------------------------------
  n        time(i)         total(B)   useful-heap(B) extra-heap(B)   stacks(B)
--------------------------------------------------------------------------------
    1              0                0                0               0           0
    2             10           65,536           65,536               0           0
    3             20          131,072          131,072               0           0

    MB
65.5^                                           ##
    |                                           ##
    |                                       ## ##
    |                                   ## ##
    |                               ## ##
    |                           ## ##
    |                       ## ##
    |                   ## ##
    |               ## ##
    |           ## ##
    |       ## ##
    |   ## ##
    +->-----------------------------------------------TIME----------->

    Number of snapshots: 2
     Detailed snapshots: [1, 2]
```

### cachegrind - 缓存模拟

```bash
# 模拟 L1/L2 缓存
valgrind --tool=cachegrind ./app

# 输出示例
I   refs:       1,000,000
I1  misses:          10,000 (1.00%)
LLi misses:           1,000 (0.10%)
D   refs:          500,000
D1  misses:         50,000 (10.00%)
LLd misses:         10,000 (2.00%)
```

### callgrind - 调用图分析

```bash
# 生成调用图
valgrind --tool=callgrind ./app

# 查看
callgrind_annotate callgrind.out.12345

# 特定函数分析
valgrind --tool=callgrind --collect-atstart=no ./app
# 然后在另一个终端
kill -SIGPROF <pid>

# 生成调用树
callgrind_annotate --tree=both callgrind.out.12345
```

---

## 内存泄漏检测

### 泄漏类型

```
内存泄漏类型
├── 明确泄漏 (definitely lost)
│   └── 不可访问，无指针指向
├── 间接泄漏 (indirectly lost)
│   └── 可从明确泄漏的对象到达
├── 可能泄漏 (possibly lost)
│   └── 存在指针，但指针是错的 (如野指针)
└── 仍可达 (still reachable)
    └── 全局/静态指针，未释放 (通常不是问题)
```

### ASan 检测泄漏

```bash
# ASan 检测能力有限，但可以检测直接泄漏
g++ -fsanitize=address -g app.cpp -o app
./app

# 检测到泄漏时输出:
# Direct leak of 1024 byte(s) in 1 object(s) allocated from:
#     #0 0x123456 in malloc
#     #1 0x123789 in main app.cpp:20
```

### Valgrind 检测泄漏

```bash
# 最完整检测
valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes ./app

# 只检测明确泄漏
valgrind --leak-check=full --show-leak-kinds=definite ./app

# 检测泄漏并计数
valgrind --leak-check=full --errors-for-leak-kinds=definite ./app
```

### 智能指针泄漏检测

```cpp
// 使用 unique_ptr 避免泄漏
#include <memory>

class Resource {
public:
    Resource() { std::cout << "Allocated\n"; }
    ~Resource() { std::cout << "Released\n"; }
};

// 正确: 使用智能指针
std::unique_ptr<Resource> createResource() {
    return std::make_unique<Resource>();
}

// 错误: 容易泄漏
Resource* createResourceRaw() {
    return new Resource();  // 调用者忘记 delete
}
```

### 常见泄漏模式

```cpp
// 泄漏 1: 忘记删除
void leak1() {
    int* p = new int[100];
    // 忘记 delete[]
}

// 泄漏 2: 提前返回
void leak2() {
    int* p = new int[100];
    if (error_condition) return;  // 泄漏
    delete[] p;
}

// 泄漏 3: 异常
void leak3() {
    int* p = new int[100];
    throw std::runtime_error("error");  // 泄漏
    delete[] p;
}

// 正确: RAII
void noLeak() {
    std::vector<int> v(100);  // 自动释放
    if (error_condition) return;
}

// 正确: 智能指针
void smartPointer() {
    auto p = std::make_unique<int[]>(100);
    if (error_condition) return;  // 自动释放
}
```

---

## 内存分配分析

### 追踪分配点

```bash
# bpftrace 追踪 malloc/free
sudo bpftrace -e '
    malloc {
        @[ustack, comm] = count();
    }
    free {
        @[ustack, comm] = count();
    }
'

# 追踪分配大小分布
sudo bpftrace -e '
    malloc {
        @size = hist(arg0);
    }
'
```

### 分配统计

```bash
# /usr/bin/time 查看内存
/usr/bin/time -v ./app

# 输出示例
Maximum resident set size (kbytes): 102400
Minor (reclaiming a frame) page reclaims: 1000
Minor page faults: 5000
Major page faults: 100
```

### 对象池模式

```cpp
// 固定大小对象池 - 避免频繁分配
template<typename T, size_t N>
class ObjectPool {
public:
    T* allocate() {
        if (freeList_) {
            T* obj = freeList_;
            freeList_ = *reinterpret_cast<T**>(freeList_);
            return obj;
        }
        if (size_ < N) {
            return &buffer_[size_++];
        }
        return nullptr;  // 池已满
    }

    void deallocate(T* obj) {
        *reinterpret_cast<T**>(obj) = freeList_;
        freeList_ = obj;
    }

private:
    alignas(T) char buffer_[sizeof(T) * N];
    T* freeList_ = nullptr;
    size_t size_ = 0;
};

// 使用
ObjectPool<MyClass, 100> pool;
MyClass* obj = pool.allocate();
// 使用 ...
pool.deallocate(obj);
```

### Arena 分配器

```cpp
// Arena 分配器 - 批量释放
class Arena {
public:
    explicit Arena(size_t size) : size_(size) {
        memory_ = ::operator new(size);
        reset();
    }

    ~Arena() { ::operator delete(memory_); }

    void* alloc(size_t size, size_t alignment = alignof(std::max_align_t)) {
        size_t aligned = (reinterpret_cast<size_t>(ptr_) + alignment - 1) & ~(alignment - 1);
        size_t newPtr = aligned + size;
        if (newPtr > reinterpret_cast<size_t>(memory_) + size_) {
            return nullptr;
        }
        ptr_ = reinterpret_cast<void*>(newPtr);
        return reinterpret_cast<void*>(aligned);
    }

    void reset() { ptr_ = memory_; }

private:
    void* memory_;
    void* ptr_;
    size_t size_;
};

// 使用
Arena arena(1024 * 1024);  // 1MB arena
void* p1 = arena.alloc(100);
void* p2 = arena.alloc(200);
arena.reset();  // 一次性释放所有
```

---

## 实战案例

### 案例 1: 检测 use-after-free

```cpp
// use_after_free.cpp
#include <stdio.h>
#include <stdlib.h>

int main() {
    int* arr = (int*)malloc(10 * sizeof(int));
    arr[0] = 42;

    free(arr);  // 释放

    printf("%d\n", arr[0]);  // 错误: 释放后使用
    return 0;
}
```

```bash
# 编译并运行
g++ -fsanitize=address -g use_after_free.cpp -o use_after_free
./use_after_free

# ASan 输出:
# =================================================================
# ==12345== ERROR: AddressSanitizer: heap-use-after-free on address 0x602000000030
# READ of size 4 at 0x602000000030 thread T0
#     #0 0x123456 in main use_after_free.cpp:9
```

### 案例 2: 堆缓冲区溢出

```cpp
// heap_overflow.cpp
#include <vector>

int main() {
    std::vector<int> v(10);
    v[10] = 42;  // 越界访问
    return 0;
}
```

```bash
# 编译运行 (ASan 可以检测)
g++ -fsanitize=address -g heap_overflow.cpp -o heap_overflow
./heap_overflow

# 输出:
# ==12345== ERROR: AddressSanitizer: heap-buffer-overflow on address 0x602000000068
# WRITE of size 4 at 0x602000000068
#     #0 0x123456 in main heap_overflow.cpp:5
```

### 案例 3: 内存增长分析

```cpp
// memory_growth.cpp
#include <map>

int main() {
    std::map<int, int*> m;
    for (int i = 0; i < 100000; ++i) {
        m[i] = new int[100];  // 分配但从不释放
    }
    return 0;
}
```

```bash
# ASan 检测泄漏
g++ -fsanitize=address -g memory_growth.cpp -o memory_growth
./memory_growth

# Valgrind massif 分析内存增长
valgrind --tool=massif ./memory_growth
ms_print massif.out.* | grep -A 20 "100%"

# 或者直接看最终快照
ms_print massif.out.* | tail -50
```

### 案例 4: Qt 内存泄漏检测

```cpp
// qt_leak.cpp
#include <QCoreApplication>
#include <QString>
#include <QFile>

int main(int argc, char* argv[]) {
    QCoreApplication app(argc, argv);

    // 每次循环泄漏一个字符串
    for (int i = 0; i < 1000; ++i) {
        QString* leak = new QString("leaked string");
        // 忘记 delete leak;
    }

    return 0;
}
```

```bash
# 使用 ASan (需要 Qt 编译支持)
# 先确保 Qt 是用 ASan 编译的，或者使用 AddressSanitizer Qt 插件

# 或者使用 Valgrind
valgrind --leak-check=full --show-leak-kinds=all ./qt_leak

# Qt Creator 中使用 Memory Analyzer (Valgrind)
# 分析 → Valgrind Memory Analyzer
```

### 案例 5: 多线程内存竞争

```cpp
// thread_memory.cpp
#include <thread>
#include <vector>

std::vector<int> shared;

void worker() {
    for (int i = 0; i < 10000; ++i) {
        shared.push_back(i);  // 多线程不安全
    }
}

int main() {
    std::thread t1(worker);
    std::thread t2(worker);
    t1.join();
    t2.join();
    return 0;
}
```

```bash
# Helgrind 检测数据竞争
valgrind --tool=helgrind ./thread_memory

# DRD 检测
valgrind --tool=drd ./thread_memory

# 输出示例:
# ==12345== Possible data race:
# ==12345== Write during malloc initialization: T1
# ==12345==    at 0x123456: operator new (vg_replace_malloc.c:...)
# ==12345== by 0x123789: worker() (thread_memory.cpp:6)
```

---

## 工具选择指南

| 场景 | 推荐工具 |
|------|----------|
| 快速检测内存错误 | ASan (编译时) |
| 完整内存泄漏分析 | Valgrind memcheck |
| 堆内存使用分析 | Valgrind massif |
| 缓存性能分析 | Valgrind cachegrind |
| 调用图分析 | Valgrind callgrind / perf |
| 线程安全分析 | Valgrind helgrind / drd |
| 运行时追踪 | bpftrace |
| 生产环境检测 | 运行时 ASan 或监控 |
