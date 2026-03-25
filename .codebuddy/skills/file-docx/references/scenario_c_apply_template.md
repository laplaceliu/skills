# 场景 C：应用格式/模板

## 何时使用

在以下情况使用场景 C：
- 用户有现有文档并希望应用不同的视觉样式
- 用户想要重新品牌化文档（新字体、颜色、标题样式）
- 用户提供模板 DOCX 并希望将其外观应用到内容文档
- 用户希望在多个文档之间保持一致格式

**不要**在以下情况使用：用户想要编辑内容（→ 场景 B）或从零创建（→ 场景 A）。

---

## 工作流程

```
1. 分析源    → CLI: analyze source.docx      （列出样式、字体、结构）
2. 分析模板  → CLI: analyze template.docx     （列出样式、字体、结构）
3. 映射样式   → 创建映射计划（源样式 → 模板样式）
4. 应用模板   → CLI: apply-template source.docx --template template.docx --output result.docx
5. 验证 (XSD) → CLI: validate result.docx --xsd wml-subset.xsd
6. 把关检查   → CLI: validate result.docx --xsd business-rules.xsd   ← 必须通过
7. 差异验证   → CLI: diff source.docx result.docx --text-only   （内容必须相同）
```

---

## 从模板复制什么

| 部分 | 文件 | 描述 |
|------|------|-------------|
| 样式 | `word/styles.xml` | 所有样式定义（段落、字符、表格、编号） |
| 主题 | `word/theme/theme1.xml` | 配色方案、字体方案、格式方案 |
| 编号 | `word/numbering.xml` | 列表和编号定义 |
| 页眉 | `word/header*.xml` | 页眉内容和格式 |
| 页脚 | `word/footer*.xml` | 页脚内容和格式 |
| 节属性 | `w:sectPr` | 边距、页面大小、方向、栏 |

## 不复制什么

| 部分 | 原因 |
|------|------|
| 文档内容 | 段落、表格、图片保留自源文档 |
| 批注 | 属于源文档的审阅历史 |
| 修订标记 | 属于源文档的修订历史 |
| 自定义 XML 部分 | 应用程序特定数据，非视觉 |
| 文档属性 | 标题、作者、日期属于源文档 |
| 词汇表文档 | 模板的构建基块不传输 |

---

## 模板结构分析（**必需**）

在选择叠加或基础替换之前，您**必须**分析模板的内部结构。跳过这一步是失败的第一大原因。

### 步骤 1：计算模板段落并识别结构区域

运行 `$CLI analyze --input template.docx` 或手动检查：

```bash
# 快速结构扫描
scripts/docx_preview.sh template.docx
```

在模板中识别这些区域：
```
区域 A：前置部分（封面、声明、摘要、目录）
        → 这些从模板保留，绝不替换
区域 B：示例/占位正文内容（"第1章 XXX"、示例段落）
        → 这被替换为用户的实际内容
区域 C：后置部分（附录、致谢、空白页）
        → 这些从模板保留或删除
区域 D：最终 sectPr
        → 始终从模板保留
```

### 步骤 2：查找区域 B 边界（替换范围）

在模板的 document.xml 中搜索标记示例内容开始和结束的锚文本：

**开始锚点模式**（正文示例的第一个段落）：
- "第1章"、"第一章"、"Chapter 1"、"1 Introduction"、"绪论"
- 目录后第一个带有 Heading1 等效样式的段落

**结束锚点模式**（后置部分前的最后一个段落）：
- "参考文献"、"References"、"致谢"、"Acknowledgments"
- 附录或最终 sectPr 前的最后一个段落

```python
# 查找替换范围的伪代码
for i, element in enumerate(template_body_elements):
    text = get_text(element)
    style = get_style(element)
    if style in heading1_styles and ("第1章" in text or "Chapter 1" in text):
        replace_start = i
    if "参考文献" in text or "References" in text:
        replace_end = i
        break
```

**关键**：通过打印其中的内容验证范围：
```
模板元素 [0..replace_start-1]：前置部分（保留）
模板元素 [replace_start..replace_end]：示例内容（替换）
模板元素 [replace_end+1..end]：后置部分（保留）
```

如果找不到 replace_start 或 replace_end，**不要**继续。请用户识别替换边界。

### 步骤 3：决定叠加 vs 基础替换

现在您知道了结构：

| 观察 | 决定 |
|------|------|
| 模板有 ≤30 段落，无封面/目录 | **C-1：叠加**（纯样式模板） |
| 模板有 >100 段落，有封面/目录/示例章节 | **C-2：基础替换** |
| 模板段落数 ≈ 用户文档 | **C-1：叠加**（类似结构） |
| 模板段落数 >> 用户文档（例如 263 vs 134） | **C-2：基础替换** |

### 步骤 4：对于基础替换，执行替换

1. 加载模板作为基础（所有文件）
2. 使用 `list(body)` 提取用户内容元素 —— 不是 `findall('w:p')`（会遗漏表格）
3. 构建新正文：`template[0:replace_start] + cleaned_user_content + template[replace_end+1:]`
4. 将样式映射应用到每个段落
5. 清理直接格式（见下文规则）
6. 重建 document.xml，保留模板的命名空间声明
7. 合并关系（图片 + 超链接）
8. 使用模板作为 ZIP 基础写入输出

---

## 样式映射策略

当模板样式名称与源样式名称不同时，需要映射。**这一步是强制性的** —— 跳过它是模板应用中格式失败的第一大原因。

### 步骤 0：从两个文档提取 StyleIds（**必需**）

在任何模板应用之前，从两个文档提取并比较 styleIds：

```bash
# 从源文档提取所有 styleIds
$CLI analyze --input source.docx --styles-only
# 输出示例：
#   Heading1  (paragraph, basedOn: Normal)
#   Heading2  (paragraph, basedOn: Normal)
#   Normal    (paragraph)
#   ListBullet (paragraph, basedOn: Normal)

# 从模板提取所有 styleIds
$CLI analyze --input template.docx --styles-only
# 输出示例：
#   1         (paragraph, basedOn: a, name: "heading 1")
#   2         (paragraph, basedOn: a, name: "heading 2")
#   3         (paragraph, basedOn: a, name: "heading 3")
#   a         (paragraph, name: "Normal")
#   a0        (character, name: "Default Paragraph Font")
```

**关键区别**：`w:styleId` vs `w:name`：
```xml
<!-- styleId="1" 但 name="heading 1" -->
<w:style w:type="paragraph" w:styleId="1">
  <w:name w:val="heading 1"/>
  <w:basedOn w:val="a"/>
</w:style>
```

`w:styleId` 属性是 `<w:pStyle w:val="..."/>` 引用的内容。`w:name` 属性是人类可读的显示名称。**它们可能完全不同。** 许多 CJK 模板使用数字 styleIds（`1`、`2`、`3`、`a`、`a0`）而不是英文名称。

### 第一层：精确 StyleId 匹配
如果源使用 `Heading1` 且模板将 `Heading1` 定义为 styleId，直接映射。无需操作。

### 第二层：基于名称匹配
如果没有精确的 styleId 匹配，尝试按 `w:name` 属性匹配：
- 源 `Heading1`（name="heading 1"）→ 模板 styleId `1`（name="heading 1"）
- 匹配对名称值不区分大小写

在同一类型内，还尝试按以下匹配：
- 内置样式 ID（Word 的内部 ID，例如 heading 1 = 内置 ID 1）
- 样式类型（paragraph → paragraph，character → character，table → table）

### 第三层：手动映射
对于重命名或自定义样式，提供显式映射：

```json
{
  "styleMap": {
    "Heading1": "1",
    "Heading2": "2",
    "Heading3": "3",
    "Heading4": "3",
    "Normal": "a",
    "BodyText": "a",
    "ListBullet": "a",
    "CompanyName": "Title",
    "OldTableStyle": "TableGrid"
  }
}
```

### 常见非标准 StyleId 模式

| 模板来源 | StyleId 模式 | 示例 |
|----------------|-----------------|---------|
| 中文 Word（默认） | 数字/字母 | `1`、`2`、`3`、`a`、`a0` |
| 英文 Word（默认） | 英文名称 | `Heading1`、`Normal`、`Title` |
| Google Docs 导出 | 带前缀 | `Subtitle`、`NormalWeb` |
| WPS Office | 混合 | `1`、`Heading1`、自定义名称 |
| 学术模板 | 自定义 | `ThesisHeading1`、`ThesisBody` |

### 构建映射表

遵循以下算法：

1. **列出 `document.xml` 中实际使用的源 styleIds**（不是所有在 `styles.xml` 中定义的）：
   ```python
   # 伪代码：在源 document.xml 中查找所有唯一的 pStyle 值
   used_styles = set()
   for p in body.iter('w:p'):
       pStyle = p.find('w:pPr/w:pStyle')
       if pStyle is not None:
           used_styles.add(pStyle.get('val'))
   ```

2. **为每个使用的样式**，在模板中找到最佳匹配：
   - 首先尝试：精确的 styleId 匹配
   - 其次尝试：按 `w:name` 值匹配（不区分大小写）
   - 第三尝试：按样式用途匹配（任何标题 → 模板的标题样式）
   - 回退：映射到模板的默认段落样式（通常是 `Normal` 或 `a`）

3. **验证映射** —— 每个源 styleId 必须映射到现有的模板 styleId：
   ```
   ✓ Heading1 → 1（名称匹配："heading 1"）
   ✓ Heading2 → 2（名称匹配："heading 2"）
   ✓ Normal   → a（名称匹配："Normal"）
   ✗ CustomCallout → ???（未找到匹配，将回退到 'a'）
   ```

4. **复制内容时应用映射** —— 更新每个 `<w:pStyle w:val="..."/>`：
   ```xml
   <!-- 源 -->
   <w:pPr><w:pStyle w:val="Heading1"/></w:pPr>
   <!-- 映射后 -->
   <w:pPr><w:pStyle w:val="1"/></w:pPr>
   ```

### 未映射样式

源文档中在模板中没有匹配的样式将记录为警告：
```
警告：样式 'CustomCallout' 在模板中没有映射。内容将回退到 'a'（Normal）。
```

内容被保留；只有样式引用更新为模板的默认段落样式。

### C-2 基础替换：额外的 StyleId 考虑

当使用模板作为基础文档（C-2 策略）时，模板的 `styles.xml` 已经就位。您必须：

1. **绝不复制源 `styles.xml`** —— 模板的样式是权威
2. **将每个内容段落的 pStyle 映射到模板的 styleId** 然后插入
3. **有选择地去除直接格式**（见下文详细规则）—— 让模板样式控制外观
4. **验证表格样式** —— 如果源表格使用 `TableGrid` 但模板将其定义为 `a3` 或类似，也要重新映射 `<w:tblStyle>`
5. **检查字符样式** —— run 内的 `rPr` 可能引用字符样式如 `Hyperlink` 或 `Strong`，它们在模板中有不同的 ID

### 直接格式清理规则（详细）

从源到模板复制内容时，对每个段落和 run 应用这些规则：

**从 `<w:rPr>` 中删除：**
- `<w:rFonts w:ascii="..." w:hAnsi="..."/>` —— 拉丁字体覆盖（**例外**：保留 `w:eastAsia`）
- `<w:sz>`、`<w:szCs>` —— 字体大小（让样式控制）
- `<w:color>` —— 文本颜色
- `<w:highlight>` —— 高亮颜色
- `<w:shd>` —— 底纹
- `<w:b>`、`<w:i>` —— 粗体/斜体，除非源样式需要（例如强调）
- `<w:u>` —— 下划线
- `<w:spacing>` —— 字符间距

**在 `<w:rPr>` 中保留：**
- `<w:rFonts w:eastAsia="宋体"/>` —— CJK 字体声明（**必须**保留，否则中文文本渲染错误）
- `<w:rFonts w:eastAsia="华文中宋"/>` —— 同样原因
- `<w:drawing>` 内的任何内容 —— 图片引用（通过 rId 重新映射单独处理）

**从 `<w:pPr>` 中删除：**
- `<w:pBdr>` —— 段落边框
- `<w:shd>` —— 段落底纹
- `<w:spacing>` —— 行/段落间距（让样式控制）
- `<w:jc>` —— 对齐（让样式控制）
- `<w:tabs>` —— 自定义制表位
- pPr 内的 `<w:rPr>` —— 段落标记的默认 run 格式

**在 `<w:pPr>` 中保留：**
- `<w:pStyle>` —— 样式引用（映射到模板的 styleId 后）
- `<w:sectPr>` —— 节属性（如果故意插入分节符）
- `<w:numPr>` —— 编号引用（将 numId 映射到模板的编号后）

**表格单元格（`<w:tc>`）：**
对每个单元格内的每个段落应用相同的 rPr/pPr 清理。还要：
- 保留 `<w:tcPr>` 结构属性（列跨、行跨、宽度）
- 删除 `<w:tcPr><w:shd>`（单元格底纹 —— 让表格样式控制）

---

## 关系 ID 重新映射

将部分（页眉、页脚、图片）从模板复制到源包时，关系 ID（`r:id`）可能冲突。

**问题**：
- 源有 `rId7` → `image1.png`
- 模板有 `rId7` → `header1.xml`
- 复制模板的 `rId7` 会覆盖源的图片引用

**解决方案**：
1. 扫描源的 `document.xml.rels` 中的所有现有 `rId` 值
2. 找到最大数字 ID（例如 `rId12`）
3. 从 `rId13` 开始重新映射所有模板关系 ID
4. 更新复制部分中的所有引用以使用新 ID

```xml
<!-- 模板原始 -->
<Relationship Id="rId1" Type="...header" Target="header1.xml" />

<!-- 重新映射到源包后 -->
<Relationship Id="rId13" Type="...header" Target="header1.xml" />

<!-- 更新 sectPr 引用 -->
<w:headerReference w:type="default" r:id="rId13" />
```

### 超链接关系合并

当源文档包含外部超链接（例如参考文献或脚注中的 URL）时，这些作为关系存储在 `word/_rels/document.xml.rels` 中：

```xml
<Relationship Id="rId15" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink"
              Target="https://example.com/paper" TargetMode="External"/>
```

document.xml 中的相应文本引用此 rId：
```xml
<w:hyperlink r:id="rId15">
  <w:r><w:t>https://example.com/paper</w:t></w:r>
</w:hyperlink>
```

**合并步骤：**
1. 扫描源 document.xml 中的所有 `<w:hyperlink r:id="...">` 元素
2. 对于每个，在源的关系文件中找到相应的关系
3. 检查模板是否已有相同目标 URL 的关系
   - 如果有：重用现有 rId，更新超链接引用
   - 如果没有：分配新 rId（从模板的最大 rId + 1 开始），将关系添加到模板的关系，更新超链接引用
4. 还要检查脚注（`word/_rels/footnotes.xml.rels`）和尾注中使用的超链接关系

**常见错误：** 复制超链接段落而不合并关系 → 超链接静默失效（在 Word 中点击无反应）。

---

## XSD 把关检查

### 是什么

模板应用后，输出文档**必须**通过 `business-rules.xsd` 验证。这是**硬性关口** —— 如果失败，文档**不可交付**。

### business-rules.xsd 检查什么

| 规则 | 验证内容 |
|------|----------|
| 模板样式存在 | 内容段落引用的所有样式都在 `styles.xml` 中定义 |
| 边距匹配 | 页面边距匹配模板规范 |
| 字体正确 | `w:docDefaults` 字体匹配模板的字体方案 |
| 标题层次 | 标题级别是连续的（没有 H1 → H3 跳过 H2） |
| 必需样式存在 | `Normal`、`Heading1`-`Heading3`、`TableGrid` 存在 |
| 页面大小 | 匹配模板声明的页面大小 |

### 处理失败

```
把关检查失败：
  - 第 14 段引用的样式 'CustomStyle1' 未在 styles.xml 中定义
  - 边距 w:left=1080 不符合模板要求 1440
```

修复每个失败：
1. **缺失样式**：将样式定义添加到 `styles.xml`，或将段落重新映射到现有样式
2. **边距不匹配**：更新 `w:sectPr` 边距以匹配模板
3. **字体不匹配**：更新 `w:docDefaults` 以匹配模板字体方案
4. **标题层次空缺**：插入中间标题级别或调整现有级别

每次修复后重新验证，直到把关检查通过。

---

## 常见陷阱

### 1. 孤立编号引用

**问题**：源文档在列表段落中使用 `w:numId="5"`，但用模板的 `numbering.xml` 替换后，编号 ID 5 不存在。

**症状**：列表显示为普通段落（无项目符号/编号）。

**修复**：
- 将源编号 ID 映射到模板编号 ID
- 更新文档内容中的所有 `w:numId` 引用
- 或将源编号定义合并到模板的 `numbering.xml`

### 2. 缺失主题颜色

**问题**：源文档的样式引用主题颜色（`w:themeColor="accent1"`），这些颜色在模板主题中有不同的值。

**症状**：颜色意外更改（通常可接受 —— 这正是重新主题化的目的）。但如果样式同时使用 `w:color` 和 `w:themeColor`，主题颜色在 Word 中胜出。

**修复**：检查颜色更改。如果必须保留特定颜色，使用不带 `w:themeColor` 的显式 `w:val`。

### 3. 节属性冲突

**问题**：源文档有多个节（例如纵向 + 横向页面），但模板假设单节。

**症状**：所有节获得相同的边距/方向，破坏横向页面。

**修复**：
- 只将模板节属性应用到 `w:body` 中的最终 `w:sectPr`
- 保留源的中间 `w:sectPr` 元素（在 `w:pPr` 内）
- 或将模板属性应用到所有节但保留方向覆盖

### 4. 嵌入字体冲突

**问题**：模板指定目标系统上没有的字体。

**修复**：在 DOCX 中嵌入字体（`word/fonts/`）或使用网络安全替代：
- Calibri → 在 Windows/Mac/Office Online 上可用
- Arial → 通用回退
- Times New Roman → 通用衬线回退

### 5. 样式继承中断

**问题**：模板有基于 `Normal` 的 `Heading1`，但应用模板后，`Normal` 有不同的属性，将不需要的更改级联到标题。

**修复**：验证所有关键样式的 `w:basedOn` 链。确保基础样式也正确从模板传输。

---

## 验证检查清单

模板应用后，验证：

1. **内容保留** —— 文本差异显示零内容更改
2. **把关通过** —— `business-rules.xsd` 验证成功
3. **样式应用** —— 标题、正文、表格使用模板格式
4. **图片完整** —— 所有图片正确渲染（关系 ID 有效）
5. **列表工作** —— 编号和项目符号列表正确显示
6. **页眉/页脚** —— 模板页眉/页脚出现在所有页面上
7. **页面布局** —— 边距、页面大小、方向匹配模板
8. **无损坏** —— 文件在 Word 中打开无错误
