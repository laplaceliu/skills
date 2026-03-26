# Kroki 渲染脚本使用说明

## 快速开始

### 1. 启动 Kroki 服务

在项目根目录创建 `docker-compose.kroki.yml`：

```yaml
version: '3.8'
services:
  kroki:
    image: yuzutech/kroki
    container_name: kroki
    ports:
      - "8080:8080"
    environment:
      - KROKI_MERMAID_WIDTH=800
      - KROKI_MERMAID_HEIGHT=600
    restart: unless-stopped
```

启动服务：

```bash
docker compose -f docker-compose.kroki.yml up -d
```

### 2. 安装依赖

```bash
pip install requests pyyaml
```

### 3. 基本用法

```bash
# 单个图表渲染
python scripts/kroki_render.py \
  --type mermaid \
  --content "graph TD; A[开始] --> B[结束]" \
  --output output/flowchart.png

# 从文件读取
python scripts/kroki_render.py \
  --type mermaid \
  --input diagrams/auth_flow.mmd \
  --output output/auth_flow.png
```

## 支持的图表类型

| 类型 | 说明 | 示例语法 |
|------|------|---------|
| mermaid | Mermaid 图表 | `graph TD; A --> B` |
| plantuml | PlantUML | `@startuml ... @enduml` |
| graphviz | Graphviz DOT | `digraph { ... }` |
| wavedrom | WaveDrom 时序图 | `{signal: [...]}` |
| structurizr | Structurizr DSL | `model { ... }` |

## 批量渲染

创建配置文件 `diagrams.yml`：

```yaml
diagrams:
  - name: auth_flow
    type: mermaid
    input: diagrams/auth_flow.mmd
    output: output/auth_flow.png

  - name: sequence
    type: mermaid
    content: |
      sequenceDiagram
        participant U as 用户
        participant S as 服务
        U->>S: 登录请求
        S-->>U: Token

  - name: architecture
    type: plantuml
    input: diagrams/arch.puml
    output: output/arch.png
```

执行批量渲染：

```bash
python scripts/kroki_render.py --config diagrams.yml --output ./output/
```

## 常见问题

### Q: 连接被拒绝

确保 Kroki Docker 服务正在运行：

```bash
docker ps | grep kroki
docker compose -f docker-compose.kroki.yml logs kroki
```

### Q: 输出格式选择

- **PNG**: 通用性好，适合嵌入文档
- **SVG**: 矢量图形，适合网页
- **PDF**: 适合打印和高分辨率输出
