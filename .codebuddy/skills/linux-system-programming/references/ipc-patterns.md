# 进程间通信 (IPC) 模式

## IPC 方式对比

| 方式 | 延迟 | 数据结构 | 同步方式 | 适用范围 |
|------|------|----------|----------|----------|
| pipe | 低 | 字节流 | 内核缓冲 | 父子/兄弟进程 |
| socketpair | 低 | 字节流 | 内核缓冲 | 相关进程 |
| FIFO | 低 | 字节流 | 内核缓冲 | 无亲缘关系进程 |
| Unix Domain Socket | 低 | 字节流/数据报 | 内核缓冲 | 全功能 IPC |
| Message Queue (POSIX) | 中 | 消息 | 内核缓冲 | 消息队列模式 |
| Shared Memory | 最低 | 任意 | 需自行实现 | 高性能共享 |
| Signal | 最低 | 单字节 | 异步 | 通知/信号 |

---

## pipe 管道

### 基础 pipe

```cpp
#include <unistd.h>
#include <sys/wait.h>
#include <cstdio>
#include <cstring>

// 创建管道
int pipe_fd[2];
if (pipe(pipe_fd) < 0) {
    perror("pipe");
    return -1;
}

// fork
pid_t pid = fork();
if (pid < 0) {
    perror("fork");
    return -1;
}

if (pid == 0) {
    // 子进程关闭读端，写入数据
    close(pipe_fd[0]);
    const char* msg = "Hello from child";
    write(pipe_fd[1], msg, strlen(msg));
    close(pipe_fd[1]);
    _exit(0);
} else {
    // 父进程关闭写端，读取数据
    close(pipe_fd[1]);
    char buf[256];
    ssize_t n = read(pipe_fd[0], buf, sizeof(buf));
    if (n > 0) {
        buf[n] = '\0';
        printf("Parent received: %s\n", buf);
    }
    close(pipe_fd[0]);
    wait(nullptr);
}
```

### pipe 双向通信 (需要两个 pipe)

```cpp
// 父进程到子进程
int p2c_pipe[2];
// 子进程到父进程
int c2p_pipe[2];
pipe(p2c_pipe);
pipe(c2p_pipe);

pid_t pid = fork();
if (pid == 0) {
    // 子进程
    close(p2c_pipe[1]);   // 关闭写端
    close(c2p_pipe[0]);    // 关闭读端

    char buf[256];
    read(p2c_pipe[0], buf, sizeof(buf));
    printf("Child received: %s\n", buf);

    const char* response = "Hello parent";
    write(c2p_pipe[1], response, strlen(response));

    close(p2c_pipe[0]);
    close(c2p_pipe[1]);
    _exit(0);
} else {
    // 父进程
    close(p2c_pipe[0]);
    close(c2p_pipe[1]);

    const char* msg = "Hello child";
    write(p2c_pipe[1], msg, strlen(msg));

    char buf[256];
    read(c2p_pipe[0], buf, sizeof(buf));
    printf("Parent received: %s\n", buf);

    close(p2c_pipe[1]);
    close(c2p_pipe[0]);
    wait(nullptr);
}
```

---

## socketpair

### 基础 socketpair

```cpp
#include <sys/socket.h>
#include <unistd.h>
#include <cstdio>

int sv[2];
if (socketpair(AF_UNIX, SOCK_STREAM, 0, sv) < 0) {
    perror("socketpair");
    return -1;
}

// sv[0] 和 sv[1] 是一对已连接的 socket
// 可用于 fork 后的父子进程通信
```

### 进程死后自动关闭的 socketpair

```c
// 使用 SOCK_STREAM 时，任意一方关闭 socket，
// 另一方的 read 返回 0 (EOF)
// 适合父子进程双向通信
```

---

## FIFO 命名管道

### 创建 FIFO

```cpp
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

const char* fifo_path = "/tmp/my_fifo";

if (mkfifo(fifo_path, 0666) < 0 && errno != EEXIST) {
    perror("mkfifo");
    return -1;
}

// 打开 FIFO (注意: 阻塞直到双方都打开)
int fd = open(fifo_path, O_RDONLY);  // 读端
int fd = open(fifo_path, O_WRONLY);  // 写端

// 注意: O_RDWR 不会阻塞，但语义不同
```

### 读写 FIFO

```cpp
// 读者
int fd = open("/tmp/my_fifo", O_RDONLY);
char buf[256];
read(fd, buf, sizeof(buf));
close(fd);

// 写者
int fd = open("/tmp/my_fifo", O_WRONLY);
write(fd, "Hello", 5);
close(fd);

// 注意: 读者和写者必须同时存在，否则阻塞
```

---

## Unix Domain Socket

### Unix Socket 服务器

```cpp
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <cstdio>
#include <cstring>

class UnixSocketServer {
public:
    UnixSocketServer(const char* path) {
        unlink(path);  // 删除旧文件

        server_fd_ = socket(AF_UNIX, SOCK_STREAM, 0);
        if (server_fd_ < 0) throw std::runtime_error("socket failed");

        sockaddr_un addr;
        memset(&addr, 0, sizeof(addr));
        addr.sun_family = AF_UNIX;
        strncpy(addr.sun_path, path, sizeof(addr.sun_path) - 1);

        if (bind(server_fd_, (sockaddr*)&addr, sizeof(addr)) < 0)
            throw std::runtime_error("bind failed");

        if (listen(server_fd_, 5) < 0)
            throw std::runtime_error("listen failed");
    }

    int accept_client() {
        return accept(server_fd_, nullptr, nullptr);
    }

    ~UnixSocketServer() {
        close(server_fd_);
    }

private:
    int server_fd_;
};
```

### Unix Socket 客户端

```cpp
#include <sys/socket.h>
#include <sys/un.h>
#include <cstring>

class UnixSocketClient {
public:
    UnixSocketClient(const char* path) {
        fd_ = socket(AF_UNIX, SOCK_STREAM, 0);
        if (fd_ < 0) throw std::runtime_error("socket failed");

        sockaddr_un addr;
        memset(&addr, 0, sizeof(addr));
        addr.sun_family = AF_UNIX;
        strncpy(addr.sun_path, path, sizeof(addr.sun_path) - 1);

        if (connect(fd_, (sockaddr*)&addr, sizeof(addr)) < 0)
            throw std::runtime_error("connect failed");
    }

    int fd() { return fd_; }

    ~UnixSocketClient() {
        close(fd_);
    }

private:
    int fd_;
};
```

### 发送文件描述符 (ancillary data)

```cpp
#include <sys/socket.h>
#include <cstdio>

// 发送文件描述符
void send_fd(int socket, int fd_to_send) {
    char dummy = '*';
    iovec iov;
    iov.iov_base = &dummy;
    iov.iov_len = 1;

    msghdr msg;
    memset(&msg, 0, sizeof(msg));
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;
    msg.msg_control = &fd_to_send;
    msg.msg_controllen = CMSG_SPACE(sizeof(int));

    cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type = SCM_RIGHTS;
    cmsg->cmsg_len = CMSG_LEN(sizeof(int));
    memcpy(CMSG_DATA(cmsg), &fd_to_send, sizeof(int));

    sendmsg(socket, &msg, 0);
}

// 接收文件描述符
int recv_fd(int socket) {
    char dummy;
    iovec iov;
    iov.iov_base = &dummy;
    iov.iov_len = 1;

    msghdr msg;
    memset(&msg, 0, sizeof(msg));
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;

    char fd_buf[CMSG_SPACE(sizeof(int))];
    msg.msg_control = fd_buf;
    msg.msg_controllen = sizeof(fd_buf);

    recvmsg(socket, &msg, 0);

    cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
    if (cmsg && cmsg->cmsg_type == SCM_RIGHTS) {
        int fd;
        memcpy(&fd, CMSG_DATA(cmsg), sizeof(int));
        return fd;
    }
    return -1;
}
```

---

## Shared Memory

### POSIX Shared Memory

```cpp
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <cstring>

class SharedMemory {
public:
    // 创建并映射
    SharedMemory(const char* name, size_t size) : size_(size) {
        fd_ = shm_open(name, O_CREAT | O_RDWR, 0666);
        if (fd_ < 0) throw std::runtime_error("shm_open failed");

        if (ftruncate(fd_, size_) < 0)
            throw std::runtime_error("ftruncate failed");

        addr_ = mmap(nullptr, size_, PROT_READ | PROT_WRITE, MAP_SHARED, fd_, 0);
        if (addr_ == MAP_FAILED)
            throw std::runtime_error("mmap failed");
    }

    // 仅映射 (客户端)
    explicit SharedMemory(const char* name, size_t size) : size_(size) {
        fd_ = shm_open(name, O_RDWR, 0666);
        if (fd_ < 0) throw std::runtime_error("shm_open failed");

        addr_ = mmap(nullptr, size_, PROT_READ | PROT_WRITE, MAP_SHARED, fd_, 0);
        if (addr_ == MAP_FAILED)
            throw std::runtime_error("mmap failed");
    }

    ~SharedMemory() {
        munmap(addr_, size_);
        close(fd_);
    }

    void* addr() { return addr_; }
    const void* addr() const { return addr_; }
    size_t size() const { return size_; }

private:
    int fd_;
    void* addr_;
    size_t size_;
};

// 使用示例
// 进程 A (创建者)
SharedMemory shm("/my_shm", 4096);
auto* data = static_cast<int*>(shm.addr());
data[0] = 42;

// 进程 B (客户端)
SharedMemory shm("/my_shm", 4096);
auto* data = static_cast<int*>(shm.addr());
printf("Data: %d\n", data[0]);
```

### Shared Memory + 互斥锁

```cpp
#include <pthread.h>
#include <sys/mman.h>
#include <cstring>

struct SharedData {
    pthread_mutex_t mutex;
    int counter;
    char message[256];
};

class SyncSharedMemory {
public:
    SyncSharedMemory(const char* name, size_t size) {
        fd_ = shm_open(name, O_CREAT | O_RDWR, 0666);
        if (fd_ < 0) throw std::runtime_error("shm_open failed");

        if (ftruncate(fd_, size) < 0)
            throw std::runtime_error("ftruncate failed");

        addr_ = mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd_, 0);
        if (addr_ == MAP_FAILED)
            throw std::runtime_error("mmap failed");

        // 初始化互斥锁 (只在首次创建时)
        if (ftruncate(fd_, 0) >= 0 || errno == 0) {  // 检查是否是新建的
            pthread_mutexattr_t attr;
            pthread_mutexattr_init(&attr);
            pthread_mutexattr_setpshared(&attr, PTHREAD_PROCESS_SHARED);
            pthread_mutex_init(&static_cast<SharedData*>(addr_)->mutex, &attr);
            pthread_mutexattr_destroy(&attr);
        }
    }

    SharedData* data() { return static_cast<SharedData*>(addr_); }

private:
    int fd_;
    void* addr_;
};
```

---

## Message Queue (POSIX)

### 消息队列基础

```cpp
#include <mqueue.h>
#include <cstdio>
#include <cstring>
#include <cerrno>

class MessageQueue {
public:
    MessageQueue(const char* name, bool create = false) {
        if (create) {
            mq_unlink(name);  // 删除旧的
            attr_.mq_flags = 0;
            attr_.mq_maxmsg = 10;
            attr_.mq_msgsize = 1024;
            attr_.mq_curmsgs = 0;
            attr_.mq_curmsgs = 0;
            mq_ = mq_open(name, O_CREAT | O_RDWR, 0666, &attr_);
        } else {
            mq_ = mq_open(name, O_RDWR);
        }
        if (mq_ < 0) throw std::runtime_error("mq_open failed");
    }

    ~MessageQueue() { mq_close(mq_); }

    int send(const void* msg, size_t len, unsigned prio = 0) {
        return mq_send(mq_, static_cast<const char*>(msg), len, prio);
    }

    ssize_t receive(void* buf, size_t len, unsigned* prio = nullptr) {
        return mq_receive(mq_, static_cast<char*>(buf), len, prio);
    }

    mqd_t fd() { return mq_; }

private:
    mqd_t mq_;
    struct mq_attr attr_;
};

// 发送者
MessageQueue mq("/my_mq", true);
mq.send("Hello", 5, 0);

// 接收者
MessageQueue mq("/my_mq");
char buf[1024];
ssize_t n = mq.receive(buf, sizeof(buf));
```

### 带超时的消息接收

```cpp
#include <ctime>

bool receive_with_timeout(mqd_t mq, char* buf, size_t len, int timeout_ms) {
    timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    ts.tv_sec += timeout_ms / 1000;
    ts.tv_nsec += (timeout_ms % 1000) * 1'000'000;
    if (ts.tv_nsec >= 1'000'000'000) {
        ts.tv_sec += 1;
        ts.tv_nsec -= 1'000'000'000;
    }

    ssize_t n = mq_timedreceive(mq, buf, len, nullptr, &ts);
    return n >= 0;
}
```

---

## 信号量同步

### POSIX 有名信号量同步共享内存

```cpp
#include <semaphore.h>
#include <sys/mman.h>
#include <cstdio>

class SemaphoreSync {
public:
    SemaphoreSync(const char* name, int value = 1) {
        sem_ = sem_open(name, O_CREAT, 0666, value);
        if (sem_ == SEM_FAILED) throw std::runtime_error("sem_open failed");
    }

    ~SemaphoreSync() {
        sem_close(sem_);
    }

    void wait() {
        if (sem_wait(sem_) < 0) throw std::runtime_error("sem_wait failed");
    }

    void post() {
        if (sem_post(sem_) < 0) throw std::runtime_error("sem_post failed");
    }

    bool try_wait() {
        return sem_trywait(sem_) == 0;
    }

private:
    sem_t* sem_;
};

// 使用示例
// 进程 A
SemaphoreSync sem("/my_sem", 1);
int* shared_counter = static_cast<int*>(shm_base);
sem.wait();
(*shared_counter)++;
sem.post();

// 进程 B
SemaphoreSync sem("/my_sem", 1);
int* shared_counter = static_cast<int*>(shm_base);
sem.wait();
printf("Counter: %d\n", *shared_counter);
sem.post();
```

---

## IPC 选择指南

### 选择决策树

```
需要传递文件描述符?
├─ 是 → Unix Domain Socket (sendmsg/recvmsg)
└─ 否

数据量?
├─ 小 (< 64KB) →
│   ├─ 消息流式 → pipe / socketpair
│   └─ 消息边界重要 → POSIX MQ
└─ 大 (共享数据) → Shared Memory + Semaphore

实时性要求?
├─ 极低延迟 → Shared Memory
└─ 一般 → Message Queue

是否跨主机?
├─ 是 → TCP/UDP Socket
└─ 否 → 所有本地 IPC
```

### 性能对比 (典型值)

| 方式 | 延迟 (us) | 吞吐量 |
|------|-----------|--------|
| pipe | 0.5-2 | 高 |
| Unix Socket | 1-5 | 高 |
| POSIX MQ | 5-20 | 中 |
| Shared Memory | 0.1-0.5 | 极高 |
| System V MQ | 10-50 | 中 |

---

## 常见模式

### 1. 请求-响应模式 (Unix Socket)

```cpp
// 客户端发送请求，服务器返回响应
// 使用固定头部 (长度) + 数据

struct Request {
    uint32_t length;
    uint32_t type;
    char data[];
};

struct Response {
    uint32_t length;
    uint32_t status;
    char data[];
};
```

### 2. 发布-订阅模式 (Unix Socket 多播)

```cpp
// 服务器接受多个客户端连接
// 消息广播到所有订阅者

std::vector<int> subscribers;

void broadcast(const void* msg, size_t len) {
    for (int fd : subscribers) {
        send(fd, msg, len, 0);
    }
}
```

### 3. 生产者-消费者模式 (Shared Memory)

```cpp
// 共享内存作为环形缓冲区
// 信号量同步

struct RingBuffer {
    sem_t mutex;
    sem_t slots;    // 可用槽位
    sem_t items;    // 可用数据
    size_t head;    // 读位置
    size_t tail;    // 写位置
    char data[1024];
};
```

### 4. 心跳检测模式

```cpp
// 使用 pipe 或 socketpair 检测进程存活
// 定期写入心跳字节

void heartbeat(int write_fd, int interval_sec) {
    char ping = 1;
    while (running) {
        write(write_fd, &ping, 1);
        sleep(interval_sec);
    }
}

bool check_heartbeat(int read_fd, int timeout_sec) {
    fd_set fds;
    FD_ZERO(&fds);
    FD_SET(read_fd, &fds);
    timeval tv = { timeout_sec, 0 };
    int ret = select(read_fd + 1, &fds, nullptr, nullptr, &tv);
    return ret > 0;
}
```
