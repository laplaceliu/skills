# 网络编程深度指南

## socket 基础

### TCP socket 创建与连接

```cpp
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <cstdio>
#include <cstring>
#include <unistd.h>

class TcpConnection {
public:
    TcpConnection(const char* host, const char* port) {
        // 获取地址信息
        struct addrinfo hints, *result;
        memset(&hints, 0, sizeof(hints));
        hints.ai_family = AF_UNSPEC;      // IPv4 或 IPv6
        hints.ai_socktype = SOCK_STREAM;  // TCP

        int ret = getaddrinfo(host, port, &hints, &result);
        if (ret != 0) {
            fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(ret));
            throw std::runtime_error("getaddrinfo failed");
        }

        // 遍历所有地址，尝试连接
        for (struct addrinfo* rp = result; rp != NULL; rp = rp->ai_next) {
            fd_ = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
            if (fd_ < 0) continue;

            if (connect(fd_, rp->ai_addr, rp->ai_addrlen) == 0) {
                // 连接成功
                break;
            }

            close(fd_);
            fd_ = -1;
        }

        freeaddrinfo(result);

        if (fd_ < 0) {
            throw std::runtime_error("Could not connect");
        }
    }

    ~TcpConnection() {
        if (fd_ >= 0) close(fd_);
    }

    ssize_t send(const void* buf, size_t len) {
        return ::send(fd_, buf, len, 0);
    }

    ssize_t receive(void* buf, size_t len) {
        return recv(fd_, buf, len, 0);
    }

    int fd() const { return fd_; }

private:
    int fd_ = -1;
};
```

### TCP 服务器

```cpp
#include <sys/socket.h>
#include <netinet/in.h>
#include <cstring>

class TcpServer {
public:
    TcpServer(uint16_t port, int backlog = 128) : port_(port), backlog_(backlog) {}

    void listen() {
        // 创建 socket
        server_fd_ = ::socket(AF_INET, SOCK_STREAM, 0);
        if (server_fd_ < 0) throw std::runtime_error("socket failed");

        // 设置 SO_REUSEADDR
        int opt = 1;
        setsockopt(server_fd_, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

        // 绑定地址
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = INADDR_ANY;  // 任意地址
        addr.sin_port = htons(port_);

        if (bind(server_fd_, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
            throw std::runtime_error("bind failed");
        }

        // 开始监听
        if (::listen(server_fd_, backlog_) < 0) {
            throw std::runtime_error("listen failed");
        }

        printf("Listening on port %d\n", port_);
    }

    int accept_client(struct sockaddr_in* client_addr = nullptr) {
        socklen_t addr_len = sizeof(struct sockaddr_in);
        int client_fd = ::accept(server_fd_,
            client_addr ? (struct sockaddr*)client_addr : nullptr,
            client_addr ? &addr_len : nullptr);

        if (client_fd < 0) {
            if (errno == EINTR || errno == EAGAIN) return -1;
            throw std::runtime_error("accept failed");
        }
        return client_fd;
    }

    int server_fd() const { return server_fd_; }

protected:
    int server_fd_ = -1;
    uint16_t port_;
    int backlog_;
};
```

---

## 高性能 I/O 模型

### select 基础

```cpp
#include <sys/select.h>
#include <cstdio>

class SelectServer {
public:
    SelectServer(int server_fd) : server_fd_(server_fd) {
        FD_ZERO(&read_fds_);
        FD_SET(server_fd_, &read_fds_);
        max_fd_ = server_fd_;
    }

    void add_fd(int fd) {
        FD_SET(fd, &read_fds_);
        if (fd > max_fd_) max_fd_ = fd;
    }

    void remove_fd(int fd) {
        FD_CLR(fd, &read_fds_);
    }

    int wait(int timeout_ms = -1) {
        fd_set read_fds = read_fds_;  // select 会修改
        struct timeval tv = { timeout_ms / 1000, (timeout_ms % 1000) * 1000 };

        int ret = select(max_fd_ + 1, &read_fds, nullptr, nullptr,
                        timeout_ms < 0 ? nullptr : &tv);
        if (ret < 0) {
            if (errno == EINTR) return 0;
            throw std::runtime_error("select failed");
        }
        read_fds_ = read_fds;
        return ret;
    }

    bool is_readable(int fd) const {
        return FD_ISSET(fd, &read_fds_);
    }

private:
    int server_fd_;
    fd_set read_fds_;
    int max_fd_;
};
```

### poll 基础

```cpp
#include <poll.h>
#include <vector>

class PollServer {
public:
    PollServer() {
        // 初始容量
        fds_.reserve(16);
    }

    int add_fd(int fd, short events = POLLIN) {
        for (auto& f : fds_) {
            if (f.fd == -1) {
                f.fd = fd;
                f.events = events;
                f.revents = 0;
                return 0;
            }
        }
        fds_.push_back({ fd, events, 0 });
        return 0;
    }

    void remove_fd(int fd) {
        for (auto& f : fds_) {
            if (f.fd == fd) {
                f.fd = -1;
                f.events = 0;
                f.revents = 0;
            }
        }
    }

    int wait(int timeout_ms = -1) {
        // 清理已关闭的 fd
        for (auto& f : fds_) {
            if (f.fd == -1) {
                f.events = 0;
            }
        }

        int ret = poll(fds_.data(), fds_.size(), timeout_ms);
        if (ret < 0) {
            if (errno == EINTR) return 0;
            throw std::runtime_error("poll failed");
        }
        return ret;
    }

    bool is_readable(size_t index) const {
        return index < fds_.size() && (fds_[index].revents & POLLIN);
    }

    bool is_error(size_t index) const {
        return index < fds_.size() && (fds_[index].revents & (POLLERR | POLLHUP | POLLNVAL));
    }

    int fd(size_t index) const {
        return index < fds_.size() ? fds_[index].fd : -1;
    }

private:
    std::vector<struct pollfd> fds_;
};
```

### epoll 基础

```cpp
#include <sys/epoll.h>
#include <vector>
#include <cstdlib>

class EpollServer {
public:
    EpollServer() {
        epoll_fd_ = epoll_create1(EPOLL_CLOEXEC);
        if (epoll_fd_ < 0) throw std::runtime_error("epoll_create1 failed");
    }

    void add_fd(int fd, uint32_t events = EPOLLIN) {
        struct epoll_event ev;
        ev.events = events | EPOLLET;  // 边缘触发
        ev.data.fd = fd;
        if (epoll_ctl(epoll_fd_, EPOLL_CTL_ADD, fd, &ev) < 0) {
            throw std::runtime_error("epoll_ctl add failed");
        }
    }

    void modify_fd(int fd, uint32_t events) {
        struct epoll_event ev;
        ev.events = events | EPOLLET;
        ev.data.fd = fd;
        if (epoll_ctl(epoll_fd_, EPOLL_CTL_MOD, fd, &ev) < 0) {
            throw std::runtime_error("epoll_ctl mod failed");
        }
    }

    void remove_fd(int fd) {
        epoll_ctl(epoll_fd_, EPOLL_CTL_DEL, fd, nullptr);
    }

    int wait(int timeout_ms = -1) {
        int ret = epoll_wait(epoll_fd_, events_.data(), events_.size(), timeout_ms);
        if (ret < 0) {
            if (errno == EINTR) return 0;
            throw std::runtime_error("epoll_wait failed");
        }
        return ret;
    }

    struct epoll_event& event(int index) {
        return events_[index];
    }

    void resize_events(size_t size) {
        events_.resize(size);
    }

private:
    int epoll_fd_;
    std::vector<struct epoll_event> events_;
};
```

### epoll 服务器示例

```cpp
#include <sys/epoll.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <vector>
#include <map>

class EchoServer {
public:
    EchoServer(uint16_t port) : port_(port) {}

    void start() {
        // 创建服务器 socket
        server_fd_ = socket(AF_INET, SOCK_STREAM, 0);
        if (server_fd_ < 0) throw std::runtime_error("socket failed");

        int opt = 1;
        setsockopt(server_fd_, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = INADDR_ANY;
        addr.sin_port = htons(port_);

        bind(server_fd_, (struct sockaddr*)&addr, sizeof(addr));
        listen(server_fd_, 128);

        // 创建 epoll 实例
        epoll_fd_ = epoll_create1(EPOLL_CLOEXEC);

        // 添加服务器 socket 到 epoll
        struct epoll_event ev;
        ev.events = EPOLLIN;
        ev.data.fd = server_fd_;
        epoll_ctl(epoll_fd_, EPOLL_CTL_ADD, server_fd_, &ev);

        events_.resize(16);

        printf("Server started on port %d\n", port_);
    }

    void run() {
        while (running_) {
            int nfds = epoll_wait(epoll_fd_, events_.data(), events_.size(), 1000);
            for (int i = 0; i < nfds; ++i) {
                int fd = events_[i].data.fd;
                uint32_t events = events_[i].events;

                if (fd == server_fd_) {
                    // 新连接
                    if (events & EPOLLIN) {
                        handle_accept();
                    }
                } else {
                    // 客户端数据
                    if (events & (EPOLLERR | EPOLLHUP)) {
                        handle_close(fd);
                    } else if (events & EPOLLIN) {
                        handle_read(fd);
                    }
                }
            }

            // 如果事件数量等于数组大小，扩容
            if (nfds == (int)events_.size()) {
                events_.resize(events_.size() * 2);
            }
        }
    }

    void stop() { running_ = false; }

private:
    void handle_accept() {
        struct sockaddr_in client_addr;
        socklen_t len = sizeof(client_addr);
        int client_fd = accept(server_fd_, (struct sockaddr*)&client_addr, &len);

        if (client_fd < 0) return;

        // 设置非阻塞
        int flags = fcntl(client_fd, F_GETFL, 0);
        fcntl(client_fd, F_SETFL, flags | O_NONBLOCK);

        // 添加到 epoll
        struct epoll_event ev;
        ev.events = EPOLLIN | EPOLLET;
        ev.data.fd = client_fd;
        epoll_ctl(epoll_fd_, EPOLL_CTL_ADD, client_fd, &ev);

        char ip[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, &client_addr.sin_addr, ip, sizeof(ip));
        printf("Client connected: %s:%d\n", ip, ntohs(client_addr.sin_port));
    }

    void handle_read(int client_fd) {
        char buf[4096];
        ssize_t n = read(client_fd, buf, sizeof(buf));

        if (n > 0) {
            // 回显
            ssize_t written = 0;
            while (written < n) {
                ssize_t w = write(client_fd, buf + written, n - written);
                if (w <= 0) {
                    if (errno == EINTR) continue;
                    handle_close(client_fd);
                    return;
                }
                written += w;
            }
        } else if (n == 0) {
            handle_close(client_fd);
        } else {
            if (errno != EAGAIN && errno != EWOULDBLOCK) {
                handle_close(client_fd);
            }
        }
    }

    void handle_close(int fd) {
        epoll_ctl(epoll_fd_, EPOLL_CTL_DEL, fd, nullptr);
        close(fd);
        printf("Client disconnected: fd=%d\n", fd);
    }

    int server_fd_ = -1;
    int epoll_fd_ = -1;
    uint16_t port_;
    bool running_ = true;
    std::vector<struct epoll_event> events_;
};
```

---

## UDP 编程

### UDP 客户端

```cpp
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <cstring>
#include <unistd.h>

class UdpClient {
public:
    UdpClient() {
        fd_ = socket(AF_INET, SOCK_DGRAM, 0);
        if (fd_ < 0) throw std::runtime_error("socket failed");
    }

    ssize_t send_to(const char* host, uint16_t port, const void* buf, size_t len) {
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        inet_pton(AF_INET, host, &addr.sin_addr);

        return sendto(fd_, buf, len, 0, (struct sockaddr*)&addr, sizeof(addr));
    }

    ssize_t receive_from(char* host, size_t host_len, uint16_t* port,
                         void* buf, size_t len) {
        struct sockaddr_in addr;
        socklen_t addr_len = sizeof(addr);

        ssize_t n = recvfrom(fd_, buf, len, 0, (struct sockaddr*)&addr, &addr_len);
        if (n > 0 && host) {
            inet_ntop(AF_INET, &addr.sin_addr, host, host_len);
        }
        if (n > 0 && port) {
            *port = ntohs(addr.sin_port);
        }
        return n;
    }

    ~UdpClient() { close(fd); }

private:
    int fd_ = -1;
};
```

### UDP 服务器

```cpp
#include <sys/socket.h>
#include <netinet/in.h>
#include <cstring>

class UdpServer {
public:
    UdpServer(uint16_t port) : port_(port) {
        fd_ = socket(AF_INET, SOCK_DGRAM, 0);
        if (fd_ < 0) throw std::runtime_error("socket failed");

        int opt = 1;
        setsockopt(fd_, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = INADDR_ANY;
        addr.sin_port = htons(port_);

        if (bind(fd_, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
            throw std::runtime_error("bind failed");
        }
    }

    ssize_t receive_from(char* host, size_t host_len, uint16_t* port,
                        void* buf, size_t len) {
        struct sockaddr_in addr;
        socklen_t addr_len = sizeof(addr);

        ssize_t n = recvfrom(fd_, buf, len, 0, (struct sockaddr*)&addr, &addr_len);
        if (n > 0 && host) {
            inet_ntop(AF_INET, &addr.sin_addr, host, host_len);
        }
        if (n > 0 && port) {
            *port = ntohs(addr.sin_port);
        }
        return n;
    }

    ssize_t reply_to(const char* host, uint16_t port, const void* buf, size_t len) {
        struct sockaddr_in addr;
        memset(&addr, 0, sizeof(addr));
        addr.sin_family = AF_INET;
        addr.sin_port = htons(port);
        inet_pton(AF_INET, host, &addr.sin_addr);

        return sendto(fd_, buf, len, 0, (struct sockaddr*)&addr, sizeof(addr));
    }

    int fd() const { return fd_; }

private:
    int fd_ = -1;
    uint16_t port_;
};
```

---

## 网络超时与选项

### 设置 socket 超时

```cpp
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <time.h>

// 接收超时
struct timeval tv = { 5, 0 };  // 5 秒
setsockopt(fd_, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

// 发送超时
setsockopt(fd_, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));

// TCP 超时 (心跳)
int keepalive = 1;
setsockopt(fd_, SOL_SOCKET, SO_KEEPALIVE, &keepalive, sizeof(keepalive));

int keepidle = 60;  // 空闲 60 秒后开始探测
setsockopt(fd_, IPPROTO_TCP, TCP_KEEPIDLE, &keepidle, sizeof(keepidle));

int keepintvl = 10;  // 探测间隔 10 秒
setsockopt(fd_, IPPROTO_TCP, TCP_KEEPINTVL, &keepintvl, sizeof(keepintvl));

int keepcnt = 3;  // 最多探测 3 次
setsockopt(fd_, IPPROTO_TCP, TCP_KEEPCNT, &keepcnt, sizeof(keepcnt));

// 禁用 Nagle 算法 (低延迟)
int nodelay = 1;
setsockopt(fd_, IPPROTO_TCP, TCP_NODELAY, &nodelay, sizeof(nodelay));
```

### 非阻塞 socket

```cpp
#include <fcntl.h>

int set_nonblocking(int fd) {
    int flags = fcntl(fd, F_GETFL, 0);
    if (flags < 0) return -1;
    return fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}

int set_cloexec(int fd) {
    int flags = fcntl(fd, F_GETFD, 0);
    if (flags < 0) return -1;
    return fcntl(fd, F_SETFD, flags | FD_CLOEXEC);
}
```

---

## 实用工具函数

### 完整 read/write 循环

```cpp
#include <unistd.h>
#include <cstddef>
#include <cerrno>

ssize_t read_all(int fd, void* buf, size_t count) {
    char* ptr = static_cast<char*>(buf);
    size_t remaining = count;

    while (remaining > 0) {
        ssize_t n = read(fd, ptr, remaining);
        if (n < 0) {
            if (errno == EINTR) continue;
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                return count - remaining;  // 非阻塞，返回已读
            }
            return -1;
        }
        if (n == 0) {
            return count - remaining;  // EOF
        }
        ptr += n;
        remaining -= n;
    }
    return count;
}

ssize_t write_all(int fd, const void* buf, size_t count) {
    const char* ptr = static_cast<const char*>(buf);
    size_t remaining = count;

    while (remaining > 0) {
        ssize_t n = write(fd, ptr, remaining);
        if (n < 0) {
            if (errno == EINTR) continue;
            if (errno == EAGAIN || errno == EWOULDBLOCK) {
                return count - remaining;
            }
            return -1;
        }
        if (n == 0) {
            return -1;  // 不应该发生
        }
        ptr += n;
        remaining -= n;
    }
    return count;
}
```

### 地址格式化

```cpp
#include <arpa/inet.h>
#include <netinet/in.h>
#include <cstdio>

// IPv4
struct sockaddr_in addr;
char ip[INET_ADDRSTRLEN];

inet_ntop(AF_INET, &addr.sin_addr, ip, sizeof(ip));
printf("IP: %s, Port: %d\n", ip, ntohs(addr.sin_port));

// 解析 IP
inet_pton(AF_INET, "192.168.1.1", &addr.sin_addr);

// IPv6
struct sockaddr_in6 addr6;
char ip6[INET6_ADDRSTRLEN];

inet_ntop(AF_INET6, &addr6.sin6_addr, ip6, sizeof(ip6));

// 通用地址格式化
void print_sockaddr(struct sockaddr* sa) {
    if (sa->sa_family == AF_INET) {
        struct sockaddr_in* sin = (struct sockaddr_in*)sa;
        char ip[INET_ADDRSTRLEN];
        inet_ntop(AF_INET, &sin->sin_addr, ip, sizeof(ip));
        printf("%s:%d\n", ip, ntohs(sin->sin_port));
    } else if (sa->sa_family == AF_INET6) {
        struct sockaddr_in6* sin6 = (struct sockaddr_in6*)sa;
        char ip6[INET6_ADDRSTRLEN];
        inet_ntop(AF_INET6, &sin6->sin6_addr, ip6, sizeof(ip6));
        printf("[%s]:%d\n", ip6, ntohs(sin6->sin6_port));
    }
}
```

---

## 常见问题

### CLOSE_WAIT 问题

```cpp
// 问题: 对端关闭连接后，本端未关闭 socket，导致 CLOSE_WAIT
// 解决: 检测到 read 返回 0 时立即关闭 socket

ssize_t n = read(fd, buf, sizeof(buf));
if (n == 0) {
    // 对端关闭连接
    close(fd);
    fd = -1;
    // 清理相关资源
}
```

### TIME_WAIT 问题

```cpp
// 问题: 主动关闭连接的一方会进入 TIME_WAIT 状态，持续 2*MSL
// 解决: 设置 SO_REUSEADDR，允许在 TIME_WAIT 期间绑定同一端口

int opt = 1;
setsockopt(fd_, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
```

### 惊群问题 (Thundering Herd)

```cpp
// 问题: 多个进程/线程等待同一个 socket，accept 只处理一个
// Linux 解决: SO_REUSEPORT (每个进程有自己的 socket)
// 或者使用锁保护 accept

// epoll 不存在惊群问题，因为 epoll_wait 是针对每个 epoll 实例的
```
