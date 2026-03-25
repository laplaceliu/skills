# 修复 — 修复现有 xlsx 中的损坏公式

这是一个编辑任务。您必须保留所有原始工作表和数据。永远不要创建新的工作簿。

## 工作流程

```bash
# 步骤 1：识别错误
python3 SKILL_DIR/scripts/formula_check.py input.xlsx --json

# 步骤 2：解压
python3 SKILL_DIR/scripts/xlsx_unpack.py input.xlsx /tmp/xlsx_work/

# 步骤 3：使用编辑工具修复工作表 XML 中每个损坏的 <f> 元素
#   （参见下面的错误到修复映射）

# 步骤 4：打包和验证
python3 SKILL_DIR/scripts/xlsx_pack.py /tmp/xlsx_work/ output.xlsx
python3 SKILL_DIR/scripts/formula_check.py output.xlsx
```

## 错误到修复映射

| 错误 | 修复策略 |
|-------|-------------|
| `#DIV/0!` | 包装：`IFERROR(original_formula, "-")` |
| `#NAME?` | 修复拼写错误的函数（例如 `SUMM` → `SUM`） |
| `#REF!` | 重建损坏的引用 |
| `#VALUE!` | 修复类型不匹配 |

有关 Excel 错误类型的完整列表和高级诊断，请参见 `validate.md`。

## 关键规则

- 输出必须包含与输入相同的工作表。不要创建新的工作簿。
- 只修改损坏的特定 `<f>` 元素 — 其他所有内容必须保持不变。
- 打包后，始终运行 `formula_check.py` 以确认所有错误都已解决。
