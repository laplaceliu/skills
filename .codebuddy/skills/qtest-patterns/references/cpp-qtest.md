# C++ QTest 参考

## 完整宏参考

### 断言宏

| 宏 | 通过条件 | 失败显示 |
|---|---|---|
| `QVERIFY(expr)` | expr 为真 | "expr returned false" |
| `QVERIFY2(expr, msg)` | expr 为真 | 自定义消息 |
| `QCOMPARE(actual, expected)` | 值相等 | 显示两个值的差异 |
| `QVERIFY_THROWS_EXCEPTION(ExType, expr)` | expr 抛出 ExType | 未抛出或类型错误 |
| `QVERIFY_THROWS_NO_EXCEPTION(expr)` | expr 不抛出 | 异常消息 |
| `QTRY_VERIFY(expr)` | expr 在 5 秒内最终为真 | 超时 |
| `QTRY_COMPARE(a, b)` | 值在 5 秒内最终相等 | 超时 |
| `QTRY_VERIFY_WITH_TIMEOUT(expr, ms)` | expr 最终为真 | 超时 |
| `QSKIP("reason")` | — | 标记测试为跳过 |
| `QEXPECT_FAIL("", "reason", Continue)` | — | 标记下一个 QVERIFY 预期失败 |

### 数据驱动测试

```cpp
void MyTest::myTest_data() {
    QTest::addColumn<QString>("input");
    QTest::addColumn<int>("expected");

    QTest::newRow("empty") << QString("") << 0;
    QTest::newRow("one word") << QString("hello") << 5;
    QTest::newRow("unicode") << QString("héllo") << 5;
}

void MyTest::myTest() {
    QFETCH(QString, input);
    QFETCH(int, expected);
    QCOMPARE(computeLength(input), expected);
}
```

`_data()` 函数必须与测试函数同名并附加 `_data`，且必须是私有 slot。

### 信号间谍

`QSignalSpy` 记录所有信号发射以供后续检查:

```cpp
#include <QSignalSpy>

QLineEdit *edit = new QLineEdit();
QSignalSpy spy(edit, &QLineEdit::textChanged);

edit->setText("hello");

QCOMPARE(spy.count(), 1);
QList<QVariant> args = spy.takeFirst();
QCOMPARE(args.at(0).toString(), "hello");
```

对于具有多个参数的信号，`args` 按顺序包含所有参数。

### GUI/输入模拟

```cpp
#include <QTest>

// 鼠标
QTest::mouseClick(widget, Qt::LeftButton);
QTest::mouseClick(widget, Qt::LeftButton, Qt::NoModifier, QPoint(10, 10));
QTest::mouseDClick(widget, Qt::LeftButton);
QTest::mousePress(widget, Qt::LeftButton);
QTest::mouseRelease(widget, Qt::LeftButton);
QTest::mouseMove(widget, QPoint(50, 50));

// 键盘
QTest::keyClick(widget, Qt::Key_Return);
QTest::keyClick(widget, 'a', Qt::ControlModifier);
QTest::keyClicks(widget, "hello world");
QTest::keyPress(widget, Qt::Key_Shift);
QTest::keyRelease(widget, Qt::Key_Shift);

// 延迟 (用于动画/防抖场景)
QTest::qWait(100);  // 毫秒
QTest::qSleep(100); // 毫秒 (阻塞事件循环 — 在 GUI 测试中避免)
```

### 基准测试宏

```cpp
void MyBenchmark::sortBenchmark() {
    QVector<int> data = generateData(10000);

    QBENCHMARK {
        std::sort(data.begin(), data.end());
    }
}
```

运行基准测试: `./my_test -benchmark`。

可用的测量后端:
- 默认: walltime
- `-callgrind`: Valgrind Callgrind
- `-perf`: Linux perf 事件计数器
- `-tickcounter`: CPU 计时器计数

## 输出格式

```bash
./my_test                        # 纯文本 (默认)
./my_test -o results.xml,xml     # JUnit XML (CI 友好)
./my_test -o results.tap,tap     # TAP 格式
./my_test -o -,txt -o results.xml,xml  # 同时多输出
./my_test -v1                    # 详细: 打印测试名称
./my_test -v2                    # 非常详细: 所有断言
./my_test TestClass::specificTest  # 按名称运行一个测试
./my_test -functions             # 列出所有测试函数名称
```

## CMake 模式

### 简单 (每个测试一个可执行文件)

```cmake
find_package(Qt6 REQUIRED COMPONENTS Test)

add_executable(TestCalculator test_calculator.cpp)
target_link_libraries(TestCalculator PRIVATE Qt6::Test calculator_lib)
add_test(NAME TestCalculator COMMAND TestCalculator)
```

### 辅助函数 (多个测试时推荐)

```cmake
function(qt_add_unit_test name)
    add_executable(${name} ${ARGN})
    target_link_libraries(${name}
        PRIVATE Qt6::Test ${PROJECT_NAME}_lib
    )
    set_target_properties(${name} PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/tests"
    )
    add_test(NAME ${name} COMMAND ${name} -o "${name}.xml,xml")
endfunction()

qt_add_unit_test(TestCalculator test_calculator.cpp)
qt_add_unit_test(TestMainWindow test_main_window.cpp)
```

### CTest 配置

```cmake
# 设置每个测试的超时时间 (默认无限)
set_tests_properties(TestCalculator PROPERTIES TIMEOUT 30)

# 并行运行
set(CTEST_PARALLEL_LEVEL 4)
```

运行所有测试: `ctest --output-on-failure --parallel 4`

## 链接应用程序代码

避免直接链接测试到应用程序可执行文件。相反，将逻辑提取到静态库或共享库:

```cmake
# 主 CMakeLists.txt
add_library(myapp_lib STATIC
    src/calculator.cpp
    src/formatter.cpp
)
target_link_libraries(myapp_lib PUBLIC Qt6::Core Qt6::Widgets)

add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE myapp_lib)

# 测试链接库，而非可执行文件
enable_testing()
add_subdirectory(tests)
```

## 故障排除

**`undefined reference to 'TestFoo::staticMetaObject'`**: 缺少在测试文件末尾的 `#include "test_foo.moc"`。

**测试找不到 Qt 头文件**: `find_package(Qt6 REQUIRED COMPONENTS Test)` 必须在 `target_link_libraries` 之前。

**GUI 测试在 CI 上失败**: 使用 `QT_QPA_PLATFORM=offscreen` 或 Xvfb。CI 机器没有显示器。

**`QCOMPARE` 失败但没有显示差异**: 类型可能没有 `operator<<(QDebug, T)`。注册它或使用带有手动消息的 `QVERIFY(a == b)`。
