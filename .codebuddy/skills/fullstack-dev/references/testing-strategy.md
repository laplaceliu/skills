# 后端测试策略

后端和全栈应用的全面测试指南。涵盖完整的测试金字塔，深入关注 API 集成测试、数据库测试、契约测试和性能测试。

## 快速开始清单

- [ ] **测试运行器已配置** (Jest/Vitest, Pytest, Go test)
- [ ] **测试数据库**就绪 (Docker 容器或内存中)
- [ ] **数据库隔离**每测试 (事务回滚或截断)
- [ ] **测试工厂**用于常见实体 (user, order, product)
- [ ] **认证辅助**为测试生成令牌
- [ ] **CI 流水线**用真实数据库服务运行测试
- [ ] **覆盖率阈值**强制执行 (≥ 80%)

---

## 测试金字塔

```
         ╱╲        E2E (少量, 慢) — 跨服务的完整流程
        ╱  ╲
       ╱────╲       集成 (适量) — API + DB + 外部
      ╱      ╲
     ╱────────╲      单元 (大量, 快) — 纯业务逻辑
    ╱__________╲
```

| 层级 | 什么 | 速度 | 数量 |
|-------|------|-------|-------|
| 单元 | 纯函数, 业务逻辑, 无 I/O | < 10ms | 70%+ 的测试 |
| 集成 | API 路由 + 真实数据库 + mock 外部 | 50-500ms | ~20% |
| E2E | 跨已部署服务的完整用户流程 | 1-30s | ~10% |
| 契约 | 服务间 API 兼容性 | < 100ms | 每个 API 边界 |
| 性能 | 负载, 压力, 浸泡 | 分钟 | 每个关键路径 |

---

## 1. API 集成测试 (关键)

### 每个端点测试什么

| 方面 | 要写的测试 |
|--------|---------------|
| 主流程 | 正确输入 → 预期响应 + 正确 DB 状态 |
| 认证 | 无令牌 → 401, 错误令牌 → 401, 过期 → 401 |
| 授权 | 错误角色 → 403, 非所有者 → 403 |
| 验证 | 缺失字段 → 422, 错误类型 → 422, 边界值 |
| 未找到 | 无效 ID → 404, 已删除资源 → 404 |
| 冲突 | 重复创建 → 409, 过期更新 → 409 |
| 幂等性 | 相同请求两次 → 相同结果 |
| 副作用 | DB 状态改变, 事件发出, 缓存失效 |
| 错误格式 | 所有错误符合 RFC 9457 信封 |

### TypeScript (Jest + Supertest)

```typescript
describe('POST /api/orders', () => {
  let token: string;
  let product: Product;

  beforeAll(async () => {
    await resetDatabase();
    const user = await createTestUser({ role: 'customer' });
    token = await getAuthToken(user);
    product = await createTestProduct({ price: 29.99, stock: 10 });
  });

  it('creates order → 201 + correct DB state', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${token}`)
      .send({ items: [{ productId: product.id, quantity: 2 }] });

    expect(res.status).toBe(201);
    expect(res.body.data.total).toBe(59.98);

    const updated = await db.product.findUnique({ where: { id: product.id } });
    expect(updated!.stock).toBe(8);
  });

  it('rejects without auth → 401', async () => {
    const res = await request(app).post('/api/orders').send({ items: [] });
    expect(res.status).toBe(401);
  });

  it('rejects empty items → 422', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${token}`)
      .send({ items: [] });
    expect(res.status).toBe(422);
    expect(res.body.errors[0].field).toBe('items');
  });
});
```

### Python (Pytest + FastAPI TestClient)

```python
@pytest.fixture
def client(db_session):
    def override_get_db():
        yield db_session
    app.dependency_overrides[get_db] = override_get_db
    yield TestClient(app)
    app.dependency_overrides.clear()

def test_create_order_success(client, auth_headers, test_product):
    response = client.post("/api/orders", json={
        "items": [{"product_id": test_product.id, "quantity": 2}]
    }, headers=auth_headers)
    assert response.status_code == 201
    assert response.json()["data"]["total"] == 59.98

def test_create_order_no_auth(client):
    response = client.post("/api/orders", json={"items": []})
    assert response.status_code == 401

def test_create_order_empty_items(client, auth_headers):
    response = client.post("/api/orders", json={"items": []}, headers=auth_headers)
    assert response.status_code == 422
```

---

## 2. 数据库测试 (高)

### 测试隔离策略

| 策略 | 速度 | 真实性 | 何时使用 |
|----------|-------|---------|------|
| **事务回滚** |  最快 | 中 | 单元 + 集成的默认 |
| **截断** | 快 | 高 | 回滚不可能时 |
| **测试容器** | 启动慢 | 最高 | CI 流水线, 完整集成 |

**事务回滚 (推荐默认):**
```typescript
let tx: Transaction;
beforeEach(async () => { tx = await db.beginTransaction(); });
afterEach(async () => { await tx.rollback(); });
```

**Docker 测试容器 (CI):**
```yaml
# docker-compose.test.yml
services:
  test-db:
    image: postgres:16-alpine
    tmpfs: /var/lib/postgresql/data   # RAM 磁盘加速
    environment:
      POSTGRES_DB: myapp_test
```

### 测试工厂 (非原始 SQL)

```typescript
// factories/user.factory.ts
import { faker } from '@faker-js/faker';

export function buildUser(overrides: Partial<User> = {}): CreateUserDTO {
  return {
    email: faker.internet.email(),
    firstName: faker.person.firstName(),
    role: 'customer',
    ...overrides,
  };
}
export async function createUser(overrides = {}) {
  return db.user.create({ data: buildUser(overrides) });
}
```

```python
# factories/user_factory.py
import factory
from faker import Faker

class UserFactory(factory.Factory):
    class Meta:
        model = User
    email = factory.LazyAttribute(lambda _: Faker().email())
    first_name = factory.LazyAttribute(lambda _: Faker().first_name())
    role = "customer"
```

---

## 3. 外部服务测试 (高)

### HTTP 级 Mocking (非函数 Mocking)

**TypeScript (nock):**
```typescript
import nock from 'nock';

it('processes payment successfully', async () => {
  nock('https://api.stripe.com')
    .post('/v1/charges')
    .reply(200, { id: 'ch_123', status: 'succeeded', amount: 5000 });

  const result = await paymentService.charge({ amount: 50.00, currency: 'usd' });
  expect(result.status).toBe('succeeded');
});

it('handles payment timeout', async () => {
  nock('https://api.stripe.com').post('/v1/charges').delay(10000).reply(200);
  await expect(paymentService.charge({ amount: 50, currency: 'usd' }))
    .rejects.toThrow('timeout');
});
```

**Python (responses):**
```python
import responses

@responses.activate
def test_payment_success():
    responses.post("https://api.stripe.com/v1/charges",
                   json={"id": "ch_123", "status": "succeeded"}, status=200)
    result = payment_service.charge(amount=50.00, currency="usd")
    assert result.status == "succeeded"
```

### 基础设施测试容器

```typescript
import { PostgreSqlContainer } from '@testcontainers/postgresql';
import { RedisContainer } from '@testcontainers/redis';

beforeAll(async () => {
  const pg = await new PostgreSqlContainer('postgres:16').start();
  process.env.DATABASE_URL = pg.getConnectionUri();
  await runMigrations();
}, 60000);
```

---

## 4. 契约测试 (中-高)

### 消费者驱动契约 (Pact)

**消费者 (OrderService 调用 UserService):**
```typescript
it('can fetch user by ID', async () => {
  await pact.addInteraction()
    .given('user usr_123 exists')
    .uponReceiving('GET /users/usr_123')
    .withRequest('GET', '/api/users/usr_123')
    .willRespondWith(200, (b) => {
      b.jsonBody({ data: { id: MatchersV3.string(), email: MatchersV3.email() } });
    })
    .executeTest(async (mockserver) => {
      const user = await new UserClient(mockserver.url).getUser('usr_123');
      expect(user.id).toBeDefined();
    });
});
```

**提供者在 CI 中验证:**
```typescript
await new Verifier({
  providerBaseUrl: 'http://localhost:3001',
  pactBrokerUrl: process.env.PACT_BROKER_URL,
  provider: 'UserService',
}).verifyProvider();
```

---

## 5. 性能测试 (中)

### k6 负载测试

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 },    // 爬坡
    { duration: '1m',  target: 100 },   // 持续
    { duration: '30s', target: 0 },     // 降坡
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};

export default function () {
  const res = http.get(`${__ENV.BASE_URL}/api/orders`);
  check(res, { 'status 200': (r) => r.status === 200 });
  sleep(1);
}
```

### 性能预算

| 指标 | 目标 | 超标时操作 |
|--------|--------|--------------------|
| p95 响应时间 | < 500ms | 优化查询/缓存 |
| p99 响应时间 | < 1000ms | 检查异常查询 |
| 错误率 | < 0.1% | 调查激增 |
| DB 查询时间 | < 100ms 每个 | 添加索引 |

### 何时运行

| 触发条件 | 测试类型 |
|---------|-----------|
| 主要发布前 | 完整负载测试 |
| 新 DB 查询/索引 | 查询基准测试 |
| 基础设施变更 | 基线比较 |
| 每周 (CI) | 冒烟负载测试 |

---

## 测试文件组织

```
tests/
  unit/                      # 纯逻辑, mock 依赖
    order.service.test.ts
  integration/               # API + 真实 DB
    orders.api.test.ts
    auth.api.test.ts
  contracts/                 # 消费者驱动契约
    user-service.consumer.pact.ts
  performance/               # 负载测试
    load-test.js
  fixtures/
    factories/               # 测试数据工厂
      user.factory.ts
    seeds/
      test-data.ts
  helpers/
    setup.ts                 # 全局测试配置
    auth.helper.ts           # 令牌生成
    db.helper.ts             # DB 清理
```

---

## 反模式

| # |  不要 |  应该这样做 |
|---|---------|--------------|
| 1 | 仅测试主流程 | 测试错误, 认证, 验证, 边界情况 |
| 2 | 所有内容都 mock (无真实 DB) | 使用测试容器或测试 DB |
| 3 | 测试依赖执行顺序 | 每个测试设置/拆卸自己的状态 |
| 4 | 硬编码测试数据 | 使用工厂 (faker + 覆盖) |
| 5 | 测试实现细节 | 测试行为: 输入 → 输出 |
| 6 | 共享可变状态 | 每测试隔离 (事务回滚) |
| 7 | CI 中跳过迁移测试 | 在 CI 中从零运行迁移 |
| 8 | 发布前无性能测试 | 每个主要发布都进行负载测试 |
| 9 | 针对生产数据测试 | 仅生成测试数据 |
| 10 | 测试套件 > 10 分钟 | 并行化, RAM 磁盘, 优化设置 |

---

## 常见问题

### 问题 1: "测试单独通过但一起失败"

**原因:** 测试间共享数据库状态。缺少清理。

**修复:**
```typescript
beforeEach(async () => { await db.raw('TRUNCATE orders, users CASCADE'); });
// 或每测试使用事务回滚
```

### 问题 2: "Jest 在测试运行后一秒未退出"

**原因:** 未关闭的数据库连接或 HTTP 服务器。

**修复:**
```typescript
afterAll(async () => {
  await db.destroy();
  await server.close();
});
```

### 问题 3: "异步回调在超时内未被调用"

**原因:** 缺少 `async/await` 或未处理的 promise。

**修复:**
```typescript
//  Promise 未等待
it('should work', () => { request(app).get('/users'); });

//  正确等待
it('should work', async () => { await request(app).get('/users'); });
```

### 问题 4: "CI 中集成测试太慢"

**修复:**
1. PostgreSQL 数据目录用 `tmpfs` (RAM 磁盘)
2. `beforeAll` 中运行迁移一次, `beforeEach` 中截断
3. 用 `--maxWorkers` 并行化测试套件
4. 功能分支跳过性能测试 (仅 main 分支)
