# 数据读取与分析指南

> 读取路径的参考。使用 `xlsx_reader.py` 进行结构发现和数据质量审计，
> 然后使用 pandas 进行自定义分析。**永远不要修改源文件。**

---

## 何时使用此路径

用户要求读取、分析、查看、汇总、提取或回答有关 Excel/CSV 文件内容的问题，
不需要文件修改。如果需要修改，请移交给 `edit.md`。

---

## 工作流程

### 步骤 1 — 结构发现

首先运行 `xlsx_reader.py`。它处理格式检测、编码回退、结构探索和数据质量审计：

```bash
python3 SKILL_DIR/scripts/xlsx_reader.py input.xlsx                 # 完整报告
python3 SKILL_DIR/scripts/xlsx_reader.py input.xlsx --sheet Sales   # 单个工作表
python3 SKILL_DIR/scripts/xlsx_reader.py input.xlsx --quality       # 仅质量审计
python3 SKILL_DIR/scripts/xlsx_reader.py input.xlsx --json          # 机器可读格式
```

支持的格式：`.xlsx`、`.xlsm`、`.csv`、`.tsv`。该脚本尝试 CSV 的多种编码（utf-8-sig、gbk、utf-8、latin-1）。

### 步骤 2 — 使用 pandas 进行自定义分析

加载数据并执行用户请求的分析：

```python
import pandas as pd
df = pd.read_excel("input.xlsx", sheet_name=None)  # 所有工作表的字典
# 对于 CSV: pd.read_csv("input.csv")
```

**表头处理**（当默认的 `header=0` 不起作用时）：

| 情况 | 代码 |
|-----------|------|
| 第 3 行的表头 | `pd.read_excel(path, header=2)` |
| 多级合并表头 | `pd.read_excel(path, header=[0, 1])` |
| 无表头 | `pd.read_excel(path, header=None)` |

**分析快速参考：**

| 场景 | 模式 |
|----------|---------|
| 描述性统计 | `df.describe()` 或 `df['Col'].agg(['sum', 'mean', 'min', 'max'])` |
| 分组聚合 | `df.groupby('Region')['Revenue'].agg(Total='sum', Avg='mean')` |
| 前 N 名 | `df.groupby('Region')['Revenue'].sum().sort_values(ascending=False).head(5)` |
| 透视表 | `df.pivot_table(values='Revenue', index='Region', columns='Quarter', aggfunc='sum', margins=True)` |
| 时间序列 | `df.set_index(pd.to_datetime(df['Date'])).resample('ME')['Revenue'].sum()` |
| 跨工作表合并 | `pd.merge(sales, customers, on='CustomerID', how='left', validate='m:1')` |
| 堆叠工作表 | `pd.concat([df.assign(Source=name) for name, df in sheets.items()], ignore_index=True)` |
| 大文件 (>50MB) | `pd.read_excel(path, usecols=['Date', 'Revenue'])` 或 `pd.read_csv(path, chunksize=10000)` |

### 步骤 3 — 输出

如果用户指定了输出文件路径，将结果写入其中（最高优先级）。将报告格式化为：

```
## 分析报告：{filename}
### 文件概览     — 格式、工作表、行数
### 数据质量      — 空值、重复项、混合类型（或"无问题"）
### 关键发现      — 直接回答用户的问题
### 附加说明      — 公式 NaN、编码问题、注意事项
```

**数字显示**：货币 `1,234,567.89`，百分比 `12.3%`，倍数 `8.5x`，计数为整数。

---

## 常见陷阱

| 陷阱 | 原因 | 解决方法 |
|---------|-------|-----|
| 公式单元格读取为 NaN | 新生成的文件中 `<v>` 缓存为空 | 告知用户；建议在 Excel 中打开并重新保存；或使用 `libreoffice_recalc.py` |
| CSV 编码错误 | 中文 Windows 导出使用 GBK | `xlsx_reader.py` 自动尝试多种编码；如果全部失败则手动指定 |
| 列中混合类型 | 列中同时有数字和文本（例如，"N/A"） | `pd.to_numeric(df['Col'], errors='coerce')` — 报告无法转换的行 |
| 年份显示为 2,024 | 对年份应用了千位分隔符格式 | `df['Year'].astype(int).astype(str)` |
| 多级表头 | 两行合并的表头 | `pd.read_excel(path, header=[0, 1])`，然后使用 `' - '.join()` 展平 |
| 行号不匹配 | pandas 从 0 开始索引 vs Excel 从 1 开始索引 | `excel_row = pandas_index + 2` (+1 表示从 1 开始，+1 表示表头) |

**关键**：永远不要使用 `data_only=True` 然后 `save()` — 这会永久销毁所有公式。

---

## 禁止事项

- 永远不要修改源文件（不使用 `save()`，不进行 XML 编辑）
- 永远不要将公式 NaN 报告为"数据为零" — 解释这是公式缓存问题
- 永远不要将 pandas 索报告为 Excel 行号
- 永远不要做出数据不支持的推测性结论
