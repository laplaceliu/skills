---
name: linux-system-programming
description: |
  Linux 系统编程指南，调用 Linux system call 和 libc 函数等系统接口。
  触发条件: Linux 系统编程、C++ 系统开发、调用 Linux 系统调用、
  进程/线程管理、文件 I/O、内存管理、信号处理、进程间通信 (IPC)、
  网络编程 (socket)、系统监控、系统调优、系统安全编程、
  系统服务开发、守护进程开发、POSIX 编程。
  不触发条件: 纯 Qt GUI 应用 (用 qt- 开头的 skill)、纯 Web 后端开发 (用 fullstack-dev)。
license: MIT
metadata:
  category: systems-programming
  version: "1.0.0"
  sources:
    - "The Linux Programming Interface (TLPI) - Michael Kerrisk"
    - "Advanced Programming in the UNIX Environment (APUE) - Stevens & Rago"
    - POSIX.1-2017 Standard
    - Linux man pages
---

# Linux 系统编程实践

## 强制工作流 — 按顺序执行以下步骤

**当此技能被触发时，在编写任何代码前必须遵循此工作流。**

### 第 0 步: 收集需求

在开始 Linux 系统编程项目之前，请用户明确（或从上下文中推断）:

1. **目标平台**: 桌面 Linux、服务器、嵌入式 Linux (ARM 等)、Android (NDK)?
2. **编程语言**: C++ (默认)、C、或混合?
3. **系统接口类型**: 文件 I/O、进程管理、线程、网络编程、IPC、或综合?
4. **依赖库**: 是否使用 GLIBC 特有接口、POSIX 标准接口、或需要跨平台?
5. **性能要求**: 实时性要求、高并发、低延迟?
6. **编译工具链**: GCC/Clang、CMake/qmake、静态/动态链接?

如果用户已在请求中说明这些，跳过询问直接继续。

### 第 1 步: 架构决策

根据需求，在编码前做出并说明以下决策:

| 决策项 | 选项 | 参考 |
|--------|------|------|
| 项目结构 | 特性优先 vs 分层优先 | [第 1 节](#1-项目结构与分层-关键) |
| 错误处理 | 错误码 + errno vs 异常 | [第 11 节](#11-错误处理与日志-高) |
| 内存管理 | RAII + 智能指针 vs 手动管理 | [第 5 节](#5-内存管理-高) |
| 并发模型 | 多进程 vs 多线程 vs 混合 | [第 4 节](#4-进程与线程管理-高) |
| IPC 方式 | pipe/FIFO vs socket vs shared memory | [第 7 节](#7-进程间通信-高) |

简要解释每个选择 (每项 1 句话)。

### 第 2 步: 使用清单搭建项目

使用下方合适的清单。确保所有勾选项都已实现 — 不要跳过任何一项。

### 第 3 步: 按模式实现

编写代码时遵循本文档中的模式。实现各部分时引用具体章节。

### 第 4 步: 测试与验证

实现完成后，在声称完成前运行以下检查:

1. **编译检查**: 确保无警告编译通过
   ```bash
   g++ -Wall -Wextra -Werror -pedantic -std=c++17 -o program source.cpp -lpthread
   ```
2. **静态分析**: 运行静态分析工具检查代码质量
   ```bash
   clang-tidy -checks='*' source.cpp
   ```
3. **单元测试**: 测试核心系统抽象
   ```bash
   # 使用 GoogleTest 或 Catch2
   cmake -B build -DCMAKE_BUILD_TYPE=Debug
   ctest --output-on-failure
   ```
4. **资源泄漏检查**: 检查文件描述符、内存泄漏
   ```bash
   valgrind --leak-check=full ./program
   lsof -p $(pgrep -f program)  # 检查打开的文件描述符
   ```

如有任何检查失败，先修复问题再继续。

### 第 5 步: 移交摘要

向用户提供简要摘要:

- **已完成**: 实现的功能和模块列表
- **如何编译**: 编译命令和依赖库
- **缺失项/后续步骤**: 任何延期项目、已知限制或建议改进
- **关键文件**: 用户应了解的最重要的文件列表

---

## 适用范围

**使用此技能的情况:**
- Linux 系统编程，直接调用系统调用和 libc 函数
- 系统工具、守护进程、系统服务开发
- 进程/线程管理、文件 I/O、内存管理
- 信号处理、进程间通信 (IPC)
- 网络编程 (socket)、网络协议实现
- 系统监控、系统调优、系统安全编程
- POSIX 标准编程、GLIBC 编程

**不适用的情况:**
- 纯 Qt GUI 应用 (使用 qt- 开头的 skill)
- 纯 Web 后端开发 (使用 fullstack-dev)
- 纯嵌入式裸机开发 (使用 embedded-dev)
- Windows/macOS 系统编程

---

## 快速开始 — 新项目清单

- [ ] 使用**分层模块化**结构搭建项目
- [ ] 配置 **CMake** 构建系统 (推荐)
- [ ] 定义**类型化错误码**和错误处理宏
- [ ] 封装 **RAII 文件描述符**和 **RAII 互斥锁**
- [ ] 添加**结构化日志** (带时间戳、日志级别、模块名)
- [ ] 实现 **POSIX 信号处理** (至少 SIGINT/SIGTERM)
- [ ] 配置 **compiler flags**: `-Wall -Wextra -Werror -pedantic`
- [ ] 添加**单元测试**框架 (GoogleTest/Catch2)
- [ ] 提交 `.clang-tidy` 和 `.clang-format` 配置文件

## 快速开始 — 系统调用清单

- [ ] 使用 `open()`/`close()` 而非 `fopen()`/`fclose()` (需要文件描述符控制)
- [ ] 使用 `read()`/`write()` 进行无缓冲 I/O
- [ ] 使用 `mmap()` 进行内存映射 I/O (大文件高效)
- [ ] 使用 `poll()`/`epoll()` 而非 `select()` (高并发)
- [ ] 使用 `pthread_mutex_*` 而非 `std::mutex` (需要 POSIX 语义)
- [ ] 使用 `sigaction()` 而非 `signal()` (可靠信号)
- [ ] 使用 `getaddrinfo()` 而非 `gethostbyname()` (IPv6 支持)
- [ ] 使用 `open()` 带 `O_CLOEXEC` 避免 fd 泄漏

---

## 快速导航

| 需要… | 跳转到 |
|-------|--------|
| 组织项目文件夹 | [1. 项目结构与分层](#1-项目结构与分层-关键) |
| 文件 I/O 操作 | [2. 文件 I/O](#2-文件-io-关键) |
| 进程管理 | [3. 进程管理](#3-进程管理-高) |
| 线程与并发 | [4. 线程与并发](#4-线程与并发-高) |
| 内存管理 | [5. 内存管理](#5-内存管理-高) |
| 信号处理 | [6. 信号处理](#6-信号处理-高) |
| 进程间通信 | [7. 进程间通信](#7-进程间通信-高) |
| 网络编程 | [8. 网络编程](#8-网络编程-高) |
| 文件系统操作 | [9. 文件系统](#9-文件系统-中) |
| 时间与定时 | [10. 时间与定时](#10-时间与定时-中) |
| 错误处理 | [11. 错误处理与日志](#11-错误处理与日志-高) |
| 环境与资源 | [12. 环境与资源限制](#12-环境与资源限制-中) |
| 系统调用快速参考 | [references/system-call-quick-ref.md](references/system-call-quick-ref.md) |
| POSIX 线程编程 | [references/posix-threads-guide.md](references/posix-threads-guide.md) |
| IPC 模式 | [references/ipc-patterns.md](references/ipc-patterns.md) |
| 网络编程深度指南 | [references/network-programming.md](references/network-programming.md) |

---

## 核心原则 (10 条铁律)

```
1. 始终检查系统调用返回值 — errno 指示错误原因
2. 所有资源必须 RAII 化 — 文件描述符、互斥锁、内存映射
3. 子进程必须正确处理僵尸状态 — wait() 或 signal(SIGCHLD, SIG_IGN)
4. 信号处理函数必须 async-signal-safe — 绝不使用 printf、malloc
5. 互斥锁必须成对使用 — lock 后必须 unlock，禁止在持有锁时返回
6. 所有缓冲区必须边界检查 — 禁止缓冲区溢出、禁止字符串函数误用
7. 文件描述符必须 close-on-exec 或及时关闭 — 防止 fd 泄漏
8. 使用 poll/epoll 而非 select — select 有 fd 数量限制
9. 时间值必须使用 struct timespec (纳秒) 而非 struct timeval (微秒)
10. 多线程程序必须处理信号异步性 — 使用 sigwaitinfo() 或 eventfd 替代信号
```

---

## 1. 项目结构与分层 (关键)

### 推荐项目结构

```
linux-system-project/
src/
  main.cpp                         应用入口
  app/
    application.cpp                应用逻辑
    service.cpp                    系统服务
  process/
    daemon.cpp                     守护进程
    fork_utils.cpp                 进程工具
  thread/
    thread_pool.cpp                线程池
    worker.cpp                     工作线程
  ipc/
    pipe.cpp                       管道通信
    shm.cpp                        共享内存
    socketpair.cpp                 socketpair
  fs/
    file_ops.cpp                   文件操作
    dir_ops.cpp                    目录操作
  net/
    tcp_server.cpp                 TCP 服务器
    udp_client.cpp                 UDP 客户端
    epoll_server.cpp               epoll 服务器
  signal/
    signal_handler.cpp             信号处理
  utils/
    logger.cpp                     日志工具
    error.cpp                      错误处理
    raii.cpp                       RAII 封装
  config/
    config.cpp                     配置管理
tests/
  unit_tests/                      单元测试
  integration_tests/               集成测试
cmake/
  FindThreads.cmake                线程查找
  CompilerFlags.cmake              编译标志
include/
  linux_sys/
    fd.hpp                         文件描述符 RAII
    mutex.hpp                      互斥锁 RAII
    mmap_file.hpp                  内存映射 RAII
```

### 分层职责

| 层 | 职责 | 绝不 |
|-----|------|------|
| 应用层 (app/) | 业务逻辑、状态机、服务编排 | 直接操作 fd、直接调用系统调用 |
| 系统层 (process/thread/ipc/net/) | 系统调用封装、POSIX 抽象 | 业务逻辑 |
| 工具层 (utils/) | 日志、错误处理、RAII 封装 | 系统调用、硬件相关代码 |
| 配置层 (config/) | 配置解析、环境变量 | 运行时逻辑 |

### RAII 文件描述符封装

```cpp
// include/linux_sys/fd.hpp
#pragma once
#include <unistd.h>
#include <fcntl.h>
#include <system_error>
#include <optional>

namespace linux_sys {

// RAII 文件描述符封装
class FileDescriptor {
public:
    FileDescriptor() = default;

    explicit FileDescriptor(int fd) : fd_(fd) {}

    // 接管所有权
    FileDescriptor(FileDescriptor&& other) noexcept : fd_(other.release()) {}

    FileDescriptor& operator=(FileDescriptor&& other) noexcept {
        if (this != &other) {
            reset();
            fd_ = other.release();
        }
        return *this;
    }

    // 禁止复制
    FileDescriptor(const FileDescriptor&) = delete;
    FileDescriptor& operator=(const FileDescriptor&) = delete;

    ~FileDescriptor() { reset(); }

    int get() const { return fd_; }
    int release() { int tmp = fd_; fd_ = -1; return tmp; }
    void reset() {
        if (fd_ >= 0) {
            ::close(fd_);
            fd_ = -1;
        }
    }

    explicit operator bool() const { return fd_ >= 0; }

private:
    int fd_ = -1;
};

// RAII 内存映射封装
class MmapFile {
public:
    MmapFile() = default;

    MmapFile(const char* path, size_t length, int prot, int flags) {
        fd_ = ::open(path, O_RDWR);
        if (fd_ < 0) throw std::system_error(errno, std::generic_category(), "open");

        data_ = ::mmap(nullptr, length, prot, flags, fd_, 0);
        if (data_ == MAP_FAILED) {
            ::close(fd_);
            throw std::system_error(errno, std::generic_category(), "mmap");
        }
        length_ = length;
    }

    ~MmapFile() {
        if (data_ != MAP_FAILED) munmap(data_, length_);
        if (fd_ >= 0) ::close(fd_);
    }

    void* data() { return data_; }
    const void* data() const { return data_; }
    size_t size() const { return length_; }

private:
    int fd_ = -1;
    void* data_ = MAP_FAILED;
    size_t length_ = 0;
};

} // namespace linux_sys
```

### RAII 互斥锁封装

```cpp
// include/linux_sys/mutex.hpp
#pragma once
#include <pthread.h>
#include <system_error>

namespace linux_sys {

class Mutex {
public:
    Mutex() {
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ERRORCHECK);  // 检测死锁
        if (pthread_mutex_init(&mutex_, &attr) != 0) {
            pthread_mutexattr_destroy(&attr);
            throw std::system_error(errno, std::generic_category(), "pthread_mutex_init");
        }
        pthread_mutexattr_destroy(&attr);
    }

    ~Mutex() { pthread_mutex_destroy(&mutex_); }

    void lock() {
        int ret = pthread_mutex_lock(&mutex_);
        if (ret != 0) throw std::system_error(ret, std::generic_category(), "pthread_mutex_lock");
    }

    bool try_lock() {
        int ret = pthread_mutex_trylock(&mutex_);
        if (ret == EBUSY) return false;
        if (ret != 0) throw std::system_error(ret, std::generic_category(), "pthread_mutex_trylock");
        return true;
    }

    void unlock() {
        int ret = pthread_mutex_unlock(&mutex_);
        if (ret != 0) throw std::system_error(ret, std::generic_category(), "pthread_mutex_unlock");
    }

    pthread_mutex_t* native_handle() { return &mutex_; }

private:
    pthread_mutex_t mutex_;
};

// RAII 锁守卫
template<typename Mutex>
class LockGuard {
public:
    explicit LockGuard(Mutex& mutex) : mutex_(mutex) { mutex_.lock(); }
    ~LockGuard() { mutex_.unlock(); }
    LockGuard(const LockGuard&) = delete;
    LockGuard& operator=(const LockGuard&) = delete;
private:
    Mutex& mutex_;
};

} // namespace linux_sys
```

---

## 2. 文件 I/O (关键)

### open/read/write/close

```cpp
#include <fcntl.h>
#include <unistd.h>
#include <system_error>
#include <cstddef>
#include <cstring>

// 打开文件
int fd = ::open("/path/to/file", O_RDONLY);
if (fd < 0) throw std::system_error(errno, std::generic_category(), "open");

// 读取数据
char buffer[4096];
ssize_t n = ::read(fd, buffer, sizeof(buffer));
if (n < 0) throw std::system_error(errno, std::generic_category(), "read");

// 写入数据
const char* msg = "Hello, Linux!";
ssize_t written = ::write(STDOUT_FILENO, msg, strlen(msg));
if (written < 0) throw std::system_error(errno, std::generic_category(), "write");

// 关闭文件
if (::close(fd) < 0) throw std::system_error(errno, std::generic_category(), "close");
```

### open flags 详解

```cpp
// 文件访问模式 (互斥，必须选一个)
O_RDONLY      // 只读
O_WRONLY      // 只写
O_RDWR        // 读写

// 文件创建选项 (与 O_CREAT 配合)
O_CREAT       // 文件不存在则创建
O_EXCL        // 与 O_CREAT 配合，文件存在则报错
O_TRUNC       // 截断文件为 0
O_APPEND      // 每次写入追加到文件末尾

// 文件状态
O_NONBLOCK    // 非阻塞 I/O
O_CLOEXEC     // exec 时关闭文件描述符 (推荐!)
O_DIRECT      // 绕过页缓存 (直接 I/O)
O_DSYNC       // 写入等待物理写入完成
O_SYNC        // 同步 I/O
O_NOCTTY      // 不将此终端作为控制终端

// 示例: 打开文件用于读写，不存在则创建，close-on-exec
int fd = ::open(path, O_RDWR | O_CREAT | O_CLOEXEC, 0644);
```

### read/write 返回值处理

```cpp
// read/write 可能返回少于请求的字节数 (非阻塞或信号中断)
// 必须循环处理直到读完所有数据

ssize_t read_all(int fd, void* buf, size_t count) {
    char* ptr = static_cast<char*>(buf);
    size_t remaining = count;
    while (remaining > 0) {
        ssize_t n = ::read(fd, ptr, remaining);
        if (n < 0) {
            if (errno == EINTR) continue;  // 信号中断，重试
            if (errno == EAGAIN || errno == EWOULDBLOCK) break;  // 非阻塞，无数据
            throw std::system_error(errno, std::generic_category(), "read");
        }
        if (n == 0) break;  // EOF
        ptr += n;
        remaining -= n;
    }
    return count - remaining;
}

ssize_t write_all(int fd, const void* buf, size_t count) {
    const char* ptr = static_cast<const char*>(buf);
    size_t remaining = count;
    while (remaining > 0) {
        ssize_t n = ::write(fd, ptr, remaining);
        if (n < 0) {
            if (errno == EINTR) continue;
            throw std::system_error(errno, std::generic_category(), "write");
        }
        ptr += n;
        remaining -= n;
    }
    return count - remaining;
}
```

### lseek 文件偏移

```cpp
#include <unistd.h>
#include <cstddef>

// 文件偏移
off_t pos = ::lseek(fd, 0, SEEK_CUR);    // 获取当前偏移
off_t pos = ::lseek(fd, 0, SEEK_SET);     // 设置到开头
off_t pos = ::lseek(fd, 0, SEEK_END);     // 设置到末尾

// 文件空洞 (sparse file)
off_t pos = ::lseek(fd, 10'000'000'000, SEEK_SET);  // 跳转到大偏移
::write(fd, "data", 4);  // 只写入 4 字节，中间是空洞
```

### ftruncate 调整文件大小

```cpp
#include <unistd.h>
#include <fcntl.h>

// 扩展文件
int fd = ::open("file", O_WRONLY | O_CREAT | O_TRUNC, 0644);
if (::ftruncate(fd, 10'000) < 0) throw std::system_error(errno, std::generic_category(), "ftruncate");
```

### 文件 I/O 规则

```
使用 O_CLOEXEC 打开所有文件描述符
非阻塞 I/O 使用 poll/epoll 检测可读/可写
read/write 返回 0 表示 EOF，-1 表示错误
始终循环处理部分 I/O，直到完成或遇到错误
使用 ftruncate 扩展文件，lseek + write 创建空洞

绝不忽略 read/write 的返回值
绝不使用 select 管理大量 fd (用 epoll)
绝不混合使用 fopen 和 open (缓冲区冲突)
```

---

## 3. 进程管理 (高)

### fork 创建子进程

```cpp
#include <unistd.h>
#include <sys/wait.h>
#include <system_error>
#include <cerrno>
#include <cstdlib>

pid_t fork_process() {
    pid_t pid = ::fork();
    if (pid < 0) throw std::system_error(errno, std::generic_category(), "fork");
    return pid;
}

// 典型用法: 创建子进程执行不同任务
pid_t pid = fork_process();
if (pid == 0) {
    // 子进程
    ::execlp("ls", "ls", "-la", nullptr);
    ::_exit(127);  // exec 失败必须用 _exit
}
// 父进程继续
int status;
pid_t ret = ::waitpid(pid, &status, 0);
if (ret < 0) throw std::system_error(errno, std::generic_category(), "waitpid");
```

### exec 系列函数

```cpp
#include <unistd.h>

// exec 族函数: 替换当前进程镜像
// 成功不返回，失败返回 -1

// execl: 参数列表
::execl("/bin/ls", "ls", "-l", nullptr);

// execlp: 在 PATH 中搜索可执行文件
::execlp("ls", "ls", "-l", nullptr);

// execv: 参数数组
const char* args[] = {"ls", "-l", nullptr};
::execv("/bin/ls", const_cast<char* const*>(args));

// execvp: 在 PATH 中搜索
::execvp("ls", const_cast<char* const*>(args));

// execve: 最底层，可指定环境变量
extern char** environ;
::execve("/path/to/program", args, environ);
```

### wait / waitpid 等待子进程

```cpp
#include <sys/wait.h>
#include <unistd.h>
#include <csignal>
#include <cstring>

// 等待任意子进程
int status;
pid_t pid = ::wait(&status);  // 阻塞
if (pid < 0) throw std::system_error(errno, std::generic_category(), "wait");

// 等待指定子进程
pid_t pid = ::waitpid(child_pid, &status, 0);

// WIFEXITED / WEXITSTATUS: 正常退出
if (WIFEXITED(status)) {
    int exit_code = WEXITSTATUS(status);
}

// WIFSIGNALED / WTERMSIG: 信号终止
if (WIFSIGNALED(status)) {
    int sig = WTERMSIG(status);  // 终止信号
}

// WIFSTOPPED / WSTOPSIG: 停止 (作业控制)
if (WIFSTOPPED(status)) {
    int sig = WSTOPSIG(status);
}
```

### 避免僵尸进程

```cpp
// 方法 1: 忽略 SIGCHLD (系统自动回收)
::signal(SIGCHLD, SIG_IGN);

// 方法 2: 父进程调用 wait/waitpid
// 适用于需要知道子进程退出状态

// 方法 3: 非阻塞 wait + 循环处理
while (true) {
    int status;
    pid_t pid = ::waitpid(-1, &status, WNOHANG);  // 非阻塞
    if (pid == 0) break;  // 没有更多子进程
    if (pid < 0) {
        if (errno == ECHILD) break;  // 没有子进程
        throw std::system_error(errno, std::generic_category(), "waitpid");
    }
    // 处理已退出的子进程
}

// 方法 4: 使用 self-pipe 避免紧急信号
```

### 守护进程 (Daemon)

```cpp
#include <unistd.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <cstdlib>
#include <cstdio>

void become_daemon() {
    // 1. 创建子进程，父进程退出
    pid_t pid = ::fork();
    if (pid < 0) throw std::runtime_error("fork failed");
    if (pid > 0) ::_exit(0);  // 父进程退出

    // 2. 成为新会话的领头进程 (脱离控制终端)
    if (::setsid() < 0) throw std::runtime_error("setsid failed");

    // 3. 再次 fork，防止再次打开控制终端
    pid = ::fork();
    if (pid < 0) throw std::runtime_error("fork failed");
    if (pid > 0) ::_exit(0);

    // 4. 改变工作目录到根目录
    ::chdir("/");

    // 5. 关闭所有文件描述符
    for (int i = 0; i < 1024; ++i) ::close(i);

    // 6. 重定向标准输入/输出/错误到 /dev/null
    ::open("/dev/null", O_RDONLY);   // stdin
    ::open("/dev/null", O_WRONLY);   // stdout
    ::dup(1);                         // stderr

    // 7. 设置 umask
    ::umask(0);

    // 8. 忽略 SIGCHLD
    ::signal(SIGCHLD, SIG_IGN);
}
```

### 进程规则

```
fork 后必须 wait/waitpid 回收子进程，避免僵尸
exec 族函数成功不返回，失败才返回
exec 后子进程用 _exit() 退出，不用 exit()
守护进程必须关闭所有继承的 fd
守护进程必须 chdir("/")，允许卸载文件系统
setsid() 使进程脱离控制终端

绝不 fork 后不 wait (产生僵尸进程)
绝不使用 signal(SIGCHLD, SIG_IGN) 后期待 wait() 有意义
exec 失败必须 _exit()，不能用 return
```

---

## 4. 线程与并发 (高)

### pthread 创建线程

```cpp
#include <pthread.h>
#include <system_error>
#include <cstdint>
#include <cstdlib>

struct ThreadArgs {
    int id;
    const char* name;
};

void* thread_entry(void* arg) {
    auto* args = static_cast<ThreadArgs*>(arg);
    // 线程工作
    delete args;
    return nullptr;  // 返回值可传递给 join
}

void create_thread_example() {
    pthread_t thread;
    auto* args = new ThreadArgs{1, "worker"};

    int ret = pthread_create(&thread, nullptr, thread_entry, args);
    if (ret != 0) {
        delete args;
        throw std::system_error(ret, std::generic_category(), "pthread_create");
    }

    void* retval;
    ret = pthread_join(thread, &retval);  // 等待线程结束
    if (ret != 0) throw std::system_error(ret, std::generic_category(), "pthread_join");
}
```

### pthread 互斥锁

```cpp
#include <pthread.h>
#include <mutex>
#include <system_error>
#include <chrono>

class ThreadSafeCounter {
public:
    void increment() {
        std::lock_guard<std::mutex> lock(mutex_);
        ++counter_;
    }

    int get() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return counter_;
    }

private:
    mutable std::mutex mutex_;
    int counter_ = 0;
};

// POSIX pthread_mutex (需要更细控制时)
class PosixMutex {
public:
    PosixMutex() {
        pthread_mutexattr_t attr;
        pthread_mutexattr_init(&attr);
        pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ERRORCHECK);
        if (pthread_mutex_init(&mutex_, &attr) != 0) {
            pthread_mutexattr_destroy(&attr);
            throw std::system_error(errno, std::generic_category(), "pthread_mutex_init");
        }
        pthread_mutexattr_destroy(&attr);
    }

    void lock() {
        int ret = pthread_mutex_lock(&mutex_);
        if (ret != 0) throw std::system_error(ret, std::generic_category(), "pthread_mutex_lock");
    }

    bool try_lock() {
        int ret = pthread_mutex_trylock(&mutex_);
        if (ret == EBUSY) return false;
        if (ret != 0) throw std::system_error(ret, std::generic_category(), "pthread_mutex_trylock");
        return true;
    }

    void unlock() {
        int ret = pthread_mutex_unlock(&mutex_);
        if (ret != 0) throw std::system_error(ret, std::generic_category(), "pthread_mutex_unlock");
    }

    ~PosixMutex() { pthread_mutex_destroy(&mutex_); }

private:
    pthread_mutex_t mutex_;
};
```

### pthread 条件变量

```cpp
#include <pthread.h>
#include <system_error>
#include <queue>
#include <mutex>

template<typename T>
class ThreadSafeQueue {
public:
    void push(T value) {
        std::lock_guard<std::mutex> lock(mutex_);
        queue_.push(std::move(value));
        pthread_cond_signal(&cond_);  // 通知等待的线程
    }

    bool pop(T& result) {
        std::lock_guard<std::mutex> lock(mutex_);
        while (queue_.empty()) {
            int ret = pthread_cond_wait(&cond_, mutex_.native_handle());
            if (ret != 0) throw std::system_error(ret, std::generic_category(), "pthread_cond_wait");
        }
        result = std::move(queue_.front());
        queue_.pop();
        return true;
    }

    bool empty() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return queue_.empty();
    }

private:
    mutable std::mutex mutex_;
    pthread_cond_t cond_ = PTHREAD_COND_INITIALIZER;
    std::queue<T> queue_;
};

// 带超时的 pop
bool pop_with_timeout(T& result, int timeout_ms) {
    std::unique_lock<std::mutex> lock(mutex_);
    timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    ts.tv_sec += timeout_ms / 1000;
    ts.tv_nsec += (timeout_ms % 1000) * 1'000'000;
    if (ts.tv_nsec >= 1'000'000'000) {
        ts.tv_sec += 1;
        ts.tv_nsec -= 1'000'000'000;
    }

    while (queue_.empty()) {
        int ret = pthread_cond_timedwait(&cond_, mutex_.native_handle(), &ts);
        if (ret == ETIMEDOUT) return false;
        if (ret != 0) throw std::system_error(ret, std::generic_category(), "pthread_cond_timedwait");
    }
    result = std::move(queue_.front());
    queue_.pop();
    return true;
}
```

### pthread 读写锁

```cpp
#include <pthread.h>
#include <system_error>
#include <map>
#include <string>

class ReadWriteLock {
public:
    void read_lock() {
        pthread_rwlock_rdlock(&rwlock_);
    }

    void write_lock() {
        pthread_rwlock_wrlock(&rwlock_);
    }

    void unlock() {
        pthread_rwlock_unlock(&rwlock_);
    }

    ~ReadWriteLock() {
        pthread_rwlock_destroy(&rwlock_);
    }

private:
    pthread_rwlock_t rwlock_ = PTHREAD_RWLOCK_INITIALIZER;
};

class ConfigStore {
public:
    std::string get(const std::string& key) {
        ReadLock lock(rwlock_);
        auto it = data_.find(key);
        if (it != data_.end()) return it->second;
        return "";
    }

    void set(const std::string& key, const std::string& value) {
        WriteLock lock(rwlock_);
        data_[key] = value;
    }

private:
    ReadWriteLock rwlock_;
    std::map<std::string, std::string> data_;
};
```

### 线程局部存储 (TLS)

```cpp
#include <pthread.h>
#include <cstdlib>
#include <ctime>

// C++11 thread_local (推荐)
thread_local std::time_t last_time = 0;

void process_request() {
    last_time = time(nullptr);  // 每个线程独立
}

// pthread key (C 兼容)
pthread_key_t thread_log_key;

void init_thread_log() {
    pthread_key_create(&thread_log_key, [](void* ptr) {
        // 线程退出时调用，清理资源
        if (ptr) free(ptr);
    });
}

void set_thread_log(FILE* log) {
    pthread_setspecific(thread_log_key, log);
}

FILE* get_thread_log() {
    return static_cast<FILE*>(pthread_getspecific(thread_log_key));
}
```

### 线程规则

```
使用 std::mutex 或 RAII 锁守卫管理互斥锁
条件变量必须与互斥锁一起使用
读写锁适用于读多写少场景
线程入口函数必须处理异常，或用 noexcept
使用 thread_local 存储线程本地数据
线程栈大小默认 8MB，注意不要用大对象

绝不使用 mutex 的 try_lock 代替正确设计
绝不在持有锁时做阻塞操作
绝不使用 select 在多线程中代替条件变量
绝不忽略 pthread_create 的返回值
绝不使用 bare pthread API 而不 RAII 封装
```

---

## 5. 内存管理 (高)

### malloc / free

```cpp
#include <cstdlib>
#include <cstddef>
#include <cstring>
#include <system_error>

// 分配内存
void* ptr = std::malloc(1024);
if (!ptr) throw std::bad_alloc();  // malloc 返回 nullptr 表示失败

// 释放内存
std::free(ptr);

// 分配并初始化为 0
void* ptr = std::calloc(1024, sizeof(int));

// 重新分配
void* new_ptr = std::realloc(old_ptr, new_size);
if (!new_ptr) {
    // 失败时 old_ptr 仍然有效，必须手动释放
    std::free(old_ptr);
    throw std::bad_alloc();
}
```

### mmap / munmap 内存映射

```cpp
#include <sys/mman.h>
#include <unistd.h>
#include <fcntl.h>
#include <system_error>
#include <cstddef>

// 匿名映射 (相当于 malloc，但可指定大小)
void* ptr = mmap(nullptr, 4096, PROT_READ | PROT_WRITE,
                 MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
if (ptr == MAP_FAILED) throw std::system_error(errno, std::generic_category(), "mmap");
munmap(ptr, 4096);

// 文件映射
int fd = open("file.bin", O_RDONLY);
if (fd < 0) throw std::system_error(errno, std::generic_category(), "open");

struct stat st;
if (fstat(fd, &st) < 0) throw std::system_error(errno, std::generic_category(), "fstat");

void* ptr = mmap(nullptr, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
if (ptr == MAP_FAILED) throw std::system_error(errno, std::generic_category(), "mmap");
close(fd);  // 映射后可以关闭 fd

// 写时复制映射 (适合 fork 前准备数据)
void* ptr = mmap(nullptr, size, PROT_READ | PROT_WRITE,
                 MAP_PRIVATE, fd, 0);

// 共享映射 (多进程共享)
void* ptr = mmap(nullptr, size, PROT_READ | PROT_WRITE,
                 MAP_SHARED, fd, 0);
```

### mprotect 修改保护

```cpp
#include <sys/mman.h>

// 改变映射区域的保护
void* ptr = mmap(nullptr, 4096, PROT_READ | PROT_WRITE,
                 MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);

// 改为只读
if (mprotect(ptr, 4096, PROT_READ) < 0)
    throw std::system_error(errno, std::generic_category(), "mprotect");

// 改为读写
if (mprotect(ptr, 4096, PROT_READ | PROT_WRITE) < 0)
    throw std::system_error(errno, std::generic_category(), "mprotect");
```

### brk / sbrk (legacy)

```cpp
#include <unistd.h>

// sbrk 增加/减少程序 break
void* old_brk = sbrk(0);  // 获取当前 break
void* new_brk = sbrk(4096);  // 增加 4096 bytes

// 恢复 break (释放内存)
sbrk(-4096);  // 恢复原状
```

### 内存分配规则

```
malloc 返回 nullptr 表示失败，必须检查
free 只能释放由 malloc/calloc/realloc 分配的内存，且只一次
mmap 映射的区域用 munmap 释放，不能用 free
内存映射文件关闭 fd 后映射仍然有效
使用 mlock/munlock 锁定物理内存，防止换页

绝不使用已释放的内存 (use-after-free)
绝不复用已经 free 的指针
绝不 free/munmap 两次
绝不用 malloc 分配巨大内存 (用 mmap)
```

---

## 6. 信号处理 (高)

### signal vs sigaction

```cpp
#include <signal.h>
#include <unistd.h>
#include <cstdlib>

// signal() - 简单但不保证语义 (不要使用!)
::signal(SIGINT, [](int) { /* 可能重置为默认行为 */ });

// sigaction() - 可靠信号，推荐使用
struct sigaction sa;
sa.sa_handler = [](int sig) {
    // 注意: async-signal-safe 函数才能在这里使用
    // _exit() 是安全的
    _exit(128 + sig);
};
sigemptyset(&sa.sa_mask);
sa.sa_flags = 0;  // 或 SA_RESTART 自动重启系统调用

if (sigaction(SIGINT, &sa, nullptr) < 0)
    throw std::system_error(errno, std::generic_category(), "sigaction");
```

### async-signal-safe 函数

```cpp
// 可在信号处理函数中安全调用的函数:
// _exit(), _exit(), _exit()
// write() - 注意缓冲区
// read() - 注意死锁
// open(), close()
// signal() - 不可重入，但可设置另一个处理函数
// getpid()

// 不可在信号处理函数中调用:
// printf(), fprintf(), std::cout (缓冲 I/O)
// malloc(), free(), new, delete
// 大部分 libc 函数

// 安全的消息传递: self-pipe
int pipe_fd[2];
::pipe(pipe_fd);

void signal_handler(int sig) {
    char c = sig;  // 发送信号编号
    ::write(pipe_fd[1], &c, 1);  // write 是安全的
}
```

### 信号等待

```cpp
#include <signal.h>
#include <cstring>

// sigwaitinfo() - 同步等待信号
sigset_t mask;
sigemptyset(&mask);
sigaddset(&mask, SIGINT);
sigaddset(&mask, SIGTERM);
pthread_sigmask(SIG_BLOCK, &mask, nullptr);  // 阻塞信号

while (running) {
    siginfo_t info;
    int sig = sigwaitinfo(&mask, &info);
    if (sig < 0) continue;
    if (sig == SIGINT || sig == SIGTERM) {
        running = false;
    }
}

// sigtimedwait() - 带超时
timespec ts = { .tv_sec = 1, .tv_nsec = 0 };
siginfo_t info;
int sig = sigtimedwait(&mask, &info, &ts);
```

### 信号规则

```
使用 sigaction() 而非 signal()
在信号处理函数中使用 async-signal-safe 函数
用 self-pipe 或 eventfd 替代信号处理复杂逻辑
pthread_sigmask() 在新线程中阻塞信号，主线程用 sigwaitinfo()
SA_RESTART 自动重启阻塞的系统调用，但非阻塞 I/O 不会

绝不在信号处理函数中使用 printf、malloc
绝不使用 signal() (行为不确定)
绝不假设信号处理函数可重入
绝不混淆 kill() (发送信号) 和 raise() (给自己发)
```

---

## 7. 进程间通信 (高)

### pipe 匿名管道

```cpp
#include <unistd.h>
#include <cstddef>
#include <cstring>
#include <sys/wait.h>

int pipe_fd[2];
if (::pipe(pipe_fd) < 0) throw std::system_error(errno, std::generic_category(), "pipe");

pid_t pid = fork();
if (pid == 0) {
    // 子进程关闭读端
    close(pipe_fd[0]);
    // 写入管道
    const char* msg = "Hello from child";
    ::write(pipe_fd[1], msg, strlen(msg));
    close(pipe_fd[1]);
    _exit(0);
}

// 父进程关闭写端
close(pipe_fd[1]);
char buf[256];
ssize_t n = ::read(pipe_fd[0], buf, sizeof(buf));
if (n > 0) {
    buf[n] = '\0';
    // 处理数据
}
close(pipe_fd[0]);

int status;
waitpid(pid, &status, 0);
```

### popen / pclose

```cpp
#include <cstdio>

// 读取命令输出
FILE* fp = ::popen("ls -la", "r");
if (!fp) throw std::runtime_error("popen failed");

char buf[256];
while (fgets(buf, sizeof(buf), fp)) {
    // 处理输出行
}
int status = ::pclose(fp);
if (status < 0) throw std::runtime_error("pclose failed");

// 写入命令输入
FILE* fp = ::popen("wc -l", "w");
if (!fp) throw std::runtime_error("popen failed");
fprintf(fp, "line1\nline2\nline3\n");
int status = ::pclose(fp);
```

### FIFO 命名管道

```cpp
#include <sys/stat.h>
#include <unistd.h>
#include <cstdio>

// 创建 FIFO
if (mkfifo("/tmp/my_fifo", 0666) < 0 && errno != EEXIST)
    throw std::system_error(errno, std::generic_category(), "mkfifo");

// 打开 FIFO (可能阻塞直到对方也打开)
int fd = open("/tmp/my_fifo", O_RDONLY);  // 读端
int fd = open("/tmp/my_fifo", O_WRONLY);  // 写端

// 注意: O_RDWR 不会阻塞 (但读写语义不同)
```

### Unix Domain Socket

```cpp
#include <sys/socket.h>
#include <sys/un.h>
#include <cstring>
#include <unistd.h>

// 创建 Unix Domain Socket
int sockfd = socket(AF_UNIX, SOCK_STREAM, 0);
if (sockfd < 0) throw std::system_error(errno, std::generic_category(), "socket");

// 绑定到路径
sockaddr_un addr;
addr.sun_family = AF_UNIX;
strncpy(addr.sun_path, "/tmp/my_socket", sizeof(addr.sun_path) - 1);
unlink(addr.sun_path);  // 删除旧文件

if (bind(sockfd, (sockaddr*)&addr, sizeof(addr)) < 0)
    throw std::system_error(errno, std::generic_category(), "bind");

listen(sockfd, 5);

// 接受连接
int client_fd = accept(sockfd, nullptr, nullptr);
if (client_fd < 0) throw std::system_error(errno, std::generic_category(), "accept");

// 发送/接收数据
send(client_fd, "hello", 5, 0);
recv(client_fd, buf, sizeof(buf), 0);

close(client_fd);
close(sockfd);
unlink("/tmp/my_socket");
```

### Shared Memory (System V)

```cpp
#include <sys/shm.h>
#include <sys/stat.h>
#include <cstring>

// 创建共享内存段
int shmid = shmget(IPC_PRIVATE, 4096, IPC_CREAT | 0666);
if (shmid < 0) throw std::system_error(errno, std::generic_category(), "shmget");

// 附加到进程地址空间
void* addr = shmat(shmid, nullptr, 0);
if (addr == (void*)-1) throw std::system_error(errno, std::generic_category(), "shmat");

// 使用共享内存...

// 分离
if (shmdt(addr) < 0) throw std::system_error(errno, std::generic_category(), "shmdt");

// 控制共享内存
shmid_ds stat;
if (shmctl(shmid, IPC_STAT, &stat) < 0) throw std::system_error(errno, std::generic_category(), "shmctl");
if (shmctl(shmid, IPC_RMID, nullptr) < 0) throw std::system_error(errno, std::generic_category(), "shmctl");
```

### Shared Memory (POSIX)

```cpp
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <cstring>

// 创建共享内存对象
int fd = shm_open("/my_shm", O_CREAT | O_RDWR, 0666);
if (fd < 0) throw std::system_error(errno, std::generic_category(), "shm_open");

// 设置大小
if (ftruncate(fd, 4096) < 0) throw std::system_error(errno, std::generic_category(), "ftruncate");

// 映射到进程地址空间
void* addr = mmap(nullptr, 4096, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
if (addr == MAP_FAILED) throw std::system_error(errno, std::generic_category(), "mmap");

close(fd);

// 使用共享内存...

munmap(addr, 4096);
shm_unlink("/my_shm");
```

### Message Queue (POSIX)

```cpp
#include <mqueue.h>
#include <cstring>
#include <cstdlib>

// 打开/创建消息队列
mqd_t mq = mq_open("/my_mq", O_CREAT | O_RDWR, 0666, nullptr);
if (mq < 0) throw std::system_error(errno, std::generic_category(), "mq_open");

// 发送消息
const char* msg = "Hello";
if (mq_send(mq, msg, strlen(msg), 0) < 0)
    throw std::system_error(errno, std::generic_category(), "mq_send");

// 接收消息
char buf[8192];
unsigned prio;
ssize_t n = mq_receive(mq, buf, sizeof(buf), &prio);
if (n < 0) throw std::system_error(errno, std::generic_category(), "mq_receive");

mq_close(mq);
mq_unlink("/my_mq");
```

### IPC 规则

```
pipe 用于有亲缘关系的进程 (父子、兄弟)
FIFO 用于无亲缘关系的进程 (需要文件系统路径)
Unix Domain Socket 功能最全，支持 stream 和 datagram
共享内存最快，但需要同步 (信号量或互斥锁)
消息队列适合消息边界明确的场景

绝不使用过时的 System V IPC (优先 POSIX)
绝不在共享内存不使用同步原语
绝不用 pipe 传递文件描述符 (用 sendmsg/recvmsg)
```

---

## 8. 网络编程 (高)

### TCP 服务器

```cpp
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <cstring>
#include <cstdlib>
#include <cstdio>
#include <poll.h>

class TcpServer {
public:
    TcpServer(uint16_t port) : port_(port) {}

    void start() {
        // 创建 socket
        server_fd_ = ::socket(AF_INET, SOCK_STREAM, 0);
        if (server_fd_ < 0) throw std::system_error(errno, std::generic_category(), "socket");

        // 设置 SO_REUSEADDR
        int opt = 1;
        setsockopt(server_fd_, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

        // 绑定地址
        sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = INADDR_ANY;
        addr.sin_port = htons(port_);

        if (bind(server_fd_, (sockaddr*)&addr, sizeof(addr)) < 0)
            throw std::system_error(errno, std::generic_category(), "bind");

        // 监听
        if (listen(server_fd_, 128) < 0)
            throw std::system_error(errno, std::generic_category(), "listen");

        printf("Server listening on port %d\n", port_);
    }

    void run() {
        while (running_) {
            sockaddr_in client_addr;
            socklen_t client_len = sizeof(client_addr);
            int client_fd = accept(server_fd_, (sockaddr*)&client_addr, &client_len);
            if (client_fd < 0) {
                if (errno == EINTR) continue;
                perror("accept");
                continue;
            }

            char client_ip[INET_ADDRSTRLEN];
            inet_ntop(AF_INET, &client_addr.sin_addr, client_ip, sizeof(client_ip));
            printf("Client connected: %s:%d\n", client_ip, ntohs(client_addr.sin_port));

            handle_client(client_fd);
        }
    }

    void stop() { running_ = false; }

private:
    void handle_client(int client_fd) {
        char buf[1024];
        while (true) {
            ssize_t n = read(client_fd, buf, sizeof(buf));
            if (n <= 0) break;
            write_all(client_fd, buf, n);
        }
        close(client_fd);
    }

    ssize_t write_all(int fd, const void* buf, size_t count) {
        const char* ptr = static_cast<const char*>(buf);
        while (count > 0) {
            ssize_t n = write(fd, ptr, count);
            if (n < 0) {
                if (errno == EINTR) continue;
                return -1;
            }
            ptr += n;
            count -= n;
        }
        return 0;
    }

    int server_fd_ = -1;
    uint16_t port_;
    bool running_ = true;
};
```

### epoll 高并发服务器

```cpp
#include <sys/epoll.h>
#include <unistd.h>
#include <vector>
#include <cstring>

class EpollServer {
public:
    EpollServer(uint16_t port) : port_(port) {}

    void start() {
        server_fd_ = socket(AF_INET, SOCK_STREAM, 0);
        if (server_fd_ < 0) throw std::system_error(errno, std::generic_category(), "socket");

        int opt = 1;
        setsockopt(server_fd_, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

        sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = INADDR_ANY;
        addr.sin_port = htons(port_);
        bind(server_fd_, (sockaddr*)&addr, sizeof(addr));
        listen(server_fd_, 128);

        epoll_fd_ = epoll_create1(0);
        if (epoll_fd_ < 0) throw std::system_error(errno, std::generic_category(), "epoll_create1");

        epoll_event ev;
        ev.events = EPOLLIN;
        ev.data.fd = server_fd_;
        if (epoll_ctl(epoll_fd_, EPOLL_CTL_ADD, server_fd_, &ev) < 0)
            throw std::system_error(errno, std::generic_category(), "epoll_ctl");
    }

    void run() {
        std::vector<epoll_event> events(1024);
        while (true) {
            int n = epoll_wait(epoll_fd_, events.data(), events.size(), -1);
            if (n < 0) {
                if (errno == EINTR) continue;
                break;
            }

            for (int i = 0; i < n; ++i) {
                int fd = events[i].data.fd;
                if (fd == server_fd_) {
                    // 新连接
                    sockaddr_in client_addr;
                    socklen_t len = sizeof(client_addr);
                    int client_fd = accept(server_fd_, (sockaddr*)&client_addr, &len);
                    if (client_fd >= 0) {
                        add_client(client_fd);
                    }
                } else {
                    // 客户端数据
                    if (events[i].events & (EPOLLERR | EPOLLHUP)) {
                        remove_client(fd);
                    } else if (events[i].events & EPOLLIN) {
                        handle_client(fd);
                    }
                }
            }
        }
    }

private:
    void add_client(int fd) {
        epoll_event ev;
        ev.events = EPOLLIN | EPOLLET;  // 边缘触发
        ev.data.fd = fd;
        epoll_ctl(epoll_fd_, EPOLL_CTL_ADD, fd, &ev);
    }

    void remove_client(int fd) {
        epoll_ctl(epoll_fd_, EPOLL_CTL_DEL, fd, nullptr);
        close(fd);
    }

    void handle_client(int fd) {
        char buf[4096];
        ssize_t n = read(fd, buf, sizeof(buf));
        if (n > 0) {
            write(fd, buf, n);  // 回显
        } else if (n == 0) {
            remove_client(fd);
        }
    }

    int server_fd_ = -1;
    int epoll_fd_ = -1;
    uint16_t port_;
};
```

### UDP 客户端

```cpp
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <cstring>
#include <unistd.h>

class UdpClient {
public:
    UdpClient(const char* server_ip, uint16_t server_port)
        : server_ip_(server_ip), server_port_(server_port) {

        fd_ = socket(AF_INET, SOCK_DGRAM, 0);
        if (fd_ < 0) throw std::system_error(errno, std::generic_category(), "socket");

        memset(&server_addr_, 0, sizeof(server_addr_));
        server_addr_.sin_family = AF_INET;
        server_addr_.sin_port = htons(server_port);
        inet_pton(AF_INET, server_ip_, &server_addr_.sin_addr);
    }

    ssize_t send(const void* buf, size_t len) {
        return sendto(fd_, buf, len, 0, (sockaddr*)&server_addr_, sizeof(server_addr_));
    }

    ssize_t receive(void* buf, size_t len) {
        sockaddr_in from;
        socklen_t from_len = sizeof(from);
        return recvfrom(fd_, buf, len, 0, (sockaddr*)&from, &from_len);
    }

    ~UdpClient() { close(fd_); }

private:
    int fd_;
    const char* server_ip_;
    uint16_t server_port_;
    sockaddr_in server_addr_;
};
```

### 网络编程规则

```
使用 socketpair 进行 Unix Domain Socket 通信
使用 SO_REUSEADDR 允许服务器快速重启
非阻塞 I/O 使用 poll/epoll，不要用 select
边缘触发 (EPOLLET) 配合非阻塞 fd 使用
使用 getaddrinfo() 获取地址，支持 IPv6

绝不使用 select 管理超过 1024 个 fd
绝不使用 getsockopt/setsockopt 的已废弃选项
绝不在主循环中同步 DNS 查询
```

---

## 9. 文件系统 (中)

### stat / fstat / lstat

```cpp
#include <sys/stat.h>
#include <unistd.h>
#include <cstddef>

struct stat st;
if (stat("/path/to/file", &st) < 0)
    throw std::system_error(errno, std::generic_category(), "stat");

// 检查文件类型
if (S_ISREG(st.st_mode))    // 普通文件
if (S_ISDIR(st.st_mode))    // 目录
if (S_ISLNK(st.st_mode))    // 符号链接
if (S_ISCHR(st.st_mode))    // 字符设备
if (S_ISBLK(st.st_mode))    // 块设备
if (S_ISFIFO(st.st_mode))   // FIFO
if (S_ISSOCK(st.st_mode))   // Socket

// st_mode 位掩码
st.st_mode & S_IRWXU  // 所有者读写执行
st.st_mode & S_IRWXG  // 组读写执行
st.st_mode & S_IRWXO  // 其他读写执行
```

### access / faccessat 权限检查

```cpp
#include <unistd.h>

// 检查文件是否可读/写/执行
if (access("/path/to/file", R_OK) < 0) { /* 不可读 */ }
if (access("/path/to/file", W_OK) < 0) { /* 不可写 */ }
if (access("/path/to/file", X_OK) < 0) { /* 不可执行 */ }

// F_OK 检查文件是否存在
if (access("/path/to/file", F_OK) < 0) { /* 不存在 */ }
```

### 目录操作

```cpp
#include <dirent.h>
#include <cstring>

// 打开目录
DIR* dir = opendir("/path/to/dir");
if (!dir) throw std::system_error(errno, std::generic_category(), "opendir");

// 读取目录项
struct dirent* entry;
while ((entry = readdir(dir)) != nullptr) {
    // entry->d_name 是文件名
    // entry->d_type 是文件类型 (DT_REG, DT_DIR, DT_LNK, etc.)
    if (entry->d_name[0] != '.') {  // 跳过隐藏文件
        printf("%s\n", entry->d_name);
    }
}

closedir(dir);

// 创建目录
if (mkdir("/path/to/new_dir", 0755) < 0)
    throw std::system_error(errno, std::generic_category(), "mkdir");

// 递归创建目录
void mkdir_recursive(const char* path) {
    char tmp[1024];
    strncpy(tmp, path, sizeof(tmp) - 1);
    tmp[sizeof(tmp) - 1] = '\0';

    for (char* p = tmp + 1; *p; ++p) {
        if (*p == '/') {
            *p = '\0';
            mkdir(tmp, 0755);
            *p = '/';
        }
    }
    mkdir(tmp, 0755);
}

// 删除目录 (必须为空)
if (rmdir("/path/to/empty_dir") < 0)
    throw std::system_error(errno, std::generic_category(), "rmdir");
```

### 文件系统规则

```
使用 stat() 检查文件类型和权限
access() 检查实际用户权限 (非 effective)
使用 opendir/readdir/closedir 遍历目录
mkdir() 创建目录，rmdir() 删除空目录
使用 rename() 原子性重命名文件

绝不使用 ls 的输出来判断文件存在性
绝不使用 access() 判断打开文件权限 (竞态)
```

---

## 10. 时间与定时 (中)

### time / gettimeofday / clock_gettime

```cpp
#include <ctime>
#include <sys/time.h>
#include <cstring>

// time_t (秒)
time_t now = time(nullptr);
printf("Current time: %s", ctime(&now));

// struct timeval (微秒)
struct timeval tv;
if (gettimeofday(&tv, nullptr) < 0)
    throw std::system_error(errno, std::generic_category(), "gettimeofday");
printf("Seconds: %ld, Microseconds: %ld\n", tv.tv_sec, tv.tv_usec);

// struct timespec (纳秒) - 推荐
struct timespec ts;
if (clock_gettime(CLOCK_REALTIME, &ts) < 0)
    throw std::system_error(errno, std::generic_category(), "clock_gettime");
printf("Seconds: %ld, Nanoseconds: %ld\n", ts.tv_sec, ts.tv_nsec);

// CLOCK_MONOTONIC - 系统启动后单调递增，不受时钟调整影响
struct timespec mono;
clock_gettime(CLOCK_MONOTONIC, &mono);

// CLOCK_PROCESS_CPUTIME_ID - 进程 CPU 时间
struct timespec cpu;
clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &cpu);
```

### sleep / nanosleep / usleep

```cpp
#include <unistd.h>
#include <time.h>
#include <cstring>

// sleep (秒) - 可能被信号中断
unsigned int seconds = sleep(1);  // 返回剩余秒数

// nanosleep (纳秒) - 高精度，可靠
struct timespec req = { .tv_sec = 0, .tv_nsec = 500'000'000 };  // 500ms
struct timespec rem;
while (nanosleep(&req, &rem) < 0) {
    if (errno == EINTR) {
        req = rem;  // 被信号中断，重试剩余时间
    } else {
        throw std::system_error(errno, std::generic_category(), "nanosleep");
    }
}

// clock_nanosleep - 使用特定时钟
struct timespec ts;
clock_gettime(CLOCK_MONOTONIC, &ts);
ts.tv_sec += 1;  // 1秒后
clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &ts, nullptr);
```

### 定时器 (timerfd)

```cpp
#include <sys/timerfd.h>
#include <cinttypes>
#include <cstdlib>

// 创建定时器文件描述符
int timer_fd = timerfd_create(CLOCK_MONOTONIC, 0);
if (timer_fd < 0) throw std::system_error(errno, std::generic_category(), "timerfd_create");

// 设置定时器 (周期性地触发)
struct itimerspec its;
its.it_value.tv_sec = 1;      // 首次触发: 1秒后
its.it_value.tv_nsec = 0;
its.it_interval.tv_sec = 1;   // 周期: 1秒
its.it_interval.tv_nsec = 0;

if (timerfd_settime(timer_fd, 0, &its, nullptr) < 0)
    throw std::system_error(errno, std::generic_category(), "timerfd_settime");

// 读取定时器到期次数 (可用于 epoll)
uint64_t expirations;
read(timer_fd, &expirations, sizeof(expirations));
printf("Timer expired %" PRIu64 " times\n", expirations);

close(timer_fd);
```

### 时间规则

```
使用 clock_gettime(CLOCK_REALTIME) 获取当前时间
使用 CLOCK_MONOTONIC 计算时间间隔 (不受时钟调整影响)
使用 nanosleep 代替 sleep (高精度，不被信号中断)
使用 timerfd 创建定时器，可集成到 epoll

绝不依赖 time() 的秒级精度做精确计时
绝不使用 gettimeofday() 计算时间间隔 (可能被 NTP 调整)
```

---

## 11. 错误处理与日志 (高)

### errno 与错误码

```cpp
#include <cerrno>
#include <system_error>
#include <cstring>
#include <string>

// 系统调用错误处理
int fd = open("/path", O_RDONLY);
if (fd < 0) {
    throw std::system_error(errno, std::generic_category(), "open: " + std::string("/path"));
}

// 自定义错误码
enum class ErrorCode {
    Success = 0,
    NotFound = 1,
    PermissionDenied = 2,
    InvalidArgument = 3,
    SystemError = 4,
};

class Error : public std::exception {
public:
    Error(ErrorCode code, const std::string& msg)
        : code_(code), msg_(msg) {}

    const char* what() const noexcept override {
        return msg_.c_str();
    }

    ErrorCode code() const { return code_; }

private:
    ErrorCode code_;
    std::string msg_;
};

// 使用示例
if (some_condition) {
    throw Error(ErrorCode::NotFound, "Resource not found: " + path);
}

// 从 errno 转换为错误码
ErrorCode from_errno() {
    switch (errno) {
        case ENOENT: return ErrorCode::NotFound;
        case EACCES: return ErrorCode::PermissionDenied;
        case EINVAL: return ErrorCode::InvalidArgument;
        default: return ErrorCode::SystemError;
    }
}
```

### 结构化日志

```cpp
#include <ctime>
#include <cstdio>
#include <cstdarg>
#include <pthread.h>
#include <unistd.h>

enum class LogLevel {
    DEBUG,
    INFO,
    WARN,
    ERROR,
};

class Logger {
public:
    static Logger& instance() {
        static Logger logger;
        return logger;
    }

    void log(LogLevel level, const char* fmt, ...) {
        if (level < min_level_) return;

        timespec ts;
        clock_gettime(CLOCK_REALTIME, &ts);

        char timestamp[64];
        strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S",
                 localtime(&ts.tv_sec));
        char ms[16];
        snprintf(ms, sizeof(ms), "%03ld", ts.tv_nsec / 1'000'000);

        pthread_t tid = pthread_self();

        FILE* fp = (level >= LogLevel::ERROR) ? stderr : stdout;
        fprintf(fp, "[%s.%s] [%d] [%s] ",
                timestamp, ms, tid, level_string(level));

        va_list args;
        va_start(args, fmt);
        vfprintf(fp, fmt, args);
        va_end(args);

        fprintf(fp, "\n");
        fflush(fp);
    }

    void set_level(LogLevel level) { min_level_ = level; }

private:
    Logger() : min_level_(LogLevel::INFO) {}

    const char* level_string(LogLevel level) {
        switch (level) {
            case LogLevel::DEBUG: return "DEBUG";
            case LogLevel::INFO: return "INFO ";
            case LogLevel::WARN: return "WARN ";
            case LogLevel::ERROR: return "ERROR";
        }
        return "UNKNOWN";
    }

    LogLevel min_level_;
};

#define LOG_DEBUG(fmt, ...) Logger::instance().log(LogLevel::DEBUG, fmt, ##__VA_ARGS__)
#define LOG_INFO(fmt, ...) Logger::instance().log(LogLevel::INFO, fmt, ##__VA_ARGS__)
#define LOG_WARN(fmt, ...) Logger::instance().log(LogLevel::WARN, fmt, ##__VA_ARGS__)
#define LOG_ERROR(fmt, ...) Logger::instance().log(LogLevel::ERROR, fmt, ##__VA_ARGS__)
```

### 错误处理规则

```
所有系统调用必须检查返回值
错误时设置 errno，系统调用返回 -1 或 nullptr
使用 std::system_error 抛出异常
使用结构化日志记录错误 (时间戳、级别、线程 ID、上下文)
使用 RAII 封装资源，确保异常安全

绝不在错误路径上忽略返回值
绝不使用 printf 而非日志系统
绝不在错误消息中泄露敏感信息
```

---

## 12. 环境与资源限制 (中)

### getenv / setenv

```cpp
#include <cstdlib>
#include <cstring>

// 读取环境变量
const char* path = std::getenv("PATH");
if (!path) throw std::runtime_error("PATH not set");

// 设置环境变量
if (setenv("MY_VAR", "value", 1) < 0)
    throw std::system_error(errno, std::generic_category(), "setenv");

// 删除环境变量
unsetenv("MY_VAR");

// 遍历所有环境变量
extern char** environ;
for (char** env = environ; *env; ++env) {
    printf("%s\n", *env);
}
```

### getrlimit / setrlimit

```cpp
#include <sys/resource.h>
#include <cstdio>

// 获取资源限制
struct rlimit rl;
if (getrlimit(RLIMIT_NOFILE, &rl) < 0)
    throw std::system_error(errno, std::generic_category(), "getrlimit");
printf("Soft limit: %lu, Hard limit: %lu\n", rl.rlim_cur, rl.rlim_max);

// 修改资源限制
struct rlimit new_rl;
new_rl.rlim_cur = 1024;  // 软限制
new_rl.rlim_max = 4096;  // 硬限制
if (setrlimit(RLIMIT_NOFILE, &new_rl) < 0)
    throw std::system_error(errno, std::generic_category(), "setrlimit");

// 常见资源类型
RLIMIT_NOFILE   // 打开文件描述符数量
RLIMIT_NPROC    // 进程数量
RLIMIT_CPU      // CPU 时间 (秒)
RLIMIT_FSIZE    // 文件大小 (字节)
RLIMIT_AS       // 地址空间 (字节)
RLIMIT_STACK    // 栈大小 (字节)
RLIMIT_CORE     // core 文件大小
```

### getpagesize

```cpp
#include <unistd.h>

// 获取系统页大小
long page_size = sysconf(_SC_PAGESIZE);
printf("Page size: %ld bytes\n", page_size);

// 获取时钟频率
long tick = sysconf(_SC_CLK_TCK);
printf("Clock tick: %ld Hz\n", tick);
```

---

## 反模式

| # | 不要 | 要做 |
|---|------|------|
| 1 | 直接使用 open/fork/pthread 等裸 API | RAII 封装文件描述符、互斥锁 |
| 2 | 忽略系统调用返回值 | 检查并处理错误 |
| 3 | fork 后不 wait | wait/waitpid 回收子进程 |
| 4 | signal() 处理信号 | sigaction() 可靠信号 |
| 5 | printf in signal handler | async-signal-safe 函数 |
| 6 | select() 管理大量 fd | poll() 或 epoll() |
| 7 | malloc 后不检查 nullptr | 检查分配结果 |
| 8 | 忘记 close(fd) | RAII 自动关闭 |
| 9 | time() 计算时间间隔 | clock_gettime(CLOCK_MONOTONIC) |
| 10 | 混用 fopen 和 open | 只用一种 |
| 11 | 使用 getsockopt 已废弃选项 | 使用现代 socket API |
| 12 | 非阻塞 connect 不处理 EINPROGRESS | 检查并使用 poll/epoll |

---

## 常见问题

### 问题 1: "如何选择 IPC 方式?"

**考虑因素:**

| 方式 | 延迟 | 复杂度 | 适用场景 |
|------|------|--------|----------|
| pipe | 低 | 低 | 父子进程通信 |
| socketpair | 低 | 低 | 相关进程双向通信 |
| FIFO | 低 | 中 | 无亲缘关系进程 |
| Unix Domain Socket | 低 | 中 | 全功能 IPC |
| Message Queue | 中 | 中 | 消息队列模式 |
| Shared Memory | 最低 | 高 | 高性能数据共享 |

### 问题 2: "epoll vs select vs poll?"

**规则:**
- fd < 1000: select 可接受
- fd < 1024: poll 可接受
- fd > 1024 或高并发: epoll (边缘触发模式)
- 需要同时等待多种事件: poll 或 epoll

### 问题 3: "多线程还是多进程?"

**规则:**
- 共享数据多: 多线程 (共享地址空间)
- 需要隔离: 多进程 (独立地址空间)
- 任务简单: 多线程 (开销小)
- 稳定性要求高: 多进程 (一个崩溃不影响其他)

### 问题 4: "如何调试系统编程问题?"

**工具:**
- `strace -f ./program`: 跟踪所有系统调用
- `ltrace -f ./program`: 跟踪库调用
- `lsof -p PID`: 查看进程打开的文件
- `cat /proc/PID/fd`: 查看文件描述符
- `valgrind --leak-check=full ./program`: 检查内存泄漏
- `dstat`, `top`, `htop`: 查看系统资源

---

## 参考文档

此技能包含专业主题的深度参考。需要详细指导时阅读相关参考。

| 需要… | 参考 |
|-------|------|
| 系统调用快速参考 | [references/system-call-quick-ref.md](references/system-call-quick-ref.md) |
| POSIX 线程编程指南 | [references/posix-threads-guide.md](references/posix-threads-guide.md) |
| IPC 模式详解 | [references/ipc-patterns.md](references/ipc-patterns.md) |
| 网络编程深度指南 | [references/network-programming.md](references/network-programming.md) |
| 文件 I/O 高级技术 | [references/file-io-techniques.md](references/file-io-techniques.md) |
