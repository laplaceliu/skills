---
name: qt-coverage-workflow
description: >
  当用户询问"coverage"、"test coverage"、"coverage gaps"、"untested code"、"gcov"、"lcov"、"coverage report"、"improve coverage"、"missing tests"、"coverage threshold"、"coverage-driven test generation"或"what code isn't tested"时使用此技能。
  涵盖 Python/PySide6（coverage.py）和 C++/Qt（gcov + lcov）的完整覆盖率反馈循环。
  也适用于"pytest-cov"、"run coverage on my Qt project"或"CI coverage report"。
---

# Qt 覆盖率工作流程

覆盖率驱动的测试生成是一个循环：**运行带插桩的测试 → 生成报告 → 识别缺口 → 生成针对性测试 → 重新运行以验证改进**。此技能涵盖 Python 和 C++ Qt 项目的完整循环。

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

## Python 项目（coverage.py）

**完整的 Python 覆盖率演练** — 参见 [references/python-coverage-workflow.md](references/python-coverage-workflow.md)，了解安装、所有报告格式、分支覆盖率、CI 集成和 agent 交接解析模式。

关键 CI 步骤模式：
```yaml
- name: Run coverage
  run: pytest --cov=myapp --cov-report=xml --cov-fail-under=80 tests/
```

## C++ 项目（gcov + lcov）

**完整的 gcov/lcov 演练** — 参见 [references/gcov-lcov-workflow.md](references/gcov-lcov-workflow.md)，了解 CMake 预设、完整的 lcov 命令序列、Clang/LLVM 替代方案、缺口解析和故障排除。

## 覆盖率阈值

在 `.qt-test.json` 中配置阈值：

```json
{
  "coverage_threshold": 80,
  "coverage_exclude": ["tests/*", "*/migrations/*"]
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
在 calculator.py 中发现的缺口：第 18-22 行（除零路径）、第 45 行（溢出检查）
在 formatter.py 中发现的缺口：第 8-10 行（空字符串处理）
当前覆盖率：74%。目标：80%。
生成针对这些特定行的测试。
```

在 `/qt:coverage` 完成并发现缺口后，`test-generator` agent 会自动激活。

## 其他资源

- **`references/gcov-lcov-workflow.md`** — 完整的 gcov/lcov 命令参考、CMake 预设模式、故障排除
- **`references/python-coverage-workflow.md`** — coverage.py 配置、分支覆盖率、并行测试运行
- **`templates/qt-coverage.yml`** — 可直接使用的 GitHub Actions 工作流程（Python + C++ 变体）
- **`templates/run-coverage.sh`** — 用于本地和通用 CI 的可移植 shell 脚本
