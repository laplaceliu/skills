# 公式验证与重新计算指南

确保交付前 xlsx 文件中的每个公式都是可证明正确的。打开没有可见错误的文件不是通过的文件 — 只有通过了两个验证层级的文件才是通过的文件。

---

## 基础规则

- **永远不要在不先运行 `formula_check.py` 的情况下声明通过。** 电子表格的可视检查不是验证。
- **第 1 层级（静态）在每个场景下都是强制性的。** 第 2 层级（动态）在 LibreOffice 可用时是强制性的。如果不可用，您必须在报告中明确说明这一点 — 您不得静默跳过。
- **永远不要使用带有 `data_only=True` 的 openpyxl 来检查公式值。** 在 `data_only=True` 模式下打开并保存工作簿会永久将所有公式替换为它们最后的缓存值。之后公式无法恢复。
- **仅自动修复确定性错误。** 任何需要理解业务逻辑的修复必须标记为人工审核。

---

## 两层级验证架构

```
第 1 层级 — 静态验证（XML 扫描，无外部工具）
  │
  ├── 检测：已缓存在 <v> 元素中的所有 7 种 Excel 错误类型
  ├── 检测：指向不存在工作表的跨工作表引用
  ├── 检测：带有 t="e" 属性的公式单元格（错误类型标记）
  └── 工具：formula_check.py + 手动 XML 检查
        │
        ▼ （如果存在 LibreOffice）
第 2 层级 — 动态验证（LibreOffice 无头重新计算）
  │
  ├── 通过 LibreOffice Calc 引擎执行所有公式
  ├── 用实际计算结果填充 <v> 缓存值
  ├── 暴露重新计算前不可见的运行时错误
  └── 后续：在重新计算后的文件上重新运行第 1 层级
```

**为什么需要两个层级？**

openpyxl 和所有 Python xlsx 库都将公式字符串（例如 `=SUM(B2:B9)`）写入 `<f>` 元素，但不计算它们。新生成的文件对于每个公式单元格都有空的 `<v>` 缓存元素。这意味着：

- 第 1 层级只能捕获已编码在 XML 中的错误 — 作为 `t="e"` 单元格或结构损坏的跨工作表引用。
- 第 2 层级使用 LibreOffice 作为实际计算引擎，运行每个公式，用实际结果填充 `<v>`，并显示只能在计算后出现的运行时错误（`#DIV/0!`、`#N/A` 等）。

单独任何一个层级都不够。它们一起覆盖完整的可修正性表面。

---

## 第 1 层级 — 静态验证

静态验证不需要外部工具。它直接在 xlsx 文件的 ZIP/XML 结构上工作。

### 步骤 1：运行 formula_check.py

**标准（人类可读）输出：**

```bash
python3 SKILL_DIR/scripts/formula_check.py /path/to/file.xlsx
```

**JSON 输出（用于程序化处理）：**

```bash
python3 SKILL_DIR/scripts/formula_check.py /path/to/file.xlsx --json
```

**单工作表模式（用于有针对性的检查，更快）：**

```bash
python3 SKILL_DIR/scripts/formula_check.py /path/to/file.xlsx --sheet Summary
```

**摘要模式（仅计数，无每个单元格的详细信息）：**

```bash
python3 SKILL_DIR/scripts/formula_check.py /path/to/file.xlsx --summary
```

退出代码：
- `0` — 无硬错误（通过或通过启发式警告）
- `1` — 检测到硬错误，或文件无法打开（失败）

#### formula_check.py 检查的内容

该脚本在不使用任何 Excel 库的情况下将 xlsx 作为 ZIP 压缩包打开。它读取 `xl/workbook.xml` 以枚举工作表名称和命名范围，读取 `xl/_rels/workbook.xml.rels` 以将每个工作表映射到其 XML 文件，然后遍历每个工作表中的每个 `<c>` 元素。

它执行五项检查：

1. **错误值检测**：如果单元格有 `t="e"`，其 `<v>` 元素包含 Excel 错误字符串。记录其工作表名称、单元格引用（例如 `C5`）、错误值以及公式文本（如果存在）。

2. **损坏的跨工作表引用检测**：如果单元格有 `<f>` 元素，脚本会从公式中提取所有引用的工作表名称（`SheetName!` 和 `'Sheet Name'!` 语法）。每个名称都与 `workbook.xml` 中的工作表列表进行比较。不匹配就是损坏的引用。

3. **未知的命名范围检测（启发式）**：公式中不是函数名、不是单元格引用、也不在 `workbook.xml` 的 `<definedNames>` 中的标识符被标记为 `unknown_name_ref` 警告。这是启发式的 — 可能存在误报；始终手动验证。

4. **共享公式完整性**：共享公式消费单元格（只有 `<f t="shared" si="N"/>` 的单元格）会跳过公式计数和交叉引用检查，因为它们继承主单元格的公式。只有主单元格（带有 `ref="..."` 属性和公式文本的单元格）被检查并计数。

5. **格式错误的错误单元格**：带有 `t="e"` 但没有 `<v>` 子元素的单元格被标记为结构性 XML 问题。

硬错误（退出代码 1）：`error_value`、`broken_sheet_ref`、`malformed_error_cell`、`file_error`
软警告（退出代码 0）：`unknown_name_ref` — 必须手动验证但单独不会阻止交付

#### 阅读 formula_check.py 人类可读输出

干净的文件看起来像这样：

```
文件   : /tmp/budget_2024.xlsx
工作表 : Summary, Q1, Q2, Q3, Q4, Assumptions
检查的公式数      : 312 个不同的公式单元格
共享公式范围 : 4 个范围
发现的错误          : 0

通过 — 未检测到公式错误
```

有错误的文件看起来像这样：

```
文件   : /tmp/budget_2024.xlsx
工作表 : Summary, Q1, Q2, Q3, Q4, Assumptions
检查的公式数      : 312 个不同的公式单元格
共享公式范围 : 4 个范围
发现的错误          : 4

── 错误详情 ──
  [失败] [Summary!C12] 包含 #REF! (公式: Q1!A0/Q1!A1)
  [失败] [Summary!D15] 引用缺少的工作表 'Q5'
         公式: Q5!D15
         有效工作表: ['Assumptions', 'Q1', 'Q2', 'Q3', 'Q4', 'Summary']
  [失败] [Q1!F8] 包含 #DIV/0!
  [警告] [Q2!B10] 使用未知名称 'GrowthAssumptions' (启发式 — 请手动验证)
         公式: SUM(GrowthAssumptions)
         定义的名称: ['RevenueRange', 'CostRange']

失败 — 交付前必须修复 3 个错误
警告 — 1 个启发式警告需要人工审核
```

每行解释：
- `[失败] [Summary!C12] 包含 #REF! (公式: Q1!A0/Q1!A1)` — 单元格有 `t="e"` 和 `<v>#REF!</v>`。公式引用第 0 行，在 Excel 的基于 1 的系统中不存在。这是生成的引用中的差一错误。
- `[失败] [Summary!D15] 引用缺少的工作表 'Q5'` — 公式包含 `Q5!D15`，但不存在名为 `Q5` 的工作表。为便于比较，提供了有效工作表列表。
- `[失败] [Q1!F8] 包含 #DIV/0!` — 此单元格的 `<v>` 已经是错误值（文件之前已重新计算）。公式除以零。
- `[警告] [Q2!B10] 使用未知名称 'GrowthAssumptions'` — 标识符 `GrowthAssumptions` 出现在公式中，但不在 `<definedNames>` 中。这可能是拼写错误或意外遗漏的名称。这是启发式警告 — 请手动验证。警告本身不会阻止交付。

#### 阅读 formula_check.py JSON 输出

```json
{
  "file": "/tmp/budget_2024.xlsx",
  "sheets_checked": ["Summary", "Q1", "Q2", "Q3", "Q4", "Assumptions"],
  "formula_count": 312,
  "shared_formula_ranges": 4,
  "error_count": 4,
  "errors": [
    {
      "type": "error_value",
      "error": "#REF!",
      "sheet": "Summary",
      "cell": "C12",
      "formula": "Q1!A0/Q1!A1"
    },
    {
      "type": "broken_sheet_ref",
      "sheet": "Summary",
      "cell": "D15",
      "formula": "Q5!D15",
      "missing_sheet": "Q5",
      "valid_sheets": ["Assumptions", "Q1", "Q2", "Q3", "Q4", "Summary"]
    },
    {
      "type": "error_value",
      "error": "#DIV/0!",
      "sheet": "Q1",
      "cell": "F8",
      "formula": null
    },
    {
      "type": "unknown_name_ref",
      "sheet": "Q2",
      "cell": "B10",
      "formula": "SUM(GrowthAssumptions)",
      "unknown_name": "GrowthAssumptions",
      "defined_names": ["RevenueRange", "CostRange"],
      "note": "启发式检查 — 如果是误报请手动验证"
    }
  ]
}
```

字段参考：

| 字段 | 含义 |
|-------|---------|
| `type: "error_value"` | 单元格有 `t="e"` — Excel 错误存储在 `<v>` 元素中 |
| `type: "broken_sheet_ref"` | 公式引用 workbook.xml 中不存在的工作表名称 |
| `type: "unknown_name_ref"` | 公式引用不在 `<definedNames>` 中的标识符（启发式，软警告） |
| `type: "malformed_error_cell"` | 单元格有 `t="e"` 但没有 `<v>` 子元素 — 结构性 XML 问题 |
| `type: "file_error"` | 文件无法打开（ZIP 损坏、未找到等） |
| `sheet` | 发现错误的工作表 |
| `cell` | A1 表示法中的单元格引用 |
| `formula` | 来自 `<f>` 元素的完整公式文本（如果没有则为 null） |
| `error` | 来自 `<v>` 的错误字符串（对于 `error_value` 类型） |
| `missing_sheet` | 公式中提取的不存在的工作表名称 |
| `valid_sheets` | workbook.xml 中实际存在的所有工作表名称 |
| `unknown_name` | 在 `<definedNames>` 中未找到的标识符 |
| `defined_names` | workbook.xml 中实际存在的所有命名范围 |
| `shared_formula_ranges` | 共享公式定义的数量（顶级 `<f t="shared" ref="...">` 元素） |

### 步骤 2：手动 XML 检查

当 formula_check.py 报告错误时，解压文件以检查原始 XML：

```bash
python3 SKILL_DIR/scripts/xlsx_unpack.py /path/to/file.xlsx /tmp/xlsx_inspect/
```

导航到报告工作表的工作表文件。工作表到文件的映射在 `xl/_rels/workbook.xml.rels` 中。例如，如果 `rId1` 映射到 `worksheets/sheet1.xml`，则 sheet1.xml 是 `xl/workbook.xml` 中具有 `r:id="rId1"` 的工作表的文件。

对于每个报告的错误单元格，找到 `<c r="CELLREF">` 元素并检查：

**对于 `error_value` 错误：**
```xml
<!-- 这是 XML 中错误单元格的样子 -->
<c r="C12" t="e">
  <f>Q1!C10/Q1!C11</f>
  <v>#DIV/0!</v>
</c>
```

询问：
- `<f>` 公式在语法上正确吗？
- 公式中的单元格引用是否指向存在的行/列？
- 如果是除法，分母单元格是否可能为空或零？

**对于 `broken_sheet_ref` 错误：**

检查 `xl/workbook.xml` 中的实际工作表列表：

```xml
<sheets>
  <sheet name="Summary" sheetId="1" r:id="rId1"/>
  <sheet name="Q1"      sheetId="2" r:id="rId2"/>
  <sheet name="Q2"      sheetId="3" r:id="rId3"/>
</sheets>
```

工作表名称是区分大小写的。`q1` 和 `Q1` 是不同的工作表。将公式中的名称与此处的名称精确比较。

### 步骤 3：跨工作表引用审计（多工作表工作簿）

对于具有 3 个或更多工作表的工作簿，在解压后运行更广泛的交叉引用审计：

```bash
# 提取所有包含跨工作表引用的公式
grep -h "<f>" /tmp/xlsx_inspect/xl/worksheets/*.xml | grep "!"

# 列出 workbook.xml 中的所有实际工作表名称
grep -o 'name="[^"]*"' /tmp/xlsx_inspect/xl/workbook.xml | grep -v sheetId
```

公式中出现的每个工作表名称（以 `SheetName!` 或 `'Sheet Name'!` 形式）都必须出现在工作表列表中。如果有任何不匹配，那就是损坏的引用，即使 formula_check.py 没有捕获到它（对于共享公式只检查主单元格时可能发生）。

要专门检查共享公式，请查找 `<f t="shared" ref="...">` 元素：

```xml
<!-- 共享公式：在 D2 上定义，应用于 D2:D100 -->
<c r="D2"><f t="shared" ref="D2:D100" si="0">Q1!B2*C2</f><v></v></c>

<!-- 共享公式消费者：只存在 si，没有公式文本 -->
<c r="D3"><f t="shared" si="0"/><v></v></c>
```

formula_check.py 从主单元格（上面的 `D2`）读取公式文本。该公式中引用的工作表 `Q1` 适用于整个范围 `D2:D100`。如果工作表损坏，即使它们显示为空的 `<f>` 元素，所有 99 行也都是损坏的。

---

## 第 2 层级 — 动态验证（LibreOffice 无头模式）

### 检查 LibreOffice 可用性

```bash
# 检查 macOS（典型安装位置）
which soffice
/Applications/LibreOffice.app/Contents/MacOS/soffice --version

# 检查 Linux
which libreoffice || which soffice
libreoffice --version
```

如果两个命令都没有返回路径，则未安装 LibreOffice。在报告中记录"第 2 层级：跳过 — LibreOffice 不可用"，并仅使用第 1 层级结果继续交付。

### 安装 LibreOffice（如果环境中允许）

macOS：
```bash
brew install --cask libreoffice
```

Ubuntu/Debian：
```bash
sudo apt-get install -y libreoffice
```

### 运行无头重新计算

使用专用的重新计算脚本。它处理 macOS 和 Linux 上的二进制发现，从输入的临时副本工作（保留原始文件），并提供与验证管道兼容的结构化输出和退出代码。

```bash
# 首先检查 LibreOffice 可用性
python3 SKILL_DIR/scripts/libreoffice_recalc.py --check

# 运行重新计算（默认超时：60s）
python3 SKILL_DIR/scripts/libreoffice_recalc.py /path/to/input.xlsx /tmp/recalculated.xlsx

# 对于大型或复杂文件，延长超时
python3 SKILL_DIR/scripts/libreoffice_recalc.py /path/to/input.xlsx /tmp/recalculated.xlsx --timeout 120
```

`libreoffice_recalc.py` 的退出代码：
- `0` — 重新计算成功，输出文件已写入
- `2` — 未找到 LibreOffice（在报告中记为跳过；不是硬失败）
- `1` — 找到 LibreOffice 但失败（超时、崩溃、格式错误的文件）

**脚本内部执行的操作：**

LibreOffice 的 `--convert-to xlsx` 命令使用 `--infilter="Calc MS Excel 2007 XML"` 筛选器通过完整的 Calc 引擎打开文件，执行每个公式，将计算值写入 `<v>` 缓存元素，并保存输出。这相当于服务器端的"在 Excel 中打开并按保存"。该脚本还传递 `--norestore` 以防止 LibreOffice 尝试恢复以前的会话，这可能会在自动化环境中导致挂起。

**如果 LibreOffice 未安装：**

macOS：
```bash
brew install --cask libreoffice
```

Ubuntu/Debian：
```bash
sudo apt-get install -y libreoffice
```

**如果脚本超时（libreoffice_recalc.py 以代码 1 退出并显示"超时"消息）：**

在报告中记录"第 2 层级：超时 — LibreOffice 在 N 秒内未完成"。不要在循环中重试。调查文件是否有循环引用或极大的数据范围。

### 重新计算后重新运行第 1 层级

LibreOffice 重新计算后，`<v>` 元素包含实际计算值。以前在不可见的错误（因为新生成文件中的 `<v>` 为空）现在显示为带有实际错误字符串的 `t="e"` 单元格。

```bash
python3 SKILL_DIR/scripts/formula_check.py /tmp/recalculated.xlsx
```

这第二次第 1 层级是通过的最终运行时错误检查。它发现的任何错误都是必须修复的实际计算失败。

---

## 所有 7 种错误类型 — 原因和修复策略

### #REF! — 无效的单元格引用

**含义：** 公式引用的单元格、范围或工作表不再存在或从未存在。

**生成文件中的常见原因：**
- 行/列计算中的差一错误（例如，引用在 Excel 基于 1 的系统中不存在的第 0 行）
- 列字母计算不正确（例如，第 64 列映射到 `BL`，而不是 `BK`）
- 公式引用从未创建或已重命名的工作表

**XML 特征：**
```xml
<c r="D5" t="e">
  <f>Sheet2!A0</f>
  <v>#REF!</v>
</c>
```

**修复 — 更正引用：**
```xml
<c r="D5">
  <f>Sheet2!A1</f>
  <v></v>
</c>
```

注意：更正公式后移除 `t="e"` 并清除 `<v>`。错误类型标记属于缓存状态，不属于公式。

**可自动修复？** 只有从周围上下文可以确定性确定正确目标时才可以。否则标记为人工审核。

---

### #DIV/0! — 除以零

**含义：** 公式除以零值或空单元格（空单元格在算术上下文中计算为 0）。

**生成文件中的常见原因：**
- 百分比变化公式 `=(B2-B1)/B1`，其中 `B1` 为空或零
- 比率公式 `=Value/Total`，其中总计行尚未填充

**XML 特征：**
```xml
<c r="C8" t="e">
  <f>B8/B7</f>
  <v>#DIV/0!</v>
</c>
```

**修复 — 使用 IFERROR 包装：**
```xml
<c r="C8">
  <f>IFERROR(B8/B7,0)</f>
  <v></v>
</c>
```

替代方案 — 显式零检查：
```xml
<c r="C8">
  <f>IF(B7=0,0,B8/B7)</f>
  <v></v>
</c>
```

**可自动修复？** 是。对于大多数财务公式，使用 `IFERROR(...,0)` 包装是安全的。如果业务期望结果显示为空白而非零，请改用 `IFERROR(...,"")`。

---

### #VALUE! — 错误的数据类型

**含义：** 公式尝试对错误类型的值进行算术或逻辑运算（例如，将文本字符串添加到数字）。

**生成文件中的常见原因：**
- 本应保存数字的单元格被写为字符串类型（`t="s"` 或 `t="inlineStr"`）而非数字类型
- 公式引用的单元格包含文本（例如，像"thousands"这样的单位标签）并将其视为数字

**XML 特征：**
```xml
<c r="F3" t="e">
  <f>E3+D3</f>
  <v>#VALUE!</v>
</c>
```

**修复 — 检查源单元格的类型是否正确：**

如果 `D3` 被错误地写为字符串：
```xml
<!-- 错误：数字值存储为字符串 -->
<c r="D3" t="inlineStr"><is><t>1000</t></is></c>

<!-- 正确：数字值存储为数字（t 属性省略或为 "n"） -->
<c r="D3"><v>1000</v></c>
```

或者，使用 `VALUE()` 转换包装公式：
```xml
<c r="F3">
  <f>VALUE(E3)+VALUE(D3)</f>
  <v></v>
</c>
```

**可自动修复？** 部分。如果源单元格类型明显错误（数字存储为字符串），修复类型。如果原因不明确（单元格应该包含文本），标记为人工审核。

---

### #NAME? — 无法识别的名称

**含义：** 公式包含 Excel 无法识别的标识符 — 拼写错误的函数名、未定义的命名范围，或目标 Excel 版本中不可用的函数。

**生成文件中的常见原因：**
- LLM 写的函数名有拼写错误：当只提供 3 个参数时 `SUMIF` 写成 `SUMIFS`，或在针对 Excel 2010 的上下文中使用 `XLOOKUP`
- 公式中引用的命名范围在 `xl/workbook.xml` 中不存在

**XML 特征：**
```xml
<c r="B2" t="e">
  <f>SUMSQ(A2:A10)</f>
  <v>#NAME?</v>
</c>
```

**修复 — 验证函数名和命名范围：**

在 `xl/workbook.xml` 中检查命名范围：
```xml
<definedNames>
  <definedName name="RevenueRange">Sheet1!$B$2:$B$13</definedName>
</definedNames>
```

如果公式引用 `RevenuRange`（拼写错误），请更正为 `RevenueRange`：
```xml
<c r="B2">
  <f>SUM(RevenueRange)</f>
  <v></v>
</c>
```

**可自动修复？** 只有正确名称明确时才可以（例如，存在单个接近匹配）。否则标记为人工审核 — 函数名修复需要理解预期的计算。

---

### #N/A — 值不可用

**含义：** 查找函数（VLOOKUP、HLOOKUP、MATCH、INDEX/MATCH、XLOOKUP）搜索了查找表中不存在的值。

**生成文件中的常见原因：**
- 查找键存在于公式中，但查找表为空或尚未填充
- 键格式不匹配（文本 "2024" vs 数字 2024）

**XML 特征：**
```xml
<c r="G5" t="e">
  <f>VLOOKUP(F5,Assumptions!$A$2:$B$20,2,0)</f>
  <v>#N/A</v>
</c>
```

**修复 — 使用 IFERROR 包装以容忍缺失匹配：**
```xml
<c r="G5">
  <f>IFERROR(VLOOKUP(F5,Assumptions!$A$2:$B$20,2,0),0)</f>
  <v></v>
</c>
```

**可自动修复？** 如果零默认值可接受，添加 `IFERROR` 是安全的。如果查找失败表示数据完整性问题（键应该始终存在），请不要自动修复 — 标记为人工审核。

---

### #NULL! — 空交集

**含义：** 空间运算符（计算两个范围的交集）被应用于两个不相交的范围。

**生成文件中的常见原因：**
- 两个范围引用之间意外出现空格：`SUM(A1:A5 C1:C5)` 而不是 `SUM(A1:A5,C1:C5)`
- 在典型的财务模型中很少见；通常表示公式生成错误

**XML 特征：**
```xml
<c r="H10" t="e">
  <f>SUM(A1:A5 C1:C5)</f>
  <v>#NULL!</v>
</c>
```

**修复 — 将空格替换为逗号（并集）或冒号（范围）：**
```xml
<!-- 两个独立范围的并集 -->
<c r="H10">
  <f>SUM(A1:A5,C1:C5)</f>
  <v></v>
</c>
```

**可自动修复？** 是。空间运算符在生成的公式中几乎从不是故意的。替换为逗号是安全的。

---

### #NUM! — 数字错误

**含义：** 公式生成了 Excel 无法表示的数字（溢出、下溢）或没有实数结果的数学运算（负数的平方根，零或负数的对数）。

**生成文件中的常见原因：**
- 现金流量系列没有收敛解的 IRR 或 NPV 公式
- 应用于可能为负的单元格的 `SQRT()`
- 非常大的幂运算

**XML 特征：**
```xml
<c r="J15" t="e">
  <f>IRR(B5:B15)</f>
  <v>#NUM!</v>
</c>
```

**修复 — 添加条件保护：**
```xml
<c r="J15">
  <f>IFERROR(IRR(B5:B15),"")</f>
  <v></v>
</c>
```

对于 SQRT：
```xml
<c r="K5">
  <f>IF(A5>=0,SQRT(A5),"")</f>
  <v></v>
</c>
```

**可自动修复？** 部分。使用 `IFERROR` 包装会抑制错误显示，但不会修复潜在的计算问题。即使在应用 IFERROR 包装后，也要将该单元格标记为人工审核。

---

## 自动修复 vs. 人工审核决策矩阵

| 错误类型 | 可安全自动修复？ | 条件 | 操作 |
|------------|---------------|-----------|--------|
| `#DIV/0!` | 是 | 始终 | 使用 `IFERROR(formula,0)` 包装 |
| `#NULL!` | 是 | 始终 | 将空间运算符替换为逗号 |
| `#REF!` | 是 | 仅当从上下文可以明确正确目标时 | 更正引用；否则标记 |
| `#NAME?` | 是 | 仅当拼写错误有且只有一个合理的更正时 | 修复名称；否则标记 |
| `#N/A` | 有条件 | 如果零/空白默认值在业务上可接受 | 添加 IFERROR 包装；记录假设 |
| `#VALUE!` | 有条件 | 仅当源单元格类型明显错误时 | 修复类型；否则标记 |
| `#NUM!` | 否 | 始终 | 添加 IFERROR 以抑制显示，然后标记 |
| 损坏的工作表引用 | 是 | 仅当可以从 workbook.xml 识别重命名的工作表时 | 更正名称 |
| 业务逻辑错误 | 否 | 任何情况 | 仅限人工审核 |

**什么算作业务逻辑错误（永远不要自动修复）：**
- 产生错误数字但没有 Excel 错误的公式（例如，当意图是 `=SUM(B2:B9)` 时的 `=SUM(B2:B8)`）
- IFERROR 默认值有意义的公式（例如，是使用 0、空白还是前期值）
- 修复错误需要知道公式应该计算什么的任何公式

---

## 交付标准 — 验证报告

每个验证任务必须生成结构化报告。无论是否发现错误，此报告都是可交付成果。

### 所需的报告格式

```markdown
## 公式验证报告

**文件**：/path/to/filename.xlsx
**日期**：YYYY-MM-DD
**检查的工作表**：Sheet1, Sheet2, Sheet3
**扫描的公式总数**：N

---

### 第 1 层级 — 静态验证

**状态**：通过 / 失败
**工具**：formula_check.py（直接 XML 扫描）

| 工作表 | 单元格 | 错误类型 | 详情 | 应用的修复 |
|-------|------|-----------|--------|-------------|
| Summary | C12 | #REF! | 公式: Q1!A0 | 更正为 Q1!A1 |
| Summary | D15 | broken_sheet_ref | 引用缺少的工作表 'Q5' | 重命名为 Q4 |

_（如果没有错误："未检测到错误。"）_

---

### 第 2 层级 — 动态验证

**状态**：通过 / 失败 / 跳过
**工具**：LibreOffice 无头模式 (version X.Y.Z) / 不可用

_（如果 跳过：说明原因 — LibreOffice 未安装、超时等）_

| 工作表 | 单元格 | 错误类型 | 详情 | 应用的修复 |
|-------|------|-----------|--------|-------------|
| Q1 | F8 | #DIV/0! | 公式: C8/C7 | 使用 IFERROR 包装 |

_（如果没有错误："重新计算后未检测到运行时错误。"）_

---

### 摘要

- **发现的错误总数**：N
- **自动修复**：N（列出类型）
- **标记为人工审核**：N（列出单元格和原因）
- **最终状态**：通过（可交付）/ 失败（已阻止）

### 需要人工审核

| 单元格 | 错误 | 未应用自动修复的原因 |
|------|-------|----------------------------|
| Q2!B15 | #NUM! | IRR 公式 — 业务必须确认现金流量输入 |
```

### 最低要求的字段

如果缺少以下任何一项，报告无效（交付被阻止）：
- 文件路径和日期
- 检查了哪些工作表
- 公式总数
- 带有明确 通过/失败 的第 1 层级状态
- 带有明确 通过/失败/跳过 的第 2 层级状态，如果 跳过 则说明原因
- 对于每个错误：工作表、单元格、错误类型和处理（已修复或已标记）
- 最终交付状态

---

## 常见场景

### 场景 1：创建新文件后立即验证

当 `create.md` 工作流生成新的 xlsx 时，在任何交付响应之前运行验证。

```bash
# 步骤 1：对刚写入的文件进行静态检查
python3 SKILL_DIR/scripts/formula_check.py /path/to/output.xlsx

# 步骤 2：动态检查（如果 LibreOffice 可用）
python3 SKILL_DIR/scripts/libreoffice_recalc.py /path/to/output.xlsx /tmp/recalculated.xlsx
python3 SKILL_DIR/scripts/formula_check.py /tmp/recalculated.xlsx
```

对刚创建文件的预期行为：第 1 层级会发现零个 `error_value` 错误（因为 `<v>` 元素为空，而非错误值）。如果工作表名称拼写错误，它会发现任何损坏的跨工作表引用。第 2 层级将填充 `<v>` 并显示像 `#DIV/0!` 这样的运行时错误。

如果第 2 层级显示错误，请在源 XML 中修复它们（而不是重新计算的副本），重新打包，然后重新运行两个层级。

### 场景 2：编辑现有文件后验证

当 `edit.md` 工作流修改现有 xlsx 时，如果编辑是外科手术式的，则仅验证受影响的工作表。如果编辑触及了共享公式或跨工作表引用，则验证所有工作表。

```bash
# 有针对性的静态检查 — 查看特定工作表
# (formula_check.py 检查所有工作表；只检查输出中的相关部分)
python3 SKILL_DIR/scripts/formula_check.py /path/to/edited.xlsx --json \
  | python3 -c "
import json, sys
r = json.load(sys.stdin)
for e in r['errors']:
    if e.get('sheet') in ['Summary', 'Q1']:
        print(e)
"
```

即使第 1 层级通过，在修改公式的编辑后始终运行第 2 层级。数据范围的编辑可能导致以前有效的公式产生运行时错误。

### 场景 3：用户提供有疑似公式错误的文件

当用户提交文件并报告错误值时：

```bash
# 步骤 1：静态扫描 — 找到所有错误单元格
python3 SKILL_DIR/scripts/formula_check.py /path/to/user_file.xlsx --json > /tmp/validation_results.json

# 步骤 2：解压以进行手动检查
python3 SKILL_DIR/scripts/xlsx_unpack.py /path/to/user_file.xlsx /tmp/xlsx_inspect/

# 步骤 3：动态重新计算
python3 SKILL_DIR/scripts/libreoffice_recalc.py /path/to/user_file.xlsx /tmp/user_file_recalc.xlsx

# 步骤 4：重新验证重新计算后的文件
python3 SKILL_DIR/scripts/formula_check.py /tmp/user_file_recalc.xlsx --json > /tmp/validation_after_recalc.json

# 步骤 5：比较之前和之后
python3 - <<'EOF'
import json
before = json.load(open("/tmp/validation_results.json"))
after  = json.load(open("/tmp/validation_after_recalc.json"))
print(f"重新计算前: {before['error_count']} 个错误")
print(f"重新计算后: {after['error_count']} 个错误")
EOF
```

如果错误仅在重新计算后出现（不在原始静态扫描中），则公式在语法上是正确的，但在运行时产生错误结果。这些是需要公式级修复而不是 XML 结构修复的运行时错误。

如果错误在两个扫描中都出现，它们在重新计算前就已经缓存在 `<v>` 中 — 文件之前已被 Excel/LibreOffice 打开，错误仍然存在。

---

## 关键陷阱

**陷阱 1：openpyxl `data_only=True` 会破坏公式。**
使用 `data_only=True` 打开工作簿会读取缓存值而不是公式。如果您随后保存工作簿，所有 `<f>` 元素都会永久删除，并替换为它们最后的缓存值。永远不要在验证工作流中使用此模式。

**陷阱 2：空的 `<v>` 与通过的公式不同。**
新生成的文件对于所有公式单元格都有空的 `<v>` 元素。formula_check.py 不会将这些报告为错误 — 它们还不是错误。它们只有在重新计算后才成为错误（如果计算值是错误类型）。这就是第 2 层级是强制性的原因。

**陷阱 3：共享公式错误影响整个范围。**
如果共享公式的主单元格有损坏的引用，共享范围（`ref="D2:D100"`）中的每个单元格都会继承该损坏的引用。逻辑错误的数量可能远大于 formula_check.py 输出中不同错误条目的数量。修复损坏的共享公式时，修复主单元格的 `<f t="shared" ref="...">` 元素；消费者（`<f t="shared" si="N"/>`）会自动继承更正的公式。

**陷阱 4：工作表名称是区分大小写的。**
`=q1!B5` 和 `=Q1!B5` 是不同的引用。Excel 在内部将它们视为相同，但 formula_check.py 的字符串比较是区分大小写的。如果公式使用了与工作簿中的大写工作表匹配的小写工作表名称，它将被标记为损坏的引用。修复方法是与 `workbook.xml` 中的确切大小写匹配。

**陷阱 5：`--convert-to xlsx` 不保证公式保留。**
LibreOffice 的转换偶尔会更改某些公式类型（数组公式、动态数组函数如 `SORT`、`UNIQUE`）。第 2 层级之后，如果重新计算的文件显示与错误修复无关的公式更改，请不要直接交付重新计算的文件 — 而是使用带有针对性 XML 修复的原始文件。
