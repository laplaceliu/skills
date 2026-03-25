# 质量检查流程与常见陷阱

## 质量检查流程

**假设存在问题。你的工作是找到它们。**

你的第一次渲染几乎不可能完全正确。将质量检查作为排查 bug 的过程，而不是确认步骤。如果你第一次检查时没有发现任何问题，说明你看得不够仔细。

### 内容质量检查

```bash
python -m markitdown output.pptx
```

检查缺失内容、拼写错误、顺序错误。

**检查残留占位符文本：**

```bash
python -m markitdown output.pptx | grep -iE "xxxx|lorem|ipsum|placeholder|this.*(page|slide).*layout"
```

如果 grep 有结果，在宣布成功之前修复它们。

### 验证循环

1. 生成幻灯片 → 用 `python -m markitdown output.pptx` 提取文本 → 检查内容
2. **列出发现的问题**（如果没有发现问题，再更批判性地检查一遍）
3. 修复问题
4. **重新验证受影响的幻灯片**——一次修复通常会产生另一个问题
5. 重复直到完整检查没有发现新问题

**在完成至少一个修复和验证循环之前，不要宣布成功。**

### 逐幻灯片质量检查（从头创建）

```bash
python -m markitdown slide-XX-preview.pptx
```

检查缺失内容、占位符文本、页码徽章。

---

## 应避免的常见错误

- **不要重复相同的布局**——跨幻灯片使用多样化的列、卡片和标注
- **正文不要居中**——左对齐段落和列表；仅标题居中
- **不要吝啬大小对比**——标题需要 36pt+ 才能从 14-16pt 正文中突出
- **不要默认使用蓝色**——选择反映特定主题的颜色
- **不要随机混合间距**——选择 0.3" 或 0.5" 间距并一致使用
- **不要只设计一张幻灯片而让其余的平淡**——要么全力以赴，要么保持简单
- **不要创建纯文字幻灯片**——添加图片、图标、图表或视觉元素；避免简单的标题+要点
- **不要忘记文本框内边距**——当将线条或形状与文本边缘对齐时，在文本框上设置 `margin: 0` 或偏移形状以考虑内边距
- **不要使用低对比度元素**——图标和文字都需要与背景形成强对比
- **永远不要在标题下使用强调线**——这是 AI 生成幻灯片的标志；使用空白或背景色代替
- **永远不要在十六进制颜色前加 "#"**——会导致 PptxGenJS 文件损坏
- **永远不要在十六进制字符串中编码透明度**——使用 `opacity` 属性代替
- **永远不要在 createSlide() 中使用 async/await**——compile.js 不会等待
- **永远不要跨 PptxGenJS 调用重用选项对象**——PptxGenJS 会就地修改对象

---

## 关键陷阱——PptxGenJS

### 永远不要在 createSlide() 中使用 async/await

```javascript
// 错误 - compile.js 不会等待
async function createSlide(pres, theme) { ... }

// 正确
function createSlide(pres, theme) { ... }
```

### 永远不要在十六进制颜色前加 "#"

```javascript
color: "FF0000"      // 正确
color: "#FF0000"     // 会损坏文件
```

### 永远不要在十六进制字符串中编码透明度

```javascript
shadow: { color: "00000020" }              // 会损坏文件
shadow: { color: "000000", opacity: 0.12 } // 正确
```

### 防止标题文本换行

```javascript
// 对于长标题使用 fit:'shrink'
slide.addText("长标题在这里", {
  x: 0.5, y: 2, w: 9, h: 1,
  fontSize: 48, fit: "shrink"
});
```

### 永远不要跨调用重用选项对象

```javascript
// 错误
const shadow = { type: "outer", blur: 6, offset: 2, color: "000000", opacity: 0.15 };
slide.addShape(pres.shapes.RECTANGLE, { shadow, ... });
slide.addShape(pres.shapes.RECTANGLE, { shadow, ... });

// 正确 - 工厂函数
const makeShadow = () => ({ type: "outer", blur: 6, offset: 2, color: "000000", opacity: 0.15 });
slide.addShape(pres.shapes.RECTANGLE, { shadow: makeShadow(), ... });
slide.addShape(pres.shapes.RECTANGLE, { shadow: makeShadow(), ... });
```
