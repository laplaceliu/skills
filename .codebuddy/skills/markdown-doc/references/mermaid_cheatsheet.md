# Mermaid 语法速查表

## 流程图 (Flowchart)

### 方向

| 方向 | 说明 |
|------|------|
| `TD` / `TB` | 从上到下 (Top-Down / Top-Bottom) |
| `BT` | 从下到上 (Bottom-Top) |
| `LR` | 从左到右 (Left-Right) |
| `RL` | 从右到左 (Right-Left) |

### 节点形状

```mermaid
graph TD
    A[矩形节点]
    B(圆角矩形)
    C([体育场形])
    D[[双括号]]
    E[(圆形)]
    F{菱形判断}
    G{{六角形}}
```

### 连线样式

```mermaid
graph TD
    A --> B          %% 箭头实线
    A --- B          %% 无箭头实线
    A -.-> B         %% 虚线箭头
    A -. B           %% 虚线无箭头
    A ==> B          %% 加粗箭头
    A == B           %% 加粗无箭头
    A -- 标签 --> B  %% 带标签箭头
    A --->|标签| B   %% 带标签箭头 (替代语法)
```

### 子图

```mermaid
graph TB
    subgraph 子系统A
        A1 --> A2
    end
    subgraph 子系统B
        B1 --> B2
    end
    A2 --> B1
```

---

## 时序图 (Sequence Diagram)

```mermaid
sequenceDiagram
    participant 参与者 as 别名
    participant 后端

    参与者->>后端: 同步请求 (实线箭头)
    参与者-->>后端: 响应 (虚线)
    后端->>后端: 内部处理
    参与者->>+后端: 带序号的调用
    后端-->>-参与者: 返回

    Note over 参与者,后端: 跨参与者备注
    Note right of 后端: 单侧备注
```

### 时序图控制

```mermaid
sequenceDiagram
    loop 循环条件
        A --> B: 循环内操作
    end

    alt 条件1
        A --> B: 分支1
    else 条件2
        A --> B: 分支2
    else
        A --> B: 默认分支
    end

    opt 可选
        A --> B: 可选操作
    end
```

---

## 类图 (Class Diagram)

```mermaid
classDiagram
    class Animal {
        +String name
        +int age
        +makeSound()
        +feed()
    }

    class Dog {
        +String breed
        +bark()
    }

    class Cat {
        +boolean indoor
        +meow()
    }

    Animal <|-- Dog : 继承
    Animal <|-- Cat : 继承
    Animal <|>| 企鹅 : 多态
```

### 关系符号

| 符号 | 关系 |
|------|------|
| `<|--` | 继承 |
| `*--` | 组合 (Composition) |
| `o--` | 聚合 (Aggregation) |
| `-->` | 关联 (Association) |
| `-->` | 依赖 (Dependency) |
| `..>` | 实现 (Realization) |
| `..` | 虚线 (Linetype) |

---

## 状态图 (State Diagram)

```mermaid
stateDiagram-v2
    [*] --> 初始状态

    初始状态 --> 运行中 : 启动
    运行中 --> 暂停 : 暂停命令
    暂停 --> 运行中 : 继续命令
    运行中 --> [*] : 停止

    运行中 --> 错误 : 异常发生
    错误 --> 运行中 : 恢复
```

### 分支状态

```mermaid
stateDiagram
    [*] --> 活动
    活动 --> if (条件) uthen 分支1: 条件满足
    if (条件) --> 分支2: 条件不满足
    分支1 --> [*]
    分支2 --> [*]
```

---

## ER 图 (ER Diagram)

```mermaid
erDiagram
    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ LINE-ITEM : contains
    PRODUCT ||--o{ LINE-ITEM : "is in"

    CUSTOMER {
        int id PK
        string name
        string email
    }

    ORDER {
        int id PK
        date created
        string status
    }
```

---

## 甘特图 (Gantt)

```mermaid
gantt
    title 项目计划
    dateFormat YYYY-MM-DD
    section 设计
    需求分析       :a1, 2024-01-01, 7d
    系统设计       :a2, after a1, 10d
    section 开发
    编码实现       :b1, after a2, 15d
    单元测试       :b2, 2024-02-01, 5d
    section 部署
    集成测试       :c1, after b1, 5d
    上线发布       :c2, after c1, 2d
```

---

## 饼图 (Pie)

```mermaid
pie title 市场份额
    "产品A" : 45
    "产品B" : 30
    "产品C" : 15
    "其他" : 10
```

---

## Git 图表

```mermaid
gitGraph
    commit id: "初始提交"
    branch feature
    checkout feature
    commit id: "新功能开发"
    checkout main
    merge feature id: "合并新功能"
    commit id: "修复bug" type: HIGHLIGHT
    commit id: "上线准备"
```

---

## 提示技巧

1. **ID 和标签**: 节点 ID 必须是单字母或单词；标签可以是中文
2. **转义字符**: 特殊字符用双引号包裹或转义
3. **注释**: 使用 `%%` 添加注释
4. **多行文本**: 使用 `br` 换行

```mermaid
graph LR
    A["节点<br/>换行"] --> B["特殊>字符"]
    %% 这是注释
```
