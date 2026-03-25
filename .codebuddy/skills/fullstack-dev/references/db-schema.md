---
name: fullstack-dev-db-schema
description: "数据库模式设计和迁移。在创建表、定义 ORM 模型、添加索引或设计关系时使用。涵盖零停机迁移和多租户。"
license: MIT
metadata:
  version: "1.0.0"
  sources:
    - PostgreSQL official documentation
    - Use The Index, Luke (use-the-index-luke.com)
    - Designing Data-Intensive Applications (Martin Kleppmann)
    - Database Reliability Engineering (Laine Campbell & Charity Majors)
---

# 数据库模式设计

ORM 无关的关系型数据库模式设计指南。涵盖数据建模、规范化、索引、迁移、多租户和常见应用模式。主要面向 PostgreSQL，但原则适用于 MySQL/MariaDB。

## 适用范围

**使用此技能的情况:**
- 为新项目或功能设计模式
- 在规范化和反规范化之间决策
- 选择要创建的索引
- 在实时数据库上规划零停机迁移
- 实现多租户数据隔离
- 添加审计追踪、软删除或版本控制
- 诊断由模式问题导致的慢查询

**不适用的情况:**
- 选择使用哪种数据库技术 (→ `technology-selection`)
- PostgreSQL 特定的查询调优 (使用 PostgreSQL 性能文档)
- ORM 特定配置 (→ `django-best-practices` 或你的 ORM 文档)
- 应用层缓存 (→ `fullstack-dev-practices`)

## 所需上下文

| 必需 | 可选 |
|----------|----------|
| 数据库引擎 (PostgreSQL / MySQL) | 预期数据量 (行数, 增长率) |
| 领域实体和关系 | 读/写比例 |
| 关键访问模式 (查询) | 多租户需求 |

---

## 快速开始清单

设计新模式:

- [ ] **已识别领域实体** — 映射 1 实体 = 1 表 (非 1 类 = 1 表)
- [ ] **主键**: 公开 ID 用 UUID，内部仅用序列/bigserial
- [ ] **外键**带显式 `ON DELETE` 行为
- [ ] **NOT NULL** 默认 — 仅业务逻辑需要时才可空
- [ ] **时间戳**: 每个表都有 `created_at` + `updated_at`
- [ ] **索引**为每个 WHERE, JOIN, ORDER BY 列创建
- [ ] **不提前反规范化** — 从规范化开始，测量后才反规范化
- [ ] **命名约定**一致: `snake_case`, 表名复数

---

## 快速导航

| 需要… | 跳转到 |
|----------|---------|
| 建模实体和关系 | [1. 数据建模](#1-数据建模-关键) |
| 决定规范化 vs 反规范化 | [2. 规范化](#2-规范化-vs-反规范化-关键) |
| 选择正确的索引 | [3. 索引](#3-索引策略-关键) |
| 在实时 DB 上安全运行迁移 | [4. 迁移](#4-零停机迁移-高) |
| 设计多租户模式 | [5. 多租户](#5-多租户设计-高) |
| 添加软删除 / 审计追踪 | [6. 常见模式](#6-常见模式-中) |
| 分区大表 | [7. 分区](#7-表分区-中) |
| 查看反模式 | [反模式](#反模式) |

---

## 核心原则 (7 条规则)

```
1. 从规范化 (3NF) 开始 — 仅当有测量证据时才反规范化
2. 每个表都有主键、created_at、updated_at
3. 公开 ID 用 UUID，内部连接键用序列
4. 默认 NOT NULL — null 是业务决策，非懒默认
5. 为 WHERE, JOIN, ORDER BY 中使用的每个列建索引
6. 外键在数据库中强制执行 (非仅在应用代码中)
7. 迁移是增量的 — 无多步计划绝不在生产环境删除/重命名
```

---

## 1. 数据建模 (关键)

### 表命名

```sql
--  复数, snake_case
CREATE TABLE orders (...);
CREATE TABLE order_items (...);
CREATE TABLE user_profiles (...);

--  单数, 混合大小写
CREATE TABLE Order (...);
CREATE TABLE OrderItem (...);
CREATE TABLE tbl_usr_prof (...);    -- 晦涩缩写
```

### 主键

| 策略 | 何时使用 | 优点 | 缺点 |
|----------|------|------|------|
| `bigserial` (自增) | 内部表, FK 连接 | 紧凑, 快速连接 | 可枚举, 不适合公开 ID |
| `uuid` (v4 随机) | 公开资源 | 不可猜测, 全局唯一 | 较大 (16 字节), B-Tree 随机 I/O |
| `uuid` v7 (时间排序) | 公开 + 需要排序 | 不可猜测 + 插入友好 | 较新, 生态系统支持较少 |
| `text` slug | URL 友好资源 | 人类可读 | 必须强制执行唯一性, 更新昂贵 |

**推荐默认:**

```sql
CREATE TABLE orders (
    id          bigserial PRIMARY KEY,             -- 内部 FK 目标
    public_id   uuid NOT NULL DEFAULT gen_random_uuid() UNIQUE,  -- API 面向
    -- ...
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);
```

### 关系

```sql
-- 一对多: user → orders
CREATE TABLE orders (
    id         bigserial PRIMARY KEY,
    user_id    bigint NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- ...
);
CREATE INDEX idx_orders_user_id ON orders(user_id);

-- 多对多: orders ↔ products (通过连接表)
CREATE TABLE order_items (
    id         bigserial PRIMARY KEY,
    order_id   bigint NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id bigint NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity   int NOT NULL CHECK (quantity > 0),
    unit_price numeric(10,2) NOT NULL,
    UNIQUE (order_id, product_id)  -- 防止重复行项目
);

-- 一对一: user → profile
CREATE TABLE user_profiles (
    user_id    bigint PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    bio        text,
    avatar_url text,
    -- ...
);
```

### ON DELETE 行为

| 行为 | 何时使用 | 示例 |
|----------|------|---------|
| `CASCADE` | 子项无父项无意义 | order_items 当 order 被删除时 |
| `RESTRICT` | 防止意外删除 | order_items 引用的 products |
| `SET NULL` | 保留子项, 清除引用 | orders.assigned_to 当员工离职时 |
| `SET DEFAULT` | 回退到默认值 | 罕见, 用于状态列 |

---

## 2. 规范化 vs 反规范化 (关键)

### 从规范化开始 (3NF)

**实践中的范式:**

| 范式 | 规则 | 违规示例 |
|------|------|-------------------|
| 1NF | 无重复组, 原子值 | `tags = "go,python,rust"` 在一列中 |
| 2NF | 无部分依赖 (复合键) | `order_items.product_name` 仅依赖 `product_id` |
| 3NF | 无传递依赖 | `orders.customer_city` 依赖 `customer_id`, 非 `order_id` |

**1NF 违规修复:**
```sql
--  Tags 作为逗号分隔字符串
CREATE TABLE posts (id serial, tags text);  -- tags = "go,python"

--  单独表 (或简单时用 array/JSONB)
CREATE TABLE post_tags (
    post_id bigint REFERENCES posts(id) ON DELETE CASCADE,
    tag_id  bigint REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

--  替代方案: PostgreSQL 数组 (如果 tags 只是字符串, 无元数据)
CREATE TABLE posts (id serial, tags text[] NOT NULL DEFAULT '{}');
CREATE INDEX idx_posts_tags ON posts USING GIN(tags);
```

### 何时反规范化

**仅当以下条件时才反规范化:**
1. 你**测量**了性能问题 (EXPLAIN ANALYZE, 非"我认为它慢")
2. 反规范化数据是**读密集型** (读:写比例 > 100:1)
3. 你接受**一致性维护成本** (触发器, 应用逻辑, 或物化视图)

**安全的反规范化模式:**

```sql
-- 模式 1: 物化视图 (计算, 可刷新)
CREATE MATERIALIZED VIEW order_summary AS
SELECT o.id, o.user_id, o.total,
       COUNT(oi.id) AS item_count,
       u.email AS user_email
FROM orders o
JOIN order_items oi ON oi.order_id = o.id
JOIN users u ON u.id = o.user_id
GROUP BY o.id, u.email;

REFRESH MATERIALIZED VIEW CONCURRENTLY order_summary;  -- 非阻塞

-- 模式 2: 缓存聚合列 (应用维护)
ALTER TABLE orders ADD COLUMN item_count int NOT NULL DEFAULT 0;
-- 通过触发器或应用代码在 order_item 插入/删除时更新

-- 模式 3: JSONB 快照 (写入时冻结)
-- 存储购买时的产品详情副本
CREATE TABLE order_items (
    id          bigserial PRIMARY KEY,
    order_id    bigint NOT NULL REFERENCES orders(id),
    product_id  bigint REFERENCES products(id),
    quantity    int NOT NULL,
    unit_price  numeric(10,2) NOT NULL,      -- 冻结价格
    product_snapshot jsonb NOT NULL           -- 冻结名称, 描述, 图片
);
```

---

## 3. 索引策略 (关键)

### 索引类型 (PostgreSQL)

| 类型 | 何时使用 | 示例 |
|------|------|---------|
| **B-Tree** (默认) | 相等, 范围, ORDER BY | `WHERE status = 'active'`, `WHERE created_at > '2025-01-01'` |
| **Hash** | 仅相等 (罕见, B-Tree 通常更好) | `WHERE id = 123` (大表, Postgres 10+) |
| **GIN** | 数组, JSONB, 全文搜索 | `WHERE tags @> '{go}'`, `WHERE data->>'key' = 'val'` |
| **GiST** | 几何, 范围, 最近邻 | PostGIS, tsrange, ltree |
| **BRIN** | 具有自然顺序的超大表 | 按时间戳排序的时间序列数据 |

### 索引决策规则

```
规则 1: 为 WHERE 子句中的每个列建索引
规则 2: 为 JOIN ON 条件中使用的每个列建索引
规则 3: 为 ORDER BY 中的每个列建索引 (如果与 LIMIT 一起查询)
规则 4: 多列 WHERE 使用复合索引 (最左前缀规则)
规则 5: 过滤子集时使用部分索引 (如仅活跃记录)
规则 6: 覆盖索引 (INCLUDE) 避免表查找
规则 7: 不单独为低基数列建索引 (如 boolean)
```

### 复合索引: 列顺序很重要

```sql
-- 查询: WHERE user_id = ? AND status = ? ORDER BY created_at DESC
--  最优: 从左到右匹配查询模式
CREATE INDEX idx_orders_user_status_created
ON orders(user_id, status, created_at DESC);

--  错误顺序: 无法高效用于此查询
CREATE INDEX idx_orders_created_user_status
ON orders(created_at DESC, user_id, status);
```

**最左前缀规则:** `(A, B, C)` 上的索引支持 `(A)`, `(A, B)`, `(A, B, C)` 的查询，但**不支持** `(B)`, `(C)`, 或 `(B, C)`。

### 部分索引 (仅索引重要内容)

```sql
-- 仅 5% 的 orders 是 'pending', 但频繁查询
CREATE INDEX idx_orders_pending
ON orders(created_at DESC)
WHERE status = 'pending';

-- 仅活跃用户对登录重要
CREATE INDEX idx_users_active_email
ON users(email)
WHERE is_active = true;
```

### 覆盖索引 (避免表查找)

```sql
-- 查询只需要 id 和 status, 无需读取表行
CREATE INDEX idx_orders_user_covering
ON orders(user_id) INCLUDE (status, total);

-- 现在此查询是仅索引的:
SELECT status, total FROM orders WHERE user_id = 123;
```

### 何时不建索引

```
 很少用于 WHERE/JOIN/ORDER BY 的列
 行数 < 1,000 的表 (顺序扫描更快)
 基数非常低的单列 (如 boolean is_active)
 写密集型表，索引维护成本 > 读收益
 重复索引 (检查 pg_stat_user_indexes 中未使用的索引)
```

---

## 4. 零停机迁移 (高)

### 黄金法则

```
绝不要一步做出破坏性变更。
始终: 添加 → 迁移数据 → 删除旧列 (分开发布)。
```

### 安全迁移模式

**重命名列 (3 次发布):**

```
发布 1: 添加新列
  ALTER TABLE users ADD COLUMN full_name text;
  UPDATE users SET full_name = name;           -- 回填
  -- 应用写入 name 和 full_name 两者

发布 2: 切换到新列读取
  -- 应用从 full_name 读取, 仍写入两者

发布 3: 删除旧列
  ALTER TABLE users DROP COLUMN name;
  -- 应用仅使用 full_name
```

**添加 NOT NULL 列 (2 次发布):**

```sql
-- 发布 1: 先添加可空列, 回填
ALTER TABLE orders ADD COLUMN currency text;              -- 先可空
UPDATE orders SET currency = 'USD' WHERE currency IS NULL; -- 回填

-- 发布 2: 添加约束 (所有行回填后)
ALTER TABLE orders ALTER COLUMN currency SET NOT NULL;
ALTER TABLE orders ALTER COLUMN currency SET DEFAULT 'USD';
```

**无锁定添加索引:**

```sql
--  CONCURRENTLY: 无表锁, 可在实时 DB 上运行
CREATE INDEX CONCURRENTLY idx_orders_status ON orders(status);

--  无 CONCURRENTLY: 构建期间锁定表写入
CREATE INDEX idx_orders_status ON orders(status);
```

### 迁移安全检查清单

```
 迁移在生产数据量上运行 < 30 秒
 无排他表锁 (索引使用 CONCURRENTLY)
 回滚计划已记录并测试
 回填分批运行 (非一个巨大 UPDATE)
 新列先添加为可空, 约束稍后添加
 旧列保留到所有代码引用移除

绝不要一次发布中重命名/删除列
绝不在无测试的情况下对大表 ALTER TYPE
绝不在事务中运行数据回填 (大表会 OOM)
```

### 批量回填模板

```sql
-- 每批 10,000 回填 (避免长时间运行的事务)
DO $$
DECLARE
  batch_size int := 10000;
  affected int;
BEGIN
  LOOP
    UPDATE orders
    SET currency = 'USD'
    WHERE id IN (
      SELECT id FROM orders WHERE currency IS NULL LIMIT batch_size
    );
    GET DIAGNOSTICS affected = ROW_COUNT;
    RAISE NOTICE 'Updated % rows', affected;
    EXIT WHEN affected = 0;
    PERFORM pg_sleep(0.1);  -- 短暂暂停以减少负载
  END LOOP;
END $$;
```

---

## 5. 多租户设计 (高)

### 三种方案

| 方案 | 隔离性 | 复杂度 | 何时使用 |
|----------|-----------|------------|------|
| **行级** (共享表 + `tenant_id`) | 低 | 低 | SaaS MVP, < 1,000 租户 |
| **每租户一 Schema** | 中 | 中 | 受监管行业, 中等规模 |
| **每租户一数据库** | 高 | 高 | 企业, 严格数据隔离 |

### 行级租户 (最常见)

```sql
-- 每个表都有 tenant_id
CREATE TABLE orders (
    id         bigserial PRIMARY KEY,
    tenant_id  bigint NOT NULL REFERENCES tenants(id),
    user_id    bigint NOT NULL REFERENCES users(id),
    total      numeric(10,2) NOT NULL,
    -- ...
);

-- 复合索引: tenant 优先 (大多数查询按 tenant 过滤)
CREATE INDEX idx_orders_tenant_user ON orders(tenant_id, user_id);
CREATE INDEX idx_orders_tenant_status ON orders(tenant_id, status);

-- 行级安全 (PostgreSQL)
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON orders
  USING (tenant_id = current_setting('app.tenant_id')::bigint);
```

**应用级强制执行:**

```typescript
// 中间件: 在每个请求上设置租户上下文
app.use((req, res, next) => {
  const tenantId = req.headers['x-tenant-id'];
  if (!tenantId) return res.status(400).json({ error: 'Missing tenant' });
  req.tenantId = tenantId;
  next();
});

// 仓库: 始终按租户过滤
async findOrders(tenantId: string, userId: string) {
  return db.order.findMany({
    where: { tenantId, userId },  // ← 每个查询都有 tenant_id
  });
}
```

### 规则

```
 tenant_id 在每个持有租户数据的表中
 tenant_id 在每个复合索引的第一列
 应用中间件强制执行租户上下文
 使用 RLS (PostgreSQL) 作为纵深防御, 非唯一保护
 用 2+ 租户测试以验证隔离

绝不允许应用代码中的跨租户查询
绝不在 WHERE 子句中跳过 tenant_id (即使在管理员工具中)
```

---

## 6. 常见模式 (中)

### 软删除

```sql
ALTER TABLE orders ADD COLUMN deleted_at timestamptz;

-- 所有查询过滤已删除记录
CREATE VIEW active_orders AS
SELECT * FROM orders WHERE deleted_at IS NULL;

-- 部分索引: 仅索引未删除行
CREATE INDEX idx_orders_active_status
ON orders(status, created_at DESC)
WHERE deleted_at IS NULL;
```

**ORM 集成:**

```typescript
// Prisma 中间件: 自动过滤软删除记录
prisma.$use(async (params, next) => {
  if (params.action === 'findMany' || params.action === 'findFirst') {
    params.args.where = { ...params.args.where, deletedAt: null };
  }
  return next(params);
});
```

### 审计追踪

```sql
-- 选项 A: 每个表上的审计列
ALTER TABLE orders ADD COLUMN created_by bigint REFERENCES users(id);
ALTER TABLE orders ADD COLUMN updated_by bigint REFERENCES users(id);

-- 选项 B: 单独的审计日志表 (更多细节)
CREATE TABLE audit_log (
    id          bigserial PRIMARY KEY,
    table_name  text NOT NULL,
    record_id   bigint NOT NULL,
    action      text NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data    jsonb,
    new_data    jsonb,
    changed_by  bigint REFERENCES users(id),
    changed_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_changed_at ON audit_log(changed_at DESC);
```

### 枚举列

```sql
-- 选项 A: PostgreSQL 枚举类型 (严格, 但 ALTER TYPE 很痛苦)
CREATE TYPE order_status AS ENUM ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled');
ALTER TABLE orders ADD COLUMN status order_status NOT NULL DEFAULT 'pending';

-- 选项 B: Text + CHECK 约束 (更容易迁移)
ALTER TABLE orders ADD COLUMN status text NOT NULL DEFAULT 'pending'
  CHECK (status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled'));

-- 选项 C: 查找表 (最灵活, 最适合 UI 驱动列表)
CREATE TABLE order_statuses (
    id    serial PRIMARY KEY,
    name  text UNIQUE NOT NULL,
    label text NOT NULL      -- 显示名称
);
```

**推荐:** 大多数情况用选项 B (text + CHECK)。如果状态由非开发者管理则用选项 C。

### 多态关联

```sql
--  反模式: 多态 FK (无引用完整性)
CREATE TABLE comments (
    id             bigserial PRIMARY KEY,
    commentable_type text,    -- 'Post' 或 'Photo'
    commentable_id   bigint,  -- 无法 FK 约束!
    body           text
);

--  模式 A: 单独的 FK 列 (可空)
CREATE TABLE comments (
    id       bigserial PRIMARY KEY,
    post_id  bigint REFERENCES posts(id) ON DELETE CASCADE,
    photo_id bigint REFERENCES photos(id) ON DELETE CASCADE,
    body     text NOT NULL,
    CHECK (
      (post_id IS NOT NULL AND photo_id IS NULL) OR
      (post_id IS NULL AND photo_id IS NOT NULL)
    )
);

--  模式 B: 单独的表 (最干净, 最适合不同模式)
CREATE TABLE post_comments (..., post_id bigint REFERENCES posts(id));
CREATE TABLE photo_comments (..., photo_id bigint REFERENCES photos(id));
```

### JSONB 列 (半结构化数据)

```sql
-- 良好用途: 元数据, 设置, 灵活属性
CREATE TABLE products (
    id         bigserial PRIMARY KEY,
    name       text NOT NULL,
    price      numeric(10,2) NOT NULL,
    attributes jsonb NOT NULL DEFAULT '{}'  -- 颜色, 尺寸, 重量...
);

-- 为 JSONB 查询建索引
CREATE INDEX idx_products_attrs ON products USING GIN(attributes);

-- 查询
SELECT * FROM products WHERE attributes->>'color' = 'red';
SELECT * FROM products WHERE attributes @> '{"size": "XL"}';
```

```
 对真正灵活/可选的数据使用 JSONB (元数据, 设置, 偏好)
 查询时使用 GIN 索引 JSONB 列

绝不对应该是列的数据使用 JSONB (email, status, price)
绝不用 JSONB 来避免模式设计 (它不是 MongoDB-in-Postgres)
```

---

## 7. 表分区 (中)

### 何时分区

```
 表 > 1亿 行且持续增长
 大多数查询在分区键上过滤 (日期范围, 租户)
 旧数据可以按分区删除/归档 (高效 DELETE)

 表 < 1千万 行 (开销不值得)
 查询不在分区键上过滤 (扫描所有分区)
```

### 范围分区 (时间序列)

```sql
CREATE TABLE events (
    id         bigserial,
    tenant_id  bigint NOT NULL,
    event_type text NOT NULL,
    payload    jsonb,
    created_at timestamptz NOT NULL DEFAULT now()
) PARTITION BY RANGE (created_at);

-- 按月分区
CREATE TABLE events_2025_01 PARTITION OF events
  FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');
CREATE TABLE events_2025_02 PARTITION OF events
  FOR VALUES FROM ('2025-02-01') TO ('2025-03-01');

-- 使用 pg_partman 或 cron 自动创建分区
```

### 列表分区 (多租户)

```sql
CREATE TABLE orders (
    id        bigserial,
    tenant_id bigint NOT NULL,
    total     numeric(10,2)
) PARTITION BY LIST (tenant_id);

CREATE TABLE orders_tenant_1 PARTITION OF orders FOR VALUES IN (1);
CREATE TABLE orders_tenant_2 PARTITION OF orders FOR VALUES IN (2);
```

---

## 反模式

| # |  不要 |  应该这样做 |
|---|---------|--------------|
| 1 | 提前反规范化 | 从 3NF 开始, 测量后反规范化 |
| 2 | 自增 ID 作为公开 API 标识符 | 公开用 UUID, 内部用序列 |
| 3 | 无外键约束 | FK 始终在数据库中强制执行 |
| 4 | 默认可空 | 默认 NOT NULL, 需要时才可空 |
| 5 | FK 列无索引 | 每个 FK 列都建索引 |
| 6 | 单步破坏性迁移 | 分开发布: 添加 → 迁移 → 删除 |
| 7 | `CREATE INDEX` 无 `CONCURRENTLY` | 实时表始终用 `CONCURRENTLY` |
| 8 | 多态 FK (`commentable_type + commentable_id`) | 单独 FK 列或单独表 |
| 9 | 所有内容都用 JSONB | JSONB 仅用于灵活数据, 结构化用列 |
| 10 | 无 `created_at` / `updated_at` | 每个表都有时间戳对 |
| 11 | 单列中逗号分隔值 | 单独表或 PostgreSQL 数组 |
| 12 | `text` 无长度验证 | CHECK 约束或应用验证 |

---

## 常见问题

### 问题 1: "查询慢但我已经有索引了"

**症状:** `EXPLAIN ANALYZE` 显示顺序扫描尽管有索引。

**原因:**
1. **错误的索引列顺序** — 复合索引 `(A, B)` 对 `WHERE B = ?` 无帮助
2. **低选择性** — boolean 列上的索引 (50% 行匹配), 规划器偏好顺序扫描
3. **统计信息过时** — 运行 `ANALYZE table_name;`
4. **类型不匹配** — 将 `varchar` 列与 `integer` 参数比较 → 无索引使用

**修复:** 检查 `EXPLAIN (ANALYZE, BUFFERS)`, 验证索引匹配查询模式, 运行 `ANALYZE`。

### 问题 2: "迁移锁定表数分钟"

**症状:** `ALTER TABLE` 执行期间阻塞所有写入。

**原因:** 添加 NOT NULL 约束, 更改列类型, 或无 `CONCURRENTLY` 创建索引。

**修复:**
```sql
-- 无锁添加索引
CREATE INDEX CONCURRENTLY idx_name ON table(col);

-- 无锁添加 NOT NULL 约束 (Postgres 12+)
ALTER TABLE t ADD CONSTRAINT t_col_nn CHECK (col IS NOT NULL) NOT VALID;
ALTER TABLE t VALIDATE CONSTRAINT t_col_nn;  -- 非阻塞验证
```

### 问题 3: "多少索引算太多?"

**经验法则:**
- 读密集型表 (报表, 产品目录): 5-10 个索引可以
- 写密集型表 (事件, 日志): 最多 2-3 个索引
- 用 `pg_stat_user_indexes` 监控 — 删除 `idx_scan = 0` 的索引

```sql
-- 查找未使用的索引
SELECT schemaname, relname, indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND indexrelname NOT LIKE '%pkey%'
ORDER BY pg_relation_size(indexrelid) DESC;
```
