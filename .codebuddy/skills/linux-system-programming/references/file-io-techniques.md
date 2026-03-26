# 文件 I/O 高级技术

## 直接 I/O (O_DIRECT)

### 直接 I/O 基础

```cpp
#include <fcntl.h>
#include <unistd.h>
#include <cstdio>
#include <cstring>

// 直接 I/O: 绕过页缓存，直接与设备交互
// 要求: 缓冲区、偏移量、长度必须对齐到扇区大小 (512 或 4096 字节)

class DirectFile {
public:
    DirectFile(const char* path, int flags) {
        fd_ = open(path, flags | O_DIRECT);
        if (fd_ < 0) {
            throw std::runtime_error(std::string("open: ") + strerror(errno));
        }
    }

    ~DirectFile() { close(fd_); }

    // 读取对齐的数据
    ssize_t read_aligned(void* buf, size_t len) {
        // 确保对齐
        if (len % 512 != 0) {
            len = (len / 512 + 1) * 512;
        }
        ssize_t n = ::read(fd_, buf, len);
        return n;
    }

    // 写入对齐的数据
    ssize_t write_aligned(const void* buf, size_t len) {
        if (len % 512 != 0) {
            len = (len / 512 + 1) * 512;
        }
        ssize_t n = ::write(fd_, buf, len);
        return n;
    }

private:
    int fd_;
};
```

### aligned_alloc 对齐内存

```cpp
#include <cstdlib>
#include <cstddef>

// 对齐到 4096 字节
const size_t ALIGN = 4096;
const size_t BUF_SIZE = 4096;

// C11/C++17 aligned_alloc
void* buf = aligned_alloc(ALIGN, BUF_SIZE);
if (!buf) throw std::bad_alloc();
std::free(buf);

// POSIX posix_memalign
void* buf2;
if (posix_memalign(&buf2, ALIGN, BUF_SIZE) != 0) {
    throw std::bad_alloc();
}
std::free(buf2);
```

---

## 同步 I/O (O_SYNC / fsync)

### 同步写入

```cpp
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>

// 方法 1: open 时使用 O_SYNC
int fd = open("file", O_WRONLY | O_CREAT | O_TRUNC | O_SYNC, 0644);

// 方法 2: 每次 write 后同步
write(fd, buf, len);
fsync(fd);  // 同步到磁盘

// 方法 3: fdatasync (不同步元数据)
fdatasync(fd);  // 比 fsync 快，但不保证 inode 更新

// 方法 4: sync 同步所有文件
sync();  // 同步所有文件系统的所有文件
```

### 同步选项对比

| 选项 | 作用 | 性能影响 |
|------|------|----------|
| O_SYNC | 每次 write 同步到磁盘 | 极慢 |
| O_DSYNC | write 同步，不含元数据 | 很慢 |
| O_RSYNC | 与 O_SYNC/O_DSYNC 配合，读也同步 | 很慢 |
| fsync() | 显式同步一个文件 | 慢 |
| fdatasync() | 同步数据，不含元数据 | 中等 |
| sync() | 同步所有文件系统 | 慢 |

---

## 内存映射 I/O (mmap)

### 基础 mmap

```cpp
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstdio>
#include <cstring>

class MmapFile {
public:
    MmapFile() : data_(MAP_FAILED), size_(0) {}

    void open(const char* path, size_t size) {
        // 打开或创建文件
        int fd = ::open(path, O_RDWR | O_CREAT, 0644);
        if (fd < 0) throw std::runtime_error("open failed");

        // 扩展文件大小
        if (ftruncate(fd, size) < 0) {
            ::close(fd);
            throw std::runtime_error("ftruncate failed");
        }

        // 映射
        data_ = mmap(nullptr, size, PROT_READ | PROT_WRITE, MAP_SHARED, fd, 0);
        ::close(fd);  // 映射后关闭

        if (data_ == MAP_FAILED) {
            throw std::runtime_error("mmap failed");
        }
        size_ = size;
    }

    void* data() { return data_; }
    const void* data() const { return data_; }
    size_t size() const { return size_; }

    void sync() {
        if (msync(data_, size_, MS_SYNC) < 0) {
            throw std::runtime_error("msync failed");
        }
    }

    ~MmapFile() {
        if (data_ != MAP_FAILED) {
            munmap(data_, size_);
        }
    }

private:
    void* data_;
    size_t size_;
};
```

### mmap 读写文件

```cpp
#include <sys/mman.h>
#include <fcntl.h>
#include <unistd.h>
#include <cstring>

// 读取模式映射
int fd = open("file", O_RDONLY);
struct stat st;
fstat(fd, &st);

void* data = mmap(nullptr, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
close(fd);  // 可立即关闭

// 使用 data...
char* str = static_cast<char*>(data);
printf("First 100 bytes: %.*s\n", 100, str);

munmap(data, st.st_size);
```

### 写时复制 (fork 前准备数据)

```cpp
// 父进程映射大文件
void* data = mmap(nullptr, size, PROT_READ | PROT_WRITE,
                  MAP_PRIVATE, fd, 0);

// 父进程写入数据
memcpy(data, large_content, size);

// fork 后，子进程继承映射，但是写时复制的
pid_t pid = fork();
if (pid == 0) {
    // 子进程有自己的副本
    // 修改不影响父进程
}
```

### 私有映射 (MAP_PRIVATE)

```cpp
// MAP_PRIVATE: 修改是私有的，不写回文件
// 适合读取文件内容

void* data = mmap(nullptr, size, PROT_READ | PROT_WRITE,
                  MAP_PRIVATE, fd, 0);

// 写入会创建页面副本
static_cast<char*>(data)[0] = 'X';

// 不会影响原文件
```

---

## splice / tee / vmsplice

### 高效数据传输

```cpp
#include <fcntl.h>

// splice: 在 fd 和管道之间移动数据 (零拷贝)
// 适用于大文件传输

int pipe_fd[2];
pipe(pipe_fd);

// 从文件 splice 到 pipe
ssize_t n = splice(fd_in, nullptr, pipe_fd[1], nullptr,
                    4096, SPLICE_F_MOVE | SPLICE_F_NONBLOCK);

// 从 pipe splice 到文件
ssize_t n = splice(pipe_fd[0], nullptr, fd_out, nullptr,
                    4096, SPLICE_F_MOVE | SPLICE_F_NONBLOCK);

// tee: 在两个管道之间复制数据
ssize_t n = tee(pipe_fd[0], pipe_fd[1], 4096, SPLICE_F_NONBLOCK);
```

### 使用 splice 实现高效文件传输

```cpp
#include <fcntl.h>
#include <unistd.h>
#include <sys/socket.h>

ssize_t send_file(int out_fd, int in_fd, size_t size) {
    ssize_t total = 0;

    while (size > 0) {
        ssize_t n = splice(in_fd, nullptr, out_fd, nullptr,
                           std::min(size, (size_t)4096),
                           SPLICE_F_MOVE);
        if (n <= 0) break;
        total += n;
        size -= n;
    }

    return total;
}

// 使用 splice 通过 socket 发送文件
int file_fd = open("largefile", O_RDONLY);
int sock_fd = client_socket_fd;

splice(file_fd, nullptr, sock_fd, nullptr, file_size, 0);

close(file_fd);
```

---

## ioctl 设备控制

### 基础 ioctl

```cpp
#include <sys/ioctl.h>
#include <unistd.h>

// 获取窗口大小 (终端)
struct winsize ws;
if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == 0) {
    printf("Window size: %d x %d\n", ws.ws_col, ws.ws_row);
}

// 设置窗口大小
struct winsize new_ws = { .ws_row = 40, .ws_col = 120 };
ioctl(STDOUT_FILENO, TIOCSWINSZ, &new_ws);

// FIONREAD: 获取输入缓冲区中的字节数
int nread;
ioctl(fd, FIONREAD, &nread);
```

### 文件控制操作

```cpp
#include <fcntl.h>

// 获取/设置文件描述符标志
int flags = fcntl(fd, F_GETFD);
flags |= FD_CLOEXEC;
fcntl(fd, F_SETFD, flags);

// 获取/设置文件状态标志
flags = fcntl(fd, F_GETFL);
flags |= O_NONBLOCK;
fcntl(fd, F_SETFL, flags);

// 获取/设置管道容量
int capacity = fcntl(pipe_fd[0], F_GETPIPE_SZ);
fcntl(pipe_fd[0], F_SETPIPE_SZ, 4096);
```

---

## 目录流 (opendir/readdir)

### 遍历目录

```cpp
#include <dirent.h>
#include <cstdio>
#include <cstring>

void list_directory(const char* path) {
    DIR* dir = opendir(path);
    if (!dir) {
        perror("opendir");
        return;
    }

    struct dirent* entry;
    while ((entry = readdir(dir)) != nullptr) {
        // 跳过 . 和 ..
        if (entry->d_name[0] == '.' &&
            (entry->d_name[1] == '\0' ||
             (entry->d_name[1] == '.' && entry->d_name[2] == '\0'))) {
            continue;
        }

        printf("%s", entry->d_name);

        // 根据类型显示
        switch (entry->d_type) {
            case DT_REG:  printf(" [file]\n"); break;
            case DT_DIR:  printf(" [dir]\n"); break;
            case DT_LNK:  printf(" [link]\n"); break;
            case DT_CHR:  printf(" [char device]\n"); break;
            case DT_BLK:  printf(" [block device]\n"); break;
            case DT_SOCK: printf(" [socket]\n"); break;
            case DT_FIFO: printf(" [fifo]\n"); break;
            default:       printf(" [unknown]\n"); break;
        }
    }

    closedir(dir);
}
```

### 递归目录遍历

```cpp
#include <dirent.h>
#include <cstring>
#include <vector>

void walk_directory(const char* path, int depth = 0) {
    DIR* dir = opendir(path);
    if (!dir) return;

    struct dirent* entry;
    while ((entry = readdir(dir)) != nullptr) {
        if (entry->d_name[0] == '.') continue;

        // 打印缩进
        for (int i = 0; i < depth; ++i) printf("  ");
        printf("%s", entry->d_name);

        if (entry->d_type == DT_DIR) {
            printf("/\n");
            // 递归
            std::string subpath = std::string(path) + "/" + entry->d_name;
            walk_directory(subpath.c_str(), depth + 1);
        } else if (entry->d_type == DT_LNK) {
            printf(" -> ");
            // 读取链接目标
            char target[PATH_MAX];
            std::string fullpath = std::string(path) + "/" + entry->d_name;
            ssize_t len = readlink(fullpath.c_str(), target, sizeof(target) - 1);
            if (len > 0) {
                target[len] = '\0';
                printf("%s\n", target);
            } else {
                printf("\n");
            }
        } else {
            printf("\n");
        }
    }

    closedir(dir);
}
```

### fdopendir / dirfd

```cpp
#include <dirent.h>

// 从 fd 创建 DIR*
DIR* dir = fdopendir(fd);
// fd 现在被 DIR 管理，不要直接 close

// 获取 DIR 的 fd
int fd = dirfd(dir);
// 不要 close 这个 fd，closedir 会处理
```

---

## 文件锁 (flock / fcntl)

### flock 咨询锁

```cpp
#include <sys/file.h>
#include <unistd.h>

int fd = open("file", O_RDWR);

// 锁定文件
flock(fd, LOCK_EX);  // 排他锁
// 或
flock(fd, LOCK_SH);  // 共享锁

// 解锁
flock(fd, LOCK_UN);

// 非阻塞锁定
if (flock(fd, LOCK_EX | LOCK_NB) != 0) {
    // 无法获取锁
}

// flock 特性:
// - 整个文件锁，不是字节范围
// - 咨询锁，不阻止其他进程访问
// - 自动释放 (close 时或 fork 后)
```

### fcntl 范围锁

```cpp
#include <unistd.h>
#include <fcntl.h>

struct flock fl;
fl.l_type = F_RDLCK;   // F_WRLCK, F_RDLCK, F_UNLCK
fl.l_whence = SEEK_SET;
fl.l_start = 0;        // 起始偏移
fl.l_len = 0;          // 0 = 直到 EOF
fl.l_pid = getpid();

// 获取锁
if (fcntl(fd, F_SETLKW, &fl) < 0) {  // 阻塞
    // 获取失败
}

// 非阻塞
if (fcntl(fd, F_SETLK, &fl) < 0) {
    if (errno == EACCES || errno == EAGAIN) {
        // 已被占用
    }
}

// 释放锁
fl.l_type = F_UNLCK;
fcntl(fd, F_SETLK, &fl);

// 查看锁状态
fl.l_type = F_WRLCK;
fcntl(fd, F_GETLK, &fl);  // 返回锁信息
```

### 锁的继承和释放

```
flock 锁:
- fork 后子进程不继承锁
- close() 自动释放锁
- 线程共享锁

fcntl 锁:
- 锁与进程关联，fork 后子进程有自己的锁副本
- exec() 保留锁
- close() 释放该 fd 的所有锁
- 线程共享锁 (同一进程的线程共享同一文件表项)
```

---

## 性能比较

### I/O 方式性能

| 方式 | 适用场景 | 延迟 | 吞吐量 |
|------|----------|------|--------|
| read/write (缓冲) | 小文件，顺序访问 | 中 | 高 |
| read/write (无缓冲) | 大文件，需要控制 | 中 | 高 |
| mmap | 随机访问，共享内存 | 低 | 极高 |
| splice | 大数据流传输 | 极低 | 极高 |
| O_DIRECT | 数据库，定制缓存 | 低 | 高 |

### 选择指南

```
1. 大文件顺序传输: splice
2. 随机访问文件: mmap
3. 需要绕过内核缓存: O_DIRECT
4. 标准文件操作: 普通 read/write
5. 进程间共享内存: mmap + shm_open
```
