---
name: frontend-dev
description: |
  全栈前端开发，结合高端 UI 设计、电影级动画、AI 生成媒体资产、有说服力的文案和视觉艺术。
  构建具有真实媒体、高级动效和引人入胜文案的完整、视觉冲击力强的网页。
  适用于：构建着陆页、营销网站、产品页面、仪表板，生成媒体资产（图像/视频/音频/音乐），
  撰写转化文案，创建生成艺术，或实现电影级滚动动画。
license: MIT
metadata:
  version: "1.0.0"
  category: frontend
  sources:
    - Framer Motion 文档
    - GSAP / GreenSock 文档
    - Three.js 文档
    - Tailwind CSS 文档
    - React / Next.js 文档
    - AIDA 框架（Elmo Lewis）
    - p5.js 文档
---

# Frontend Studio

通过协调 5 项专业能力来构建完整的、可交付的前端页面：设计工程、动效系统、AI 生成资产、有说服力的文案和生成艺术。

## 调用方式

```
/frontend-dev <请求>
```

用户提供自然语言形式的请求（例如"为音乐流媒体应用构建着陆页"）。

## 技能结构

```
frontend-dev/
├── SKILL.md                      # 核心技能（此文件）
├── scripts/                      # 资产生成脚本
│   ├── minimax_tts.py            # 文本转语音
│   ├── minimax_music.py          # 音乐生成
│   ├── minimax_video.py          # 视频生成（异步）
│   └── minimax_image.py          # 图片生成
├── references/                   # 详细指南（按需阅读）
│   ├── minimax-cli-reference.md  # CLI 参数速查
│   ├── asset-prompt-guide.md     # 资产提示词工程规则
│   ├── minimax-tts-guide.md      # TTS 使用与语音
│   ├── minimax-music-guide.md    # 音乐提示词与歌词格式
│   ├── minimax-video-guide.md    # 相机命令与模型
│   ├── minimax-image-guide.md    # 比例与批量生成
│   ├── minimax-voice-catalog.md  # 所有语音 ID
│   ├── motion-recipes.md         # 动画代码片段
│   ├── env-setup.md             # 环境设置
│   └── troubleshooting.md        # 常见问题
├── templates/                    # 视觉艺术模板
│   ├── viewer.html               # p5.js 交互艺术基础
│   └── generator_template.js     # p5.js 代码参考
└── canvas-fonts/                 # 静态艺术字体（TTF + 许可证）
```

## 项目结构

### 资产（通用）

所有框架使用相同的资产组织方式：

```
assets/
├── images/
│   ├── hero-landing-1710xxx.webp
│   ├── icon-feature-01.webp
│   └── bg-pattern.svg
├── videos/
│   ├── hero-bg-1710xxx.mp4
│   └── demo-preview.mp4
└── audio/
    ├── bgm-ambient-1710xxx.mp3
    └── tts-intro-1710xxx.mp3
```

**资产命名：** `{类型}-{描述符}-{时间戳}.{扩展名}`

### 按框架

| 框架 | 资产位置 | 组件位置 |
|-----------|---------------|-------------------|
| **纯 HTML** | `./assets/` | 不适用（内联或 `./js/`） |
| **React/Next.js** | `public/assets/` | `src/components/` |
| **Vue/Nuxt** | `public/assets/` | `src/components/` |
| **Svelte/SvelteKit** | `static/assets/` | `src/lib/components/` |
| **Astro** | `public/assets/` | `src/components/` |

### 纯 HTML

```
project/
├── index.html
├── assets/
│   ├── images/
│   ├── videos/
│   └── audio/
├── css/
│   └── styles.css
└── js/
    └── main.js           # 动画（GSAP/原生）
```

### React / Next.js

```
project/
├── public/assets/        # 静态资产
├── src/
│   ├── components/
│   │   ├── ui/           # Button, Card, Input
│   │   ├── sections/     # Hero, Features, CTA
│   │   └── motion/       # RevealSection, StaggerGrid
│   ├── lib/
│   ├── styles/
│   └── app/              # 页面
└── package.json
```

### Vue / Nuxt

```
project/
├── public/assets/
├── src/                  # 或 Nuxt 的根目录
│   ├── components/
│   │   ├── ui/
│   │   ├── sections/
│   │   └── motion/
│   ├── composables/      # 共享逻辑
│   ├── pages/
│   └── assets/           # 处理后的资产（可选）
└── package.json
```

### Astro

```
project/
├── public/assets/
├── src/
│   ├── components/       # .astro, .tsx, .vue, .svelte
│   ├── layouts/
│   ├── pages/
│   └── styles/
└── package.json
```

**组件命名：** PascalCase（`HeroSection.tsx`、`HeroSection.vue`、`HeroSection.astro`）

---

## 合规性

**此技能中的所有规则都是强制性的。违反任何规则是阻塞性错误 —— 在继续或交付之前必须修复。**

---

## 工作流

### 阶段 1：设计架构
1. 分析请求 —— 确定页面类型和上下文
2. 根据页面类型设置设计旋钮
3. 规划布局区块并识别资产需求

### 阶段 2：动效架构
1. 根据每个区块选择动画工具（参阅工具选择矩阵）
2. 遵循性能护栏规划动效序列

### 阶段 3：资产生成
使用 `scripts/` 生成所有图像/视频/音频资产。永远不要使用占位符 URL（unsplash、picsum、placeholder.com、via.placeholder、placehold.co 等）或外部 URL。

1. 解析资产需求（类型、风格、规格、用途）
2. 精心制作优化提示词，展示给用户，在生成前确认
3. 通过脚本执行，保存到项目 —— 在所有资产保存到本地之前不要进入阶段 5

### 阶段 4：文案与内容
遵循文案框架（AIDA、PAS、FAB）来撰写所有文本内容。不要使用"Lorem ipsum"—— 写真实的文案。

### 阶段 5：构建 UI
按照设计和动效规则搭建项目并构建每个区块。集成生成的资产和文案。所有 `<img>`、`<video>`、`<source>` 和 CSS `background-image` 必须引用阶段 3 的本地资产。

### 阶段 6：质量门禁
运行最终检查清单（参阅质量门禁部分）。

---

# 1. 设计工程

## 1.1 基线配置

| 旋钮 | 默认值 | 范围 |
|------|---------|------|
| DESIGN_VARIANCE | 8 | 1=对称，10=不对称 |
| MOTION_INTENSITY | 6 | 1=静态，10=电影级 |
| VISUAL_DENSITY | 4 | 1=通透，10=紧凑 |

根据用户请求动态调整。

## 1.2 架构约定
- **依赖验证：** 导入任何库之前检查 `package.json`。如果缺失则输出安装命令。
- **框架：** React/Next.js。默认为服务端组件。交互组件必须是隔离的 `"use client"` 叶子组件。
- **样式：** Tailwind CSS。检查 `package.json` 中的版本 —— 永远不要混合 v3/v4 语法。
- **反表情政策：** 任何地方都不要使用表情符号。仅使用 Phosphor 或 Radix 图标。
- **视口：** 使用 `min-h-[100dvh]` 而不是 `h-screen`。使用 CSS Grid 而不是 flex 百分比计算。
- **布局：** `max-w-[1400px] mx-auto` 或 `max-w-7xl`。

## 1.3 设计规则

| 规则 | 指令 |
|------|-----------|
| 排版 | 标题：`text-4xl md:text-6xl tracking-tighter`。正文：`text-base leading-relaxed max-w-[65ch]`。**永远不要**使用 Inter —— 使用 Geist/Outfit/Satoshi。**永远不要**在仪表板上使用衬线字体。 |
| 颜色 | 最多 1 个强调色，饱和度 < 80%。**永远不要**使用 AI 紫/蓝。坚持一个调色板。 |
| 布局 | 当 VARIANCE > 4 时，**永远不要**使用居中英雄图。强制使用分屏或不对称布局。 |
| 卡片 | 当 DENSITY > 7 时，**永远不要**使用通用卡片。使用 `border-t`、`divide-y` 或间距。 |
| 状态 | **始终**实现：加载中（骨架屏）、空状态、错误、触觉反馈（`scale-[0.98]`）。 |
| 表单 | 标签在输入上方。错误在输入下方。`gap-2` 用于输入块。 |

## 1.4 反垃圾技术

- **液态玻璃：** `backdrop-blur` + `border-white/10` + `shadow-[inset_0_1px_0_rgba(255,255,255,0.1)]`
- **磁性按钮：** 使用 `useMotionValue`/`useTransform` —— 永远不要为持续动画使用 `useState`
- **永恒动效：** 当 INTENSITY > 5 时，添加无限微动效（脉冲、浮动、闪光）
- **布局过渡：** 使用 Framer `layout` 和 `layoutId` 属性
- **交错动画：** 使用 `staggerChildren` 或 CSS `animation-delay: calc(var(--index) * 100ms)`

## 1.5 禁止模式

| 类别 | 禁止项 |
|----------|--------|
| 视觉 | 霓虹光晕、纯黑（#000）、过度饱和的强调色、标题上的渐变文字、自定义光标 |
| 排版 | Inter 字体、超大 H1、仪表板上的衬线字体 |
| 布局 | 3 列等宽卡片行、间距别扭的浮动元素 |
| 组件 | 未自定义的默认 shadcn/ui |

## 1.6 创意工具箱

| 类别 | 模式 |
|----------|----------|
| 导航 | Dock 放大、磁性按钮、黏性菜单、动态岛、径向菜单、速度拨号、 mega 菜单 |
| 布局 | Bento 网格 Masonry、Chroma 网格、分屏滚动、幕布揭示 |
| 卡片 | 视差倾斜、聚光灯边框、玻璃拟态、全息箔片、滑动堆叠、变形模态 |
| 滚动 | 黏性堆叠、水平劫持、机车序列、缩放视差、进度路径、液态滑动 |
| 画廊 | 穹顶画廊、Coverflow、拖动平移、手风琴滑块、悬停轨迹、故障效果 |
| 文字 | 动态字幕、文字遮罩揭示、扰码效果、圆形路径、渐变描边、动态网格 |
| 微交互 | 粒子爆炸、下拉刷新、骨架闪光、方向悬停、波纹点击、SVG 绘制、网格渐变、镜头模糊 |

## 1.7 Bento 范式

- **调色板：** 背景 `#f9fafb`，卡片纯白带 `border-slate-200/50`
- **表面：** `rounded-[2.5rem]`，漫射阴影
- **排版：** Geist/Satoshi，紧排标题 `tracking-tight`
- **标签：** 在卡片外部和下方
- **动画：** 弹簧物理（`stiffness: 100, damping: 20`），无限循环，`React.memo` 隔离

**5-卡片原型：**
1. 智能列表 —— 通过 `layoutId` 自动排序
2. 命令输入框 —— 打字机 + 闪烁光标
3. 实时状态 —— 呼吸指示器
4. 宽数据流 —— 无限水平轮播
5. 上下文 UI —— 交错高亮 + 浮动工具栏

## 1.8 品牌覆盖

当品牌样式激活时：
- 深色：`#141413`，浅色：`#faf9f5`，中间：`#b0aea5`，柔和：`#e8e6dc`
- 强调色：橙色 `#d97757`，蓝色 `#6a9bcc`，绿色 `#788c5d`
- 字体：Poppins（标题），Lora（正文）

---

# 2. 动效引擎

## 2.1 工具选择矩阵

| 需求 | 工具 |
|------|------|
| UI 进入/退出/布局 | **Framer Motion** —— `AnimatePresence`、`layoutId`、弹簧 |
| 滚动叙事（固定、擦洗） | **GSAP + ScrollTrigger** —— 帧精度控制 |
| 循环图标 | **Lottie** —— 懒加载（~50KB） |
| 3D/WebGL | **Three.js / R3F** —— 隔离的 `<Canvas>`，自己的 `"use client"` 边界 |
| 悬停/焦点状态 | **仅 CSS** —— 零 JS 成本 |
| 原生滚动驱动 | **CSS** —— `animation-timeline: scroll()` |

**冲突规则 [强制]：**
- 永远不要在同一组件中混合 GSAP + Framer Motion
- R3F 必须存在于隔离的 Canvas 包装器中
- 始终懒加载 Lottie、GSAP、Three.js

## 2.2 强度等级

| 等级 | 技术 |
|-------|------------|
| 1-2 微妙 | 仅 CSS 过渡，150-300ms |
| 3-4 流畅 | CSS 关键帧 + Framer animate，交错 ≤ 3 项 |
| 5-6 流体 | `whileInView`、磁性悬停、视差倾斜 |
| 7-8 电影级 | GSAP ScrollTrigger、固定区块、水平劫持 |
| 9-10 沉浸 | 完整滚动序列、Three.js 粒子、WebGL 着色器 |

## 2.3 动画配方

参阅 `references/motion-recipes.md` 获取完整代码。摘要：

| 配方 | 工具 | 用途 |
|--------|------|-------|
| 滚动揭示 | Framer | 视口进入时的淡入+滑动 |
| 交错网格 | Framer | 顺序列表动画 |
| 固定时间线 | GSAP | 带固定的水平滚动 |
| 倾斜卡片 | Framer | 鼠标追踪 3D 透视 |
| 磁性按钮 | Framer | 吸引光标的按钮 |
| 文字扰码 | 原生 | 矩阵式解码效果 |
| SVG 路径绘制 | CSS | 滚动链接的路径动画 |
| 水平滚动 | GSAP | 垂直到水平的劫持 |
| 粒子背景 | R3F | 装饰性 WebGL 粒子 |
| 布局变形 | Framer | 卡片到模态的扩展 |

## 2.4 性能规则

**仅 GPU 属性（仅动画化这些）：** `transform`、`opacity`、`filter`、`clip-path`

**永远不要动画化：** `width`、`height`、`top`、`left`、`margin`、`padding`、`font-size` —— 如果需要这些效果，使用 `transform: scale()` 或 `clip-path` 代替。

**隔离：**
- 永恒动效必须在 `React.memo` 叶子组件中
- 仅在动画期间使用 `will-change: transform`
- 在重容器上使用 `contain: layout style paint`

**移动端：**
- 始终尊重 `prefers-reduced-motion`
- 始终在 `pointer: coarse` 上禁用视差/3D
- 限制粒子数：桌面 800，平板 300，移动 100
- 在移动端 < 768px 上禁用 GSAP 固定

**清理：** 每个带有 GSAP/观察者的 `useEffect` 必须 `return () => ctx.revert()`

## 2.5 弹簧与缓动

| 感觉 | Framer 配置 |
|------|---------------|
| 敏捷 | `stiffness: 300, damping: 30` |
| 流畅 | `stiffness: 150, damping: 20` |
| 弹性 | `stiffness: 100, damping: 10` |
| 沉重 | `stiffness: 60, damping: 20` |

| CSS 缓动 | 值 |
|------------|-------|
| 流畅减速 | `cubic-bezier(0.16, 1, 0.3, 1)` |
| 流畅加速 | `cubic-bezier(0.7, 0, 0.84, 0)` |
| 弹性 | `cubic-bezier(0.34, 1.56, 0.64, 1)` |

## 2.6 可访问性

- 始终在 `prefers-reduced-motion` 检查中包装动效
- 永远不要让内容闪烁超过每秒 3 次（癫痫风险）
- 始终提供可见的焦点环（使用 `outline` 而不是 `box-shadow`）
- 始终为动态揭示的内容添加 `aria-live="polite"`
- 始终为自动播放动画添加暂停按钮

## 2.7 依赖

```bash
npm install framer-motion           # UI（保持在顶层）
npm install gsap                    # 滚动（懒加载）
npm install lottie-react            # 图标（懒加载）
npm install three @react-three/fiber @react-three/drei  # 3D（懒加载）
```

---

# 3. 资产生成

## 3.1 脚本

| 类型 | 脚本 | 模式 |
|------|--------|--------|
| TTS | `scripts/minimax_tts.py` | 同步 |
| 音乐 | `scripts/minimax_music.py` | 同步 |
| 视频 | `scripts/minimax_video.py` | 异步（创建 → 轮询 → 下载） |
| 图片 | `scripts/minimax_image.py` | 同步 |

环境：`MINIMAX_API_KEY`（必需）。

## 3.2 工作流

1. **解析：** 类型、数量、风格、规格、用途
2. **制作提示词：** 具体（构图、灯光、风格）。在图片提示词中**永远不要**包含文字。
3. **执行：** 展示提示词给用户，**必须确认后再生成**，然后运行脚本
4. **保存：** `<project>/public/assets/{images,videos,audio}/` 为 `{类型}-{描述符}-{时间戳}.{扩展名}` —— **必须保存到本地**
5. **后处理：** 图片 → WebP，视频 → ffmpeg 压缩，音频 → 标准化
6. **交付：** 文件路径 + 代码片段 + CSS 建议

## 3.3 预设快捷方式

| 快捷键 | 规格 |
|----------|------|
| `hero` | 16:9，电影感，文字安全 |
| `thumb` | 1:1，居中主体 |
| `icon` | 1:1，平面，干净背景 |
| `avatar` | 1:1，人像，准备圆形裁剪 |
| `banner` | 21:9，OG/社交 |
| `bg-video` | 768P，6s，`[静态镜头]` |
| `video-hd` | 1080P，6s |
| `bgm` | 30s，无人声，可循环 |
| `tts` | MiniMax HD，MP3 |

## 3.4 参考

- `references/minimax-cli-reference.md` —— CLI 参数
- `references/asset-prompt-guide.md` —— 提示词规则
- `references/minimax-voice-catalog.md` —— 语音 ID
- `references/minimax-tts-guide.md` —— TTS 使用
- `references/minimax-music-guide.md` —— 音乐生成（提示词、歌词、结构标签）
- `references/minimax-video-guide.md` —— 相机命令
- `references/minimax-image-guide.md` —— 比例、批量

---

# 4. 文案

## 4.1 核心任务

1. 吸引注意力 → 2. 创造渴望 → 3. 消除障碍 → 4. 促使行动

## 4.2 框架

**AIDA**（着陆页、电子邮件）：
```
注意力： 大胆标题（承诺或痛点）
兴趣：   详细阐述问题（"是的，那就是我"）
渴望：   展示转变
行动：   清晰的 CTA
```

**PAS**（痛点驱动产品）：
```
问题：   清晰陈述
 agitation： 使其紧迫
解决方案： 您的产品
```

**FAB**（产品差异化）：
```
特性：   它做什么
优势：   为什么重要
收益：   客户得到什么
```

## 4.3 标题

| 公式 | 示例 |
|---------|--------|
| 承诺 | "30 天内打开率翻倍" |
| 提问 | "还在每周浪费 10 小时？" |
| 如何做 | "如何自动化您的管道" |
| 数字 | "7 个正在扼杀转化的错误" |
| 负面 | "停止流失潜在客户" |
| 好奇心 | "一个让预订量翻三倍的变化" |
| 转变 | "从 50 到 500 个潜在客户" |

要具体。从结果入手，而不是方法。

## 4.4 CTA

**糟糕：** 提交、点击这里、了解详情

**好：** "开始免费试用"、"立即获取模板"、"预约策略通话"

**公式：** [行动动词] + [他们得到什么] + [紧迫性/便利性]

放置位置：首屏上方、价值呈现之后、长页面多处。

## 4.5 情感触发器

| 触发器 | 示例 |
|---------|----------|
| FOMO | "仅剩 3 个名额" |
| 损失恐惧 | "每一天没有这个，您就在损失 X 美元" |
| 地位 | "加入 10,000+ 顶级代理商" |
| 便利 | "设置一次。永远遗忘。" |
| 沮丧 | "厌倦了什么都不交付的工具？" |
| 希望 | "是的，您可以做到 10 万美元 MRR" |

## 4.6 异议处理

| 异议 | 回应 |
|-----------|----------|
| 太贵 | 展示 ROI："两周内回本" |
| 不适合我 | 来自类似客户的社会证明 |
| 没时间 | "设置只需 10 分钟" |
| 如果失败了呢 | "30 天退款保证" |
| 需要考虑 | 紧迫性/稀缺性 |

放置在 FAQ、推荐信、CTA 附近。

## 4.7 证明类型

推荐信（附姓名/头衔）、案例研究、数据/指标、社会证明、认证

---

# 5. 视觉艺术

哲学优先的工作流。两种输出模式。

## 5.1 输出模式

| 模式 | 输出 | 何时 |
|------|--------|------|
| 静态 | PDF/PNG | 海报、印刷、设计资产 |
| 交互 | HTML（p5.js） | 生成艺术、可探索变体 |

## 5.2 工作流

### 步骤 1：哲学创作
命名运动（1-2 个词）。阐述哲学（4-6 段）涵盖：
- 静态：空间、形式、颜色、规模、节奏、层次
- 交互：计算、涌现、噪音、参数化变体

### 步骤 2：概念种子
识别微妙、小众的参考 —— 精致，而不是字面。爵士音乐家引用另一首歌。

### 步骤 3：创作

**静态模式：**
- 单页、高视觉、设计导向
- 重复图案、完美形状
- 来自 `canvas-fonts/` 的稀疏排版
- 无重叠，适当边距
- 输出：`.pdf` 或 `.png` + 哲学 `.md`

**交互模式：**
1. 先阅读 `templates/viewer.html`
2. 保留 FIXED 部分（header、sidebar、seed 控件）
3. 替换 VARIABLE 部分（算法、参数）
4. 种子随机性：`randomSeed(seed); noiseSeed(seed);`
5. 输出：单个自包含 HTML

### 步骤 4：完善
完善，而不是添加。让它变得清晰。打磨成杰作。

---

# 质量门禁

**设计：**
- [ ] 高差异设计的移动端布局折叠（`w-full`、`px-4`）
- [ ] 使用 `min-h-[100dvh]` 而不是 `h-screen`
- [ ] 提供空状态、加载状态、错误状态
- [ ] 在间距足够时省略卡片

**动效：**
- [ ] 根据选择矩阵使用正确的工具
- [ ] 同一组件中不混合 GSAP + Framer
- [ ] 所有 `useEffect` 都有清理返回
- [ ] 尊重 `prefers-reduced-motion`
- [ ] 永恒动效在 `React.memo` 叶子组件中
- [ ] 仅动画化 GPU 属性
- [ ] 重型库懒加载

**通用：**
- [ ] 在 `package.json` 中验证依赖
- [ ] **无占位符 URL** —— 在输出中 grep 查找 `unsplash`、`picsum`、`placeholder`、`placehold`、`via.placeholder`、`lorem.space`、`dummyimage`。如果发现任何，立即停止并在交付前用生成的资产替换。
- [ ] **所有媒体资产都作为本地文件存在于项目的 assets 目录中**
- [ ] 资产提示词在生成前已与用户确认

---

*React 和 Next.js 是 Meta Platforms, Inc. 和 Vercel, Inc. 的商标。Vue.js 是 Evan You 的商标。Tailwind CSS 是 Tailwind Labs Inc. 的商标。Svelte 和 SvelteKit 是其各自所有者的商标。GSAP/GreenSock 是 GreenSock Inc. 的商标。Three.js、Framer Motion、Lottie、Astro 以及所有其他产品名称是其各自所有者的商标。*
