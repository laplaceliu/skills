# Mock 框架参考（C++/Qt）

## 框架选择

| 框架 | 适用场景 | 集成方式 |
|------|---------|---------|
| **Google Mock (GMock)** | C++ 接口 Mock，功能最完整 | 与 GTest 捆绑，CMake `find_package(GTest)` |
| **QTest + 手工 Fake** | 纯 Qt 项目，无需额外依赖 | Qt 内置，`Qt6::Test` |
| **Fakeit** | Header-only，轻量，不需要虚函数 | 直接包含头文件 |
| **trompeloeil** | Modern C++14 风格，表达力强 | Header-only，Conan/vcpkg 可用 |

**推荐组合：GMock + QTest（信号/槽验证用 QSignalSpy）**

---

## Google Mock 安装

### 通过 Conan 安装
```ini
# conanfile.txt
[requires]
gtest/1.14.0

[generators]
CMakeDeps
CMakeToolchain
```
```bash
conan install . --output-folder=build --build=missing
```

### 通过 vcpkg 安装
```bash
vcpkg install gtest
```
```cmake
find_package(GTest CONFIG REQUIRED)
target_link_libraries(mytest PRIVATE GTest::gtest_main GTest::gmock)
```

### 通过 CMake FetchContent 安装
```cmake
include(FetchContent)
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        v1.14.0
)
FetchContent_MakeAvailable(googletest)
target_link_libraries(mytest PRIVATE gtest_main gmock)
```

### 系统包（Ubuntu/Debian）
```bash
sudo apt-get install libgtest-dev libgmock-dev
```

---

## MOCK_METHOD 完整语法

### 基本形式

```cpp
MOCK_METHOD(返回类型, 方法名, (参数列表), (修饰符));
```

### 修饰符列表

| 修饰符 | 说明 |
|--------|------|
| `override` | 覆盖基类虚函数（推荐始终加）|
| `const` | const 成员函数 |
| `noexcept` | noexcept 函数 |
| `ref(*)` | 引用限定（`&` 或 `&&`）|

```cpp
class MockService : public IService {
public:
    // 普通方法
    MOCK_METHOD(bool, connect, (const QString& host, int port), (override));

    // const 方法
    MOCK_METHOD(QString, getName, (), (const, override));

    // noexcept 方法
    MOCK_METHOD(void, reset, (), (noexcept, override));

    // 返回引用
    MOCK_METHOD(const Config&, getConfig, (), (const, override));

    // 参数含模板（用括号包裹）
    MOCK_METHOD((std::pair<int, QString>), getResult, (), (override));

    // 无参无返回
    MOCK_METHOD(void, doWork, (), (override));
};
```

---

## EXPECT_CALL 完整语法

### 基本结构

```cpp
EXPECT_CALL(mock对象, 方法名(参数匹配器))
    .Times(调用次数)
    .WillOnce(动作)
    .WillRepeatedly(默认动作);
```

### 调用次数规格

```cpp
.Times(0)             // 不应被调用
.Times(1)             // 恰好 1 次（默认，如果只有 WillOnce）
.Times(3)             // 恰好 3 次
.Times(AtLeast(1))    // 至少 1 次
.Times(AtMost(3))     // 至多 3 次
.Times(Between(1,3))  // 1 到 3 次
.Times(AnyNumber())   // 任意次（常用于辅助 mock）
```

### 动作（Actions）

```cpp
// 返回值
.WillOnce(Return(42))
.WillOnce(Return(QString("hello")))
.WillOnce(ReturnRef(someRef))
.WillOnce(ReturnPointee(&ptr))

// 抛出异常
.WillOnce(Throw(std::runtime_error("error")))

// 调用函数/lambda
.WillOnce(Invoke([](int x) { return x * 2; }))
.WillOnce(InvokeWithoutArgs([]() { return 42; }))

// 多个动作组合（DoAll 按顺序执行，取最后一个的返回值）
.WillOnce(DoAll(
    SaveArg<0>(&capturedValue),   // 保存第0个参数
    SetArgPointee<1>(outputValue), // 设置第1个参数（输出参数）
    Return(true)
))

// 调用真实实现
.WillOnce(DoDefault())
```

### 参数匹配器（Matchers）

#### 基础匹配器

```cpp
_                     // 任意值（通配符）
Eq(value)             // 等于（也可直接写 value）
Ne(value)             // 不等于
Lt(value)             // 小于
Le(value)             // 小于等于
Gt(value)             // 大于
Ge(value)             // 大于等于
IsNull()              // nullptr
NotNull()             // 非 nullptr
IsTrue()              // 转换为 bool 为真
IsFalse()             // 转换为 bool 为假
```

#### 字符串匹配器

```cpp
StrEq("exact")        // 精确字符串相等（std::string 和 C-string）
StrNe("not this")
StrCaseEq("HELLO")    // 忽略大小写
StartsWith("http")    // 前缀
EndsWith(".xml")      // 后缀
HasSubstr("error")    // 包含子串
MatchesRegex("\\d+")  // 正则
ContainsRegex("id=\\d+")
```

#### 容器匹配器

```cpp
IsEmpty()
SizeIs(3)
Contains(5)
ElementsAre(1, 2, 3)              // 完全匹配
UnorderedElementsAre(3, 1, 2)     // 无序匹配
ElementsAreArray(vec)             // 与 vector 完全匹配
ContainerEq(other_container)
Each(Gt(0))                       // 每个元素都满足
```

#### 指针/引用匹配器

```cpp
Pointee(Eq(42))       // 指针指向的值
Ref(variable)         // 引用特定变量
Address(matcher)      // 地址满足条件
```

#### 组合匹配器

```cpp
AllOf(Gt(0), Lt(100))     // 且
AnyOf(Eq(1), Eq(2))       // 或
Not(IsNull())             // 取反
Truly([](int x) { return x % 2 == 0; })  // Lambda 谓词
```

---

## 自定义匹配器

### 简单自定义匹配器（宏方式）

```cpp
// 定义：检查 QByteArray 是否包含特定前缀
MATCHER_P(StartsWithBytes, prefix, "starts with " + PrintToString(prefix)) {
    return arg.startsWith(prefix);
}

// 使用
EXPECT_CALL(mock, sendData(StartsWithBytes(QByteArray("HEADER"))));
```

### 复杂自定义匹配器（类方式）

```cpp
// 检查 QNetworkRequest 的 URL
class HasUrlMatcher {
public:
    explicit HasUrlMatcher(const QString& expectedUrl)
        : m_expectedUrl(expectedUrl) {}

    bool MatchAndExplain(const QNetworkRequest& req,
                         ::testing::MatchResultListener* listener) const {
        *listener << "url is " << req.url().toString().toStdString();
        return req.url().toString() == m_expectedUrl;
    }

    void DescribeTo(std::ostream* os) const {
        *os << "has URL " << m_expectedUrl.toStdString();
    }

    void DescribeNegationTo(std::ostream* os) const {
        *os << "does not have URL " << m_expectedUrl.toStdString();
    }

private:
    QString m_expectedUrl;
};

inline auto HasUrl(const QString& url) {
    return ::testing::MakeMatcher(new HasUrlMatcher(url));
}

// 使用
EXPECT_CALL(mockNetwork, sendRequest(HasUrl("https://api.example.com/data")));
```

---

## ON_CALL vs EXPECT_CALL

| | `EXPECT_CALL` | `ON_CALL` |
|--|---|---|
| 用途 | 验证方法被调用（断言） | 设置默认行为（无断言） |
| 未调用时 | 测试失败 | 不影响测试 |
| 适用场景 | 必须验证的交互 | 辅助设置，不关心是否调用 |

```cpp
// 辅助依赖：只需设置返回值，不验证是否调用
ON_CALL(mockConfig, getValue("timeout"))
    .WillByDefault(Return(30));

// 核心依赖：必须验证被调用
EXPECT_CALL(mockGateway, charge(_, Eq(100.0)))
    .Times(1)
    .WillOnce(Return(ChargeResult::Success));
```

---

## 严格/宽松 Mock

```cpp
// NiceMock — 忽略未期望的调用（不报警告）
::testing::NiceMock<MockService> niceMock;

// NaggyMock — 未期望的调用打印警告（默认行为）
::testing::NaggyMock<MockService> naggyMock;

// StrictMock — 任何未期望的调用都导致测试失败
::testing::StrictMock<MockService> strictMock;
```

**建议：**
- 辅助依赖（日志器、配置）用 `NiceMock`
- 核心依赖（支付、数据库）用 `StrictMock`

---

## 测试 Fixture 模式

```cpp
class PaymentServiceTest : public ::testing::Test {
protected:
    void SetUp() override {
        // 每个测试前执行
        sut = std::make_unique<PaymentService>(&mockGateway, &mockDb);
    }

    void TearDown() override {
        // 每个测试后执行（通常不需要，unique_ptr 自动析构）
    }

    // Mock 成员
    ::testing::NiceMock<MockPaymentGateway> mockGateway;
    ::testing::StrictMock<MockDatabase> mockDb;

    // 被测对象
    std::unique_ptr<PaymentService> sut;

    // 通用辅助方法
    PaymentRequest makeValidRequest(double amount = 100.0) {
        return PaymentRequest{.userId = 42, .amount = amount, .currency = "CNY"};
    }
};

TEST_F(PaymentServiceTest, chargesSuccessfullyForValidRequest) {
    auto req = makeValidRequest(200.0);
    EXPECT_CALL(mockGateway, charge(Eq(42), Eq(200.0))).WillOnce(Return(true));
    EXPECT_CALL(mockDb, saveTransaction(_)).WillOnce(Return(true));

    EXPECT_TRUE(sut->processPayment(req));
}
```

---

## 参数化测试（数据驱动）

```cpp
struct TestCase {
    double amount;
    bool expectedResult;
    QString description;
};

class PaymentAmountTest
    : public ::testing::TestWithParam<TestCase> {
protected:
    MockPaymentGateway mockGateway;
    PaymentService sut{&mockGateway};
};

TEST_P(PaymentAmountTest, validatesAmountCorrectly) {
    auto [amount, expected, desc] = GetParam();

    ON_CALL(mockGateway, charge(_, _)).WillByDefault(Return(expected));

    EXPECT_EQ(sut->charge(amount), expected)
        << "场景: " << desc.toStdString();
}

INSTANTIATE_TEST_SUITE_P(
    AmountBoundary,
    PaymentAmountTest,
    ::testing::Values(
        TestCase{100.0,  true,  "正常金额"},
        TestCase{0.01,   true,  "最小金额"},
        TestCase{0.0,    false, "零金额"},
        TestCase{-1.0,   false, "负数金额"},
        TestCase{999999, true,  "大额"}
    )
);
```

---

## GTest 断言速查

```cpp
// 布尔
EXPECT_TRUE(expr);
EXPECT_FALSE(expr);

// 值比较
EXPECT_EQ(actual, expected);    // ==
EXPECT_NE(a, b);                // !=
EXPECT_LT(a, b);                // <
EXPECT_LE(a, b);                // <=
EXPECT_GT(a, b);                // >
EXPECT_GE(a, b);                // >=

// 浮点
EXPECT_FLOAT_EQ(a, b);          // ±4 ULP
EXPECT_DOUBLE_EQ(a, b);
EXPECT_NEAR(a, b, 0.001);       // 绝对误差

// 字符串
EXPECT_STREQ("abc", str);       // C-string
EXPECT_STRNE("abc", str);
EXPECT_STRCASEEQ("ABC", str);   // 忽略大小写

// 异常
EXPECT_THROW(expr, ExceptionType);
EXPECT_NO_THROW(expr);
EXPECT_ANY_THROW(expr);

// 指针
EXPECT_NULL(ptr);
EXPECT_NOT_NULL(ptr);

// 与 GMock Matchers 结合
EXPECT_THAT(value, AllOf(Gt(0), Lt(100)));
EXPECT_THAT(str, StartsWith("hello"));
EXPECT_THAT(vec, ElementsAre(1, 2, 3));

// ASSERT_* — 失败时立即停止当前测试（EXPECT_* 继续执行）
ASSERT_TRUE(initialized) << "必须先初始化才能继续";
```

---

## 常见编译错误排查

| 错误 | 原因 | 解决 |
|------|------|------|
| `error: 'MOCK_METHOD' was not declared` | 未包含 gmock 头文件 | `#include <gmock/gmock.h>` |
| `error: cannot allocate an object of abstract type` | 基类有未实现的纯虚函数 | 检查 Mock 类是否覆盖了所有纯虚方法 |
| `Uninteresting mock function call` | 调用了未设置期望的方法 | 用 `NiceMock` 或添加 `ON_CALL` |
| `EXPECT_CALL on uninteresting function` | 对已有 `NiceMock` 设置 `EXPECT_CALL` | 正常，`EXPECT_CALL` 覆盖 `NiceMock` |
| `const` 方法不匹配 | `MOCK_METHOD` 缺少 `const` | 在修饰符列表加 `const, override` |
| `Times(1) called 0 times` | 被测代码未调用 mock | 检查被测代码的依赖注入是否正确 |
