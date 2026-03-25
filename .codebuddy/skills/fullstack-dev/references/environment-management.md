# 环境与 CORS 管理

跨前后端技术栈管理环境变量、API URL 和 CORS 配置的模式。

---

## 标准环境模式

```
# .env.local (gitignored, 用于本地开发)
NEXT_PUBLIC_API_URL=http://localhost:3001
NEXT_PUBLIC_WS_URL=ws://localhost:3001

# 预发布环境 (在 Vercel/CI 中设置)
NEXT_PUBLIC_API_URL=https://api-staging.example.com

# 生产环境 (在 Vercel/CI 中设置)
NEXT_PUBLIC_API_URL=https://api.example.com
```

---

## 环境变量规则

```
 API 基础 URL 来自环境变量 — 绝不硬编码
 客户端变量前缀用 NEXT_PUBLIC_ (Next.js) 或 VITE_ (Vite)
 后端 URL = 仅服务端环境变量 (用于 SSR 调用, 不暴露给浏览器)
 后端 CORS: 每环境显式允许来源列表

生产构建绝不用 localhost URL
绝不用 NEXT_PUBLIC_ 前缀暴露仅后端密钥
绝不提交 .env.local (提交带占位符的 .env.example)
```

---

## CORS 配置

```typescript
// 后端: 感知环境的 CORS
const ALLOWED_ORIGINS = {
  development: ['http://localhost:3000', 'http://localhost:5173'],
  staging: ['https://staging.example.com'],
  production: ['https://example.com', 'https://www.example.com'],
};

app.use(cors({
  origin: ALLOWED_ORIGINS[process.env.NODE_ENV || 'development'],
  credentials: true,  // cookie (认证) 需要
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
}));
```

---

## 常见问题

### 问题 1: "浏览器中 CORS 错误但 Postman 中正常"

**原因:** CORS 是浏览器安全功能。Postman/curl 跳过它。

**修复:**
1. 后端必须返回 `Access-Control-Allow-Origin: https://your-frontend.com`
2. 对于 cookie/认证: 两边都设置 `credentials: true`
3. 检查预检 `OPTIONS` 请求是否返回正确的响应头

### 问题 2: "浏览器中环境变量未定义"

**原因:** 客户端访问缺少 `NEXT_PUBLIC_` 或 `VITE_` 前缀。

**修复:** 客户端变量必须有框架前缀。添加新环境变量后重新构建 (它们在构建时嵌入)。

### 问题 3: "本地正常, 预发布环境失败"

**原因:** 不同来源, 预发布域缺少 CORS 配置。

**修复:** 将预发布来源添加到 `ALLOWED_ORIGINS`, 验证部署平台中是否设置了环境变量。
