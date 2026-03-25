# MISRA C++ 编码标准

## 概述

MISRA C++ 是汽车电子行业广泛使用的编码标准，旨在提高嵌入式代码的安全性、可靠性和可维护性。

## 核心规则 (精选)

### 1. 语言的正确使用

```cpp
// 规则 3-1-2: 禁止使用 // 注释嵌套
// /* 大多数编译器会拒绝，以下代码是非法的
void bad() {
    int x = 0;
    // // 这不是合法的 C++
        // 嵌套注释
    // */
}

// 正确做法: 使用 #if 0 ... #endif 代替多行注释
void good() {
    int x = 0;
    #if 0
        注释内容
        注释内容
    #endif
}
```

### 2. 类型安全

```cpp
// 规则 4-5-1: 不要混用有符号和无符号类型
void bad() {
    int8_t signed_val = -1;
    uint32_t unsigned_val = 10;
    if (signed_val < unsigned_val) {  // 有符号被提升为无符号！
        // 永远不会执行这里
    }
}

void good() {
    int8_t signed_val = -1;
    uint32_t unsigned_val = 10;
    if (signed_val < 0 || static_cast<uint32_t>(signed_val) < unsigned_val) {
        // 正确比较
    }
}

// 规则 4-7-1: 使用显式转换
void good() {
    float f = 3.14f;
    int32_t i = static_cast<int32_t>(f);  // 显式转换
}
```

### 3. 动态内存

```cpp
// 规则 7-4-1: 禁止使用动态内存
void bad() {
    int* p = new int[100];  // 禁止！
    delete[] p;
}

// 正确做法: 使用静态分配
void good() {
    static int buffer[100];  // 静态分配
    int* p = buffer;
    // 使用 buffer
}
```

### 4. 指针操作

```cpp
// 规则 7-5-1: 不要返回局部对象的指针
int* bad() {
    int local = 10;
    return &local;  // 危险！local 已在栈上销毁
}

// 正确: 返回引用或使用静态/堆外内存
static int local = 10;
int* good() {
    return &local;  // 安全，静态对象生命周期同程序
}

// 规则 7-5-2: 参数指针应标记其是否可为空
void process_data(int32_t* const data)  // const 指针，不可修改指针本身
void process_data(int32_t* data)        // 可修改指针
void process_data(int32_t* restrict data)  // restrict 提示无别名
```

### 5. 类和继承

```cpp
// 规则 8-3-1: 函数参数类型应尽可能精确
void bad(UartHandle* handle);  // 太模糊
void good(UartHandle* const handle);  // const 指针

// 规则 8-4-3: 禁止隐式转换
class Distance {
public:
    explicit Distance(uint32_t mm) : value_(mm) {}  // explicit 禁止隐式转换
    uint32_t value() const { return value_; }
private:
    uint32_t value_;
};

void bad() {
    Distance d = 1000;  // 错误！需要 explicit
}

void good() {
    Distance d(1000);   // 正确
    Distance d2{1000}; // 也正确
}

// 规则 9-6-1: 枚举使用强类型枚举
enum BadEnum { RED, GREEN, BLUE };  // 禁止！会污染命名空间

enum class Color : uint8_t {  // 强类型枚举
    Red,
    Green,
    Blue
};

void good() {
    Color c = Color::Red;  // 正确
}
```

### 6. 异常处理

```cpp
// 规则 15-0-2: 禁止使用异常
void bad() {
    try {
        // ...
    } catch (const std::exception& e) {
        // 禁止！
    }
}

// 正确: 使用错误码
ErrorCode process() {
    if (failed()) {
        return ErrorCode::Failed;  // 返回错误码
    }
    return ErrorCode::None;
}
```

### 7. 模板和容器

```cpp
// 规则 17-0-1: 禁止使用 std::vector::push_back 等可能触发动态分配的函数
void bad() {
    std::vector<int> v;
    v.push_back(1);  // 可能触发重新分配！
}

// 正确: 使用固定大小容器
void good() {
    std::array<int, 10> arr;  // 固定大小，无动态分配
    arr[0] = 1;  // 直接访问
}

// 或使用自定义固定内存池
template<typename T, size_t N>
class FixedBuffer {
public:
    bool push_back(const T& item) {
        if (size_ >= N) return false;
        buffer_[size_++] = item;
        return true;
    }
    size_t size() const { return size_; }
private:
    T buffer_[N];
    size_t size_ = 0;
};
```

### 8. 运算符

```cpp
// 规则 18-0-1: 不要使用 union
union BadUnion {  // 禁止
    int32_t i;
    float f;
};

// 使用结构体代替
struct GoodStruct {
    int32_t as_int;
    float as_float;
    bool is_int;  // 使用标记区分类型
};
```

## 常见检查项

| 类别 | 规则数 | 关键规则 |
|------|--------|----------|
| 语言使用 | 15 | 无嵌套注释、禁止宏副作用 |
| 类型安全 | 12 | 禁止隐式转换、无符号混用 |
| 动态内存 | 8 | 禁止 new/delete、禁止 malloc |
| 指针 | 15 | 不返回局部指针、指针参数验证 |
| 类 | 20 | 成员 const、禁止隐式转换 |
| 异常 | 6 | 禁止异常 |
| 模板 | 8 | 固定大小容器 |
| 运算符 | 5 | 禁止 union |

## 自动化检查

```bash
# 使用静态分析工具检查 MISRA 违规
# 1. 使用 clang-tidy
clang-tidy -checks='-*,misc-*,readability-*,modernize-*' source.cpp

# 2. 使用 PC-lint
lint source.cpp --e960   // 允许某些规则
```

## 实施建议

```
1. 从最关键的规则开始实施
2. 配置编译器启用最严格的警告
3. 使用静态分析工具自动化检查
4. 代码审查时关注常见违规模式
5. 为遗留代码制定合规路径
```
