# 图片生成指南

## CLI 使用

```bash
# 基本用法 (1:1, 1024x1024)
python scripts/minimax_image.py "A cat astronaut floating in space" -o cat.png

# 16:9 用于英雄横幅
python scripts/minimax_image.py "Mountain landscape at golden hour" -o hero.png --ratio 16:9

# 批量：一次生成 4 张图片
python scripts/minimax_image.py "Minimalist product icon" -o icons.png -n 4

# 使用种子以便复现
python scripts/minimax_image.py "Abstract gradient background" -o bg.png --seed 42

# 启用提示词优化
python scripts/minimax_image.py "a dog" -o dog.png --optimize

# Base64 模式（不下载 URL，直接保存）
python scripts/minimax_image.py "Logo concept" -o logo.png --base64
```

## 编程使用

```python
from minimax_image import generate_image, download_and_save

# 生成并获取 URL
result = generate_image("A cat in space", aspect_ratio="16:9")
url = result["data"]["image_urls"][0]
download_and_save(url, "cat.png")

# 生成多张
result = generate_image("Icon design", n=4, aspect_ratio="1:1")
for i, url in enumerate(result["data"]["image_urls"]):
    download_and_save(url, f"icon-{i}.png")
```

## 模型

目前仅支持 `image-01`。

## 比例与尺寸

| 比例 | 像素 | 适用场景 |
|------|------|----------|
| `1:1` | 1024x1024 | 头像、图标、方形缩略图 |
| `16:9` | 1280x720 | 英雄横幅、视频缩略图 |
| `4:3` | 1152x864 | 标准横版 |
| `3:2` | 1248x832 | 照片风格 |
| `2:3` | 832x1248 | 竖版、移动端 |
| `3:4` | 864x1152 | 竖版卡片 |
| `9:16` | 720x1280 | 移动端全屏、故事 |
| `21:9` | 1344x576 | 超宽横幅 |

也支持自定义尺寸：宽度/高度在 [512, 2048] 范围内，必须能被 8 整除。

## 限制

- 提示词：最多 1,500 个字符
- 批量：每次请求 1–9 张图片
- URL 有效期为 24 小时（使用 `--base64` 可避免过期）
- 设置种子可对相同提示词获得可复现的结果