---
name: qt-coverage-workflow
description: >
  当用户询问"coverage"、"test coverage"、"coverage gaps"、"untested code"、"gcov"、"lcov"、"coverage report"、"improve coverage"、"missing tests"、"coverage threshold"、"coverage-driven test generation"或"what code isn't tested"时使用此技能。
  涵盖 C++/Qt（gcov + lcov）的完整覆盖率反馈循环。
  也适用于"run coverage on my Qt project"或"CI coverage report"。
---

# Qt C++ 覆盖率工作流程

覆盖率驱动的测试生成是一个循环：**运行带插桩的测试 → 生成报告 → 识别缺口 → 生成针对性测试 → 重新运行以验证改进**。

## 覆盖率循环

```
运行插桩测试
        ↓
解析覆盖率报告（缺口列表）
        ↓
将缺口发送给 Claude / test-generator agent
        ↓
生成针对性测试
        ↓
重新运行测试 → 验证增量
        ↓
重复直到达到阈值
```

使用 `/qt:coverage` 来执行此循环。在 `/qt:coverage` 识别出缺口后，`test-generator` agent 会自动激活。

## C++ 项目（gcov + lcov）

**完整的 gcov/lcov 演练** — 参见 [references/gcov-lcov-workflow.md](references/gcov-lcov-workflow.md)，了解 CMake 预设、完整的 lcov 命令序列、Clang/LLVM 替代方案、缺口解析和故障排除。

### CMake 覆盖率配置

```cmake
# CMakeLists.txt
include(CheckGCCCompilerFlag)

# 启用覆盖率（仅在 Debug 构建时）
if(CMAKE_BUILD_TYPE STREQUAL "Debug" OR CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fprofile-arcs -ftest-coverage")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fprofile-arcs -ftest-coverage")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
endif()
```

### 关键 CI 步骤模式

```yaml
# .github/workflows/coverage.yml
- name: Configure with coverage
  run: |
    cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DCMAKE_CXX_FLAGS="-fprofile-arcs -ftest-coverage"

- name: Build
  run: cmake --build build

- name: Run tests
  working-directory: build
  run: ctest --output-on-failure

- name: Generate coverage report
  run: |
    lcov --capture --directory build --output-file coverage.info
    lcov --remove coverage.info '*/tests/*' '*/moc_*' --output-file coverage.filtered.info
    genhtml coverage.filtered.info --output-directory coverage-html
```

## 覆盖率阈值

在 `.qt-test.json` 中配置阈值：

```json
{
  "project_type": "cpp",
  "coverage_threshold": 80,
  "coverage_exclude": ["tests/*", "*/moc_*", "*/qrc_*"]
}
```

| 阈值 | 适用场景 |
|---|---|
| 60–70% | 早期阶段项目、快速原型开发 |
| 80% | 通用生产代码（推荐默认值） |
| 90%+ | 安全关键组件 |
| 100% MC/DC | 航空航天/汽车（需要 Coco） |

## 识别高价值覆盖率缺口

分析缺口时，按以下优先级排序：

1. **业务逻辑类** — 最高回归风险
2. **错误路径**（异常处理程序、验证失败）— 通常未测试
3. **复杂条件** — 具有多个条件的分支
4. **公共 API 方法** — 其他代码依赖的表面区域
5. **跳过** 测试基础设施、生成的 `moc_*` 文件、纯 UI 胶水代码

## 移交给 test-generator Agent

识别缺口后，按以下方式结构化交接：

```
在 calculator.cpp 中发现的缺口：第 18-22 行（除零路径）、第 45 行（溢出检查）
在 formatter.cpp 中发现的缺口：第 8-10 行（空字符串处理）
当前覆盖率：74%。目标：80%。
生成针对这些特定行的测试。
```

在 `/qt:coverage` 完成并发现缺口后，`test-generator` agent 会自动激活。

## 其他资源

- **`references/gcov-lcov-workflow.md`** — 完整的 gcov/lcov 命令参考、CMake 预设模式、故障排除
- **`templates/qt-coverage.yml`** — 可直接使用的 GitHub Actions 工作流程
- **`templates/run-coverage.sh`** — 用于本地和通用 CI 的可移植 shell 脚本
