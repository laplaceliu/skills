# RTOS 选择与移植指南

## 主流 RTOS 对比

| RTOS | 许可 | 体积 | 实时性 | 适用场景 | 学习曲线 |
|------|------|------|--------|----------|----------|
| FreeRTOS | MIT | ~10KB | 硬实时 | 通用 | 低 |
| RT-Thread | Apache 2.0 | ~5KB | 软实时 | IoT、消费电子 | 中 |
| Zephyr | Apache 2.0 | 可配置 | 可配置 | IoT、工业 | 中 |
| Azure RTOS | MIT | ~20KB | 硬实时 | 汽车、医疗 | 高 |
| embOS | 闭源 | ~5KB | 硬实时 | 汽车、工业 | 中 |
| µC/OS-II/III | 闭源 | ~6KB | 硬实时 | 航空航天 | 高 |

## FreeRTOS

### 特点
- 最流行的开源 RTOS
- 社区活跃，文档丰富
- 广泛的芯片支持
- 商业友好 (MIT 许可)

### 任务管理

```cpp
#include "FreeRTOS.h"
#include "task.h"

// 静态任务创建 (推荐)
StackType_t task_stack[configMINIMAL_STACK_SIZE];
StaticTask_t task_buffer;

void vTaskFunction(void* params) {
    while (true) {
        // 任务逻辑
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

// 创建任务
TaskHandle_t handle = xTaskCreateStatic(
    vTaskFunction,
    "TaskName",
    configMINIMAL_STACK_SIZE,
    nullptr,
    1,  // 优先级
    task_stack,
    &task_buffer
);

// 删除任务
vTaskDelete(handle);
```

### 队列通信

```cpp
QueueHandle_t queue = xQueueCreate(10, sizeof(Message));

// 发送
Message msg = { .id = 1, .data = 42 };
xQueueSend(queue, &msg, pdMS_TO_TICKS(10));

// 接收
Message recv_msg;
if (xQueueReceive(queue, &recv_msg, pdMS_TO_TICKS(100)) == pdTRUE) {
    // 处理消息
}
```

### 互斥锁

```cpp
SemaphoreHandle_t mutex = xSemaphoreCreateMutex();

// 获取
xSemaphoreTake(mutex, pdMS_TO_TICKS(10));

// 临界区代码
access_shared_resource();

// 释放
xSemaphoreGive(mutex);
```

## RT-Thread

### 特点
- 国产 RTOS，文档中文友好
- 组件丰富 (文件系统、网络、GUI)
- 良好的 IoT 生态
- 体积小

### 线程管理

```cpp
#include <rtthread.h>

void thread_entry(void* param) {
    while (true) {
        // 线程逻辑
        rt_thread_mdelay(100);
    }
}

int thread_demo() {
    rt_thread_t tid = rt_thread_create(
        "thread1",
        thread_entry,
        RT_NULL,
        1024,    // 栈大小
        10,       // 优先级
        10        // 时间片
    );

    if (tid != RT_NULL) {
        rt_thread_startup(tid);
    }
    return 0;
}
MSH_CMD_EXPORT(thread_demo, thread demo);
```

### 信号量与互斥

```cpp
// 信号量
rt_sem_t sem = rt_sem_create("sem", 0, RT_IPC_FLAG_FIFO);

// 等待信号量
rt_err_t err = rt_sem_take(sem, RT_WAITING_FOREVER);

// 释放信号量
rt_sem_release(sem);

// 互斥锁
rt_mutex_t mutex = rt_mutex_create("mutex", RT_IPC_FLAG_FIFO);
rt_mutex_take(mutex, RT_WAITING_FOREVER);
// 临界区
rt_mutex_release(mutex);
```

## Zephyr

### 特点
- Linux 基金会支持
- 高度可配置 (Kconfig)
- 优秀的蓝牙、网络支持
- 与 Yocto、Buildroot 集成良好

### 线程

```cpp
#include <zephyr.h>
#include <device.h>

#define STACK_SIZE 1024

K_THREAD_STACK_DEFINE(thread_stack, STACK_SIZE);
struct k_thread thread_data;

void thread_entry(void* arg1, void* arg2, void* arg3) {
    while (true) {
        // 线程逻辑
        k_sleep(K_MSEC(100));
    }
}

// 创建线程
k_thread_create(&thread_data, thread_stack, STACK_SIZE,
                thread_entry, NULL, NULL, NULL,
                5, 0, K_NO_WAIT);
```

### 同步原语

```cpp
// 信号量
struct k_sem my_sem;
k_sem_init(&my_sem, 0, 1);

k_sem_take(&my_sem, K_FOREVER);
k_sem_give(&my_sem);

// 互斥锁
struct k_mutex my_mutex;
k_mutex_init(&my_mutex);

k_mutex_lock(&my_mutex, K_FOREVER);
// 临界区
k_mutex_unlock(&my_mutex);
```

## 选择建议

### 选择 FreeRTOS 当:
- 需要广泛芯片支持
- 需要快速上手
- 商业项目
- 资源适中 (20KB+ Flash)

### 选择 RT-Thread 当:
- 中国项目，需要中文支持
- 需要丰富组件 (文件系统、Network)
- IoT 设备开发
- 资源紧张

### 选择 Zephyr 当:
- 需要 Linux 集成
- 需要蓝牙、WiFi、网络
- 需要工业级支持
- 愿意投入学习时间

### 选择裸机当:
- 系统极简单 (< 3 任务)
- 资源极度受限
- 硬实时要求极高
- 需要完全控制

## 移植要点

### 最小移植步骤

```
1. 实现 systick 时钟
   - 配置硬件定时器产生周期中断
   - 在中断中调用 xPortSysTickHandler()

2. 实现端口切换
   - 实现 vPortYield() 用于任务切换
   - 实现 vPortEnterCritical() / vPortExitCritical()

3. 配置链接脚本
   - 为 RTOS 内核分配内存
   - 配置任务栈空间

4. 测试验证
   - 创建空任务验证调度器工作
   - 添加延时验证时间片
```
