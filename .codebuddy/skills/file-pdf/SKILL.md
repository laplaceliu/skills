---
name: minimax-pdf
description: >
  当 PDF 的视觉质量和设计标识很重要时使用此技能。
  CREATE（从头生成）："制作 PDF"、"生成报告"、"撰写提案"、"创建简历"、
  "精美 PDF"、"专业文档"、"封面"、"精致 PDF"、"可交付文档"。
  FILL（填写表单字段）："填写表单"、"填写此 PDF"、"填写表单字段"、
  "向 PDF 写入值"、"此 PDF 有哪些字段"。
  REFORMAT（将设计应用于现有文档）："重新格式化此文档"、"应用我们的样式"、
  "将此 Markdown/文本转换为 PDF"、"让此文档看起来更好"、"重新样式化此 PDF"。
  此技能使用基于令牌的设计系统：颜色、排版和间距从文档类型派生，并贯穿每一页。
  输出为可直接打印的成品。
  当外观重要时（而不仅仅是需要任何 PDF 输出时）优先使用此技能。
license: MIT
metadata:
  version: "1.0"
  category: document-generation
---

# minimax-pdf

三个任务，一个技能。

## 在任何 CREATE 或 REFORMAT 工作之前，请先阅读 `design/design.md`。

---

## 路由表

| 用户意图 | 路由 | 使用的脚本 |
|---|---|---|
| 从头生成新 PDF | **CREATE** | `palette.py` → `cover.py` → `render_cover.js` → `render_body.py` → `merge.py` |
| 填写/完成现有 PDF 中的表单字段 | **FILL** | `fill_inspect.py` → `fill_write.py` |
| 重新格式化/重新样式化现有文档 | **REFORMAT** | `reformat_parse.py` → 然后执行完整 CREATE 流程 |

**规则：** 当在 CREATE 和 REFORMAT 之间犹豫时，请问自己用户是否有现有文档可以开始。如果有 → REFORMAT。如果没有 → CREATE。

---

## 路由 A：CREATE（创建）

完整流程 —— 内容 → 设计令牌 → 封面 → 正文 → 合并的 PDF。

```bash
bash scripts/make.sh run \
  --title "Q3 策略回顾" --type proposal \
  --author "策略团队" --date "2025年10月" \
  --accent "#2D5F8A" \
  --content content.json --out report.pdf
```

**文档类型：** `report` · `proposal` · `resume` · `portfolio` · `academic` · `general` · `minimal` · `stripe` · `diagonal` · `frame` · `editorial` · `magazine` · `darkroom` · `terminal` · `poster`

| 类型 | 封面图案 | 视觉标识 |
|---|---|---|
| `report` | `fullbleed` | 深色背景，点阵网格，Playfair Display |
| `proposal` | `split` | 左侧面板 + 右侧几何图形，Syne |
| `resume` | `typographic` | 超大首字母，DM Serif Display |
| `portfolio` | `atmospheric` | 近黑色，径向光晕，Fraunces |
| `academic` | `typographic` | 浅色背景，古典衬线，EB Garamond |
| `general` | `fullbleed` | 深板岩色，Outfit |
| `minimal` | `minimal` | 白色 + 单个 8px 强调条，Cormorant Garamond |
| `stripe` | `stripe` | 3 条粗水平色带，Barlow Condensed |
| `diagonal` | `diagonal` | SVG 倾斜切割，深/浅两半，Montserrat |
| `frame` | `frame` | 内嵌边框，角饰，Cormorant |
| `editorial` | `editorial` | 幽灵字母，全大写标题，Bebas Neue |
| `magazine` | `magazine` | 暖米色背景，居中堆叠，封面图，Playfair Display |
| `darkroom` | `darkroom` | 海军蓝背景，居中堆叠，灰度图像，Playfair Display |
| `terminal` | `terminal` | 近黑色，网格线，等宽字体，霓虹绿 |
| `poster` | `poster` | 白色背景，粗侧边栏，超大标题，Barlow Condensed |

封面额外元素（通过 `--abstract`、`--cover-image` 注入到令牌中）：
- `--abstract "文本"` —— 封面上的摘要文本块（magazine/darkroom）
- `--cover-image "url"` —— 封面图 URL/路径（magazine, darkroom, poster）

**颜色覆盖 —— 始终根据文档内容选择：**
- `--accent "#HEX"` —— 覆盖强调色；`accent_lt` 通过向白色提亮自动推导
- `--cover-bg "#HEX"` —— 覆盖封面背景色

**强调色选择指导：**

您对强调色有创作自主权。从文档的语义背景——标题、行业、目的、受众——中选择，而不是从通用的"安全"选择中选择。强调色出现在分节规则、标注条、表格标题和封面上：它承载着文档的视觉标识。

| 背景 | 建议的强调色范围 |
|---|---|
| 法律/合规/金融 | 深海军蓝 `#1C3A5E`，炭灰 `#2E3440`，板岩 `#3D4C5E` |
| 医疗/健康 | 青绿色 `#2A6B5A`，冷绿 `#3A7D6A` |
| 科技/工程 | 钢蓝 `#2D5F8A`，靛蓝 `#3D4F8A` |
| 环境/可持续 | 森林绿 `#2E5E3A`，橄榄 `#4A5E2A` |
| 创意/艺术/文化 | 酒红 `#6B2A35`，紫红 `#5A2A6B`，赤陶 `#8A3A2A` |
| 学术/研究 | 深青 `#2A5A6B`，图书馆蓝 `#2A4A6B` |
| 企业/中性 | 板岩 `#3D4A5A`，石墨 `#444C56` |
| 奢华/高端 | 暖黑 `#1A1208`，深铜 `#4A3820` |

**规则：** 选择一位深思熟虑的设计师会为这份特定文档选择的颜色——而不是类型的默认值。柔和、低饱和度的色调效果最好；避免鲜艳的原色。如有疑问，选择更暗、更中性的颜色。

**content.json 区块类型：**

| 区块 | 用途 | 关键字段 |
|---|---|---|
| `h1` | 章节标题 + 强调规则 | `text` |
| `h2` | 子章节标题 | `text` |
| `h3` | 子子章节（粗体） | `text` |
| `body` | 两端对齐段落；支持 `<b>` `<i>` 标记 | `text` |
| `bullet` | 无序列表项（• 前缀） | `text` |
| `numbered` | 有序列表项 —— 在非编号区块上计数器自动重置 | `text` |
| `callout` | 带强调色左边框的高亮洞察框 | `text` |
| `table` | 数据表 —— 强调标题，交替行色调 | `headers`, `rows`, `col_widths`?, `caption`? |
| `image` | 缩放至列宽的嵌入式图像 | `path`/`src`, `caption`? |
| `figure` | 带自动编号"Figure N:"图注的图像 | `path`/`src`, `caption`? |
| `code` | 带强调色左边框的等宽代码块 | `text`, `language`? |
| `math` | 显示数学 —— 通过 matplotlib mathtext 使用 LaTeX 语法 | `text`, `label`?, `caption`? |
| `chart` | 通过 matplotlib 渲染的柱/线/饼图 | `chart_type`, `labels`, `datasets`, `title`?, `x_label`?, `y_label`?, `caption`?, `figure`? |
| `flowchart` | 通过 matplotlib 使用节点+边的流程图 | `nodes`, `edges`, `caption`?, `figure`? |
| `bibliography` | 带悬挂缩进的编号参考文献列表 | `items` [{id, text}], `title`? |
| `divider` | 强调色全宽规则 | — |
| `caption` | 小型柔和标签 | `text` |
| `pagebreak` | 强制新页面 | — |
| `spacer` | 垂直空白 | `pt`（默认 12） |

**chart / flowchart 模式：**
```json
{"type":"chart","chart_type":"bar","labels":["Q1","Q2","Q3","Q4"],
 "datasets":[{"label":"收入","values":[120,145,132,178]}],"caption":"Q 结果"}

{"type":"flowchart",
 "nodes":[{"id":"s","label":"开始","shape":"oval"},
          {"id":"p","label":"处理","shape":"rect"},
          {"id":"d","label":"有效？","shape":"diamond"},
          {"id":"e","label":"结束","shape":"oval"}],
 "edges":[{"from":"s","to":"p"},{"from":"p","to":"d"},
          {"from":"d","to":"e","label":"是"},{"from":"d","to":"p","label":"否"}]}

{"type":"bibliography","items":[
  {"id":"1","text":"作者（年份）。标题。出版社。"}]}
```

---

## 路由 B：FILL（填写）

在不改变布局或设计的情况下填写现有 PDF 中的表单字段。

```bash
# 步骤 1：检查
python3 scripts/fill_inspect.py --input form.pdf

# 步骤 2：填写
python3 scripts/fill_write.py --input form.pdf --out filled.pdf \
  --values '{"FirstName": "Jane", "Agree": "true", "Country": "US"}'
```

| 字段类型 | 值格式 |
|---|---|
| `text` | 任意字符串 |
| `checkbox` | `"true"` 或 `"false"` |
| `dropdown` | 必须与检查输出中的选项值匹配 |
| `radio` | 必须与单选值匹配（通常以 `/` 开头） |

始终先运行 `fill_inspect.py` 以获取确切的字段名称。

---

## 路由 C：REFORMAT（重新格式化）

解析现有文档 → content.json → CREATE 流程。

```bash
bash scripts/make.sh reformat \
  --input source.md --title "我的报告" --type report --out output.pdf
```

**支持的输入格式：** `.md` `.txt` `.pdf` `.json`

---

## 环境

```bash
bash scripts/make.sh check   # 验证所有依赖
bash scripts/make.sh fix     # 自动安装缺失的依赖
bash scripts/make.sh demo    # 构建示例 PDF
```

| 工具 | 使用者 | 安装方式 |
|---|---|---|
| Python 3.9+ | 所有 `.py` 脚本 | 系统自带 |
| `reportlab` | `render_body.py` | `pip install reportlab` |
| `pypdf` | fill, merge, reformat | `pip install pypdf` |
| Node.js 18+ | `render_cover.js` | 系统自带 |
| `playwright` + Chromium | `render_cover.js` | `npm install -g playwright && npx playwright install chromium` |
