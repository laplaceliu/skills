# QML TestCase 参考

## 模块导入

```qml
import QtTest 1.15
// 或对于 Qt 6.x:
import QtTest
```

## TestCase 结构

```qml
TestCase {
    name: "MyComponentTests"   // 必需 — 标识此测试套件

    // 可选的生命周期函数
    function initTestCase() { /* 在所有测试之前 */ }
    function cleanupTestCase() { /* 在所有测试之后 */ }
    function init() { /* 在每个测试之前 */ }
    function cleanup() { /* 在每个测试之后 */ }

    // 测试函数 — 必须以 "test_" 开头
    function test_initialState() { ... }
    function test_buttonClick() { ... }
}
```

## 断言函数

| 函数 | 通过条件 |
|---|---|
| `verify(expr)` | expr 为真 |
| `verify(expr, msg)` | expr 为真 (自定义失败消息) |
| `compare(actual, expected)` | 值相等 |
| `fuzzyCompare(a, b, delta)` | `|a - b| <= delta` |
| `fail(msg)` | 无条件失败 |
| `skip(msg)` | 跳过测试并显示消息 |
| `expectFail("", msg, AbortTestOnFail)` | 下一个比较预期失败 |

## 组件创建

```qml
TestCase {
    name: "MyComponent"

    function test_createAndDestroy() {
        // 内联组件 (简单情况首选)
        var component = Qt.createComponent("MyComponent.qml")
        verify(component !== null, "Component loaded")
        verify(component.status === Component.Ready,
               "Component ready: " + component.errorString())

        var obj = component.createObject(null)  // null 父级 = 无视觉父级
        verify(obj !== null, "Object created")

        compare(obj.title, "Untitled")

        obj.destroy()  // 始终销毁以防止泄漏
    }
}
```

### 内联组件模式 (Qt 5.15+)

```qml
TestCase {
    name: "InlinePattern"

    Component {
        id: myComp
        MyWidget {
            width: 100; height: 100
        }
    }

    function test_inlineCreate() {
        var obj = myComp.createObject(null)
        verify(obj)
        compare(obj.width, 100)
        obj.destroy()
    }
}
```

## 信号测试

```qml
TestCase {
    name: "SignalTests"

    SignalSpy {
        id: spy
        target: null  // 在测试中设置
        signalName: "clicked"
    }

    function test_buttonEmitsClicked() {
        var btn = Qt.createComponent("MyButton.qml").createObject(null)
        spy.target = btn

        btn.simulateClick()
        compare(spy.count, 1)

        btn.destroy()
        spy.target = null
        spy.clear()
    }
}
```

`SignalSpy` 必须在信号发出之前设置 `target` 和 `signalName`。使用 `spy.clear()` 在测试之间重置。

## 异步/定时器测试

```qml
TestCase {
    name: "AsyncTests"

    function test_timerFires() {
        var obj = Qt.createComponent("TimedComponent.qml").createObject(null)
        compare(obj.status, "idle")

        obj.start()
        wait(200)  // 等待 200ms 以让定时器触发

        compare(obj.status, "done")
        obj.destroy()
    }

    function test_signalEventuallyFired() {
        var spy = createTemporaryQmlObject(
            'import QtTest; SignalSpy { signalName: "finished" }', null)
        var worker = Qt.createComponent("Worker.qml").createObject(null)
        spy.target = worker

        worker.start()
        spy.wait(2000)  // 等待直到 count > 0 或超时

        compare(spy.count, 1)
        worker.destroy()
    }
}
```

## 运行 QML 测试

### CMake 设置

```cmake
find_package(Qt6 REQUIRED COMPONENTS Quick QuickTest)

# QtQuickTest 所需的最小 C++ 入口点
add_executable(qml_tests qml_test_main.cpp)
target_link_libraries(qml_tests PRIVATE Qt6::Quick Qt6::QuickTest)

add_test(NAME QmlTests
    COMMAND qml_tests -input ${CMAKE_CURRENT_SOURCE_DIR}/tests
)
```

```cpp
// qml_test_main.cpp — 样板文件，不要修改
#include <QtQuickTest>
QUICK_TEST_MAIN(qml_tests)
```

### qmltestrunner (替代方案)

如果 Qt 安装了 `qmltestrunner`:
```bash
qmltestrunner -input tests/
```

### 导入路径配置

如果 QML 模块已注册但不在默认导入路径中:
```cpp
// 带自定义导入路径的扩展入口点
#include <QtQuickTest>
#include <QGuiApplication>
#include <QQmlEngine>

class Setup : public QObject {
    Q_OBJECT
public slots:
    void applicationAvailable() {
        // 在 QML 引擎创建之前调用
    }
    void qmlEngineAvailable(QQmlEngine *engine) {
        engine->addImportPath(":/imports");
    }
};
#include "qml_test_main.moc"
QUICK_TEST_MAIN_WITH_SETUP(qml_tests, Setup)
```

## 文件命名约定

QML 测试文件应加前缀 `tst_` 以区别于它们测试的组件:

```
tests/
├── tst_Calculator.qml
├── tst_MainWindow.qml
└── tst_Navigation.qml
```

## 常见问题

**`Component.Error` 状态**: QML 导入路径不包含你的模块。检查 `engine->addImportPath()` 或 `QML_IMPORT_PATH` 环境变量。

**对象引用上的 `compare` 失败**: QML `compare` 对对象使用 `===` 语义。对于属性比较，访问属性: `compare(obj.value, expected)`。

**`wait()` 在慢速 CI 上导致不稳定**: 增加等待持续时间或使用 `SignalSpy.wait()`，它是事件驱动的而非基于时间的。

**未调用 `obj.destroy()`**: 如果未调用 `destroy()`，QML 测试会泄漏对象。这可能导致后续测试看到先前测试对象的过时状态。
