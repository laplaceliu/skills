# Python Coverage 工作流参考

## 安装

```bash
pip install coverage pytest-cov
```

## 运行覆盖率

### 通过 pytest-cov (推荐)

```bash
# 基本用法 — 测量 myapp 包的覆盖率
pytest --cov=myapp tests/

# 显示终端报告中缺失的行号
pytest --cov=myapp --cov-report=term-missing tests/

# HTML 报告 (可浏览)
pytest --cov=myapp --cov-report=html:htmlcov tests/

# XML 报告 (供 CI/SonarQube 解析)
pytest --cov=myapp --cov-report=xml:coverage.xml tests/

# 如果覆盖率低于阈值则失败
pytest --cov=myapp --cov-fail-under=80 tests/

# 同时输出多种格式
pytest --cov=myapp \
       --cov-report=term-missing \
       --cov-report=html:htmlcov \
       --cov-report=xml:coverage.xml \
       tests/
```

### 通过 coverage CLI

```bash
coverage run -m pytest tests/
coverage report --show-missing
coverage html -d htmlcov
coverage xml -o coverage.xml
coverage json -o coverage.json  # 机器可读格式
```

## 配置

### pyproject.toml (推荐)

```toml
[tool.coverage.run]
source = ["myapp"]
omit = [
    "tests/*",
    "*/migrations/*",
    "*/__main__.py",
    "myapp/vendor/*",
]
branch = true  # 除行覆盖率外还测量分支覆盖率

[tool.coverage.report]
fail_under = 80
show_missing = true
skip_covered = false  # 在报告中显示 100% 的文件 (设为 true 可隐藏)
precision = 1

[tool.coverage.html]
directory = "htmlcov"
title = "My App Coverage"

[tool.coverage.xml]
output = "coverage.xml"
```

### .coveragerc (旧式)

```ini
[run]
source = myapp
omit =
    tests/*
    */migrations/*
branch = True

[report]
fail_under = 80
show_missing = True
```

## 分支覆盖率

行覆盖率仅确认一行被执行了; 分支覆盖率确认条件的两条路径都被执行:

```python
def validate(x):
    if x > 0:       # 第 1 行 — 总是被命中
        return True  # 第 2 行 — 当 x > 0 时被命中
    return False     # 第 3 行 — 如果测试只用 x > 0 则被忽略
```

没有分支覆盖率: 3/3 行 = 100%。有分支覆盖率: `if x > 0 → True` 分支只有在同时存在 `x > 0` 和 `x <= 0` 测试用例时才能被完全测试。

通过在配置中设置 `branch = true` 或使用 `--cov-branch` 标志启用。

## 阅读差距报告

```
Name                    Stmts   Miss Branch BrPart  Cover   Missing
calculator.py              24      4      8      2    75%   18-22, 45
utils/formatter.py         12      2      4      1    67%   8-10
```

- **Stmts** — 总的可执行语句数
- **Miss** — 未执行的语句
- **Branch** — 总的分支对数 (仅在 `branch = true` 时有)
- **BrPart** — 部分覆盖的分支 (只测试了一个方向)
- **Missing** — 从未执行的行范围

当针对差距行时，`18-22` 表示跨越这些行的 `if/else` 块有一条未测试的路径。

## 解析以供 CI / Agent 交接

```bash
# 提取总覆盖率百分比
python -c "
import json, sys
data = json.load(open('coverage.json'))
total = data['totals']['percent_covered']
print(f'{total:.1f}%')
"

# 列出低于阈值的文件
python -c "
import json
data = json.load(open('coverage.json'))
threshold = 80
for fname, info in data['files'].items():
    pct = info['summary']['percent_covered']
    missing = info['missing_lines']
    if pct < threshold:
        print(f'{pct:.0f}%  {fname}  missing: {missing}')
"
```

## 并行测试运行

使用 `pytest-xdist` 运行 pytest 时，每个 worker 写入自己的 `.coverage.*` 文件。在报告前合并它们:

```bash
pytest --cov=myapp --cov-parallel -n auto tests/
coverage combine  # 合并所有 .coverage.* 文件
coverage report
```

添加到 `.coveragerc`:
```ini
[run]
parallel = True
```

## GitHub Actions 模式

```yaml
- name: Install dependencies
  run: pip install pytest pytest-cov

- name: Run tests with coverage
  run: |
    pytest --cov=myapp \
           --cov-report=xml \
           --cov-report=term-missing \
           --cov-fail-under=80 \
           tests/
  env:
    QT_QPA_PLATFORM: offscreen

- name: Upload coverage report
  uses: actions/upload-artifact@v4
  with:
    name: coverage-html
    path: htmlcov/
    if-no-files-found: warn

# 可选: 发布覆盖率摘要到 PR
- name: Coverage summary
  run: |
    python -c "
    import json
    d = json.load(open('coverage.json'))
    t = d['totals']
    print(f\"Coverage: {t['percent_covered']:.1f}% ({t['covered_lines']}/{t['num_statements']} lines)\")
    "
```
