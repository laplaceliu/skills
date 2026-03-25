# 场景 A：从零创建新 DOCX 文档

## 何时使用

在以下情况使用场景 A：
- 用户没有现有文件，想要全新文档
- 用户提供内容（文本、表格、图片）并希望将其组合成 DOCX
- 用户指定文档类型（报告、信函、备忘录、学术）或描述自定义布局

**不要**在以下情况使用：用户已有想要修改的 DOCX（→ 场景 B）或想要重新样式化现有文档（→ 场景 C）。

---

## 分步工作流程

### 1. 确定文档类型

从用户请求中询问或推断文档类型：

| 类型 | 典型信号 |
|------|----------|
| 报告 | "报告"、"分析"、"白皮书"、带标题的章节 |
| 信函 | "信函"、"尊敬的"、地址块、称呼 |
| 备忘录 | "备忘录"、"便笺"、收件人/发件人/主题字段 |
| 学术 | "论文"、"文章"、"学位论文"、提及 APA/MLA/Chicago |
| 自定义 | 以上都不是，或用户指定确切格式 |

### 2. 收集内容需求

从用户收集：
- 标题和副标题（如有）
- 作者 / 组织
- 章节结构（标题和层级）
- 每节正文内容
- 表格（表头 + 行）
- 图片（文件路径或占位符）
- 特殊元素：目录、页码、水印、页眉/页脚

### 3. 选择样式集

根据文档类型，加载匹配的样式 XML 资源：
- 报告 → `assets/styles/default_styles.xml` 或 `assets/styles/corporate_styles.xml`
- 学术 → `assets/styles/academic_styles.xml`
- 信函 / 备忘录 / 自定义 → `assets/styles/default_styles.xml`（带覆盖）

### 4. 配置页面设置

根据文档类型默认值（见下文）或用户覆盖设置 `w:sectPr` 值。

```xml
<w:sectPr>
  <w:pgSz w:w="11906" w:h="16838" />  <!-- A4 -->
  <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"
           w:header="720" w:footer="720" w:gutter="0" />
</w:sectPr>
```

### 5. 构建文档结构

使用以下内容组装 `word/document.xml`：
1. `w:body` 作为根容器
2. 带标题样式的段落（`w:p`）作为节标题
3. 带 `Normal` 样式的正文段落
4. 根据需要添加表格、图片和其他元素
5. 最后的 `w:sectPr` 作为 `w:body` 的最后一个子元素

### 6. 应用排版默认值

在 `styles.xml` 的 `w:docDefaults` 下设置文档级默认值：
```xml
<w:docDefaults>
  <w:rPrDefault>
    <w:rPr>
      <w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="SimSun" w:cs="Arial" />
      <w:sz w:val="22" />  <!-- 11pt -->
      <w:szCs w:val="22" />
    </w:rPr>
  </w:rPrDefault>
  <w:pPrDefault>
    <w:pPr>
      <w:spacing w:after="160" w:line="259" w:lineRule="auto" />
    </w:pPr>
  </w:pPrDefault>
</w:docDefaults>
```

### 7. 添加复杂元素

参见下方的复杂元素指南部分。

### 8. 运行验证流程

```
dotnet run ... validate --xsd wml-subset.xsd
dotnet run ... validate --xsd business-rules.xsd   # 如果应用模板
```

---

## 文档类型默认值

### 报告
| 属性 | 值 |
|------|-----|
| 正文字体 | Calibri 11pt |
| 标题字体 | Calibri Light |
| H1 / H2 / H3 / H4 大小 | 28pt / 24pt / 18pt / 14pt |
| 标题颜色 | #2F5496（企业蓝） |
| 边距 | 1 英寸（1440 DXA）四周 |
| 页面大小 | A4（11906 × 16838 DXA） |
| 行距 | 单倍（line="240"） |
| 段落间距 | 正文前 0pt，后 8pt |

### 信函
| 属性 | 值 |
|------|-----|
| 字体 | Calibri 11pt |
| 页面大小 | Letter（12240 × 15840 DXA） |
| 边距 | 1 英寸四周 |
| 结构 | 日期 → 地址 → 称呼 → 正文 → 结束语 → 签名 |
| 行距 | 单倍 |

### 备忘录
| 属性 | 值 |
|------|-----|
| 字体 | Arial 11pt |
| 页面大小 | Letter |
| 边距 | 0.75 英寸（1080 DXA） |
| 页眉 | "MEMO" 居中、粗体、16pt |
| 字段 | 收件人、发件人、日期、主题（粗体标签，制表对齐值） |

### 学术
| 属性 | 值 |
|------|-----|
| 字体 | Times New Roman 12pt |
| 行距 | 双倍（line="480"） |
| 边距 | 1 英寸四周 |
| 页面大小 | Letter |
| 标题 | 粗体，相同字体，H1/H2/H3 为 14/13/12pt |
| 首行缩进 | 0.5 英寸（720 DXA） |
| 标题颜色 | 黑色（无色） |

---

## 内容配置 JSON 格式

CLI `create` 命令接受 JSON 配置：

```json
{
  "type": "report",
  "title": "季度收入分析",
  "subtitle": "2026年第一季度",
  "author": "财务团队",
  "pageSize": "A4",
  "margins": { "top": 1440, "right": 1440, "bottom": 1440, "left": 1440 },
  "sections": [
    {
      "heading": "执行摘要",
      "level": 1,
      "content": [
        { "type": "paragraph", "text": "收入同比增长12%..." },
        {
          "type": "table",
          "headers": ["地区", "收入", "增长"],
          "rows": [
            ["北美", "$420万", "+15%"],
            ["欧洲", "$280万", "+8%"],
            ["亚太", "$190万", "+18%"]
          ]
        },
        { "type": "image", "path": "charts/revenue.png", "width": "5英寸", "alt": "收入图表" }
      ]
    },
    {
      "heading": "详细分析",
      "level": 1,
      "content": [
        { "type": "paragraph", "text": "按产品线细分..." }
      ]
    }
  ]
}
```

支持的内容类型：
- `paragraph` — 正文（应用 Normal 样式）
- `table` — 表头 + 行（应用 TableGrid 样式）
- `image` — 带宽度/高度控制的内联图片
- `list` — 项目符号或编号列表项
- `pageBreak` — 强制分页

---

## 复杂元素指南

### 目录

插入目录域代码。Word 将在文件打开时更新实际条目：

```xml
<w:p>
  <w:pPr><w:pStyle w:val="TOCHeading" /></w:pPr>
  <w:r><w:t>目录</w:t></w:r>
</w:p>
<w:p>
  <w:r>
    <w:fldChar w:fldCharType="begin" />
  </w:r>
  <w:r>
    <w:instrText xml:space="preserve"> TOC \o "1-3" \h \z \u </w:instrText>
  </w:r>
  <w:r>
    <w:fldChar w:fldCharType="separate" />
  </w:r>
  <w:r>
    <w:t>[目录 — 更新以填充]</w:t>
  </w:r>
  <w:r>
    <w:fldChar w:fldCharType="end" />
  </w:r>
</w:p>
```

### 页脚中的页码

添加页脚部分（`word/footer1.xml`）并在 `w:sectPr` 中引用：

```xml
<!-- 在 footer1.xml 中 -->
<w:ftr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:p>
    <w:pPr><w:jc w:val="center" /></w:pPr>
    <w:r>
      <w:fldChar w:fldCharType="begin" />
    </w:r>
    <w:r>
      <w:instrText>PAGE</w:instrText>
    </w:r>
    <w:r>
      <w:fldChar w:fldCharType="separate" />
    </w:r>
    <w:r><w:t>1</w:t></w:r>
    <w:r>
      <w:fldChar w:fldCharType="end" />
    </w:r>
  </w:p>
</w:ftr>

<!-- 在 sectPr 中 -->
<w:footerReference w:type="default" r:id="rId8" />
```

### 水印

添加带背景形状的页眉部分：

```xml
<w:hdr>
  <w:p>
    <w:r>
      <w:pict>
        <v:shape style="position:absolute;margin-left:0;margin-top:0;width:468pt;height:180pt;
                        z-index:-251657216;mso-position-horizontal:center;
                        mso-position-vertical:center"
                 fillcolor="silver" stroked="f">
          <v:textpath style="font-family:'Calibri';font-size:1pt" string="草稿" />
        </v:shape>
      </w:pict>
    </w:r>
  </w:p>
</w:hdr>
```

---

## 创建后检查清单

1. **验证** 是否符合 `wml-subset.xsd` —— 所有元素顺序正确，必需属性存在
2. **合并相邻 run** 保持 XML 整洁
3. **验证关系** —— document.xml 中的每个 `r:id` 在 `document.xml.rels` 中都有匹配条目
4. **检查内容类型** —— 包中的每个部分都在 `[Content_Types].xml` 中注册
5. **预览** —— 在 Word 或 LibreOffice 中打开以目视确认布局
6. **文件大小** —— 确认图片大小合理（如果每个 > 2MB 则压缩）
