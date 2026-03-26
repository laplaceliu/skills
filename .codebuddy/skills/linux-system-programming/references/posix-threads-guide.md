# POSIX 线程编程指南

## 线程基础

### 线程与进程对比

| 特性 | 线程 | 进程 |
|------|------|------|
| 地址空间 | 共享 | 独立 |
| 资源 | 共享 (打开的文件、内存等) | 独立 |
| 创建速度 | 快 (~10x) | 慢 |
| 通信 | 直接共享内存 | 需要 IPC |
| 隔离性 | 无 (一个崩溃影响全部) | 隔离 |
| 栈大小 | 默认 8MB | 默认 8MB |

### 线程 ID

```cpp
#include <pthread.h>
#include <unistd.h>

pthread_t tid = pthread_self();           // 获取当前线程 ID
pthread_equal(tid1, tid2);                // 比较两个线程 ID
printf("Thread ID: %lu\n", (unsigned long)tid);  // 打印
```

---

## 线程创建与终止

### 创建线程

```cpp
#include <pthread.h>
#include <cstdlib>
#include <cstring>

void* thread_function(void* arg) {
    int id = *(int*)arg;
    delete (int*)arg;  // 清理参数内存

    // 线程工作
    for (int i = 0; i < 10; ++i) {
        printf("Thread %d: %d\n", id, i);
    }

    return reinterpret_cast<void*>(id);  // 返回值
}

int main() {
    pthread_t threads[3];
    for (int i = 0; i < 3; ++i) {
        int* id = new int(i);  // 动态分配避免栈复制问题
        int ret = pthread_create(&threads[i], nullptr, thread_function, id);
        if (ret != 0) {
            fprintf(stderr, "pthread_create failed: %s\n", strerror(ret));
            delete id;
        }
    }

    // 等待所有线程结束
    for (int i = 0; i < 3; ++i) {
        void* retval;
        pthread_join(threads[i], &retval);
        printf("Thread %d returned: %ld\n", i, (long)retval);
    }
}
```

### 线程属性

```cpp
#include <pthread.h>
#include <cstring>

pthread_attr_t attr;
pthread_attr_init(&attr);
pthread_attr_destroy(&attr);

// 设置栈大小
size_t stack_size = 2 * 1024 * 1024;  // 2MB
pthread_attr_setstacksize(&attr, stack_size);

// 设置守护线程 (分离状态)
pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);

// 获取属性
size_t get_stack_size;
pthread_attr_getstacksize(&attr, &get_stack_size);
int detach_state;
pthread_attr_getdetachstate(&attr, &detach_state);
```

### 线程终止

```cpp
// 方式 1: 从入口函数返回
void* thread_func(void* arg) {
    return result;  // main 中 pthread_join 可获取
}

// 方式 2: pthread_exit
void* thread_func(void* arg) {
    pthread_exit(reinterpret_cast<void*>(42));  // 返回 42
}

// 方式 3: 取消线程
pthread_cancel(tid);  // 请求取消

// 注意: pthread_cancel 需要目标线程启用取消点才生效
```

---

## 互斥锁 (Mutex)

### 基本互斥锁

```cpp
#include <pthread.h>
#include <mutex>
#include <cstdio>

class SafeCounter {
public:
    SafeCounter() : count_(0) {}

    void increment() {
        pthread_mutex_lock(&mutex_);
        ++count_;
        pthread_mutex_unlock(&mutex_);
    }

    int get() const {
        pthread_mutex_lock(&mutex_);
        int result = count_;
        pthread_mutex_unlock(&mutex_);
        return result;
    }

private:
    mutable pthread_mutex_t mutex_ = PTHREAD_MUTEX_INITIALIZER;
    int count_;
};

// RAII 锁守卫 (推荐)
template<typename T>
class LockGuard {
public:
    explicit LockGuard(T& mutex) : mutex_(mutex) { mutex_.lock(); }
    ~LockGuard() { mutex_.unlock(); }
    LockGuard(const LockGuard&) = delete;
    LockGuard& operator=(const LockGuard&) = delete;
private:
    T& mutex_;
};

void increment_safe() {
    static pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    LockGuard<pthread_mutex_t> lock(mutex);  // RAII 自动解锁
    // 临界区代码
}
```

### 互斥锁属性

```cpp
#include <pthread.h>

pthread_mutexattr_t attr;
pthread_mutexattr_init(&attr);

// 互斥锁类型
pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL);
// PTHREAD_MUTEX_NORMAL: 不检测死锁，可能重入
// PTHREAD_MUTEX_ERRORCHECK: 检测死锁，返回错误
// PTHREAD_MUTEX_RECURSIVE: 允许递归加锁，记录锁计数
// PTHREAD_MUTEX_DEFAULT: 系统默认 (通常同 NORMAL)

// 进程共享属性
pthread_mutexattr_setpshared(&attr, PTHREAD_PROCESS_PRIVATE);  // 仅同进程 (默认)
// PTHREAD_PROCESS_SHARED: 允许跨进程共享 (需要放在共享内存中)

pthread_mutex_t mutex;
pthread_mutex_init(&mutex, &attr);
pthread_mutexattr_destroy(&attr);
```

### 递归互斥锁

```cpp
pthread_mutex_t mutex;
pthread_mutexattr_t attr;
pthread_mutexattr_init(&attr);
pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE);
pthread_mutex_init(&mutex, &attr);

// 同一个线程可以多次加锁
pthread_mutex_lock(&mutex);    // count = 1
pthread_mutex_lock(&mutex);    // count = 2
pthread_mutex_unlock(&mutex);  // count = 1
pthread_mutex_unlock(&mutex);  // count = 0，解锁

pthread_mutex_destroy(&mutex);
pthread_mutexattr_destroy(&attr);
```

---

## 条件变量

### 基础用法

```cpp
#include <pthread.h>
#include <queue>
#include <cstdio>

class ThreadSafeQueue {
public:
    void push(int value) {
        pthread_mutex_lock(&mutex_);
        queue_.push(value);
        pthread_cond_signal(&cond_);  // 通知等待的线程
        pthread_mutex_unlock(&mutex_);
    }

    int pop() {
        pthread_mutex_lock(&mutex_);
        while (queue_.empty()) {
            pthread_cond_wait(&cond_, &mutex_);  // 原子性解锁并等待
        }
        int value = queue_.front();
        queue_.pop();
        pthread_mutex_unlock(&mutex_);
        return value;
    }

    bool try_pop(int& value) {
        pthread_mutex_lock(&mutex_);
        if (queue_.empty()) {
            pthread_mutex_unlock(&mutex_);
            return false;
        }
        value = queue_.front();
        queue_.pop();
        pthread_mutex_unlock(&mutex_);
        return true;
    }

private:
    pthread_mutex_t mutex_ = PTHREAD_MUTEX_INITIALIZER;
    pthread_cond_t cond_ = PTHREAD_COND_INITIALIZER;
    std::queue<int> queue_;
};
```

### 带超时的条件变量

```cpp
#include <pthread.h>
#include <ctime>
#include <cerrno>

bool pop_with_timeout(std::queue<int>& queue, int& value, int timeout_ms) {
    pthread_mutex_lock(&mutex_);

    // 计算绝对超时时间
    timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    ts.tv_sec += timeout_ms / 1000;
    ts.tv_nsec += (timeout_ms % 1000) * 1'000'000;
    if (ts.tv_nsec >= 1'000'000'000) {
        ts.tv_sec += 1;
        ts.tv_nsec -= 1'000'000'000;
    }

    int ret;
    while (queue_.empty()) {
        ret = pthread_cond_timedwait(&cond_, &mutex_, &ts);
        if (ret == ETIMEDOUT) {
            pthread_mutex_unlock(&mutex_);
            return false;
        }
        if (ret != 0) {
            pthread_mutex_unlock(&mutex_);
            throw std::runtime_error("pthread_cond_timedwait failed");
        }
    }

    value = queue_.front();
    queue_.pop();
    pthread_mutex_unlock(&mutex_);
    return true;
}
```

### 生产者-消费者模式

```cpp
#include <pthread.h>
#include <queue>
#include <semaphore.h>
#include <cstdio>
#include <cstdlib>
#include <unistd.h>

const int BUFFER_SIZE = 10;
std::queue<int> buffer;

pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t not_full = PTHREAD_COND_INITIALIZER;
pthread_cond_t not_empty = PTHREAD_COND_INITIALIZER;

void* producer(void* arg) {
    for (int i = 0; i < 20; ++i) {
        pthread_mutex_lock(&mutex);
        while (buffer.size() >= BUFFER_SIZE) {
            pthread_cond_wait(&not_full, &mutex);
        }
        buffer.push(i);
        printf("Producer: produced %d\n", i);
        pthread_cond_signal(&not_empty);
        pthread_mutex_unlock(&mutex);
        usleep(rand() % 100'000);
    }
    return nullptr;
}

void* consumer(void* arg) {
    for (int i = 0; i < 20; ++i) {
        pthread_mutex_lock(&mutex);
        while (buffer.empty()) {
            pthread_cond_wait(&not_empty, &mutex);
        }
        int value = buffer.front();
        buffer.pop();
        printf("Consumer: consumed %d\n", value);
        pthread_cond_signal(&not_full);
        pthread_mutex_unlock(&mutex);
        usleep(rand() % 100'000);
    }
    return nullptr;
}
```

---

## 读写锁

### 基本读写锁

```cpp
#include <pthread.h>
#include <map>
#include <string>
#include <cstdio>

class ReadWriteStore {
public:
    void write(const std::string& key, const std::string& value) {
        pthread_rwlock_wrlock(&rwlock_);
        store_[key] = value;
        pthread_rwlock_unlock(&rwlock_);
    }

    bool read(const std::string& key, std::string& value) const {
        pthread_rwlock_rdlock(&rwlock_);
        auto it = store_.find(key);
        if (it != store_.end()) {
            value = it->second;
            pthread_rwlock_unlock(&rwlock_);
            return true;
        }
        pthread_rwlock_unlock(&rwlock_);
        return false;
    }

private:
    mutable pthread_rwlock_t rwlock_ = PTHREAD_RWLOCK_INITIALIZER;
    std::map<std::string, std::string> store_;
};

// 读多写少场景: 多个读线程并行，写时独占
```

### 读写锁属性

```cpp
pthread_rwlockattr_t attr;
pthread_rwlockattr_init(&attr);

// 设置进程共享属性
pthread_rwlockattr_setpshared(&attr, PTHREAD_PROCESS_SHARED);

pthread_rwlock_t rwlock;
pthread_rwlock_init(&rwlock, &attr);
pthread_rwlockattr_destroy(&attr);
```

---

## 线程局部存储 (TLS)

### pthread_key_create

```cpp
#include <pthread.h>
#include <cstdlib>
#include <cerrno>

pthread_key_t thread_log_key;
pthread_once_t once = PTHREAD_ONCE_INIT;

void init_once() {
    pthread_key_create(&thread_log_key, [](void* ptr) {
        // 线程退出时调用，清理线程本地数据
        if (ptr) {
            free(ptr);
        }
    });
}

void set_thread_log(void* log) {
    pthread_once(&once, init_once);
    pthread_setspecific(thread_log_key, log);
}

void* get_thread_log() {
    pthread_once(&once, init_once);
    return pthread_getspecific(thread_log_key);
}
```

### C++11 thread_local

```cpp
#include <thread>
#include <iostream>
#include <vector>

thread_local int thread_id = 0;
thread_local std::vector<int> local_data;

void worker(int id) {
    thread_id = id;
    for (int i = 0; i < 3; ++i) {
        local_data.push_back(i);
        std::cout << "Thread " << thread_id << ": " << i << "\n";
    }
}

int main() {
    std::vector<std::thread> threads;
    for (int i = 0; i < 3; ++i) {
        threads.emplace_back(worker, i);
    }
    for (auto& t : threads) {
        t.join();
    }
}
```

---

## 信号量 (Semaphore)

### POSIX 无名信号量

```cpp
#include <semaphore.h>
#include <pthread.h>
#include <unistd.h>

sem_t sem;  // 生产者信号量
sem_t empty;  // 空槽信号量
sem_t full;   // 满槽信号量

void sem_init_all() {
    sem_init(&empty, 0, 10);  // 10 个空槽
    sem_init(&full, 0, 0);     // 0 个满槽
}

void producer(int item) {
    sem_wait(&empty);           // 等待空槽
    sem_wait(&mutex);           // 保护临界区
    // 放入数据
    sem_post(&mutex);
    sem_post(&full);            // 增加满槽计数
}

void consumer(int& item) {
    sem_wait(&full);            // 等待满槽
    sem_wait(&mutex);           // 保护临界区
    // 取出数据
    sem_post(&mutex);
    sem_post(&empty);           // 增加空槽计数
}

void sem_destroy_all() {
    sem_destroy(&empty);
    sem_destroy(&full);
}
```

### POSIX 有名信号量

```cpp
#include <semaphore.h>

// 创建/打开有名信号量
sem_t* sem = sem_open("/my_sem", O_CREAT, 0666, 1);
// name 必须以 / 开头

// 使用
sem_wait(sem);    // P 操作
sem_post(sem);    // V 操作
sem_getvalue(sem, &value);

// 关闭和删除
sem_close(sem);
sem_unlink("/my_sem");
```

---

## 线程同步规则

### 死锁避免

```
1. 固定加锁顺序
   - 如果必须获取多个锁，总是按相同顺序加锁
   - 例如: 先 lock(A) 再 lock(B)

2. 使用 trylock 检测死锁
   pthread_mutex_trylock(&mutex);  // 失败返回 EBUSY

3. 避免嵌套锁
   - 一个线程应该最多持有一个互斥锁

4. 使用 RAII 自动解锁
   - 避免在持有锁时提前返回或异常
```

### 竞态条件检测

```
1. 确认所有共享数据都被互斥锁保护
2. 检查 unlock 位置是否正确
3. 检查是否有非原子操作被多个步骤分割
4. 使用 ThreadSanitizer 检测: -fsanitize=thread
```

### 线程安全设计

```
1. 最小化锁粒度
2. 使用读写锁区分读写操作
3. 优先使用无锁数据结构 (atomic)
4. 使用条件变量而非轮询
5. 避免忙等待 (busy waiting)
```

---

## 高级主题

### 线程取消

```cpp
#include <pthread.h>

// 设置取消状态
pthread_setcancelstate(PTHREAD_CANCEL_ENABLE, &old_state);  // 默认
pthread_setcancelstate(PTHREAD_CANCEL_DISABLE, &old_state);

// 设置取消类型
pthread_setcanceltype(PTHREAD_CANCEL_ASYNCHRONOUS, &old_type);  // 立即
pthread_setcanceltype(PTHREAD_CANCEL_DEFERRED, &old_type);       // 默认 (取消点)

// 取消点: pthread_join, pthread_cond_wait, sem_wait, read, write, etc.

// 测试取消
pthread_testcancel();
```

### 线程优先级

```cpp
#include <pthread.h>
#include <sched.h>

// 获取线程调度策略
int policy;
sched_param param;
pthread_getschedparam(pthread_self(), &policy, &param);

// 设置实时调度
param.sched_priority = 50;
pthread_setschedparam(pthread_self(), SCHED_RR, &param);

// 获取 min/max 优先级
int min_prio = sched_get_priority_min(SCHED_FIFO);
int max_prio = sched_get_priority_max(SCHED_FIFO);
```

### 线程栈大小

```cpp
#include <pthread.h>
#include <cstdio>

// 获取默认栈大小
size_t default_size;
pthread_attr_getstacksize(&attr, &default_size);
printf("Default stack size: %zu\n", default_size);

// 设置最小栈大小 (必须 >= PTHREAD_STACK_MIN)
size_t min_size;
pthread_attr_getstacksize(&attr, &min_size);
```
