---
name: fullstack-dev-api-design
description: "API 设计模式与最佳实践。在创建端点、选择方法/状态码、实现分页或编写 OpenAPI 规范时使用。预防常见的 REST/GraphQL/gRPC 错误。"
license: MIT
metadata:
  version: "2.0.0"
  sources:
    - Microsoft REST API Guidelines
    - Google API Design Guide
    - Zalando RESTful API Guidelines
    - JSON:API Specification
    - RFC 9457 (Problem Details for HTTP APIs)
    - RFC 9110 (HTTP Semantics)
---

# API 设计指南

面向后端和全栈工程师的框架无关 API 设计指南。涵盖 10 个类别的 50+ 条规则，按影响程度优先排序。覆盖 REST、GraphQL 和 gRPC。

## 适用范围

**使用此技能的情况:**
- 设计新 API 或添加端点
- 审查 API 拉取请求
- 在 REST / GraphQL / gRPC 之间选择
- 编写 OpenAPI 规范
- 迁移或版本控制现有 API

**不适用的情况:**
- 框架特定的实现细节 (使用你框架自己的技能/文档)
- 前端数据获取模式 (使用 React Query / SWR 文档)
- 认证实现细节 (使用你认证库的文档)
- 数据库模式设计 (→ `database-schema-design`)

## 所需上下文

在应用此技能前，收集以下信息:

| 必需 | 可选 |
|----------|----------|
| 目标消费者 (浏览器、移动端、服务) | 项目中现有的 API 约定 |
| 预期请求量 (RPS 估算) | 当前的 OpenAPI / Swagger 规范 |
| 认证方式 (JWT、API 密钥、OAuth) | 速率限制要求 |
| 数据模型 / 领域实体 | 缓存策略 |

---

## 快速开始清单

新 API 端点? 在编写代码前运行以下检查:

- [ ] 资源命名为**复数名词** (`/orders`, 非 `/getOrders`)
- [ ] URL 使用**短横线命名法**，主体字段使用**驼峰命名法**
- [ ] 正确的 **HTTP 方法** (GET=读取, POST=创建, PUT=替换, PATCH=部分更新, DELETE=删除)
- [ ] 正确的**状态码** (201 Created, 422 Validation, 404 Not Found…)
- [ ] 错误响应遵循 **RFC 9457** 信封格式
- [ ] 所有列表端点都有**分页** (默认 20, 最大 100)
- [ ] 需要**认证** (Bearer 令牌, 非查询参数)
- [ ] 响应头中包含 **Request ID** (`X-Request-Id`)
- [ ] 包含 **Rate limit** 响应头
- [ ] 端点已在 **OpenAPI 规范**中记录

---

## 快速导航

| 需要… | 跳转到 |
|----------|---------|
| 命名资源 URL | [1. 资源建模](#1-资源建模-关键) |
| 选择 HTTP 方法 + 状态码 | [3. HTTP 方法与状态码](#3-http-方法与状态码-关键) |
| 格式化错误响应 | [4. 错误处理](#4-错误处理-高) |
| 添加分页或过滤 | [6. 分页与过滤](#6-分页与过滤-高) |
| 选择 API 风格 (REST vs GraphQL vs gRPC) | [10. API 风格决策](#10-api-风格决策树) |
| 版本控制现有 API | [7. 版本控制](#7-版本控制-中-高) |
| 避免常见错误 | [反模式](#反模式清单) |

---

## 1. 资源建模 (关键)

### 核心规则

```
/users                         — 复数名词
/users/{id}/orders              — 1 级嵌套
/reviews?orderId={oid}          — 使用查询参数扁平化深层嵌套

/getUsers                       — URL 中包含动词
/user                           — 单数
/users/{uid}/orders/{oid}/items/{iid}/reviews  — 3+ 层深度
```

**最大嵌套: 2 层。** 超过则提升为顶级资源并使用过滤器。

### 领域对齐

资源映射到**领域概念**，而非数据库表:

```
/checkout-sessions       (领域聚合)
/shipping-labels          (领域概念)

/tbl_order_header          (数据库表泄漏)
/join_user_role            (内部模式泄漏)
```

---

## 2. URL 与命名 (关键)

| 上下文 | 约定 | 示例 |
|---------|-----------|---------|
| URL 路径 | 短横线命名法 | `/order-items` |
| JSON 主体字段 | 驼峰命名法 | `{ "firstName": "Jane" }` |
| 查询参数 | 驼峰命名法或蛇形命名法 (保持一致) | `?sortBy=createdAt` |
| 响应头 | 首字母大写命名法 | `X-Request-Id` |

**Python 例外:** 如果你的整个技术栈是 Python/蛇形命名法，你可以在 JSON 中使用 `snake_case` — 但在**所有端点中保持一致**。

```
GET /users          GET /users/
GET /reports/annual  GET /reports/annual.json
POST /users          POST /users/create
```

---

## 3. HTTP 方法与状态码 (关键)

### 方法语义

| 方法 | 语义 | 幂等 | 安全 | 请求体 |
|--------|-----------|-----------|------|-------------|
| GET | 读取 |  |  |  Never |
| POST | 创建 / 操作 |  |  |  Always |
| PUT | 完全替换 |  |  |  Always |
| PATCH | 部分更新 | * |  |  Always |
| DELETE | 删除 |  |  |  Rarely |

### 状态码快速参考

**成功:**

| 代码 | 何时使用 | 响应体 |
|------|------|--------------|
| 200 OK | GET, PUT, PATCH 成功 | 资源 / 结果 |
| 201 Created | POST 创建资源 | 创建的资源 + `Location` 响应头 |
| 202 Accepted | 异步操作已启动 | 任务 ID / 状态 URL |
| 204 No Content | DELETE 成功, PUT 无响应体 | 无 |

**客户端错误:**

| 代码 | 何时使用 | 关键区别 |
|------|------|-----------------|
| 400 Bad Request | 语法格式错误 | 无法解析 |
| 401 Unauthorized | 缺少/无效认证 | "你是谁?" |
| 403 Forbidden | 已认证, 无权限 | "我认识你, 但不行" |
| 404 Not Found | 资源不存在 | 也用于隐藏 403 |
| 409 Conflict | 重复, 版本不匹配 | 状态冲突 |
| 422 Unprocessable | 语法正确, 验证失败 | 语义错误 |
| 429 Too Many Requests | 触发速率限制 | 包含 `Retry-After` |

**服务端错误:** 500 (意外错误), 502 (上游失败), 503 (过载), 504 (上游超时)

---

## 4. 错误处理 (高)

### 标准错误信封 (RFC 9457)

每个错误响应使用此格式:

```json
{
  "type": "https://api.example.com/errors/insufficient-funds",
  "title": "Insufficient Funds",
  "status": 422,
  "detail": "Account balance $10.00 is less than withdrawal $50.00.",
  "instance": "/transactions/txn_abc123",
  "request_id": "req_7f3a8b2c",
  "errors": [
    { "field": "amount", "message": "Exceeds balance", "code": "INSUFFICIENT_BALANCE" }
  ]
}
```

### 多语言实现

**TypeScript (Express):**
```typescript
class AppError extends Error {
  constructor(
    public readonly title: string,
    public readonly status: number,
    public readonly detail: string,
    public readonly code: string,
  ) { super(detail); }
}

// 中间件
app.use((err, req, res, next) => {
  if (err instanceof AppError) {
    return res.status(err.status).json({
      type: `https://api.example.com/errors/${err.code}`,
      title: err.title, status: err.status,
      detail: err.detail, request_id: req.id,
    });
  }
  res.status(500).json({ title: 'Internal Error', status: 500, request_id: req.id });
});
```

**Python (FastAPI):**
```python
from fastapi import Request
from fastapi.responses import JSONResponse

class AppError(Exception):
    def __init__(self, title: str, status: int, detail: str, code: str):
        self.title, self.status, self.detail, self.code = title, status, detail, code

@app.exception_handler(AppError)
async def app_error_handler(request: Request, exc: AppError):
    return JSONResponse(status_code=exc.status, content={
        "type": f"https://api.example.com/errors/{exc.code}",
        "title": exc.title, "status": exc.status,
        "detail": exc.detail, "request_id": request.state.request_id,
    })
```

### 铁律

```
为所有错误返回 RFC 9457 错误信封
在每个错误响应中包含 request_id
在 `errors` 数组中返回字段级验证错误

绝不在生产环境暴露堆栈跟踪
绝不为错误返回 200
绝不静默吞掉错误
```

---

## 5. 认证与授权 (高)

```
Authorization: Bearer eyJhbGci...      (响应头)
GET /users?token=eyJhbGci...            (URL — 出现在日志中)

401 → "你是谁?"  (缺少/无效凭证)
403 → "你不能这样做"  (已认证, 无权限)
404 → 隐藏资源存在性  (需要时替代 403)
```

**速率限制响应头 (始终包含):**
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 42
X-RateLimit-Reset: 1625097600
Retry-After: 30
```

---

## 6. 分页与过滤 (高)

### 游标 vs 偏移量

| 策略 | 何时使用 | 优点 | 缺点 |
|----------|------|------|------|
| **游标** (推荐) | 大型/动态数据集 | 一致, 无跳过 | 无法跳转到第 N 页 |
| **偏移量** | 小型/稳定数据集, 管理后台 UI | 简单, 可跳转页面 | 插入/删除时漂移 |

**游标分页响应:**
```json
{
  "data": [...],
  "pagination": { "next_cursor": "eyJpZCI6MTIwfQ", "has_more": true }
}
```

**偏移量分页响应:**
```json
{
  "data": [...],
  "pagination": { "page": 3, "per_page": 20, "total": 256, "total_pages": 13 }
}
```

**始终强制执行:** 默认 20 条, 最大 100 条。

### 标准过滤模式

```
GET /orders?status=shipped&created_after=2025-01-01&sort=-created_at&fields=id,status
```

| 模式 | 约定 |
|---------|-----------|
| 精确匹配 | `?status=shipped` |
| 范围 | `?price_gte=10&price_lte=100` |
| 日期范围 | `?created_after=2025-01-01&created_before=2025-12-31` |
| 排序 | `?sort=field` (升序), `?sort=-field` (降序) |
| 稀疏字段 | `?fields=id,name,email` |
| 搜索 | `?q=search+term` |

---

## 7. 版本控制 (中-高)

| 策略 | 格式 | 最适合 |
|----------|--------|----------|
| **URL 路径** (推荐) | `/v1/users` | 公开 API |
| **响应头** | `Api-Version: 2` | 内部 API |
| **查询参数** | `?version=2` | 遗留系统 (避免) |

**非破坏性变更 (无需版本升级):** 新增可选响应字段, 新端点, 新增可选参数。

**破坏性变更 (需要新版本):** 删除/重命名字段, 更改类型, 更严格的验证, 删除端点。

**弃用响应头:**
```
Sunset: Sat, 01 Mar 2026 00:00:00 GMT
Deprecation: true
Link: <https://api.example.com/v2/users>; rel="successor-version"
```

---

## 8. 请求 / 响应设计 (中)

### 一致的信封

```json
{
  "data": { "id": "ord_123", "status": "pending", "total": 99.50 },
  "meta": { "request_id": "req_abc123", "timestamp": "2025-06-15T10:30:00Z" }
}
```

### 关键规则

| 规则 | 正确 | 错误 |
|------|---------|-------|
| 时间戳 | `"2025-06-15T10:30:00Z"` (ISO 8601) | `"06/15/2025"` 或 `1718447400` |
| 公开 ID | UUID `"550e8400-..."` | 自增 `42` |
| Null vs 缺失 (PATCH) | `{ "nickname": null }` = 清空字段 | 缺失字段 = 不更改 |
| HATEOAS (公开 API) | `"links": { "cancel": "/orders/123/cancel" }` | 无可发现性 |

---

## 9. 文档 — OpenAPI (中)

**设计优先工作流:**

```
1. 编写 OpenAPI 3.1 规范
2. 与利益相关者审查规范
3. 生成服务端存根 + 客户端 SDK
4. 实现处理器
5. 在 CI 中验证响应是否符合规范
```

每个端点文档包括: 摘要, 所有参数, 请求体 + 示例, 所有响应代码 + 模式, 认证要求。

---

## 10. API 风格决策树

```
什么类型的 API?
│
├─ 浏览器 + 移动客户端, 灵活查询
│   └─ GraphQL
│       规则: DataLoader (防止 N+1), 深度限制 ≤7, Relay 分页
│
├─ 标准 CRUD, 公开消费者, 缓存重要
│   └─ REST (本指南)
│       规则: 资源, HTTP 方法, 状态码, OpenAPI
│
├─ 服务间通信, 高吞吐量, 强类型
│   └─ gRPC
│       规则: Protobuf 模式, 大数据流式, 截止时间
│
├─ 全栈 TypeScript, 同一团队维护客户端 + 服务端
│   └─ tRPC
│       规则: 共享类型, 无需代码生成
│
└─ 实时双向
    └─ WebSocket / SSE
        规则: 心跳, 重连, 消息排序
```

---

## 反模式清单

| # |  不要 |  应该这样做 |
|---|---------|--------------|
| 1 | URL 中使用动词 (`/getUser`) | HTTP 方法 + 名词资源 |
| 2 | 为错误返回 200 | 正确的 4xx/5xx 状态码 |
| 3 | 混合命名风格 | 每个上下文一种约定 |
| 4 | 暴露数据库 ID | 公开标识符使用 UUID |
| 5 | 列表无分页 | 始终分页 (默认 20) |
| 6 | 静默吞掉错误 | 结构化的 RFC 9457 错误 |
| 7 | 令牌放在 URL 查询参数中 | Authorization 响应头 |
| 8 | 深层嵌套 (3+ 层) | 使用查询参数扁平化 |
| 9 | 无版本控制的破坏性变更 | 保持兼容性或版本控制 |
| 10 | 无限速 | 实现并通过响应头传达 |
| 11 | 无请求 ID | 每个响应都带 `X-Request-Id` |
| 12 | 生产环境暴露堆栈跟踪 | 安全错误消息 + 内部日志 |

---

## 常见问题

### 问题 1: "这应该是新资源还是子资源?"

**症状:** URL 路径不断增长 (`/users/{id}/orders/{id}/items/{id}/reviews`)

**规则:** 如果子实体独立有意义，则提升它。如果它只存在于父上下文中，则保持嵌套 (最多 2 层)。

```
/reviews?orderId=123      (reviews 独立存在)
/orders/{id}/items         (items 属于 orders, 1 层)
```

### 问题 2: "PUT 还是 PATCH?"

**症状:** 团队无法就更新语义达成一致。

**规则:**
- PUT = 客户端发送**完整**资源 (缺失字段 → 设为默认值/null)
- PATCH = 客户端发送**仅更改的字段** (缺失字段 → 不变)
- 不确定时 → **PATCH** (更安全, 更不容易令人惊讶)

### 问题 3: "400 还是 422?"

**症状:** 验证错误代码不一致。

**规则:**
- 400 = 根本无法解析请求 (格式错误的 JSON, 错误的 content-type)
- 422 = 解析成功, 但值验证失败 (无效邮箱, 负数数量)
