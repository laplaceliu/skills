# Linux 系统调用快速参考

## 文件 I/O

### open

```c
#include <fcntl.h>

int open(const char *pathname, int flags, ... /* mode_t mode */);
// flags: O_RDONLY, O_WRONLY, O_RDWR, O_CREAT, O_EXCL, O_TRUNC, O_APPEND,
//        O_NONBLOCK, O_CLOEXEC, O_DIRECT, O_DSYNC, O_SYNC, O_NOCTTY
// mode: 0666, 0644, etc. (当 O_CREAT 时需要)

// 示例
int fd = open("/path/to/file", O_RDWR | O_CREAT | O_CLOEXEC, 0644);
```

### close

```c
int close(int fd);
// 成功返回 0，失败返回 -1
// 关闭后文件描述符不再有效
```

### read

```c
ssize_t read(int fd, void *buf, size_t count);
// 返回读取的字节数，0 表示 EOF，-1 表示错误
// 可能返回少于请求的字节数 (部分 I/O)
```

### write

```c
ssize_t write(int fd, const void *buf, size_t count);
// 返回写入的字节数，-1 表示错误
// 可能返回少于请求的字节数
```

### lseek

```c
#include <sys/types.h>

off_t lseek(int fd, off_t offset, int whence);
// whence: SEEK_SET (相对文件开头), SEEK_CUR (相对当前位置), SEEK_END (相对文件末尾)
// 返回新的文件偏移
```

### ftruncate

```c
int ftruncate(int fd, off_t length);
// 扩展或截断文件到指定长度
```

### stat / fstat / lstat

```c
#include <sys/stat.h>

int stat(const char *pathname, struct stat *statbuf);
int fstat(int fd, struct stat *statbuf);
int lstat(const char *pathname, struct stat *statbuf);  // 不跟随符号链接

// stat 结构
struct stat {
    dev_t     st_dev;      // 设备 ID
    ino_t     st_ino;      // inode 号
    mode_t    st_mode;     // 文件类型和权限
    nlink_t   st_nlink;    // 硬链接数
    uid_t     st_uid;      // 所有者 UID
    gid_t     st_gid;      // 所有者 GID
    dev_t     st_rdev;     // 设备号 (如果是设备文件)
    off_t     st_size;     // 文件大小 (字节)
    blksize_t st_blksize;  // I/O 块大小
    blkcnt_t  st_blocks;   // 分配的块数
    time_t    st_atime;    // 最后访问时间
    time_t    st_mtime;    // 最后修改时间
    time_t    st_ctime;    // 最后状态改变时间
};

// 文件类型宏
S_ISREG(st_mode)   // 普通文件
S_ISDIR(st_mode)   // 目录
S_ISLNK(st_mode)   // 符号链接
S_ISCHR(st_mode)   // 字符设备
S_ISBLK(st_mode)   // 块设备
S_ISFIFO(st_mode)  // FIFO
S_ISSOCK(st_mode)  // Socket
```

---

## 进程管理

### fork

```c
#include <unistd.h>

pid_t fork(void);
// 成功: 父进程中返回子进程 PID，子进程中返回 0
// 失败: 父进程返回 -1，不创建子进程
```

### exec 系列

```c
// 替换当前进程镜像
int execl(const char *path, const char *arg, ... /* (char *) NULL */);
int execlp(const char *file, const char *arg, ... /* (char *) NULL */);
int execv(const char *path, char *const argv[]);
int execvp(const char *file, char *const argv[]);
int execve(const char *path, char *const argv[], char *const envp[]);
// 成功不返回，失败返回 -1
```

### wait / waitpid

```c
#include <sys/wait.h>

pid_t wait(int *wstatus);
pid_t waitpid(pid_t pid, int *wstatus, int options);
// pid: -1 (任意子进程), >0 (指定 PID), 0 (同组), -1 (同组)
// options: WNOHANG (非阻塞), WUNTRACED, WCONTINUED
// 返回: PID 或 0 (WNOHANG) 或 -1 (失败)

// 状态宏
WIFEXITED(wstatus)      // 正常退出
WEXITSTATUS(wstatus)     // 退出码
WIFSIGNALED(wstatus)     // 信号终止
WTERMSIG(wstatus)        // 终止信号
WIFSTOPPED(wstatus)      // 停止
WSTOPSIG(wstatus)        // 停止信号
WIFCONTINUED(wstatus)    // 继续
```

### _exit

```c
void _exit(int status);
// _exit() 直接终止进程，不执行清理 (atexit, fclose 等)
// 用于子进程 exit 或 fork 后 exec 失败
```

### getpid / getppid

```c
#include <unistd.h>

pid_t getpid(void);   // 获取当前进程 PID
pid_t getppid(void);  // 获取父进程 PID
```

### setsid

```c
#include <unistd.h>

pid_t setsid(void);
// 创建新会话，成为会话首领，脱离控制终端
// 成功返回 PID，失败返回 -1
```

---

## 线程管理

### pthread_create

```c
#include <pthread.h>

int pthread_create(pthread_t *thread, const pthread_attr_t *attr,
                   void *(*start_routine) (void *), void *arg);
// attr: NULL (默认属性) 或 pthread_attr_t 对象
// 成功返回 0，失败返回错误码
```

### pthread_join

```c
int pthread_join(pthread_t thread, void **retval);
// 等待指定线程结束，获取返回值
// 成功返回 0，失败返回错误码
```

### pthread_detach

```c
int pthread_detach(pthread_t thread);
// 分离线程，结束后自动回收资源
// 分离后不能 join
```

### pthread_exit

```c
void pthread_exit(void *retval);
// 终止调用线程，返回值可被 pthread_join 获取
```

### pthread_self

```c
pthread_t pthread_self(void);
// 返回当前线程 ID
```

### pthread_mutex

```c
#include <pthread.h>

pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;  // 静态初始化
// 或动态初始化
pthread_mutex_t mutex;
pthread_mutex_init(&mutex, NULL);  // attr = NULL 默认属性
pthread_mutex_destroy(&mutex);

pthread_mutex_lock(&mutex);
pthread_mutex_trylock(&mutex);   // 失败返回 EBUSY
pthread_mutex_unlock(&mutex);
```

### pthread_cond

```c
#include <pthread.h>

pthread_cond_t cond = PTHREAD_COND_INITIALIZER;
pthread_cond_init(&cond, NULL);
pthread_cond_destroy(&cond);

pthread_cond_wait(&cond, &mutex);           // 等待条件变量
pthread_cond_timedwait(&cond, &mutex, &abs_timeout);  // 带超时
pthread_cond_signal(&cond);                 // 唤醒一个等待线程
pthread_cond_broadcast(&cond);              // 唤醒所有等待线程

// timespec 结构
struct timespec {
    time_t tv_sec;   // 秒
    long   tv_nsec;  // 纳秒
};
```

### pthread_rwlock

```c
#include <pthread.h>

pthread_rwlock_t rwlock = PTHREAD_RWLOCK_INITIALIZER;
pthread_rwlock_init(&rwlock, NULL);
pthread_rwlock_destroy(&rwlock);

pthread_rwlock_rdlock(&rwlock);   // 读锁
pthread_rwlock_wrlock(&rwlock);   // 写锁
pthread_rwlock_unlock(&rwlock);
pthread_rwlock_tryrdlock(&rwlock);
pthread_rwlock_trywrlock(&rwlock);
```

---

## 内存管理

### mmap / munmap

```c
#include <sys/mman.h>

void *mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
// prot: PROT_READ, PROT_WRITE, PROT_EXEC, PROT_NONE
// flags: MAP_PRIVATE (写时复制), MAP_SHARED (共享), MAP_ANONYMOUS (匿名)
//       MAP_FIXED, MAP_HUGETLB, MAP_STACK
// 成功返回映射地址，失败返回 MAP_FAILED

int munmap(void *addr, size_t length);
```

### mprotect

```c
int mprotect(void *addr, size_t len, int prot);
// 改变映射区域的保护属性
```

### mlock / munlock

```c
int mlock(const void *addr, size_t len);     // 锁定物理内存
int munlock(const void *addr, size_t len);
int mlockall(int flags);                       // MCL_CURRENT, MCL_FUTURE
int munlockall(void);
```

### brk / sbrk

```c
#include <unistd.h>

void *sbrk(intptr_t increment);
// 调整程序 break，改变堆大小
// sbrk(0) 返回当前 break
```

---

## 信号处理

### signal

```c
#include <signal.h>

typedef void (*sighandler_t)(int);
sighandler_t signal(int signum, sighandler_t handler);
// 注意: signal() 行为不确定，推荐使用 sigaction()
```

### sigaction

```c
#include <signal.h>

int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact);

struct sigaction {
    void     (*sa_handler)(int);           // 信号处理函数
    void     (*sa_sigaction)(int, siginfo_t *, void *);  // 备用
    sigset_t   sa_mask;                    // 阻塞信号集
    int        sa_flags;                   // 标志
    void     (*sa_restorer)(void);          // 已废弃
};

// sa_flags
SA_NOCLDSTOP    // 子进程停止时不收到 SIGCHLD
SA_ONESHOT      // 处理后恢复为默认
SA_RESTART      // 自动重启被信号中断的系统调用
SA_SIGINFO      // 使用 sa_sigaction

// 使用示例
struct sigaction sa;
sa.sa_handler = handler;
sigemptyset(&sa.sa_mask);
sa.sa_flags = 0;
sigaction(SIGINT, &sa, NULL);
```

### 信号相关函数

```c
#include <signal.h>

int raise(int sig);                    // 给当前进程发信号
int kill(pid_t pid, int sig);          // 给指定进程发信号
int pthread_kill(pthread_t thread, int sig);  // 给指定线程发信号

int sigemptyset(sigset_t *set);
int sigfillset(sigset_t *set);
int sigaddset(sigset_t *set, int signum);
int sigdelset(sigset_t *set, int signum);
int sigismember(const sigset_t *set, int signum);

int sigprocmask(int how, const sigset_t *set, sigset_t *oldset);
// how: SIG_BLOCK, SIG_UNBLOCK, SIG_SETMASK

int sigpending(sigset_t *set);         // 获取未决信号
int sigsuspend(const sigimask_t *sigmask);  // 原子性替换信号掩码并等待信号

// sigwaitinfo / sigtimedwait
int sigwaitinfo(const sigset_t *set, siginfo_t *info);
int sigtimedwait(const sigset_t *set, siginfo_t *info, const struct timespec *timeout);
```

### 常用信号

| 信号 | 默认动作 | 说明 |
|------|---------|------|
| SIGINT | 终止 | Ctrl+C |
| SIGTERM | 终止 | 优雅终止请求 |
| SIGKILL | 终止 | 强制终止 (不可捕获/忽略) |
| SIGSEGV | 终止 | 段错误 |
| SIGBUS | 终止 | 总线错误 |
| SIGFPE | 终止 | 浮点异常 |
| SIGCHLD | 忽略 | 子进程退出 |
| SIGPIPE | 终止 | 写已关闭的 pipe |
| SIGHUP | 终止 | 终端断开 |
| SIGALRM | 终止 | 定时器信号 |
| SIGUSR1/2 | 终止 | 用户自定义 |

---

## 进程间通信

### pipe

```c
#include <unistd.h>

int pipe(int pipefd[2]);
// pipefd[0] = 读端, pipefd[1] = 写端
// 成功返回 0，失败返回 -1
```

### mkfifo

```c
#include <sys/stat.h>

int mkfifo(const char *pathname, mode_t mode);
// 创建命名管道
```

### socketpair

```c
#include <sys/socket.h>

int socketpair(int domain, int type, int protocol, int sv[2]);
// 创建一对已连接的 socket
// domain: AF_UNIX, AF_INET
// type: SOCK_STREAM, SOCK_DGRAM
```

### shmget / shmat / shmdt / shmctl (System V)

```c
#include <sys/shm.h>

int shmget(key_t key, size_t size, int shmflg);
// IPC_PRIVATE 或 ftok() 生成 key
// shmflg: IPC_CREAT, IPC_EXCL, mode

void *shmat(int shmid, const void *shmaddr, int shmflg);
int shmdt(const void *shmaddr);

int shmctl(int shmid, int cmd, struct shmid_ds *buf);
// cmd: IPC_STAT, IPC_SET, IPC_RMID
```

### shm_open / shm_unlink (POSIX)

```c
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>

int shm_open(const char *name, int oflag, mode_t mode);
int shm_unlink(const char *name);
// name 必须以 / 开头，如 "/my_shm"
// oflag: O_RDONLY, O_RDWR, O_CREAT, O_EXCL, O_TRUNC
```

### mq_open / mq_close / mq_unlink (POSIX)

```c
#include <mqueue.h>

mqd_t mq_open(const char *name, int oflag, ... /* mode_t mode, struct mq_attr *attr */);
int mq_close(mqd_t mqdes);
int mq_unlink(const char *name);

int mq_send(mqd_t mqdes, const char *msg_ptr, size_t msg_len, unsigned int msg_prio);
ssize_t mq_receive(mqd_t mqdes, char *msg_ptr, size_t msg_len, unsigned int *msg_prio);
int mq_getattr(mqd_t mqdes, struct mq_attr *attr);
int mq_setattr(mqd_t mqdes, const struct mq_attr *newattr, struct mq_attr *oldattr);
```

---

## 网络编程

### socket

```c
#include <sys/socket.h>

int socket(int domain, int type, int protocol);
// domain: AF_INET (IPv4), AF_INET6 (IPv6), AF_UNIX, AF_UNIX
// type: SOCK_STREAM (TCP), SOCK_DGRAM (UDP), SOCK_RAW
// protocol: 0 (自动选择) 或 IPPROTO_TCP, IPPROTO_UDP
```

### bind

```c
#include <sys/socket.h>

int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);

// IPv4
struct sockaddr_in {
    sa_family_t    sin_family;  // AF_INET
    in_port_t      sin_port;    // 端口号 (网络字节序)
    struct in_addr sin_addr;    // IP 地址
};
struct in_addr {
    uint32_t       s_addr;       // 网络字节序
};

// IP 地址转换
#include <arpa/inet.h>
int inet_pton(int af, const char *src, void *dst);  // 字符串 -> 二进制
const char *inet_ntop(int af, const void *src, char *dst, socklen_t size);  // 二进制 -> 字符串
```

### listen

```c
int listen(int sockfd, int backlog);
// backlog: 半连接队列长度 (SYN queue)
// 通常设置为 128 或更大
```

### accept

```c
int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
// 返回新的连接 socketfd
// 阻塞直到有连接到达
```

### connect

```c
int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
// TCP: 三次握手
// UDP: 不实际发送数据，只是记录地址
```

### send / recv

```c
#include <sys/socket.h>

ssize_t send(int sockfd, const void *buf, size_t len, int flags);
ssize_t recv(int sockfd, void *buf, size_t len, int flags);
// flags: MSG_OOB, MSG_PEEK, MSG_DONTWAIT, MSG_WAITALL

ssize_t sendto(int sockfd, const void *buf, size_t len, int flags,
               const struct sockaddr *dest_addr, socklen_t addrlen);
ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags,
                 struct sockaddr *src_addr, socklen_t *addrlen);
```

### poll

```c
#include <poll.h>

struct pollfd {
    int   fd;         // 文件描述符
    short events;     // 请求的事件 (输入)
    short revents;    // 返回的事件 (输出)
};

// events/revents
POLLIN      // 可读
POLLOUT     // 可写
POLLERR     // 错误
POLLHUP     // 挂起
POLLNVAL    // 无效 fd

int poll(struct pollfd *fds, nfds_t nfds, int timeout);
// timeout: 毫秒，-1 表示无限等待，0 表示立即返回
```

### epoll

```c
#include <sys/epoll.h>

int epoll_create(int size);           // 创建 epoll 实例 (size 已被忽略)
int epoll_create1(int flags);         // flags: EPOLL_CLOEXEC

int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event);
// op: EPOLL_CTL_ADD, EPOLL_CTL_MOD, EPOLL_CTL_DEL

int epoll_wait(int epfd, struct epoll_event *events, int maxevents, int timeout);
int epoll_pwait(int epfd, struct epoll_event *events, int maxevents,
                int timeout, const sigset_t *sigmask);

struct epoll_event {
    uint32_t    events;    // EPOLLIN, EPOLLOUT, EPOLLERR, EPOLLHUP, EPOLLET (边缘触发)
    epoll_data_t data;     // 用户数据
};
union epoll_data {
    void        *ptr;
    int          fd;
    uint32_t     u32;
    uint64_t     u64;
};
```

### getsockopt / setsockopt

```c
#include <sys/socket.h>

int getsockopt(int sockfd, int level, int optname, void *optval, socklen_t *optlen);
int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);

// 常用选项
// SOL_SOCKET 级别
SO_REUSEADDR    // 允许重用本地地址
SO_REUSEPORT    // 允许重用端口
SO_KEEPALIVE    // TCP 保活
SO_RCVBUF       // 接收缓冲区大小
SO_SNDBUF       // 发送缓冲区大小
SO_LINGER       // 关闭时等待数据发送完成

// SOL_TCP 级别
TCP_NODELAY     // 禁用 Nagle 算法
TCP_KEEPIDLE    // 保活空闲时间
TCP_KEEPINTVL   // 保活探测间隔
```

### getaddrinfo / freeaddrinfo

```c
#include <sys/socket.h>
#include <netdb.h>

int getaddrinfo(const char *node, const char *service,
                const struct addrinfo *hints, struct addrinfo **res);
void freeaddrinfo(struct addrinfo *res);

struct addrinfo {
    int     ai_flags;
    int     ai_family;     // AF_INET, AF_INET6, AF_UNSPEC
    int     ai_socktype;    // SOCK_STREAM, SOCK_DGRAM
    int     ai_protocol;
    socklen_t ai_addrlen;
    struct sockaddr *ai_addr;
    char   *ai_canonname;
    struct addrinfo *ai_next;
};

// 使用示例
struct addrinfo hints, *result;
memset(&hints, 0, sizeof(hints));
hints.ai_family = AF_UNSPEC;
hints.ai_socktype = SOCK_STREAM;

int ret = getaddrinfo("example.com", "http", &hints, &result);
if (ret != 0) {
    fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(ret));
    return;
}

for (struct addrinfo *rp = result; rp != NULL; rp = rp->ai_next) {
    int sfd = socket(rp->ai_family, rp->ai_socktype, rp->ai_protocol);
    if (connect(sfd, rp->ai_addr, rp->ai_addrlen) == 0) break;
    close(sfd);
}
freeaddrinfo(result);
```

---

## 时间

### time / gettimeofday / clock_gettime

```c
#include <time.h>

time_t time(time_t *tloc);
// 返回自 Epoch (1970-01-01 00:00:00 UTC) 以来的秒数

#include <sys/time.h>
int gettimeofday(struct timeval *tv, struct timezone *tz);
struct timeval {
    time_t      tv_sec;     // 秒
    suseconds_t tv_usec;    // 微秒
};

#include <time.h>
int clock_gettime(clockid_t clockid, struct timespec *tp);
struct timespec {
    time_t tv_sec;      // 秒
    long   tv_nsec;     // 纳秒
};

// clockid
CLOCK_REALTIME        // 系统实时时钟 (可被 NTP 调整)
CLOCK_MONOTONIC       // 启动后单调递增 (不受时钟调整影响)
CLOCK_PROCESS_CPUTIME_ID  // 进程 CPU 时间
CLOCK_THREAD_CPUTIME_ID   // 线程 CPU 时间
```

### sleep / nanosleep

```c
#include <unistd.h>

unsigned int sleep(unsigned int seconds);
// 返回剩余秒数

#include <time.h>
int nanosleep(const struct timespec *req, struct timespec *rem);
// 返回 0 成功，-1 失败 (errno = EINTR 表示被信号中断)

int clock_nanosleep(clockid_t clock_id, int flags,
                    const struct timespec *req, struct timespec *rem);
// flags: 0 (相对时间), TIMER_ABSTIME (绝对时间)
```

### timerfd_create / timerfd_settime

```c
#include <sys/timerfd.h>

int timerfd_create(int clockid, int flags);
// clockid: CLOCK_REALTIME, CLOCK_MONOTONIC
// flags: TFD_CLOEXEC, TFD_NONBLOCK

int timerfd_settime(int fd, int flags,
                    const struct itimerspec *new_value,
                    struct itimerspec *old_value);
// flags: 0 (相对), TFD_TIMER_ABSTIME (绝对)
// itimerspec
struct itimerspec {
    struct timespec it_value;    // 首次触发时间
    struct timespec it_interval; // 周期
};
```

---

## 环境与资源

### getenv / setenv / unsetenv

```c
#include <stdlib.h>

char *getenv(const char *name);
int setenv(const char *name, const char *value, int overwrite);
int unsetenv(const char *name);
// setenv: overwrite = 0 时若已存在则不修改
```

### getrlimit / setrlimit / prlimit

```c
#include <sys/resource.h>

int getrlimit(int resource, struct rlimit *rlim);
int setrlimit(int resource, const struct rlimit *rlim);
int prlimit(pid_t pid, int resource, const struct rlimit *new_limit, struct rlimit *old_limit);

struct rlimit {
    rlim_t rlim_cur;  // 软限制 (当前)
    rlim_t rlim_max;  // 硬限制 (上限)
};

// 资源类型
RLIMIT_AS       // 地址空间 (进程虚拟内存大小)
RLIMIT_CORE     // core 文件最大大小
RLIMIT_CPU      // CPU 时间 (秒)
RLIMIT_DATA     // 数据段 + 堆 + 栈最大大小
RLIMIT_FSIZE    // 文件大小最大限制
RLIMIT_NOFILE   // 打开文件描述符最大数量
RLIMIT_NPROC    // 用户可创建最大进程数
RLIMIT_RSS      // 常驻内存大小
RLIMIT_STACK    // 栈大小
```

### sysconf

```c
#include <unistd.h>

long sysconf(int name);
// name: _SC_PAGESIZE, _SC_CLK_TCK, _SC_OPEN_MAX, _SC_NPROCESSORS_ONLN, etc.
```
