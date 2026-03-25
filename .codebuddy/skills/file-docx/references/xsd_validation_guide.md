# XSD 验证指南

## 运行验证

```bash
# 针对 WML 子集模式验证
dotnet run --project minimax-docx validate input.docx --xsd assets/xsd/wml-subset.xsd

# 针对业务规则验证（场景 C 把关必需）
dotnet run --project minimax-docx validate input.docx --xsd assets/xsd/business-rules.xsd

# 同时针对两者验证
dotnet run --project minimax-docx validate input.docx --xsd assets/xsd/wml-subset.xsd --xsd assets/xsd/business-rules.xsd
```

---

## wml-subset.xsd 覆盖范围

子集模式验证最常见的 WordprocessingML 元素：

| 区域 | 验证的元素 |
|------|------------|
| 文档结构 | `w:document`、`w:body`、`w:sectPr` |
| 段落 | `w:p`、`w:pPr`、`w:r`、`w:rPr`、`w:t` |
| 表格 | `w:tbl`、`w:tblPr`、`w:tblGrid`、`w:tr`、`w:tc` |
| 样式 | `w:styles`、`w:style`、`w:docDefaults` |
| 列表 | `w:numbering`、`w:abstractNum`、`w:num` |
| 页眉/页脚 | `w:hdr`、`w:ftr` |
| 修订标记 | `w:ins`、`w:del`、`w:rPrChange`、`w:pPrChange` |
| 批注 | `w:comment`、`w:commentRangeStart`、`w:commentRangeEnd` |

### 不覆盖的内容

- DrawingML 元素 (`a:`、`pic:`、`wp:`) —— 图片/形状内部
- VML 元素 (`v:`、`o:`) —— 旧版形状
- 数学元素 (`m:`) —— 公式
- 扩展命名空间 (`w14`、`w15`、`w16*`) —— 供应商扩展
- 自定义 XML 数据部分
- 关系和内容类型验证（基于结构，不是模式）

---

## 解读错误

### 元素顺序错误

```
错误：元素 'w:jc' 在此位置不被预期。
预期：w:spacing、w:ind、w:contextualSpacing、...
位置：/word/document.xml，第 45 行
```

**原因**：子元素顺序错误。参见 `references/openxml_element_order.md`。
**修复**：重新排序子元素以匹配模式序列。

### 缺失必需元素

```
错误：元素 'w:tbl' 缺失必需的子元素 'w:tblPr'。
位置：/word/document.xml，第 102 行
```

**原因**：缺少必需的子元素。
**修复**：添加缺失的元素。表格需要 `w:tblPr` 和 `w:tblGrid`。

### 无效属性值

```
错误：属性 'w:val' 有无效值 'middle'。
预期：'left'、'center'、'right'、'both'、'distribute'
位置：/word/document.xml，第 78 行
```

**原因**：属性值不在允许的枚举中。
**修复**：使用错误中列出的有效值之一。

### 意外元素

```
错误：元素 'w:customTag' 不被预期。
位置：/word/document.xml，第 200 行
```

**原因**：子集模式中未定义的元素。可能是供应商扩展。
**修复**：检查是否是已知扩展 (w14/w15/w16)。如果是，可能安全。如果是未知的，调查或移除。

---

## 业务规则 XSD

`business-rules.xsd` 模式在标准 OpenXML 有效性之外强制执行项目特定约束：

| 规则 | 检查内容 |
|------|----------|
| 必需样式 | `Normal`、`Heading1`-`Heading3`、`TableGrid` 必须存在于 `styles.xml` |
| 字体一致性 | `w:docDefaults` 字体匹配预期值 |
| 边距范围 | 页面边距在可接受范围内 (720-2160 DXA) |
| 页面大小 | 必须是 A4 或 Letter |
| 标题层次 | 无空缺（例如，无 H1 → H3 跳过 H2） |
| 样式链 | `w:basedOn` 引用必须解析为现有样式 |

### 扩展业务规则

要添加项目特定规则，添加 `xs:assert` 或 `xs:restriction` 元素：

```xml
<!-- 要求最小 1 英寸边距 -->
<xs:element name="pgMar">
  <xs:complexType>
    <xs:attribute name="top" type="xs:integer">
      <xs:restriction>
        <xs:minInclusive value="1440" />
      </xs:restriction>
    </xs:attribute>
  </xs:complexType>
</xs:element>
```

---

## 把关检查：场景 C 硬门槛

在场景 C（应用模板）中，输出文档**必须**在交付前通过 `business-rules.xsd` 验证：

```
1. 应用模板  →  output.docx
2. 验证        →  dotnet run ... validate output.docx --xsd business-rules.xsd
3. 通过？       →  交付给用户
4. 失败？       →  修复问题，重新验证，重复直到通过
```

**这是硬门槛。** 未通过业务规则验证的文档**不可交付**，即使它在 Word 中正确打开。

---

## 误报

### 供应商扩展

扩展命名空间 (`w14`、`w15`、`w16*`) 中的元素不在子集模式中，可能触发警告：

```
警告：元素 '{http://schemas.microsoft.com/office/word/2010/wordml}shadow' 不被预期。
```

这些通常可以安全忽略 —— 它们是 Microsoft 针对新功能的扩展（例如高级文本效果、批注扩展）。

### 标记兼容性

文档可能包含带回退内容的 `mc:AlternateContent` 块。子集模式可能无法识别 `mc:` 命名空间处理。如果文档在 Word 中正确打开，这些是安全的。

### 推荐方法

1. 运行验证
2. 将**错误**视为必须修复
3. 审查**警告** —— 忽略已知供应商扩展，调查未知元素
4. 修复错误后，重新验证确认
