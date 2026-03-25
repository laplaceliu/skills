# 场景 B：在现有 DOCX 中编辑/填充内容

## 核心原则

**"首先，不要造成伤害。"** 编辑现有文档时，最小化更改。只触碰需要更改的部分。保留所有与编辑无直接关系的格式、样式、关系和结构。

---

## 何时使用

- 替换占位符文本（`{{name}}`、`$DATE$`、`[占位符]`）
- 更新特定段落或表格单元格
- 填写表单字段
- 在已知位置添加或删除段落
- 为审阅工作流插入修订标记

**不要**在以下情况使用：用户想要更改整个文档的外观/样式（→ 场景 C）或从零创建（→ 场景 A）。

---

## 工作流程

```
1. 预览   → CLI: analyze <input.docx>
2. 分析   → 理解结构：节、样式、标题、表格
3. 识别   → 定位确切的编辑目标（段落索引、表格索引、占位符文本）
4. 编辑   → 通过 CLI 或直接 XML 应用精确更改
5. 验证   → CLI: validate <output.docx>
6. 差异   → 比较前后以验证只做了预期更改
```

---

## 何时使用 API vs 直接 XML

### 在以下情况使用 CLI 编辑命令：
- 替换占位符文本（例如 `{{fieldName}}` → 实际值）
- 从 JSON 填充表格数据
- 更新文档属性（标题、作者）
- 简单文本插入或删除

### 在以下情况使用直接 XML 操作：
- 文本跨越具有不同格式的多个 run（run 边界问题）
- 添加复杂结构（嵌套表格、多图片布局）
- 操作修订标记
- 修改页眉/页脚内容
- 调整节属性

---

## 占位符模式

CLI 原生支持 `{{fieldName}}` 占位符：

```bash
# 从 JSON 映射替换所有 {{占位符}}
dotnet run ... edit input.docx --fill-placeholders data.json --output filled.docx
```

其中 `data.json`：
```json
{
  "companyName": "Acme Corp",
  "date": "2026年3月21日",
  "amount": "¥15,000.00",
  "recipientName": "简·史密斯"
}
```

其他占位符格式（`$FIELD$`、`[占位符]`）需要文本替换：
```bash
dotnet run ... edit input.docx --replace "$DATE$" "2026年3月21日" --output updated.docx
```

---

## 文本替换策略

### 简单替换

当整个搜索文本在单个 `w:r`（run）内时：

```xml
<!-- 替换前 -->
<w:r>
  <w:rPr><w:b /></w:rPr>
  <w:t>{{companyName}}</w:t>
</w:r>

<!-- 替换后 —— 格式保留 -->
<w:r>
  <w:rPr><w:b /></w:rPr>
  <w:t>Acme Corp</w:t>
</w:r>
```

直接替换。run 的 `w:rPr` 保持不变。

### 复杂替换（分割 Run）

当搜索文本跨越多个 run 时（当 Word 应用拼写检查或格式时常见）：

```xml
<!-- "{{companyName}}" 分割成 3 个 run -->
<w:r><w:rPr><w:b /></w:rPr><w:t>{{company</w:t></w:r>
<w:r><w:rPr><w:b /><w:i /></w:rPr><w:t>Na</w:t></w:r>
<w:r><w:rPr><w:b /></w:rPr><w:t>me}}</w:t></w:r>
```

策略：
1. 跨 run 连接文本以找到匹配
2. 将替换文本放在**第一个** run 中（保留其 `w:rPr`）
3. 从后续 run 中删除文本（如果为空则删除整个 run）

```xml
<!-- 替换后 -->
<w:r><w:rPr><w:b /></w:rPr><w:t>Acme Corp</w:t></w:r>
```

**规则**：始终保留匹配中第一个 run 的格式。

---

## 表格编辑

### 按索引

表格在文档顺序中是 0 索引的：

```bash
dotnet run ... edit input.docx --table-index 0 --table-data data.json --output updated.docx
```

### 按表头匹配

通过表头行内容查找表格：

```bash
dotnet run ... edit input.docx --table-match "姓名,金额,日期" --table-data data.json
```

### 表格数据 JSON 格式

```json
{
  "rows": [
    ["爱丽丝·约翰逊", "¥5,000", "2026-03-15"],
    ["鲍勃·史密斯", "¥3,200", "2026-03-18"]
  ],
  "appendRows": true
}
```

- `appendRows: true` —— 在现有数据后添加行
- `appendRows: false`（默认）—— 替换所有数据行（保留表头行）

### 直接 XML 表格编辑

要修改特定单元格，通过行/列索引定位：

```xml
<!-- 第 2 行（0 索引），第 1 列 -->
<w:tr>  <!-- tr[2] -->
  <w:tc>...</w:tc>
  <w:tc>  <!-- tc[1] —— 目标单元格 -->
    <w:p>
      <w:r><w:t>旧值</w:t></w:r>
    </w:p>
  </w:tc>
</w:tr>
```

替换 `w:t` 内容。**不要**修改 `w:tcPr`（单元格属性）或 `w:tblPr`（表格属性）。

---

## 修订标记指南

### 何时添加修订标记
- 用户明确要求修订跟踪
- 文档已启用跟踪（设置中的 `w:trackChanges`）
- 协作审阅工作流

### 何时**不**添加修订标记
- 表单填写 / 占位符替换（这些是"完成"文档，不是"修订"它）
- 用户想要干净结果的直接编辑
- 批量数据填充操作

### 添加修订标记

完整 XML 示例参见 `references/track_changes_guide.md`。

快速参考 —— 带跟踪的文本插入：
```xml
<w:ins w:id="1" w:author="MiniMaxAI" w:date="2026-03-21T10:00:00Z">
  <w:r>
    <w:t>此处为新文本</w:t>
  </w:r>
</w:ins>
```

带跟踪的文本删除：
```xml
<w:del w:id="2" w:author="MiniMaxAI" w:date="2026-03-21T10:00:00Z">
  <w:r>
    <w:delText>已删除文本</w:delText>  <!-- 必须使用 delText，不是 t -->
  </w:r>
</w:del>
```

---

## 常见陷阱

### 1. 破坏 Run 边界

**问题**：通过天真地修改单个 run 来替换跨越 run 的文本会破坏内联格式。

**修复**：连接 run 文本，找到匹配边界，合并到第一个 run，删除已消耗的 run。

### 2. 超链接内容

**问题**：替换 `w:hyperlink` 元素内的文本而不保留超链接包装器会移除链接。

```xml
<w:hyperlink r:id="rId5">
  <w:r>
    <w:rPr><w:rStyle w:val="Hyperlink" /></w:rPr>
    <w:t>点击此处</w:t>  <!-- 只替换此文本 -->
  </w:r>
</w:hyperlink>
```

**修复**：只修改超链接 run 内的 `w:t`。绝不删除或替换 `w:hyperlink` 元素本身。

### 3. 修订标记上下文

**问题**：替换 `w:ins` 或 `w:del` 元素内的文本而不理解修订上下文会创建无效标记。

**修复**：如果目标文本在修订标记内，要么：
- 在修订上下文内替换（保留 `w:ins`/`w:del` 包装器）
- 或删除旧修订并创建新修订

### 4. 样式保留

**问题**：添加没有指定样式的新段落会导致它们继承 `Normal`，这可能与周围上下文不匹配。

**修复**：插入段落时，从同类型的相邻段落复制 `w:pStyle`。

### 5. 编号连续性

**问题**：插入新列表项会破坏编号序列。

**修复**：确保新段落与相邻列表项具有相同的 `w:numId` 和 `w:ilvl`。如果要继续序列，设置 `w:numPr` 以匹配。

### 6. XML 特殊字符

**问题**：用户内容包含 `&`、`<`、`>`、`"`、`'` —— 这些必须在 XML 中转义。

**修复**：在插入 `w:t` 元素之前始终对用户提供的内容进行 XML 转义：
- `&` → `&amp;`
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&quot;`
- `'` → `&apos;`

### 7. 空白保留

**问题**：`w:t` 中的前导/尾随空格会被 XML 解析器剥离。

**修复**：添加 `xml:space="preserve"` 属性：
```xml
<w:t xml:space="preserve"> 带有前导空格的文本</w:t>
```

---

## 差异验证

编辑后，始终比较前后状态：

```bash
# 结构差异 —— 只显示更改的元素
dotnet run ... diff original.docx modified.docx

# 纯文本差异 —— 显示内容更改
dotnet run ... diff original.docx modified.docx --text-only
```

验证：
- 只有预期的文本更改
- 没有修改样式
- 没有意外添加/删除关系
- 表格结构完整（除非有意更改，否则行/列数量相同）
- 图片和其他媒体未更改
