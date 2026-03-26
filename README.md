# Skills 项目 README

> 本文档介绍 `.codebuddy/skills/` 目录下所有 SKILL 的分类、用途，以及如何在实际开发中按流程使用它们。

---

## 一、SKILL 总览

共计 **29 个 SKILL**，分布在以下类别：

| 类别 | 数量 | 说明 |
|------|------|------|
| 通用技能 | 4 | 需求分析、技术选型、前端开发、全栈开发 |
| 文档处理 | 4 | DOCX、PDF、PPTX、XLSX |
| 嵌入式开发 | 1 | C++ 嵌入式系统开发 |
| Qt/C++ 开发 | 18 | 覆盖 Qt C++ 应用完整生命周期 |
| 测试与质量 | 2 | Mock 测试、Qt 测试模式 |

---

## 二、SKILL 按开发流程分类

### 📋 第一阶段：需求与规划

| SKILL | 一句话描述 | 核心功能 |
|-------|----------|---------|
| **requirements-analysis** | 需求分析与系统设计 | 需求澄清、结构化、DDD 拆解、敏捷计划、技术方案设计 |
| **tech-selection** | C++/Qt 技术选型指南 | 平台评估、候选方案对比、Benchmark 测试、对比报告生成 |

**何时使用：**
- 用户提出新需求或新项目 → `requirements-analysis`
- 需要在多个技术方案之间做选择 → `tech-selection`

---

### 🎨 第二阶段：界面/前端开发

| SKILL | 一句话描述 | 核心功能 |
|-------|----------|---------|
| **frontend-dev** | 全栈前端开发 + 高端 UI + 电影级动画 | 设计工程、动效系统、AI 资产生成、有说服力文案、生成艺术 |
| **qt-architecture** | Qt C++ 应用架构与项目结构 | 入口点模式、src 布局、QMainWindow、CMake 配置、MVP 架构 |
| **qt-dialogs** | Qt C++ 对话框模式 | QMessageBox、QFileDialog、自定义模态/非模态对话框 |
| **qt-layouts** | Qt C++ 布局管理器 | QVBoxLayout、QHBoxLayout、QGridLayout、QSplitter |
| **qt-styling** | Qt C++ 样式表与主题定制 | QSS 选择器、深色/浅色模式、Fusion 样式、动态属性 |
| **qt-qml** | QML 和 Qt Quick 声明式 UI | C++/QML 集成、属性声明、信号连接、QtQuick.Controls |

**何时使用：**
- 构建 Web 前端页面 → `frontend-dev`
- 开发 Qt Widgets 应用 → `qt-architecture` + `qt-layouts` + `qt-dialogs`
- 实现深色模式/主题切换 → `qt-styling`
- 开发 QML/Qt Quick 应用 → `qt-qml`

---

### ⚙️ 第三阶段：核心功能实现

| SKILL | 一句话描述 | 核心功能 |
|-------|----------|---------|
| **qt-signals-slots** | Qt C++ 信号与槽核心机制 | 自定义信号、连接语法、跨线程通信、重载处理 |
| **qt-model-view** | Qt C++ 模型/视图架构 | QAbstractItemModel、QTableView、代理模型、排序筛选 |
| **qt-threading** | Qt C++ 线程模式 | QThread、QRunnable、QThreadPool、线程安全 |
| **qt-resources** | Qt C++ 资源系统 | .qrc 文件、图标嵌入、rcc 编译器、高 DPI 支持 |
| **qt-settings** | Qt C++ 持久化应用程序设置 | QSettings、窗口几何保存、近期文件、INI 配置 |
| **embedded-dev** | C++ 嵌入式系统开发指南 | 交叉编译、外设驱动、RTOS、内存管理、中断处理、低功耗设计 |

**何时使用：**
- 实现 UI 与业务逻辑的通信 → `qt-signals-slots`
- 显示表格/列表数据 → `qt-model-view`
- 处理耗时操作/保持 UI 响应 → `qt-threading`
- 打包图标/图片资源 → `qt-resources`
- 保存用户偏好设置 → `qt-settings`
- 开发嵌入式设备固件 → `embedded-dev`

---

### 🧪 第四阶段：测试与质量保障

| SKILL | 一句话描述 | 核心功能 |
|-------|----------|---------|
| **qtest-patterns** | Qt 测试模式 | C++ QTest、pytest-qt、QML TestCase、CMake 集成 |
| **mock-test** | C++/Qt Mock 测试专家技能 | GMock 接口隔离、QSignalSpy、异步测试、数据仿真器 |
| **qt-coverage-workflow** | C++/Qt 覆盖率工作流程 | gcov + lcov、覆盖率阈值、CI 集成 |

**何时使用：**
- 编写 Qt 单元测试 → `qtest-patterns`
- 需要 mock 网络/数据库等外部依赖 → `mock-test`
- 分析测试覆盖率缺口 → `qt-coverage-workflow`

---

### 🐛 第五阶段：调试与问题定位

| SKILL | 一句话描述 | 核心功能 |
|-------|----------|---------|
| **qt-debugging** | Qt C++ 应用程序诊断与修复 | 崩溃诊断、事件循环问题、widget 渲染、段错误、ASAN 配置 |
| **qt-troubleshooting** | Qt 问题定位与调试工作流 | 交互式诊断、问题分类、调用 qt-debugging、生成报告 |
| **performance-profiling** | C++/Qt 性能剖析与优化指南 | perf/BPF 剖析、内存分析、火焰图、Qt GUI 优化 |

**何时使用：**
- 应用崩溃/闪退 → `qt-debugging`
- 需要系统化诊断 Qt 问题 → `qt-troubleshooting`
- 性能瓶颈/内存泄漏 → `performance-profiling`

---

### 📦 第六阶段：打包与部署

| SKILL | 一句话描述 | 核心功能 |
|-------|----------|---------|
| **qt-packaging** | Qt C++ 应用程序打包与分发 | CMake/Conan/vcpkg、Windows/macOS/Linux 部署、AppImage |

**何时使用：**
- 创建可安装的分发包 → `qt-packaging`

---

### 📄 第七阶段：文档生成

| SKILL | 一句话描述 | 核心功能 |
|-------|----------|---------|
| **markdown-doc** | Markdown 文档创建（图表/公式） | Mermaid 图表、KaTeX 公式、Kroki 图片渲染 |
| **file-docx** | Word 文档创建/编辑/格式化 | OpenXML SDK、模板填充、XSD 验证 |
| **file-pdf** | 高视觉质量 PDF 生成 | 封面设计、正文渲染、图表、表单填写 |
| **file-pptx** | PowerPoint 演示文稿生成 | PptxGenJS 创建、设计系统、XML 编辑 |
| **file-xlsx** | Excel 文件创建/分析 | XML 模板、公式验证、财务格式 |

**何时使用：**
- 编写技术文档（推荐带图表） → `markdown-doc`
- 生成正式报告/合同 → `file-docx`
- 创建精美 PDF 提案/简历 → `file-pdf`
- 制作演示幻灯片 → `file-pptx`
- 处理表格数据/财务模型 → `file-xlsx`

---

## 三、从零开始使用 SKILL 的示例

### 场景：开发一个 Qt 数据采集桌面应用

下面展示在不同阶段"什么时候，使用什么样的提示词"来调用 SKILL。

---

### 🚀 阶段 0：需求确认

**提示词：**
> 我想开发一个数据采集桌面应用，主要功能是实时显示传感器数据，支持数据导出为 Excel。需要运行在 Windows 上。

**触发的 SKILL：** `requirements-analysis`

**AI 会做的：**
1. 通过交互式提问澄清需求（目标用户、核心功能、验收标准等）
2. 生成需求结构化文档
3. 拆解为开发任务
4. 制定技术方案

---

### 🔧 阶段 1：技术选型

**提示词：**
> 数据采集应用需要每秒处理 1000 个数据点，在 JSON 序列化库选择上纠结。请对比 nlohmann/json、rapidjson、Qt JSON 三者的性能。

**触发的 SKILL：** `tech-selection`

**AI 会做的：**
1. 搜索候选方案
2. 生成 Benchmark 测试代码
3. 执行性能测试
4. 生成对比报告（含雷达图）

---

### 🏗️ 阶段 2：项目架构搭建

**提示词：**
> 使用 CMake 和 Qt6 创建项目入口点和基本架构。

**触发的 SKILL：** `qt-architecture`

**AI 会做的：**
- 生成标准 `main.cpp`
- 生成 `CMakeLists.txt`
- 生成 `src/` 目录结构
- 展示 MVP 架构模式

---

### 🎨 阶段 3：UI 开发

**提示词：**
> 实现一个设置对话框，包含主题切换（深色/浅色模式）。

**触发的 SKILL：** `qt-dialogs` + `qt-styling`

**AI 会做的：**
- 使用 `qt-styling` 生成主题管理代码
- 使用 `qt-dialogs` 生成设置对话框
- 展示 `QSettings` 持久化

---

**提示词：**
> 用表格显示实时数据，每秒更新 1000 行，需要支持排序和筛选。

**触发的 SKILL：** `qt-model-view`

**AI 会做的：**
- 实现 `QAbstractTableModel` 子类
- 添加排序/筛选代理模型
- 配置 `QTableView`

---

### ⚙️ 阶段 4：信号与槽

**提示词：**
> 子线程采集到数据后，如何安全地更新主线程的 UI？

**触发的 SKILL：** `qt-signals-slots` + `qt-threading`

**AI 会做的：**
- 使用 Worker + QThread 模式
- 展示跨线程信号通信
- 包含线程安全的数据传递

---

### 🧪 阶段 5：单元测试

**提示词：**
> 为数据处理类 `DataProcessor` 添加 Mock 测试，需要 Mock 传感器接口。

**触发的 SKILL：** `mock-test`

**AI 会做的：**
1. 探索项目结构
2. 提取 `ISensor` 接口
3. 生成 `MockSensor` 类
4. 编写测试用例（GMock + QTest）
5. 集成到 CMake

---

### 📊 阶段 6：性能优化

**提示词：**
> 表格卡顿，1000 行数据更新时 UI 明显卡顿，如何优化？

**触发的 SKILL：** `performance-profiling`

**AI 会做的：**
1. 使用 `perf` 采样定位瓶颈
2. 分析是否需要批量更新/懒加载
3. 给出 Qt Model/View 优化建议

---

### 🐛 阶段 7：调试问题

**提示词：**
> Qt 应用在点击导出按钮后崩溃，提示 "QPixmap: Must construct a QGuiApplication before a QPaintDevice"。

**触发的 SKILL：** `qt-troubleshooting`

**AI 会做的：**
1. 收集问题信息
2. 分类为"图形上下文问题"
3. 调用 `qt-debugging` 获取具体诊断技术
4. 指导修复方案
5. 生成问题解决报告

---

### 📦 阶段 8：打包分发

**提示词：**
> 将应用打包为 Windows 可执行文件，使用 Release 构建。

**触发的 SKILL：** `qt-packaging`

**AI 会做的：**
- 配置 CMake Release 构建
- 使用 `windeployqt` 部署 Qt 依赖
- 生成自包含安装包

---

### 📄 阶段 9：生成文档

**提示词：**
> 生成一份用户使用手册，包含截图和操作说明，输出为 PDF。

**触发的 SKILL：** `markdown-doc` → `file-pdf`

**AI 会做的：**
1. 使用 `markdown-doc` 生成 Markdown 文档（含截图命令占位符）
2. 使用 `file-pdf` 将 Markdown 转换为高视觉质量的 PDF

---

## 四、SKILL 快速索引

| 需求场景 | 推荐 SKILL |
|---------|----------|
| 新项目需求分析 | `requirements-analysis` |
| 技术方案选型 | `tech-selection` |
| Qt 项目结构搭建 | `qt-architecture` |
| Qt UI 布局与对话框 | `qt-layouts` + `qt-dialogs` |
| Qt 主题/样式定制 | `qt-styling` |
| Qt 表格/列表/树 | `qt-model-view` |
| QML/Qt Quick 开发 | `qt-qml` |
| Qt 信号与槽/跨线程 | `qt-signals-slots` + `qt-threading` |
| Qt 资源文件打包 | `qt-resources` |
| Qt 设置持久化 | `qt-settings` |
| Qt 单元测试 | `qtest-patterns` |
| Mock 测试 | `mock-test` |
| 测试覆盖率分析 | `qt-coverage-workflow` |
| Qt 问题诊断 | `qt-troubleshooting` |
| Qt 调试技术 | `qt-debugging` |
| 性能剖析优化 | `performance-profiling` |
| Qt 应用打包分发 | `qt-packaging` |
| 嵌入式 C++ 开发 | `embedded-dev` |
| Markdown 文档（图表） | `markdown-doc` |
| Word 文档 | `file-docx` |
| PDF 文档 | `file-pdf` |
| PowerPoint 幻灯片 | `file-pptx` |
| Excel 表格 | `file-xlsx` |
| Web 前端开发 | `frontend-dev` |
| 全栈后端开发 | `fullstack-dev` |

---

*最后更新：2026-03-26*