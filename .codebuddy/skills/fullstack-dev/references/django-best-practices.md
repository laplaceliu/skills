# Django 最佳实践

面向 Django 5.x 和 Django REST Framework 的生产级指南。8 个类别的 40+ 条规则。

## 核心原则 (7 条规则)

```
1. 在第一次迁移前自定义 User 模型 (以后无法更改)
2. 每个领域概念一个 Django 应用 (users, orders, payments)
3. 胖模型, 瘦视图 — 业务逻辑在模型/管理器中, 不在视图中
4. 始终使用 select_related/prefetch_related (防止 N+1)
5. 按环境拆分设置 (base + dev + prod)
6. 用 pytest-django + factory_boy 测试 (不用 fixtures)
7. 生产环境绝不用 runserver (Gunicorn + Nginx)
```

---

## 1. 项目结构 (关键)

### 每领域一个应用

```
myproject/
├── config/                     # 项目配置
│   ├── __init__.py
│   ├── settings/
│   │   ├── base.py             # 共享设置
│   │   ├── dev.py              # DEBUG=True, SQLite 可以
│   │   └── prod.py             # DEBUG=False, Postgres, HTTPS
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
├── apps/
│   ├── users/                  # 自定义 User 模型
│   │   ├── models.py
│   │   ├── serializers.py
│   │   ├── views.py
│   │   ├── urls.py
│   │   ├── admin.py
│   │   ├── services.py         # 业务逻辑
│   │   ├── selectors.py        # 复杂查询
│   │   └── tests/
│   │       ├── test_models.py
│   │       ├── test_views.py
│   │       └── factories.py
│   ├── orders/
│   └── payments/
├── manage.py
├── requirements/
│   ├── base.txt
│   ├── dev.txt
│   └── prod.txt
└── docker-compose.yml
```

### 规则

```
 一个应用 = 一个限界上下文 (users, orders, payments)
 业务逻辑在 services.py / selectors.py, 不在视图中
 每个应用有自己的 urls.py, admin.py, tests/

绝不要把所有内容放在一个应用中
绝不要在模型层跨应用边界导入 (使用 ID)
绝不要把业务逻辑放在视图或序列化器中
```

---

## 2. 模型与迁移 (关键)

### 自定义 User 模型 (第一天!)

```python
# apps/users/models.py
from django.contrib.auth.models import AbstractUser
from django.db import models
import uuid

class User(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username']

    class Meta:
        db_table = 'users'

# config/settings/base.py
AUTH_USER_MODEL = 'users.User'
```

**这必须在 `migrate` 之前完成。之后无法更改。**

### 模型最佳实践

```python
class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    class Meta:
        abstract = True

class Order(TimeStampedModel):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='orders')
    status = models.CharField(max_length=20, choices=OrderStatus.choices, default=OrderStatus.PENDING, db_index=True)
    total = models.DecimalField(max_digits=10, decimal_places=2)

    class Meta:
        db_table = 'orders'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'status']),
        ]

    def can_cancel(self) -> bool:
        return self.status in [OrderStatus.PENDING, OrderStatus.CONFIRMED]

    def cancel(self):
        if not self.can_cancel():
            raise ValueError(f"Cannot cancel order in {self.status} status")
        self.status = OrderStatus.CANCELLED
        self.save(update_fields=['status', 'updated_at'])
```

### 迁移规则

```
 审查迁移 SQL: python manage.py sqlmigrate app_name 0001
 描述性命名迁移: --name add_status_index_to_orders
 数据迁移与模式迁移分开
 非破坏性优先: 添加列 → 回填 → 删除旧列

绝不编辑或删除已应用的迁移
绝不在无 reverse 函数的情况下使用 RunPython
```

---

## 3. 视图与序列化器 — DRF (高)

### 服务层模式

```python
# apps/orders/services.py
from django.db import transaction

class OrderService:
    @staticmethod
    @transaction.atomic
    def create_order(user, items_data: list[dict]) -> Order:
        total = sum(item['price'] * item['quantity'] for item in items_data)
        order = Order.objects.create(user=user, total=total)
        OrderItem.objects.bulk_create([
            OrderItem(order=order, **item) for item in items_data
        ])
        return order

    @staticmethod
    def cancel_order(order_id: str, user) -> Order:
        order = Order.objects.select_for_update().get(id=order_id, user=user)
        order.cancel()
        return order
```

### 序列化器

```python
class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    class Meta:
        model = Order
        fields = ['id', 'status', 'total', 'items', 'created_at']
        read_only_fields = ['id', 'total', 'created_at']

class CreateOrderSerializer(serializers.Serializer):
    """仅输入序列化器 — 与输出分开。"""
    items = serializers.ListField(
        child=serializers.DictField(), min_length=1, max_length=50,
    )
    def validate_items(self, items):
        for item in items:
            if item.get('quantity', 0) < 1:
                raise serializers.ValidationError("Quantity must be at least 1")
        return items
```

### 视图 (瘦!)

```python
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order(request):
    serializer = CreateOrderSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    order = OrderService.create_order(request.user, serializer.validated_data['items'])
    return Response({'data': OrderSerializer(order).data}, status=status.HTTP_201_CREATED)
```

### 规则

```
 输入序列化器与输出序列化器分开
 视图仅: 验证 → 调用服务 → 序列化 → 响应
 多模型写入使用 @transaction.atomic

绝不要把业务逻辑放在视图或序列化器中
绝不要对写操作使用 ModelSerializer (太隐式)
```

---

## 4. 认证 (高)

| 方法 | 何时使用 | 前端 |
|--------|------|----------|
| Session | 同域, SSR, Django 模板 | Django 模板 / htmx |
| JWT | 不同域, SPA, 移动端 | React, Vue, 移动应用 |
| OAuth2 | 第三方登录, API 消费者 | 任意 |

### JWT 配置 (djangorestframework-simplejwt)

```python
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=15),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'BLACKLIST_AFTER_ROTATION': True,
}
```

---

## 5. 性能优化 (高)

### N+1 查询预防

```python
#  N+1: 1 次 orders 查询 + N 次 users 查询
orders = Order.objects.all()
for o in orders:
    print(o.user.email)     # 每次迭代都访问 DB

#  select_related (FK/OneToOne — JOIN)
orders = Order.objects.select_related('user').all()

#  prefetch_related (ManyToMany/反向 FK — 2 次查询)
orders = Order.objects.prefetch_related('items').all()

#  组合
orders = Order.objects.select_related('user').prefetch_related('items').all()
```

### 查询优化工具包

```python
# 仅获取需要的列
User.objects.values('id', 'email')
User.objects.values_list('email', flat=True)

# 用注解代替 Python 循环
from django.db.models import Count, Sum
Order.objects.annotate(item_count=Count('items'), revenue=Sum('items__price'))

# 批量操作
OrderItem.objects.bulk_create([...])
Order.objects.filter(status='pending').update(status='cancelled')

# 数据库索引
class Meta:
    indexes = [
        models.Index(fields=['user', 'status']),
        models.Index(fields=['-created_at']),
        models.Index(fields=['email'], condition=Q(is_active=True)),
    ]

# 分页
from rest_framework.pagination import CursorPagination
class OrderPagination(CursorPagination):
    page_size = 20
    ordering = '-created_at'
```

### 缓存

```python
from django.core.cache import cache

def get_product(product_id: str):
    cache_key = f'product:{product_id}'
    product = cache.get(cache_key)
    if product is None:
        product = Product.objects.get(id=product_id)
        cache.set(cache_key, product, timeout=300)
    return product
```

---

## 6. 测试 (中-高)

### pytest-django + factory_boy

```python
# conftest.py
@pytest.fixture
def api_client():
    return APIClient()

@pytest.fixture
def authenticated_client(api_client, user_factory):
    user = user_factory()
    api_client.force_authenticate(user=user)
    return api_client
```

```python
# factories.py
class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User
    email = factory.Sequence(lambda n: f'user{n}@example.com')
    username = factory.Sequence(lambda n: f'user{n}')

class OrderFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = 'orders.Order'
    user = factory.SubFactory(UserFactory)
    total = factory.Faker('pydecimal', left_digits=3, right_digits=2, positive=True)
```

```python
# test_views.py
@pytest.mark.django_db
class TestListOrders:
    def test_returns_user_orders(self, authenticated_client):
        OrderFactory.create_batch(3, user=authenticated_client.handler._force_user)
        response = authenticated_client.get('/api/orders/')
        assert response.status_code == 200
        assert len(response.data['data']) == 3

    def test_requires_authentication(self, api_client):
        response = api_client.get('/api/orders/')
        assert response.status_code == 401
```

---

## 7. 管理后台定制 (中)

```python
class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 0
    readonly_fields = ['price']

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ['id', 'user', 'status', 'total', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['user__email', 'id']
    readonly_fields = ['id', 'created_at', 'updated_at']
    inlines = [OrderItemInline]
    date_hierarchy = 'created_at'

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user')
```

---

## 8. 生产部署 (中)

### 安全设置

```python
# settings/prod.py
DEBUG = False
ALLOWED_HOSTS = ['example.com', 'www.example.com']
CSRF_TRUSTED_ORIGINS = ['https://example.com']
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000
```

### 部署栈

```
Nginx → Gunicorn → Django
         ↕
      PostgreSQL + Redis (缓存)
         ↕
      Celery (后台任务)
```

```bash
gunicorn config.wsgi:application \
  --bind 0.0.0.0:8000 \
  --workers 4 \
  --timeout 120 \
  --access-logfile -
```

### WhiteNoise 用于静态文件

```python
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',  # 紧跟 Security 之后
    ...
]
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
```

### 规则

```
 Gunicorn + Nginx (或 Cloud Run / Railway)
 PostgreSQL (非 SQLite)
 python manage.py check --deploy
 Sentry 用于错误追踪

生产环境绝不用 runserver
生产环境绝不用 DEBUG=True
生产环境绝不用 SQLite
```

---

## 反模式

| # |  不要 |  应该这样做 |
|---|---------|--------------|
| 1 | 视图中的业务逻辑 | 服务层 (`services.py`) |
| 2 | 一个巨大应用 | 每领域一个应用 |
| 3 | 默认 User 模型 | 第一次 migrate 前自定义 User |
| 4 | 无 `select_related` | 始终急切加载相关对象 |
| 5 | Django fixtures 用于测试 | `factory_boy` factories |
| 6 | 单个 `settings.py` 文件 | 拆分: base + dev + prod |
| 7 | 生产环境用 `runserver` | Gunicorn + Nginx |
| 8 | 生产环境用 SQLite | PostgreSQL |
| 9 | 写操作用 `ModelSerializer` | 显式输入序列化器 |
| 10 | 视图中用原始 SQL | ORM querysets + `selectors.py` |

---

## 常见问题

### 问题 1: "第一次迁移后无法更改 User 模型"

**修复:** 如果全新开始: 删除所有迁移 + DB, 设置自定义 User, 重新迁移。如果有数据: 复杂迁移 (使用 `django-allauth` 或增量字段迁移)。

### 问题 2: "大型查询集上序列化器太慢"

**修复:** 缺少 `select_related` / `prefetch_related` → N+1 查询。
```python
queryset = Order.objects.select_related('user').prefetch_related('items')
```

### 问题 3: "应用间循环导入"

**修复:** 使用字符串引用: `models.ForeignKey('orders.Order', ...)` 代替导入模型类。对于服务, 在函数内部导入。
