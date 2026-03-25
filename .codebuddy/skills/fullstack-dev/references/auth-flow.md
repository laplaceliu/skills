# 认证流程模式

跨前后端的完整认证流程。涵盖 JWT bearer 流程、自动令牌刷新、Next.js 服务端认证、RBAC 和后端中间件顺序。

---

## JWT Bearer 流程 (最常见)

```
1. 登录
   客户端 → POST /api/auth/login { email, password }
   服务端 → { accessToken (15分钟), refreshToken (7天, httpOnly cookie) }

2. 认证请求
   客户端 → GET /api/orders  Authorization: Bearer <accessToken>
   服务端 → 验证 JWT → 返回数据

3. 令牌刷新 (透明)
   客户端 → 收到 401 → POST /api/auth/refresh (cookie 自动发送)
   服务端 → 新 accessToken
   客户端 → 使用新令牌重试原始请求

4. 登出
   客户端 → POST /api/auth/logout
   服务端 → 使刷新令牌失效 → 清除 cookie
```

---

## 前端: 自动令牌刷新

```typescript
// lib/api-client.ts — 添加到现有的 fetch 包装器
async function apiWithRefresh<T>(path: string, options: RequestInit = {}): Promise<T> {
  try {
    return await api<T>(path, options);
  } catch (err) {
    if (err instanceof ApiError && err.status === 401) {
      // 尝试刷新
      const refreshed = await api<{ accessToken: string }>('/api/auth/refresh', {
        method: 'POST',
        credentials: 'include',  // 发送 httpOnly cookie
      });
      setAuthToken(refreshed.accessToken);
      // 重试原始请求
      return api<T>(path, options);
    }
    throw err;
  }
}
```

---

## Next.js: 服务端认证 (App Router)

```typescript
// middleware.ts — 服务端保护路由
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  const token = request.cookies.get('session')?.value;
  if (!token && request.nextUrl.pathname.startsWith('/dashboard')) {
    return NextResponse.redirect(new URL('/login', request.url));
  }
  return NextResponse.next();
}

// app/dashboard/page.tsx — 带认证的服务端组件
import { cookies } from 'next/headers';

export default async function Dashboard() {
  const token = (await cookies()).get('session')?.value;
  const user = await fetch(`${process.env.API_URL}/api/me`, {
    headers: { Authorization: `Bearer ${token}` },
  }).then(r => r.json());

  return <DashboardContent user={user} />;
}
```

---

## 后端: 标准中间件顺序

```
请求 → 1.RequestID → 2.Logging → 3.CORS → 4.RateLimit → 5.BodyParse
     → 6.Auth → 7.Authz → 8.Validation → 9.Handler → 10.ErrorHandler → 响应
```

---

## 后端: JWT 规则

```
短期访问令牌 (15分钟) + 刷新令牌 (服务端存储)
最小声明: userId, roles (非整个用户对象)
定期轮换签名密钥

绝不将令牌存储在 localStorage (XSS 风险)
绝不在 URL 查询参数中传递令牌
```

---

## 后端: RBAC 模式

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

---

## 认证决策表

| 方法 | 何时使用 | 前端 |
|--------|------|----------|
| Session | 同域, SSR, Django 模板 | Django 模板 / htmx |
| JWT | 不同域, SPA, 移动端 | React, Vue, 移动应用 |
| OAuth2 | 第三方登录, API 消费者 | 任意 |

---

## 铁律

```
访问令牌: 短期 (15分钟), 内存中
刷新令牌: httpOnly cookie (防 XSS)
401 时自动透明刷新
刷新失败时重定向到登录

绝不将令牌存储在 localStorage (XSS 风险)
绝不在 URL 查询参数中发送令牌 (会被记录)
绝不单独信任客户端认证检查 (服务端必须验证)
```

---

## 常见问题

### 问题 1: "页面加载时认证有效，但导航时失效"

**原因:** 令牌存储在组件状态中 (卸载时丢失)。

**解决:** 将访问令牌存储在持久位置:
- React Context (导航时保留, 刷新时丢失)
- Cookie (刷新时保留)
- React Query 缓存配合 `staleTime: Infinity` 用于 session

### 问题 2: "认证请求出现 CORS 错误"

**原因:** 前端缺少 `credentials: 'include'` 或后端 CORS 配置缺少 `credentials: true`。

**解决:**
1. 前端: `fetch(url, { credentials: 'include' })`
2. 后端: `cors({ origin: 'https://your-frontend.com', credentials: true })`
3. 后端: 使用凭证时显式指定来源 (非 `*`)
