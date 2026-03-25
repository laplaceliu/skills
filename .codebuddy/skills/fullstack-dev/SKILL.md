---
name: fullstack-dev
description: |
  全栈后端架构与前后端集成指南。
  触发条件: 构建全栈应用、创建带前端的 REST API、搭建后端服务、
  构建待办应用、构建 CRUD 应用、构建实时应用、构建聊天应用、
  Express + React、Next.js API、Node.js 后端、Python 后端、Go 后端、
  设计服务层、实现错误处理、管理配置/认证、
  设置 API 客户端、实现认证流程、处理文件上传、
  添加实时功能 (SSE/WebSocket)、生产环境加固。
  不触发条件: 纯前端 UI 工作、纯 CSS/样式、仅数据库模式设计。
license: MIT
metadata:
  category: full-stack
  version: "1.0.0"
  sources:
    - The Twelve-Factor App (12factor.net)
    - Clean Architecture (Robert C. Martin)
    - Domain-Driven Design (Eric Evans)
    - Patterns of Enterprise Application Architecture (Martin Fowler)
    - Martin Fowler (Testing Pyramid, Contract Tests)
    - Google SRE Handbook (Release Engineering)
    - ThoughtWorks Technology Radar
---

# 全栈开发实践

## 强制工作流 — 按顺序执行以下步骤

**当此技能被触发时，在编写任何代码前必须遵循此工作流。**

### 第 0 步: 收集需求

在开始搭建项目之前，请用户明确（或从上下文中推断）:

1. **技术栈**: 后端和前端的语言/框架 (如 Express + React、Django + Vue、Go + HTMX)
2. **服务类型**: 纯 API、全栈单体还是微服务?
3. **数据库**: SQL (PostgreSQL、SQLite、MySQL) 还是 NoSQL (MongoDB、Redis)?
4. **集成方式**: REST、GraphQL、tRPC 还是 gRPC?
5. **实时功能**: 是否需要? 如需 — 使用 SSE、WebSocket 还是轮询?
6. **认证**: 是否需要? 如需 — 使用 JWT、session、OAuth 还是第三方 (Clerk、Auth.js)?

如果用户已在请求中说明这些，跳过询问直接继续。

### 第 1 步: 架构决策

根据需求，在编码前做出并说明以下决策:

| 决策项 | 选项 | 参考 |
|--------|------|------|
| 项目结构 | 特性优先 (推荐) vs 分层优先 | [第 1 节](#1-项目结构与分层-关键) |
| API 客户端方案 | 类型化 fetch / React Query / tRPC / OpenAPI 代码生成 | [第 5 节](#5-api-客户端模式-中等) |
| 认证策略 | JWT + 刷新 / session / 第三方 | [第 6 节](#6-认证与中间件-高) |
| 实时方案 | 轮询 / SSE / WebSocket | [第 11 节](#11-实时模式-中等) |
| 错误处理 | 类型化错误层次 + 全局处理器 | [第 3 节](#3-错误处理与弹性-高) |

简要解释每个选择 (每项 1 句话)。

### 第 2 步: 使用清单搭建项目

使用下方合适的清单。确保所有勾选项都已实现 — 不要跳过任何一项。

### 第 3 步: 按模式实现

编写代码时遵循本文档中的模式。实现各部分时引用具体章节。

### 第 4 步: 测试与验证

实现完成后，在声称完成前运行以下检查:

1. **构建检查**: 确保前后端都能无错误编译
   ```bash
   # 后端
   cd server && npm run build
   # 前端
   cd client && npm run build
   ```
2. **启动与冒烟测试**: 启动服务器，验证关键端点返回预期响应
   ```bash
   # 启动服务器，然后测试
   curl http://localhost:3000/health
   curl http://localhost:3000/api/<resource>
   ```
3. **集成检查**: 验证前端能连接到后端 (CORS、API 基础 URL、认证流程)
4. **实时功能检查** (如适用): 打开两个浏览器标签，验证变更同步

如有任何检查失败，先修复问题再继续。

### 第 5 步: 移交摘要

向用户提供简要摘要:

- **已完成**: 实现的功能和端点列表
- **如何运行**: 启动前后端的精确命令
- **缺失项/后续步骤**: 任何延期项目、已知限制或建议改进
- **关键文件**: 用户应了解的最重要的文件列表

---

## 适用范围

**使用此技能的情况:**
- 构建全栈应用 (后端 + 前端)
- 搭建新的后端服务或 API
- 设计服务层和模块边界
- 实现数据库访问、缓存或后台任务
- 编写错误处理、日志记录或配置管理
- 审查后端代码的架构问题
- 生产环境加固
- 设置 API 客户端、认证流程、文件上传或实时功能

**不适用的情况:**
- 纯前端/UI 问题 (使用你前端框架的文档)
- 无后端上下文的纯数据库模式设计

---

## 快速开始 — 新后端服务清单

- [ ] 使用**特性优先**结构搭建项目
- [ ] 配置**集中式**管理，环境变量**在启动时验证** (快速失败)
- [ ] 定义**类型化错误层次** (非通用 `Error`)
- [ ] 添加**全局错误处理**中间件
- [ ] 带请求 ID 传播的**结构化 JSON 日志**
- [ ] 数据库: 设置**迁移**，配置**连接池**
- [ ] 所有端点的**输入验证** (Zod / Pydantic / Go validator)
- [ ] 添加**认证中间件**
- [ ] **健康检查**端点 (`/health`, `/ready`)
- [ ] **优雅关闭**处理 (SIGTERM)
- [ ] 配置 **CORS** (显式指定来源，非 `*`)
- [ ] **安全响应头** (helmet 或等效方案)
- [ ] 提交 `.env.example` (不含真实密钥)

## 快速开始 — 前后端集成清单

- [ ] 配置 **API 客户端** (类型化 fetch 包装、React Query、tRPC 或 OpenAPI 生成)
- [ ] **基础 URL** 来自环境变量 (非硬编码)
- [ ] **认证令牌** 自动附加到请求 (拦截器 / 中间件)
- [ ] **错误处理** — API 错误映射到用户友好的消息
- [ ] 处理 **加载状态** (骨架屏/加载动画，非空白屏幕)
- [ ] 跨边界的**类型安全** (共享类型、OpenAPI 或 tRPC)
- [ ] **CORS** 配置显式来源 (生产环境非 `*`)
- [ ] 实现 **刷新令牌** 流程 (httpOnly cookie + 401 时自动重试)

---

## 快速导航

| 需要… | 跳转到 |
|-------|--------|
| 组织项目文件夹 | [1. 项目结构](#1-项目结构与分层-关键) |
| 管理配置 + 密钥 | [2. 配置](#2-配置与环境-关键) |
| 正确处理错误 | [3. 错误处理](#3-错误处理与弹性-高) |
| 编写数据库代码 | [4. 数据库访问模式](#4-数据库访问模式-高) |
| 从前端设置 API 客户端 | [5. API 客户端模式](#5-api-客户端模式-中等) |
| 添加认证中间件 | [6. 认证与中间件](#6-认证与中间件-高) |
| 设置日志 | [7. 日志与可观测性](#7-日志与可观测性-中-高) |
| 添加后台任务 | [8. 后台任务](#8-后台任务与异步-中等) |
| 实现缓存 | [9. 缓存](#9-缓存模式-中等) |
| 上传文件 (预签名 URL、分片) | [10. 文件上传模式](#10-文件上传模式-中等) |
| 添加实时功能 (SSE、WebSocket) | [11. 实时模式](#11-实时模式-中等) |
| 在前端 UI 处理 API 错误 | [12. 跨边界错误处理](#12-跨边界错误处理-中等) |
| 生产环境加固 | [13. 生产加固](#13-生产加固-中等) |
| 设计 API 端点 | [API 设计](references/api-design.md) |
| 设计数据库模式 | [数据库模式](references/db-schema.md) |
| 认证流程 (JWT、刷新、Next.js SSR、RBAC) | [references/auth-flow.md](references/auth-flow.md) |
| CORS、环境变量、环境管理 | [references/environment-management.md](references/environment-management.md) |

---

## 核心原则 (7 条铁律)

```
1. 按特性组织，不按技术层组织
2. 控制器绝不含业务逻辑
3. 服务绝不导入 HTTP 请求/响应类型
4. 所有配置来自环境变量，启动时验证，快速失败
5. 每个错误都有类型、记录日志，并返回统一格式
6. 在边界处验证所有输入 — 不信任来自客户端的任何内容
7. 结构化 JSON 日志带请求 ID — 不用 console.log
```

---

## 1. 项目结构与分层 (关键)

### 特性优先组织

```
特性优先                    分层优先
src/                        src/
  orders/                     controllers/
    order.controller.ts         order.controller.ts
    order.service.ts            user.controller.ts
    order.repository.ts       services/
    order.dto.ts                order.service.ts
    order.test.ts               user.service.ts
  users/                      repositories/
    user.controller.ts          ...
    user.service.ts
  shared/
    database/
    middleware/
```

### 三层架构

```
控制器 (HTTP) → 服务 (业务逻辑) → 仓库 (数据访问)
```

| 层 | 职责 | 绝不 |
|-----|-------|------|
| 控制器 | 解析请求、验证、调用服务、格式化响应 | 业务逻辑、数据库查询 |
| 服务 | 业务规则、编排、事务管理 | HTTP 类型 (req/res)、直接数据库访问 |
| 仓库 | 数据库查询、外部 API 调用 | 业务逻辑、HTTP 类型 |

### 依赖注入 (所有语言)

**TypeScript:**
```typescript
class OrderService {
  constructor(
    private readonly orderRepo: OrderRepository,    // 注入接口
    private readonly emailService: EmailService,
  ) {}
}
```

**Python:**
```python
class OrderService:
    def __init__(self, order_repo: OrderRepository, email_service: EmailService):
        self.order_repo = order_repo                 # 已注入
        self.email_service = email_service
```

**Go:**
```go
type OrderService struct {
    orderRepo    OrderRepository                      // 接口
    emailService EmailService
}

func NewOrderService(repo OrderRepository, email EmailService) *OrderService {
    return &OrderService{orderRepo: repo, emailService: email}
}
```

---

## 2. 配置与环境 (关键)

### 集中式、类型化、快速失败

**TypeScript:**
```typescript
const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  database: { url: requiredEnv('DATABASE_URL'), poolSize: intEnv('DB_POOL_SIZE', 10) },
  auth: { jwtSecret: requiredEnv('JWT_SECRET'), expiresIn: process.env.JWT_EXPIRES_IN || '1h' },
} as const;

function requiredEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var: ${name}`);  // 快速失败
  return value;
}
```

**Python:**
```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    database_url: str                        # 必需 — 缺失则应用无法启动
    jwt_secret: str                          # 必需
    port: int = 3000                         # 可选，有默认值
    db_pool_size: int = 10
    class Config:
        env_file = ".env"

settings = Settings()                        # 如 DATABASE_URL 缺失则快速失败
```

### 规则

```
所有配置通过环境变量 (十二要素)
启动时验证必需变量 — 快速失败
在配置层进行类型转换，非使用处
提交带虚拟值的 .env.example

绝不硬编码密钥、URL 或凭证
绝不提交 .env 文件
绝不在代码中散布 process.env / os.environ
```

---

## 3. 错误处理与弹性 (高)

### 类型化错误层次

```typescript
// 基础 (TypeScript)
class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly statusCode: number,
    public readonly isOperational: boolean = true,
  ) { super(message); }
}
class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(`${resource} not found: ${id}`, 'NOT_FOUND', 404);
  }
}
class ValidationError extends AppError {
  constructor(public readonly errors: FieldError[]) {
    super('Validation failed', 'VALIDATION_ERROR', 422);
  }
}
```

```python
# 基础 (Python)
class AppError(Exception):
    def __init__(self, message: str, code: str, status_code: int):
        self.message, self.code, self.status_code = message, code, status_code

class NotFoundError(AppError):
    def __init__(self, resource: str, id: str):
        super().__init__(f"{resource} not found: {id}", "NOT_FOUND", 404)
```

### 全局错误处理器

```typescript
// TypeScript (Express)
app.use((err, req, res, next) => {
  if (err instanceof AppError && err.isOperational) {
    return res.status(err.statusCode).json({
      title: err.code, status: err.statusCode,
      detail: err.message, request_id: req.id,
    });
  }
  logger.error('Unexpected error', { error: err.message, stack: err.stack, request_id: req.id });
  res.status(500).json({ title: 'Internal Error', status: 500, request_id: req.id });
});
```

### 规则

```
类型化、领域特定的错误类
全局错误处理器捕获所有错误
运维错误 → 结构化响应
程序错误 → 记录日志 + 通用 500
使用指数退避重试瞬时失败

绝不静默捕获并忽略错误
绝不在客户端暴露堆栈跟踪
绝不抛出通用 Error('something')
```

---

## 4. 数据库访问模式 (高)

### 始终使用迁移

```bash
# TypeScript (Prisma)           # Python (Alembic)              # Go (golang-migrate)
npx prisma migrate dev          alembic revision --autogenerate  migrate -source file://migrations
npx prisma migrate deploy       alembic upgrade head             migrate -database $DB up
```

```
通过迁移进行模式变更，绝不手动 SQL
迁移必须可逆
生产环境前审查迁移 SQL
绝不手动修改生产模式
```

### 防止 N+1

```typescript
// N+1: 1 次查询 + N 次查询
const orders = await db.order.findMany();
for (const o of orders) { o.items = await db.item.findMany({ where: { orderId: o.id } }); }

// 单次 JOIN 查询
const orders = await db.order.findMany({ include: { items: true } });
```

### 多步写入使用事务

```typescript
await db.$transaction(async (tx) => {
  const order = await tx.order.create({ data: orderData });
  await tx.inventory.decrement({ productId, quantity });
  await tx.payment.create({ orderId: order.id, amount });
});
```

### 连接池

连接池大小 = `(CPU 核心数 × 2) + 磁盘数` (从 10-20 开始)。始终设置连接超时。无服务器环境使用 PgBouncer。

---

## 5. API 客户端模式 (中等)

前后端之间的"胶水层"。选择适合你团队和技术的方案。

### 选项 A: 类型化 Fetch 包装器 (简单，无依赖)

```typescript
// lib/api-client.ts
const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001';

class ApiError extends Error {
  constructor(public status: number, public body: any) {
    super(body?.detail || body?.message || `API error ${status}`);
  }
}

async function api<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getAuthToken();  // 从 cookie / 内存 / 上下文获取

  const res = await fetch(`${BASE_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...options.headers,
    },
  });

  if (!res.ok) {
    const body = await res.json().catch(() => null);
    throw new ApiError(res.status, body);
  }

  if (res.status === 204) return undefined as T;
  return res.json();
}

export const apiClient = {
  get: <T>(path: string) => api<T>(path),
  post: <T>(path: string, data: unknown) => api<T>(path, { method: 'POST', body: JSON.stringify(data) }),
  put: <T>(path: string, data: unknown) => api<T>(path, { method: 'PUT', body: JSON.stringify(data) }),
  patch: <T>(path: string, data: unknown) => api<T>(path, { method: 'PATCH', body: JSON.stringify(data) }),
  delete: <T>(path: string) => api<T>(path, { method: 'DELETE' }),
};
```

### 选项 B: React Query + 类型化客户端 (React 推荐)

```typescript
// hooks/use-orders.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';

interface Order { id: string; total: number; status: string; }
interface CreateOrderInput { items: { productId: string; quantity: number }[] }

export function useOrders() {
  return useQuery({
    queryKey: ['orders'],
    queryFn: () => apiClient.get<{ data: Order[] }>('/api/orders'),
    staleTime: 1000 * 60,  // 1 分钟
  });
}

export function useCreateOrder() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: CreateOrderInput) =>
      apiClient.post<{ data: Order }>('/api/orders', data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['orders'] });
    },
  });
}

// 组件中使用:
function OrdersPage() {
  const { data, isLoading, error } = useOrders();
  const createOrder = useCreateOrder();
  if (isLoading) return <Skeleton />;
  if (error) return <ErrorBanner error={error} />;
  // ...
}
```

### 选项 C: tRPC (同一团队维护前后端)

```typescript
// 服务端: trpc/router.ts
export const appRouter = router({
  orders: router({
    list: publicProcedure.query(async () => {
      return db.order.findMany({ include: { items: true } });
    }),
    create: protectedProcedure
      .input(z.object({ items: z.array(orderItemSchema) }))
      .mutation(async ({ input, ctx }) => {
        return orderService.create(ctx.user.id, input);
      }),
  }),
});
export type AppRouter = typeof appRouter;

// 客户端: 自动类型安全，无需代码生成
const { data } = trpc.orders.list.useQuery();
const createOrder = trpc.orders.create.useMutation();
```

### 选项 D: OpenAPI 生成客户端 (公开 / 多消费者 API)

```bash
npx openapi-typescript-codegen \
  --input http://localhost:3001/api/openapi.json \
  --output src/generated/api \
  --client axios
```

### 决策: 使用哪个 API 客户端?

| 方案 | 适用场景 | 类型安全 | 工作量 |
|------|----------|----------|--------|
| 类型化 fetch 包装器 | 简单应用、小团队 | 手动类型 | 低 |
| React Query + fetch | React 应用、服务器状态 | 手动类型 | 中等 |
| tRPC | 同一团队、两边 TypeScript | 自动 | 低 |
| OpenAPI 生成 | 公开 API、多消费者 | 自动 | 中等 |
| GraphQL codegen | GraphQL API | 自动 | 中等 |

---

## 6. 认证与中间件 (高)

> **完整参考:** [references/auth-flow.md](references/auth-flow.md) — JWT 持有者流程、自动令牌刷新、Next.js 服务端认证、RBAC 模式、后端中间件顺序。

### 标准中间件顺序

```
请求 → 1.RequestID → 2.Logging → 3.CORS → 4.RateLimit → 5.BodyParse
     → 6.Auth → 7.Authz → 8.Validation → 9.Handler → 10.ErrorHandler → 响应
```

### JWT 规则

```
短期访问令牌 (15分钟) + 刷新令牌 (服务端存储)
最小声明: userId、roles (非整个用户对象)
定期轮换签名密钥

绝不将令牌存储在 localStorage (XSS 风险)
绝不在 URL 查询参数中传递令牌
```

### RBAC 模式

```typescript
function authorize(...roles: Role[]) {
  return (req, res, next) => {
    if (!req.user) throw new UnauthorizedError();
    if (!roles.some(r => req.user.roles.includes(r))) throw new ForbiddenError();
    next();
  };
}
router.delete('/users/:id', authenticate, authorize('admin'), deleteUser);
```

### 认证令牌自动刷新

```typescript
// lib/api-client.ts — 401 时透明刷新
async function apiWithRefresh<T>(path: string, options: RequestInit = {}): Promise<T> {
  try {
    return await api<T>(path, options);
  } catch (err) {
    if (err instanceof ApiError && err.status === 401) {
      const refreshed = await api<{ accessToken: string }>('/api/auth/refresh', {
        method: 'POST',
        credentials: 'include',  // 发送 httpOnly cookie
      });
      setAuthToken(refreshed.accessToken);
      return api<T>(path, options);  // 重试
    }
    throw err;
  }
}
```

---

## 7. 日志与可观测性 (中-高)

### 结构化 JSON 日志

```typescript
// 结构化 — 可解析、可过滤、可告警
logger.info('Order created', {
  orderId: order.id, userId: user.id, total: order.total,
  items: order.items.length, duration_ms: Date.now() - startTime,
});
// 输出: {"level":"info","msg":"Order created","orderId":"ord_123",...}

// 非结构化 — 大规模下无用
console.log(`Order created for user ${user.id} with total ${order.total}`);
```

### 日志级别

| 级别 | 何时使用 | 生产环境? |
|------|----------|-----------|
| error | 需要立即关注 | 始终 |
| warn | 意外但已处理 | 始终 |
| info | 正常操作、审计追踪 | 始终 |
| debug | 开发调试 | 仅开发 |

### 规则

```
每条日志条目包含请求 ID (通过中间件传播)
在层边界记录日志 (请求入、响应出、外部调用)
绝不记录密码、令牌、PII 或密钥
绝不在生产代码中使用 console.log
```

---

## 8. 后台任务与异步 (中等)

### 规则

```
所有任务必须是幂等的 (同一任务运行两次 = 相同结果)
失败任务 → 重试 (最多 3 次) → 死信队列 → 告警
工作进程作为独立进程运行 (非 API 服务器的线程)

绝不在请求处理器中执行长时间运行的任务
绝不假设任务只执行一次
```

### 幂等任务模式

```typescript
async function processPayment(data: { orderId: string }) {
  const order = await orderRepo.findById(data.orderId);
  if (order.paymentStatus === 'completed') return;  // 已处理
  await paymentGateway.charge(order);
  await orderRepo.updatePaymentStatus(order.id, 'completed');
}
```

---

## 9. 缓存模式 (中等)

### 旁路缓存 (懒加载)

```typescript
async function getUser(id: string): Promise<User> {
  const cached = await redis.get(`user:${id}`);
  if (cached) return JSON.parse(cached);

  const user = await userRepo.findById(id);
  if (!user) throw new NotFoundError('User', id);

  await redis.set(`user:${id}`, JSON.stringify(user), 'EX', 900);  // 15分钟 TTL
  return user;
}
```

### 规则

```
始终设置 TTL — 绝不无过期缓存
写入时失效 (更新后删除缓存键)
用于读取缓存，绝不用于权威状态

绝不无 TTL 缓存 (陈旧数据比慢数据更糟)
```

| 数据类型 | 建议 TTL |
|----------|----------|
| 用户资料 | 5-15 分钟 |
| 产品目录 | 1-5 分钟 |
| 配置 / 功能开关 | 30-60 秒 |
| Session | 匹配 session 时长 |

---

## 10. 文件上传模式 (中等)

### 选项 A: 预签名 URL (大文件推荐)

```
客户端 → GET /api/uploads/presign?filename=photo.jpg&type=image/jpeg
服务端 → { uploadUrl: "https://s3.../presigned", fileKey: "uploads/abc123.jpg" }
客户端 → PUT uploadUrl (直接上传到 S3，绕过你的服务器)
客户端 → POST /api/photos { fileKey: "uploads/abc123.jpg" }  (保存引用)
```

**后端:**
```typescript
app.get('/api/uploads/presign', authenticate, async (req, res) => {
  const { filename, type } = req.query;
  const key = `uploads/${crypto.randomUUID()}-${filename}`;
  const url = await s3.getSignedUrl('putObject', {
    Bucket: process.env.S3_BUCKET, Key: key,
    ContentType: type, Expires: 300,  // 5 分钟
  });
  res.json({ uploadUrl: url, fileKey: key });
});
```

**前端:**
```typescript
async function uploadFile(file: File) {
  const { uploadUrl, fileKey } = await apiClient.get<PresignResponse>(
    `/api/uploads/presign?filename=${file.name}&type=${file.type}`
  );
  await fetch(uploadUrl, { method: 'PUT', body: file, headers: { 'Content-Type': file.type } });
  return apiClient.post('/api/photos', { fileKey });
}
```

### 选项 B: 分片 (小文件 < 10MB)

```typescript
// 前端
const formData = new FormData();
formData.append('file', file);
formData.append('description', 'Profile photo');
const res = await fetch('/api/upload', { method: 'POST', body: formData });
// 注意: 不要设置 Content-Type 头 — 浏览器自动设置 boundary
```

### 决策

| 方法 | 文件大小 | 服务器负载 | 复杂度 |
|------|----------|------------|--------|
| 预签名 URL | 任意 (> 5MB 推荐) | 无 (直接到存储) | 中等 |
| 分片 | < 10MB | 高 (流经服务器) | 低 |
| 分块 / 断点续传 | > 100MB | 中等 | 高 |

---

## 11. 实时模式 (中等)

### 选项 A: 服务器发送事件 (SSE) — 单向服务端 → 客户端

最适合: 通知、实时信息流、流式 AI 响应。

**后端 (Express):**
```typescript
app.get('/api/events', authenticate, (req, res) => {
  res.writeHead(200, {
    'Content-Type': 'text/event-stream',
    'Cache-Control': 'no-cache',
    Connection: 'keep-alive',
  });
  const send = (event: string, data: unknown) => {
    res.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
  };
  const unsubscribe = eventBus.subscribe(req.user.id, (event) => {
    send(event.type, event.payload);
  });
  req.on('close', () => unsubscribe());
});
```

**前端:**
```typescript
function useServerEvents(userId: string) {
  useEffect(() => {
    const source = new EventSource(`/api/events?userId=${userId}`);
    source.addEventListener('notification', (e) => {
      showToast(JSON.parse(e.data).message);
    });
    source.onerror = () => { source.close(); setTimeout(() => /* 重连 */, 3000); };
    return () => source.close();
  }, [userId]);
}
```

### 选项 B: WebSocket — 双向

最适合: 聊天、协同编辑、游戏。

**后端 (ws 库):**
```typescript
import { WebSocketServer } from 'ws';
const wss = new WebSocketServer({ server: httpServer, path: '/ws' });
wss.on('connection', (ws, req) => {
  const userId = authenticateWs(req);
  if (!userId) { ws.close(4001, 'Unauthorized'); return; }
  ws.on('message', (raw) => handleMessage(userId, JSON.parse(raw.toString())));
  ws.on('close', () => cleanupUser(userId));
  const interval = setInterval(() => ws.ping(), 30000);
  ws.on('pong', () => { /* 存活 */ });
  ws.on('close', () => clearInterval(interval));
});
```

**前端:**
```typescript
function useWebSocket(url: string) {
  const [ws, setWs] = useState<WebSocket | null>(null);
  useEffect(() => {
    const socket = new WebSocket(url);
    socket.onopen = () => setWs(socket);
    socket.onclose = () => setTimeout(() => /* 重连 */, 3000);
    return () => socket.close();
  }, [url]);
  const send = useCallback((data: unknown) => ws?.send(JSON.stringify(data)), [ws]);
  return { ws, send };
}
```

### 选项 C: 轮询 (最简单，无基础设施)

```typescript
function useOrderStatus(orderId: string) {
  return useQuery({
    queryKey: ['order-status', orderId],
    queryFn: () => apiClient.get<Order>(`/api/orders/${orderId}`),
    refetchInterval: (query) => {
      if (query.state.data?.status === 'completed') return false;
      return 5000;
    },
  });
}
```

### 决策

| 方法 | 方向 | 复杂度 | 适用场景 |
|------|------|--------|----------|
| 轮询 | 客户端 → 服务端 | 低 | 简单状态检查，< 10 客户端 |
| SSE | 服务端 → 客户端 | 中等 | 通知、信息流、AI 流式 |
| WebSocket | 双向 | 高 | 聊天、协同、游戏 |

---

## 12. 跨边界错误处理 (中等)

### API 错误 → 用户友好消息

```typescript
// lib/error-handler.ts
export function getErrorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    switch (error.status) {
      case 401: return '请先登录以继续。';
      case 403: return '您没有权限执行此操作。';
      case 404: return '您查找的项目不存在。';
      case 409: return '与现有项目冲突。';
      case 422:
        const fields = error.body?.errors;
        if (fields?.length) return fields.map((f: any) => f.message).join('. ');
        return '请检查您的输入。';
      case 429: return '请求过多，请稍后再试。';
      default: return '出了点问题，请重试。';
    }
  }
  if (error instanceof TypeError && error.message === 'Failed to fetch') {
    return '无法连接到服务器，请检查您的网络连接。';
  }
  return '发生了意外错误。';
}
```

### React Query 全局错误处理器

```typescript
const queryClient = new QueryClient({
  defaultOptions: {
    mutations: { onError: (error) => toast.error(getErrorMessage(error)) },
    queries: {
      retry: (failureCount, error) => {
        if (error instanceof ApiError && error.status < 500) return false;
        return failureCount < 3;
      },
    },
  },
});
```

### 规则

```
将每个 API 错误码映射为人类可读的消息
在表单输入旁显示字段级验证错误
5xx 自动重试 (最多 3 次，带退避)，4xx 绝不重试
401 时重定向到登录 (刷新尝试失败后)
fetch 失败出现 TypeError 时显示"离线"提示

绝不向用户显示原始 API 错误消息 ("NullPointerException")
绝不静默吞掉错误 (显示提示或记录日志)
绝不重试 4xx 错误 (客户端错误，重试无用)
```

### 集成决策树

```
同一团队维护前端 + 后端?
│
├─ 是，两边 TypeScript
│   └─ tRPC (端到端类型安全，零代码生成)
│
├─ 是，不同语言
│   └─ OpenAPI 规范 → 生成客户端 (通过代码生成实现类型安全)
│
├─ 否，公开 API
│   └─ REST + OpenAPI → 为消费者生成 SDK
│
└─ 复杂数据需求，多个前端
    └─ GraphQL + 代码生成 (每个客户端灵活查询)

需要实时功能?
│
├─ 仅服务端 → 客户端 (通知、信息流、AI 流式)
│   └─ SSE (最简单，自动重连，可穿透代理)
│
├─ 双向 (聊天、协同)
│   └─ WebSocket (需要心跳 + 重连逻辑)
│
└─ 简单状态轮询 (< 10 客户端)
    └─ React Query refetchInterval (无需基础设施)
```

---

## 13. 生产加固 (中等)

### 健康检查

```typescript
app.get('/health', (req, res) => res.json({ status: 'ok' }));           // 存活检查
app.get('/ready', async (req, res) => {                                   // 就绪检查
  const checks = {
    database: await checkDb(), redis: await checkRedis(), 
  };
  const ok = Object.values(checks).every(c => c.status === 'ok');
  res.status(ok ? 200 : 503).json({ status: ok ? 'ok' : 'degraded', checks });
});
```

### 优雅关闭

```typescript
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received');
  server.close();              // 停止新连接
  await drainConnections();    // 完成进行中的请求
  await closeDatabase();
  process.exit(0);
});
```

### 安全检查清单

```
CORS: 显式来源 (生产环境绝不 '*')
安全响应头 (helmet / 等效方案)
公开端点的速率限制
所有端点的输入验证 (不信任任何内容)
强制 HTTPS
绝不向客户端暴露内部错误
```

---

## 反模式

| # | 不要 | 要做 |
|---|------|------|
| 1 | 在路由/控制器中写业务逻辑 | 移到服务层 |
| 2 | 到处散布 `process.env` | 集中式类型化配置 |
| 3 | 用 `console.log` 记录日志 | 结构化 JSON 日志器 |
| 4 | 通用 `Error('oops')` | 类型化错误层次 |
| 5 | 控制器中直接调用数据库 | 仓库模式 |
| 6 | 无输入验证 | 在边界验证 (Zod/Pydantic) |
| 7 | 静默捕获错误 | 记录日志 + 重抛或返回错误 |
| 8 | 无健康检查端点 | `/health` + `/ready` |
| 9 | 硬编码配置/密钥 | 环境变量 |
| 10 | 无优雅关闭 | 正确处理 SIGTERM |
| 11 | 前端硬编码 API URL | 环境变量 (`NEXT_PUBLIC_API_URL`) |
| 12 | JWT 存储在 localStorage | 内存 + httpOnly 刷新 cookie |
| 13 | 向用户显示原始 API 错误 | 映射为人类可读消息 |
| 14 | 重试 4xx 错误 | 仅重试 5xx (服务端故障) |
| 15 | 跳过加载状态 | 获取时显示骨架屏/加载动画 |
| 16 | 大文件通过 API 服务器上传 | 预签名 URL → 直接到 S3 |
| 17 | 轮询实时数据 | SSE 或 WebSocket |
| 18 | 前后端重复类型 | 共享类型、tRPC 或 OpenAPI 代码生成 |

---

## 常见问题

### 问题 1: "这条业务规则放哪?"

**规则:** 如果涉及 HTTP (请求解析、状态码、响应头) → 控制器。如果涉及业务决策 (定价、权限、规则) → 服务。如果涉及数据库 → 仓库。

### 问题 2: "服务变得太大了"

**症状:** 单个服务文件 > 500 行，20+ 个方法。

**解决:** 按子域拆分。`OrderService` → `OrderCreationService` + `OrderFulfillmentService` + `OrderQueryService`。每个聚焦于一个工作流。

### 问题 3: "测试慢因为访问数据库"

**解决:** 单元测试 mock 仓库层 (快)。集成测试使用测试容器或事务回滚 (真实数据库，仍然快)。集成测试中绝不 mock 服务层。

---

## 参考文档

此技能包含专业主题的深度参考。需要详细指导时阅读相关参考。

| 需要… | 参考 |
|-------|------|
| 编写后端测试 (单元、集成、e2e、契约、性能) | [references/testing-strategy.md](references/testing-strategy.md) |
| 部署前验证发布 (6 道关卡清单) | [references/release-checklist.md](references/release-checklist.md) |
| 选择技术栈 (语言、框架、数据库、基础设施) | [references/technology-selection.md](references/technology-selection.md) |
| 使用 Django / DRF 构建 (模型、视图、序列化器、admin) | [references/django-best-practices.md](references/django-best-practices.md) |
| 设计 REST/GraphQL/gRPC 端点 (URL、状态码、分页) | [references/api-design.md](references/api-design.md) |
| 设计数据库模式、索引、迁移、多租户 | [references/db-schema.md](references/db-schema.md) |
| 认证流程 (JWT bearer、令牌刷新、Next.js SSR、RBAC、中间件顺序) | [references/auth-flow.md](references/auth-flow.md) |
| CORS 配置、每环境环境变量、常见 CORS 问题 | [references/environment-management.md](references/environment-management.md) |
