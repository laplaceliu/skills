# 现有 xlsx 的微创编辑

对现有 xlsx 文件进行精确、外科手术般的修改，同时保留您不接触的所有内容：样式、宏、数据透视表、图表、迷你图、命名区域、数据验证、条件格式以及所有其他嵌入内容。

---

## 1. 何时使用此路径

当任务涉及**修改现有 xlsx 文件**时，使用编辑（解压 → XML 编辑 → 打包）路径：

- 模板填充 — 用值或公式填充指定的输入单元格
- 数据更新 — 替换实时文件中过时的数字、文本或日期
- 内容更正 — 修复错误的值、损坏的公式或打错字的标签
- 向现有表格添加新数据行
- 重命名工作表
- 将新样式应用于特定单元格

不要将此路径用于从头创建全新的工作簿。为此，请参阅 `create.md`。

---

## 2. 为什么禁止对现有文件使用 openpyxl 往返操作

openpyxl 的 `load_workbook()` 后跟 `workbook.save()` 对于包含高级功能的任何文件来说都是一个**破坏性操作**。该库会静默删除它不理解的内容：

| 功能 | openpyxl 行为 | 后果 |
|---------|-------------------|-------------|
| VBA 宏 (`vbaProject.bin`) | 完全删除 | 所有自动化丢失；文件保存为 `.xlsx` 而非 `.xlsm` |
| 数据透视表 (`xl/pivotTables/`) | 删除 | 交互式分析被破坏 |
| 切片器 | 删除 | 筛选器 UI 丢失 |
| 迷你图 (`<sparklineGroups>`) | 删除 | 单元格内迷你图表消失 |
| 图表格式详细信息 | 部分丢失 | 系列颜色、自定义轴可能恢复 |
| 打印区域/分页符 | 有时丢失 | 打印布局更改 |
| 自定义 XML 部件 | 删除 | 第三方数据绑定被破坏 |
| 主题链接颜色 | 可能去主题化 | 颜色转换为绝对值，破坏主题切换 |

即使在没有任何这些功能的"普通"文件上，openpyxl 也可能规范化 Excel 依赖的 XML 中的空白，更改命名空间声明，或重置 `calcMode` 标志。

**规则是绝对的：永远不要为了重新保存而用 openpyxl 打开现有文件。**

XML 直接编辑方法是安全的，因为它操作原始字节。您只更改接触的节点。其他所有内容都与原始内容字节等效。

---

## 3. 标准操作程序

### 步骤 1 — 解压

```bash
python3 SKILL_DIR/scripts/xlsx_unpack.py input.xlsx /tmp/xlsx_work/
```

该脚本解压缩 xlsx，美化打印每个 XML 和 `.rels` 文件，并打印关键文件的分类清单以及检测到高风险内容（VBA、数据透视表、图表）时的警告。

在继续之前仔细阅读打印的输出。如果脚本报告了 `xl/vbaProject.bin` 或 `xl/pivotTables/`，请遵循第 7 节中的约束。

### 步骤 2 — 侦察

在接触任何内容之前先映射结构。

**识别工作表名称及其 XML 文件：**

```
xl/workbook.xml  →  <sheet name="Revenue" sheetId="1" r:id="rId1"/>
xl/_rels/workbook.xml.rels  →  <Relationship Id="rId1" Target="worksheets/sheet1.xml"/>
```

名为"Revenue"的工作表位于 `xl/worksheets/sheet1.xml` 中。在编辑工作表之前始终解析此映射。

**了解共享字符串表：**

```bash
# 计算 xl/sharedStrings.xml 中的现有条目数
grep -c "<si>" /tmp/xlsx_work/xl/sharedStrings.xml
```

每个文本单元格都使用基于零的索引引用此表。在追加之前了解当前计数。

**了解样式表：**

```bash
# 计算现有的 cellXfs 条目数
grep -c "<xf " /tmp/xlsx_work/xl/styles.xml
```

新的样式槽位会追加到现有条目之后。第一个新槽位的索引 = 当前计数。

**扫描目标工作表中的高风险 XML 区域：**

编辑前在目标 `sheet*.xml` 中查找这些元素：

- `<mergeCell>` — 合并单元格范围；行/列插入会移动这些
- `<conditionalFormatting>` — 条件范围；行/列插入会移动这些
- `<dataValidations>` — 验证范围；行/列插入会移动这些
- `<tableParts>` — 表格定义；在表格内插入行需要更新 `<tableColumn>`
- `<sparklineGroups>` — 迷你图；保留而不修改

### 步骤 3 — 将意图映射到最小的 XML 更改

在编写单个字符之前，生成一份书面列表，列出确切要更改哪些 XML 节点。这可以防止范围蔓延。

| 用户意图 | 要更改的文件 | 要更改的节点 |
|-------------|----------------|-----------------|
| 更改单元格的数字值 | `xl/worksheets/sheetN.xml` | 目标 `<c>` 内的 `<v>` |
| 更改单元格的文本 | `xl/sharedStrings.xml` (追加) + `xl/worksheets/sheetN.xml` | 新的 `<si>`，更新单元格 `<v>` 索引 |
| 更改单元格的公式 | `xl/worksheets/sheetN.xml` | 目标 `<c>` 内的 `<f>` 文本 |
| 在底部添加新数据行 | `xl/worksheets/sheetN.xml` + 可能 `xl/sharedStrings.xml` | 追加 `<row>` 元素 |
| 将新样式应用于单元格 | `xl/styles.xml` + `xl/worksheets/sheetN.xml` | 在 `<cellXfs>` 中追加 `<xf>`，更新 `<c>` 上的 `s` 属性 |
| 重命名工作表 | `xl/workbook.xml` | `<sheet>` 元素上的 `name` 属性 |
| 重命名工作表（带跨工作表公式） | `xl/workbook.xml` + 所有 `xl/worksheets/*.xml` | `name` 属性 + 引用旧名称的 `<f>` 文本 |

### 步骤 4 — 执行更改

使用编辑工具。进行最小化编辑。永远不要重写整个文件。

有关每种操作类型的精确 XML 模式，请参见第 4 节。

### 步骤 5 — 级联检查

在对行或列位置进行任何更改后，审核所有受影响的 XML 区域。请参见第 5 节。

### 步骤 6 — 打包和验证

```bash
python3 SKILL_DIR/scripts/xlsx_pack.py /tmp/xlsx_work/ output.xlsx
python3 SKILL_DIR/scripts/formula_check.py output.xlsx
```

打包脚本在创建 ZIP 之前验证 XML 格式正确性。在打包之前修复任何报告的解析错误。打包后，运行 `formula_check.py` 以确认没有引入公式错误。

---

## 4. 常见编辑的精确 XML 模式

### 4.1 更改数字单元格值

在工作表 XML 中找到 `<c r="B5">` 元素并替换 `<v>` 文本。

**之前：**
```xml
<c r="B5">
  <v>1000</v>
</c>
```

**之后（新值 1500）：**
```xml
<c r="B5">
  <v>1500</v>
</c>
```

规则：
- 除非明确更改样式，否则不要添加或删除 `s` 属性（样式）。
- 不要添加 `t` 属性 — 数字省略 `t` 或使用 `t="n"`。
- 不要更改 `r` 属性（单元格引用）。

---

### 4.2 更改文本单元格值

文本单元格通过索引 (`t="s"`) 引用共享字符串表。如果不影响使用相同索引的其他每个单元格，就无法就地编辑字符串。安全的方法是追加新条目。

**之前 — 共享字符串文件 (`xl/sharedStrings.xml`)：**
```xml
<sst count="4" uniqueCount="4">
  <si><t>Revenue</t></si>
  <si><t>Cost</t></si>
  <si><t>Margin</t></si>
  <si><t>Old Label</t></si>
</sst>
```

**之后 — 追加新字符串，递增计数：**
```xml
<sst count="5" uniqueCount="5">
  <si><t>Revenue</t></si>
  <si><t>Cost</t></si>
  <si><t>Margin</t></si>
  <si><t>Old Label</t></si>
  <si><t>New Label</t></si>
</sst>
```

新字符串位于索引 4（基于零）。

**之前 — 工作表 XML 中的单元格：**
```xml
<c r="A7" t="s">
  <v>3</v>
</c>
```

**之后 — 指向新索引：**
```xml
<c r="A7" t="s">
  <v>4</v>
</c>
```

规则：
- 永远不要修改或删除现有的 `<si>` 条目。只能追加。
- `count` 和 `uniqueCount` 必须一起递增。
- 如果新字符串包含 `&`、`<` 或 `>`，请对它们进行转义：`&amp;`、`&lt;`、`&gt;`。
- 如果字符串有前导或尾随空格，请向 `<t>` 添加 `xml:space="preserve"`：
  ```xml
  <si><t xml:space="preserve">  indented text  </t></si>
  ```

---

### 4.3 更改公式

公式存储在 `<f>` 元素中，**没有前导 `=`**（与您在 Excel UI 中键入的不同）。

**之前：**
```xml
<c r="C10">
  <f>SUM(C2:C9)</f>
  <v>4800</v>
</c>
```

**之后（扩展范围）：**
```xml
<c r="C10">
  <f>SUM(C2:C11)</f>
  <v></v>
</c>
```

规则：
- 更改公式时将 `<v>` 清除为空字符串。缓存值现在已过时。
- 不要向公式单元格添加 `t="s"` 或任何类型属性。`t` 属性缺失或使用结果类型值，而非公式标记。
- 跨工作表引用使用 `SheetName!CellRef`。如果工作表名称包含空格，请用单引号括起来：`'Q1 Data'!B5`。
- `<f>` 文本不得包含前导 `=`。

**之前（将硬编码值转换为实时公式）：**
```xml
<c r="D15">
  <v>95000</v>
</c>
```

**之后：**
```xml
<c r="D15">
  <f>SUM(D2:D14)</f>
  <v></v>
</c>
```

---

### 4.4 添加新数据行

在 `<sheetData>` 内的最后一个 `<row>` 元素之后追加。OOXML 中的行号是 1 开始的，必须是连续的。

**之前（最后一行是第 10 行）：**
```xml
  <row r="10">
    <c r="A10" t="s"><v>3</v></c>
    <c r="B10"><v>2023</v></c>
    <c r="C10"><v>88000</v></c>
    <c r="D10"><f>C10*1.1</f><v></v></c>
  </row>
</sheetData>
```

**之后（追加了新第 11 行）：**
```xml
  <row r="10">
    <c r="A10" t="s"><v>3</v></c>
    <c r="B10"><v>2023</v></c>
    <c r="C10"><v>88000</v></c>
    <c r="D10"><f>C10*1.1</f><v></v></c>
  </row>
  <row r="11">
    <c r="A11" t="s"><v>4</v></c>
    <c r="B11"><v>2024</v></c>
    <c r="C11"><v>96000</v></c>
    <c r="D11"><f>C11*1.1</f><v></v></c>
  </row>
</sheetData>
```

规则：
- 行内的每个 `<c>` 必须将 `r` 设置为正确的单元格地址（例如，`A11`）。
- 文本单元格需要 `t="s"` 和 `<v>` 中的 sharedStrings 索引。数字单元格省略 `t`。
- 公式单元格使用 `<f>` 和空的 `<v>`。
- 如果需要匹配样式，请从上一行复制 `s` 属性。不要编造 `styles.xml` 中不存在的样式索引。
- 如果工作表包含 `<dimension>` 元素（例如，`<dimension ref="A1:D10"/>`），请将其更新为包含新行：`<dimension ref="A1:D11"/>`。
- 如果工作表包含引用表格的 `<tableparts>`，请在相应的 `xl/tables/tableN.xml` 文件中更新表格的 `ref` 属性。

---

### 4.5 添加新列

向每个现有的 `<row>` 追加新的 `<c>` 元素，如果存在，还要更新 `<cols>` 部分。

**之前（行有 A-C 列）：**
```xml
<cols>
  <col min="1" max="3" width="14" customWidth="1"/>
</cols>
<sheetData>
  <row r="1">
    <c r="A1" t="s"><v>0</v></c>
    <c r="B1" t="s"><v>1</v></c>
    <c r="C1" t="s"><v>2</v></c>
  </row>
  <row r="2">
    <c r="A2"><v>100</v></c>
    <c r="B2"><v>200</v></c>
    <c r="C2"><v>300</v></c>
  </row>
</sheetData>
```

**之后（添加 D 列）：**
```xml
<cols>
  <col min="1" max="3" width="14" customWidth="1"/>
  <col min="4" max="4" width="14" customWidth="1"/>
</cols>
<sheetData>
  <row r="1">
    <c r="A1" t="s"><v>0</v></c>
    <c r="B1" t="s"><v>1</v></c>
    <c r="C1" t="s"><v>2</v></c>
    <c r="D1" t="s"><v>5</v></c>
  </row>
  <row r="2">
    <c r="A2"><v>100</v></c>
    <c r="B2"><v>200</v></c>
    <c r="C2"><v>300</v></c>
    <c r="D2"><f>A2+B2+C2</f><v></v></c>
  </row>
</sheetData>
```

规则：
- 在最后（最后一列之后）添加列是安全的 — 现有公式引用不会移动。
- 在中间插入列会将所有列向右移动，这需要与行插入相同的级联更新（请参见第 5 节）。
- 如果存在，请更新 `<dimension>` 元素。

---

### 4.6 修改或添加样式

样式使用多级间接引用链。有关完整链，请阅读 `ooxml-cheatsheet.md`。关键规则：**只能追加新条目，永远不要修改现有条目**。

**场景：** 添加尚不存在的蓝色字体样式（用于硬编码输入单元格）。

**步骤 1 — 检查 `xl/styles.xml` 中是否已存在匹配的字体：**
```xml
<!-- 在 <fonts> 内查找现有的蓝色字体 -->
<font>
  <color rgb="000000FF"/>
  <!-- 其他属性 -->
</font>
```

如果找到，记下其索引（`<fonts>` 列表中基于零的位置）。如果未找到，则追加。

**步骤 2 — 如果需要，追加新字体：**

之前：
```xml
<fonts count="3">
  <font>...</font>   <!-- 索引 0 -->
  <font>...</font>   <!-- 索引 1 -->
  <font>...</font>   <!-- 索引 2 -->
</fonts>
```

之后：
```xml
<fonts count="4">
  <font>...</font>   <!-- 索引 0 -->
  <font>...</font>   <!-- 索引 1 -->
  <font>...</font>   <!-- 索引 2 -->
  <font>
    <b/>
    <sz val="11"/>
    <color rgb="000000FF"/>
    <name val="Calibri"/>
  </font>             <!-- 索引 3 (新) -->
</fonts>
```

**步骤 3 — 在 `<cellXfs>` 中追加新的 `<xf>`：**

之前：
```xml
<cellXfs count="5">
  <xf .../>   <!-- 索引 0 -->
  <xf .../>   <!-- 索引 1 -->
  <xf .../>   <!-- 索引 2 -->
  <xf .../>   <!-- 索引 3 -->
  <xf .../>   <!-- 索引 4 -->
</cellXfs>
```

之后：
```xml
<cellXfs count="6">
  <xf .../>   <!-- 索引 0 -->
  <xf .../>   <!-- 索引 1 -->
  <xf .../>   <!-- 索引 2 -->
  <xf .../>   <!-- 索引 3 -->
  <xf .../>   <!-- 索引 4 -->
  <xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0"
      applyFont="1"/>   <!-- 索引 5 (新) -->
</cellXfs>
```

**步骤 4 — 应用于目标单元格：**

之前：
```xml
<c r="B3">
  <v>0.08</v>
</c>
```

之后：
```xml
<c r="B3" s="5">
  <v>0.08</v>
</c>
```

规则：
- 永远不要删除或重新排序 `<fonts>`、`<fills>`、`<borders>`、`<cellXfs>` 中的现有条目。
- 追加时始终更新 `count` 属性。
- 新的 `cellXfs` 索引 = 追加前的旧 `count` 值（基于零：如果 count 是 5，新索引是 5）。
- 自定义 `numFmt` ID 必须是 164 或更高。ID 0–163 是内置的，不得重新声明。
- 如果文件中其他位置已存在所需的样式（在类似单元格上），请重用其 `s` 索引而不是创建重复项。

---

### 4.7 重命名工作表

**只需要更改 `xl/workbook.xml`** — 除非跨工作表公式引用了旧名称。

**之前 (`xl/workbook.xml`)：**
```xml
<sheet name="Sheet1" sheetId="1" r:id="rId1"/>
```

**之后：**
```xml
<sheet name="Revenue" sheetId="1" r:id="rId1"/>
```

**如果任何工作表中的任何公式引用了旧名称，也要更新这些公式：**

之前 (`xl/worksheets/sheet2.xml`)：
```xml
<c r="B5"><f>Sheet1!C10</f><v></v></c>
```

之后：
```xml
<c r="B5"><f>Revenue!C10</f><v></v></c>
```

如果新名称包含空格：
```xml
<c r="B5"><f>'Q1 Revenue'!C10</f><v></v></c>
```

扫描所有工作表 XML 文件中的旧名称：
```bash
grep -r "Sheet1!" /tmp/xlsx_work/xl/worksheets/
```

规则：
- `.rels` 文件和 `[Content_Types].xml` 不需要更改 — 它们引用 XML 文件路径，而非工作表名称。
- `sheetId` 不得更改；它是稳定的内部标识符。
- 工作表名称在公式引用中是区分大小写的。

---

## 5. 高风险操作 — 级联影响

### 5.1 在中间插入行

在位置 N 插入行会将所有从 N 开始的行向下移动。每个 XML 文件中对那些行的每个引用都必须更新。

**要检查和更新的文件：**

| XML 区域 | 要更新的内容 | 示例移动 |
|------------|---------------|---------------|
| 工作表 `<row r="...">` 属性 | 为所有行号 >= N 的行递举行号 | `r="7"` → `r="8"` |
| 这些行中的所有 `<c r="...">` | 在单元格地址中递举行号 | `r="A7"` → `r="A8"` |
| 任何工作表中的所有 `<f>` 公式文本 | 移动绝对行引用 >= N | `B7` → `B8` |
| `<mergeCell ref="...">` | 移动起始和结束行 | `A7:C7` → `A8:C8` |
| `<conditionalFormatting sqref="...">` | 移动范围 | `A5:D20` → `A5:D21` |
| `<dataValidations sqref="...">` | 移动范围 | `B6:B50` → `B7:B51` |
| `xl/charts/chartN.xml` 数据源范围 | 移动系列范围 | `Sheet1!$B$5:$B$20` → `Sheet1!$B$6:$B$21` |
| `xl/pivotTables/*.xml` 源范围 | 移动源数据范围 | 极度小心处理 — 请参见第 7 节 |
| `<dimension ref="...">` | 扩展以包含新的范围 | `A1:D20` → `A1:D21` |
| `xl/tables/tableN.xml` `ref` 属性 | 扩展表格边界 | `A1:D20` → `A1:D21` |

**不要尝试在大型或公式密集型文件中手动插入行。** 请改用专用的移动脚本：

```bash
# 在第 5 行插入 1 行：第 5 行及以下的所有行向下移动 1 行
python3 SKILL_DIR/scripts/xlsx_shift_rows.py /tmp/xlsx_work/ insert 5 1

# 在第 8 行删除 1 行：第 9 行及以上的所有行向上移动 1 行
python3 SKILL_DIR/scripts/xlsx_shift_rows.py /tmp/xlsx_work/ delete 8 1
```

该脚本在一次传递中更新：`<row r="...">` 属性、`<c r="...">` 单元格地址、每个工作表中的所有 `<f>` 公式文本、`<mergeCell>` 范围、`<conditionalFormatting sqref="...">`、`<dataValidation sqref="...">`、`<dimension ref="...">`、`xl/tables/` 中的表格 `ref` 属性、`xl/charts/` 中的图表系列范围，以及 `xl/pivotCaches/` 中的透视缓存源范围。

**运行移动脚本后，始终重新打包和验证：**
```bash
python3 SKILL_DIR/scripts/xlsx_pack.py /tmp/xlsx_work/ output.xlsx
python3 SKILL_DIR/scripts/formula_check.py output.xlsx
```

**脚本不更新的内容（手动检查）：**
- `xl/workbook.xml` `<definedNames>` 中的命名范围 — 如果它们引用移动的行，请检查并更新。
- 公式内的结构化表格引用 (`Table[@Column]`)。
- `xl/externalLinks/` 中的外部工作簿链接。

### 5.2 在中间插入列

与行插入的级联逻辑相同，但针对列。公式中的列引用（`B`、`$C` 等）以及合并单元格范围、条件格式范围和图表数据源都需要更新。

列字母移动更难安全地自动化。只要可能，**在最后追加列**。

### 5.3 删除行或列

删除比插入更危险，因为任何引用已删除行或列的公式都会变成 `#REF!`。删除之前：

1. 在所有 `<f>` 元素中搜索对已删除范围的引用。
2. 如果任何公式引用了已删除行/列中的单元格，请不要删除 — 而是清除该行的数据或咨询用户。
3. 删除后，将超出删除点的所有引用向下/向左移动。

---

## 6. 模板填充 — 识别和填充输入单元格

模板将某些单元格指定为输入区域。用于识别它们的常见模式：

### 6.1 模板如何标记输入区域

| 信号 | XML 表现形式 | 要查找的内容 |
|--------|-------------------|-----------------|
| 蓝色字体颜色 | `s` 属性指向带有 `fontId` → `<color rgb="000000FF"/>` 的 `cellXfs` 条目 | 检查 `styles.xml` 以解码 `s` 值 |
| 黄色填充（高亮） | `s` → `fillId` → `<fill><patternFill><fgColor rgb="00FFFF00"/>` | |
| 空的 `<v>` 元素 | `<c r="B5"><v></v></c>` 或单元格完全不存在于 `<row>` 中 | 该单元格尚无值 |
| 单元格附近的注释/批注 | 带有 `ref="B5"` 的 `xl/comments1.xml` | 注释通常标记输入字段 |
| 命名范围 | `xl/workbook.xml` `<definedName>` 元素 | 模板可能定义 `InputRevenue` 等 |

### 6.2 填充模板单元格

不要更改 `s` 属性。除非必须从空更改为类型，否则不要更改 `t` 属性。仅更改 `<v>` 或添加 `<f>`。

**之前（保留样式的空输入单元格）：**
```xml
<c r="C5" s="3">
  <v></v>
</c>
```

**之后（填充数字，样式不变）：**
```xml
<c r="C5" s="3">
  <v>125000</v>
</c>
```

**之后（填充文本 — 首先需要在共享字符串表中添加条目）：**
```xml
<!-- 1. 追加到 sharedStrings.xml: <si><t>North Region</t></si> 位于索引 7 -->
<c r="C5" t="s" s="3">
  <v>7</v>
</c>
```

**之后（填充公式，保留样式）：**
```xml
<c r="C5" s="3">
  <f>Assumptions!D12</f>
  <v></v>
</c>
```

### 6.3 在不在 Excel 中打开文件的情况下定位输入区域

解压后，解码可疑输入单元格上的样式索引以确定它们是否具有模板的输入颜色：

1. 记下单元格上的 `s` 值（例如，`s="4"`）。
2. 在 `xl/styles.xml` 中，找到 `<cellXfs>` 并查看第 5 个条目（索引 4）。
3. 记下其 `fontId`（例如，`fontId="2"`）。
4. 在 `<fonts>` 中，查看第 3 个条目（索引 2）并检查 `<color rgb="000000FF"/>`（蓝色）或其他输入标记。

如果模板使用命名范围作为输入字段，请从 `xl/workbook.xml` 中读取它们：
```xml
<definedNames>
  <definedName name="InputGrowthRate">Assumptions!$B$5</definedName>
  <definedName name="InputDiscountRate">Assumptions!$B$6</definedName>
</definedNames>
```

直接填充目标单元格（`Assumptions!B5`、`Assumptions!B6`）。

### 6.4 模板填充规则

- 仅填充模板指定为输入的单元格。不要填充由公式驱动的单元格。
- 填充时不要应用新样式。模板的格式是可交付成果。
- 除非模板明确有"在此处追加"区域，否则不要在模板的数据区域内添加或删除行。
- 填充后，验证没有引入公式错误：某些模板具有输入验证公式，如果输入了错误的数据类型，会产生 `#VALUE!`。

---

## 7. 您绝对不能修改的文件

### 7.1 绝对禁止触碰列表

| 文件/位置 | 原因 |
|-----------------|------|
| `xl/vbaProject.bin` | 二进制 VBA 字节码。任何字节修改都会损坏宏项目。即使编辑一位也会导致宏无法加载。 |
| `xl/pivotCaches/pivotCacheDefinition*.xml` | 缓存定义将透视表绑定到其源数据。在不更新相应的 `pivotTable*.xml` 的情况下编辑它会损坏透视表。 |
| `xl/pivotTables/*.xml` | 透视表 XML 与缓存定义和内部状态紧密耦合，Excel 会在加载时重建这些。不要编辑。如果移动了行并且透视表的源范围现在指向错误的数据，请仅在缓存定义中更新 `<cacheSource>` 范围，并且仅在透视表中更新 `ref` 属性 — 没有其他更改。 |
| `xl/slicers/*.xml` | 切片器连接到特定的缓存 ID 和透视字段。破坏这些连接会静默损坏文件。 |
| `xl/connections.xml` | 外部数据连接。编辑会破坏实时数据刷新。 |
| `xl/externalLinks/` | 外部工作簿链接。不得修改其中的二进制 `.bin` 文件。 |

### 7.2 有条件安全的文件（仅更新特定属性）

| 文件 | 您可以更新的内容 | 不要触碰的内容 |
|------|--------------------|--------------------|
| `xl/charts/chartN.xml` | 行/列移动后的数据系列范围引用 (`<numRef><f>`) | 图表类型、格式、布局 |
| `xl/tables/tableN.xml` | 添加行后 `<table>` 上的 `ref` 属性 | 列定义、样式信息 |
| `xl/pivotCaches/pivotCacheDefinition*.xml` | 移动源数据后 `<cacheSource><worksheetSource>` 上的 `ref` 属性 | 所有其他内容 |

---

## 8. 每次编辑后的验证

永远不要跳过验证。即使公式中的一字符更改也可能导致级联错误。

```bash
# 打包
python3 SKILL_DIR/scripts/xlsx_pack.py /tmp/xlsx_work/ output.xlsx

# 静态公式验证（始终运行）
python3 SKILL_DIR/scripts/formula_check.py output.xlsx

# 动态验证（如果 LibreOffice 可用）
python3 SKILL_DIR/scripts/libreoffice_recalc.py output.xlsx /tmp/recalc.xlsx
python3 SKILL_DIR/scripts/formula_check.py /tmp/recalc.xlsx
```

如果 `formula_check.py` 报告任何错误：
1. 再次解压输出文件（它是打包版本）。
2. 在工作表 XML 中找到报告的单元格。
3. 修复 `<f>` 元素。
4. 重新打包并重新验证。

在 `formula_check.py` 报告零错误之前，不要交付文件。

---

## 9. 绝对规则摘要

| 规则 | 理由 |
|------|-----------|
| 永远不要对现有文件使用 openpyxl `load_workbook` + `save` | 往返会破坏透视表、VBA、迷你图、切片器 |
| 永远不要删除或重新排序 sharedStrings 中的现有 `<si>` 条目 | 会破坏引用该索引的每个单元格 |
| 永远不要删除或重新排序 `<cellXfs>` 中的现有 `<xf>` 条目 | 会破坏使用该样式索引的每个单元格 |
| 永远不要修改 `vbaProject.bin` | 二进制文件；任何更改都会损坏 VBA |
| 重命名工作表时永远不要更改 `sheetId` | 内部 ID 是稳定的；更改它会破坏关系 |
| 永远不要跳过编辑后验证 | 留下未检测到的损坏引用 |
| 永远不要编辑超出需要的更多 XML 节点 | 额外的更改可能引入细微的损坏 |
| 更改公式时将 `<v>` 清除为空字符串 | 防止过时的缓存值误导下游消费者 |
| 仅追加到 sharedStrings | 现有索引必须保持有效 |
| 仅追加到样式集合 | 现有样式索引必须保持有效 |
