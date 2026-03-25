---
name: minimax-docx
license: MIT
metadata:
  version: "1.0.0"
  category: document-processing
  author: MiniMaxAI
  sources:
    - "ECMA-376 Office Open XML 文件格式"
    - "GB/T 9704-2012 党政机关公文格式标准"
    - "IEEE / ACM / APA / MLA / Chicago / Turabian 样式指南"
    - "Springer LNCS / Nature / HBR 文档模板"
description: >
  使用 OpenXML SDK (.NET) 进行专业的 DOCX 文档创建、编辑和格式化。
  包含三个流程：(A) 从零创建新文档，(B) 在现有文档中填充/编辑内容，(C) 应用模板格式并进行 XSD 验证把关。
  当用户需要生成、修改或格式化 Word 文档时，必须使用该技能 —— 包括用户说"写一份报告"、"起草提案"、"制作合同"、
  "填写此表单"、"重新格式化以匹配此模板"，或任何最终输出为 .docx 文件的任务。即使用户没有明确提到"docx"，
  如果任务暗示需要可打印的/正式文档，也要使用该技能。
triggers:
  - Word
  - docx
  - document
  - 文档
  - Word文档
  - 报告
  - 合同
  - 公文
  - 排版
  - 套模板
---

# minimax-docx

通过 CLI 工具或直接基于 OpenXML SDK (.NET) 的 C# 脚本创建、编辑和格式化 DOCX 文档。

## 环境配置

**首次使用：** 运行 `bash scripts/setup.sh`（Windows 上使用 `powershell scripts/setup.ps1`，`--minimal` 跳过可选依赖）。

**会话中首次操作：** 运行 `scripts/env_check.sh` —— 如果显示 `NOT READY` 请勿继续。（同一会话的后续操作可跳过。）

## 快速开始：直接 C# 路径

当任务需要进行结构性文档操作（自定义样式、复杂表格、多节布局、页眉/页脚、目录、图片）时，直接使用 C# 编写，而不是纠结于 CLI 的限制。使用以下脚手架：

```csharp
// 文件: scripts/dotnet/task.csx（或 Console 项目中的新 .cs 文件）
// dotnet run --project scripts/dotnet/MiniMaxAIDocx.Cli -- run-script task.csx
#r "nuget: DocumentFormat.OpenXml, 3.2.0"

using DocumentFormat.OpenXml;
using DocumentFormat.OpenXml.Packaging;
using DocumentFormat.OpenXml.Wordprocessing;

using var doc = WordprocessingDocument.Create("output.docx", WordprocessingDocumentType.Document);
var mainPart = doc.AddMainDocumentPart();
mainPart.Document = new Document(new Body());

// --- 在此处编写您的逻辑 ---
// 首先阅读相关的 Samples/*.cs 文件获取经过测试的模式。
// 参见下方 References 部分中的 Samples 表格。
```

**在编写任何 C# 代码之前，请先阅读相关的 `Samples/*.cs` 文件** —— 它们包含可编译的、SDK 版本已验证的模式。References 部分的 Samples 表格将主题映射到文件。

## CLI 简写

以下所有 CLI 命令使用 `$CLI` 作为简写：
```bash
dotnet run --project scripts/dotnet/MiniMaxAIDocx.Cli --
```

## 流程路由

通过检查用户是否有输入的 .docx 文件来进行路由：

```
用户任务
├─ 无输入文件 → 流程 A：创建
│   信号词："写"、"创建"、"起草"、"生成"、"新"、"制作报告/提案/备忘录"
│   → 阅读 references/scenario_a_create.md
│
└─ 有输入 .docx
    ├─ 替换/填充/修改内容 → 流程 B：填充-编辑
    │   信号词："填写"、"替换"、"更新"、"更改文本"、"添加章节"、"编辑"
    │   → 阅读 references/scenario_b_edit_content.md
    │
    └─ 重新格式化/应用样式/模板 → 流程 C：格式化-应用
        信号词："重新格式化"、"应用模板"、"更改样式"、"匹配此格式"、"套模板"、"排版"
        ├─ 模板是纯样式（无内容） → C-1：叠加（将样式应用到源文档）
        └─ 模板有结构（封面/目录/示例章节） → C-2：基础-替换
            （使用模板作为基础，将示例内容替换为用户内容）
        → 阅读 references/scenario_c_apply_template.md
```

如果请求跨越多个流程，按顺序运行它们（例如，先创建然后格式化-应用）。

## 预处理

如需转换 `.doc` → `.docx`：`scripts/doc_to_docx.sh input.doc output_dir/`

编辑前预览（避免阅读原始 XML）：`scripts/docx_preview.sh document.docx`

编辑场景的结构分析：`$CLI analyze --input document.docx`

## 场景 A：创建

首先阅读 `references/scenario_a_create.md`、`references/typography_guide.md` 和 `references/design_principles.md`。从 `Samples/AestheticRecipeSamples.cs` 中选择与文档类型匹配的美观方案 —— 不要自行创造格式化值。对于 CJK 文档，还需阅读 `references/cjk_typography.md`。

**选择您的路径：**
- **简单**（纯文本，最少格式）：使用 CLI —— `$CLI create --type report --output out.docx --config content.json`
- **结构性**（自定义样式、多节、目录、图片、复杂表格）：直接使用 C# 编写。先阅读相关的 `Samples/*.cs`。

CLI 选项：`--type`（report|letter|memo|academic）、`--title`、`--author`、`--page-size`（letter|a4|legal|a3）、`--margins`（standard|narrow|wide）、`--header`、`--footer`、`--page-numbers`、`--toc`、`--content-json`。

然后运行 **验证流程**（见下文）。

## 场景 B：编辑 / 填充

首先阅读 `references/scenario_b_edit_content.md`。预览 → 分析 → 编辑 → 验证。

**选择您的路径：**
- **简单**（文本替换、占位符填充）：使用 CLI 子命令。
- **结构性**（添加/重组章节、修改样式、操作表格、插入图片）：直接使用 C# 编写。阅读 `references/openxml_element_order.md` 和相关的 `Samples/*.cs`。

可用的 CLI 编辑子命令：
- `replace-text --find "X" --replace "Y"`
- `fill-placeholders --data '{"key":"value"}'`
- `fill-table --data table.json`
- `insert-section`、`remove-section`、`update-header-footer`

```bash
$CLI edit replace-text --input in.docx --output out.docx --find "OLD" --replace "NEW"
$CLI edit fill-placeholders --input in.docx --output out.docx --data '{"name":"John"}'
```

然后运行 **验证流程**。同时运行 diff 以验证最小更改：
```bash
$CLI diff --before in.docx --after out.docx
```

## 场景 C：应用模板

首先阅读 `references/scenario_c_apply_template.md`。预览并分析源文档和模板。

```bash
$CLI apply-template --input source.docx --template template.docx --output out.docx
```

对于复杂的模板操作（多模板合并、每节页眉/页脚、样式合并），直接使用 C# 编写 —— 参见下方关键规则中的必需模式。

运行 **验证流程**，然后运行 **硬把关检查**：
```bash
$CLI validate --input out.docx --gate-check assets/xsd/business-rules.xsd
```
把关检查是 **硬性要求**。未通过前不要交付。如果失败：诊断、修复、重新运行。

同时 diff 以验证内容保留：`$CLI diff --before source.docx --after out.docx`

## 验证流程

每次写入操作后运行。对于场景 C，完整流程是 **强制性的**；对于 A/B 是 **推荐的**（仅在操作非常简单时可跳过）。

```bash
$CLI merge-runs --input doc.docx                                    # 1. 合并连续 run
$CLI validate --input doc.docx --xsd assets/xsd/wml-subset.xsd     # 2. XSD 结构
$CLI validate --input doc.docx --business                           # 3. 业务规则
```

如果 XSD 失败，自动修复并重试：
```bash
$CLI fix-order --input doc.docx
$CLI validate --input doc.docx --xsd assets/xsd/wml-subset.xsd
```

如果 XSD 仍然失败，回退到业务规则 + 预览：
```bash
$CLI validate --input doc.docx --business
scripts/docx_preview.sh doc.docx
# 验证：字体污染=0，表格数量正确，图片数量正确，sectPr 数量正确
```

最终预览：`scripts/docx_preview.sh doc.docx`

## 关键规则

这些规则可防止文件损坏 —— OpenXML 对元素顺序要求严格。

**元素顺序**（属性始终在前）：

| 父元素 | 顺序 |
|--------|------|
| `w:p`  | `pPr` → run |
| `w:r`  | `rPr` → `t`/`br`/`tab` |
| `w:tbl`| `tblPr` → `tblGrid` → `tr` |
| `w:tr` | `trPr` → `tc` |
| `w:tc` | `tcPr` → `p`（至少 1 个 `<w:p/>`） |
| `w:body`| 块内容 → `sectPr`（最后一个子元素） |

**直接格式污染：** 从源文档复制内容时，内联 `rPr`（字体、颜色）和 `pPr`（边框、底纹、间距）会覆盖模板样式。始终去除直接格式 —— 只保留 `pStyle` 引用和 `t` 文本。也要清理表格（包括单元格内的 `pPr/rPr`）。

**修订标记：** `<w:del>` 使用 `<w:delText>`，绝不使用 `<w:t>`。`<w:ins>` 使用 `<w:t>`，绝不使用 `<w:delText>`。

**字体大小：** `w:sz` = 磅值 × 2（12pt → `sz="24"`）。边距/间距使用 DXA（1 英寸 = 1440，1cm ≈ 567）。

**标题样式必须有 OutlineLevel：** 定义标题样式（Heading1、ThesisH1 等）时，始终在 `StyleParagraphProperties` 中包含 `new OutlineLevel { Val = N }`（H1→0，H2→1，H3→2）。没有此项，Word 会将它们视为普通样式文本 —— 目录和导航窗格将无法工作。

**多模板合并：** 当给定多个模板文件（字体、标题、分页）时，**首先**阅读 `references/scenario_c_apply_template.md` 中的"多模板合并"部分。关键规则：
- 将所有模板的样式合并到一个 styles.xml 中。结构（章节/分页）来自分页模板。
- 每个内容段落必须**只出现一次** —— 插入分节符时不要重复。
- **绝不**插入空/空白段落作为填充或分节符。输出段落数量必须等于输入。使用分节符属性（`w:sectPr` 在 `w:pPr` 内）和样式间距（`w:spacing` 前/后）进行视觉分隔。
- 在每个章节标题前插入 oddPage 分节符，而不仅仅是第一个。即使章节有双栏内容，也必须以 oddPage 开头；在标题后使用第二个 continuous 分节符进行栏切换。
- 双栏章节需要**三个**分节符：(1) 前一段落 pPr 中的 oddPage，(2) 章节**标题** pPr 中的 continuous+cols=2，(3) 最后正文段落 pPr 中的 continuous+cols=1 以恢复。
- 为**每个**节复制 `titlePg` 设置。摘要和目录节通常需要 `titlePg=true`。

**多节页眉/页脚：** 具有 10+ 节的模板（如中文论文）每节有不同的页眉/页脚（罗马数字与阿拉伯数字页码，不同区域的页眉文本）。规则：
- 使用 C-2 基础替换：将**模板**复制为输出基础，然后替换正文内容。这会自动保留所有节、页眉、页脚和 titlePg 设置。
- **绝不**从头重新创建页眉/页脚 —— 逐字节复制模板页眉/页脚 XML。
- **绝不**添加模板页眉 XML 中不存在的格式（边框、对齐、字体大小）。
- 非封面节必须有页眉/页脚 XML 文件（至少空页眉 + 页码页脚）。
- 参见 `references/scenario_c_apply_template.md` 中的"多节页眉/页脚传输"部分。

## 参考资料

按需加载 —— 不要一次性全部加载。选择最相关的文件。

**下面的 C# 示例和设计参考资料是项目的知识库（"百科全书"）。** 编写 OpenXML 代码时，**始终**先阅读相关的示例文件 —— 它包含可编译的、SDK 版本已验证的模式，可防止常见错误。进行美观决策时，阅读设计原则和方案文件 —— 它们编码了来自权威来源（IEEE、ACM、APA、Nature 等）的经过测试的和谐参数集，而不是猜测。

### 场景指南（每个流程首先阅读）

| 文件 | 何时阅读 |
|------|----------|
| `references/scenario_a_create.md` | 流程 A：从零创建 |
| `references/scenario_b_edit_content.md` | 流程 B：编辑现有内容 |
| `references/scenario_c_apply_template.md` | 流程 C：应用模板格式 |

### C# 代码示例（可编译，大量注释 —— 编写代码时阅读）

| 文件 | 主题 |
|------|------|
| `Samples/DocumentCreationSamples.cs` | 文档生命周期：创建、打开、保存、流、文档默认值、设置、属性、页面设置、多节 |
| `Samples/StyleSystemSamples.cs` | 样式：Normal/Heading 链、字符/表格/列表样式、DocDefaults、latentStyles、CJK 公文、APA 第7版、导入、解析继承 |
| `Samples/CharacterFormattingSamples.cs` | RunProperties：字体、大小、粗体/斜体、所有下划线、颜色、高亮、删除线、下标/上标、大小写、间距、底纹、边框、着重号 |
| `Samples/ParagraphFormattingSamples.cs` | ParagraphProperties：对齐、缩进、行/段间距、保持/孤行控制、大纲级别、边框、制表位、编号、双向文本、框架 |
| `Samples/TableSamples.cs` | 表格：边框、网格、单元格属性、边距、行高、标题行重复、合并（水平+垂直）、嵌套、浮动、三线表、斑马纹 |
| `Samples/HeaderFooterSamples.cs` | 页眉/页脚：页码、"第 X 页，共 Y 页"、首页/偶数/奇数页、Logo 图片、表格布局、公文 "-X-"、每节不同 |
| `Samples/ImageSamples.cs` | 图片：内联、浮动、文字环绕、边框、替代文本、在页眉/表格中、替换、SVG 回退、尺寸计算 |
| `Samples/ListAndNumberingSamples.cs` | 编号：项目符号、多级十进制、自定义符号、大纲→标题、法律编号、中文 一/（一）/1./(1)、重新开始/继续 |
| `Samples/FieldAndTocSamples.cs` | 域：目录、SimpleField 与复杂域、DATE/PAGE/REF/SEQ/MERGEFIELD/IF/STYLEREF、目录样式 |
| `Samples/FootnoteAndCommentSamples.cs` | 脚注、尾注、批注（4文件系统）、书签、超链接（内部+外部） |
| `Samples/TrackChangesSamples.cs` | 修订：插入（w:t）、删除（w:delText!）、格式更改、接受/拒绝所有、移动跟踪 |
| `Samples/AestheticRecipeSamples.cs` | 来自权威来源的 13 种美观方案：ModernCorporate、AcademicThesis、ExecutiveBrief、ChineseGovernment (GB/T 9704)、MinimalModern、IEEE Conference、ACM sigconf、APA 7th、MLA 9th、Chicago/Turabian、Springer LNCS、Nature、HBR —— 每个都包含官方样式指南的精确值 |

注意：`Samples/` 路径相对于 `scripts/dotnet/MiniMaxAIDocx.Core/`。

### Markdown 参考资料（需要规范或设计规则时阅读）

| 文件 | 何时阅读 |
|------|----------|
| `references/openxml_element_order.md` | XML 元素排序规则（防止损坏） |
| `references/openxml_units.md` | 单位换算：DXA、EMU、半点、八分之一点 |
| `references/openxml_encyclopedia_part1.md` | 详细的 C# 百科全书：文档创建、样式、字符和段落格式化 |
| `references/openxml_encyclopedia_part2.md` | 详细的 C# 百科全书：页面设置、表格、页眉/页脚、节、文档属性 |
| `references/openxml_encyclopedia_part3.md` | 详细的 C# 百科全书：目录、脚注、域、修订跟踪、批注、图片、数学公式、编号、保护 |
| `references/typography_guide.md` | 字体搭配、大小、间距、页面布局、表格设计、配色方案 |
| `references/cjk_typography.md` | CJK 字体、字号、RunFonts 映射、GB/T 9704 公文标准 |
| `references/cjk_university_template_guide.md` | 中国大学论文模板：数字 styleIds（1/2/3 vs Heading1）、文档区域结构（封面→摘要→目录→正文→参考文献）、字体期望、常见错误 |
| `references/design_principles.md` | **美观基础**：6 个设计原则（留白、对比/比例、接近、对齐、重复、层次）—— 教授 WHY，而不仅仅是 WHAT |
| `references/design_good_bad_examples.md` | **好与坏的对比**：10 类排版错误，包含 OpenXML 值、ASCII 示意图和修复方法 |
| `references/track_changes_guide.md` | 修订标记深入指南 |
| `references/troubleshooting.md` | **症状导向修复**：按您看到的问题索引的 13 个常见问题（标题错误、图片缺失、目录损坏等）—— 按症状搜索，找到修复方法 |
