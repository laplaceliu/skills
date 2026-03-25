# TTS 语音合成指南

## CLI 使用方法（推荐）

```bash
# 基本用法
python scripts/minimax_tts.py "Hello world" -o output.mp3

# 自定义声音和语速
python scripts/minimax_tts.py "你好世界" -o hi.mp3 -v female-shaonv --speed 0.9

# WAV 格式，高质量
python scripts/minimax_tts.py "Welcome" -o out.wav -v male-qn-jingying --format wav --sample-rate 32000

# 带情绪（用于 speech-2.6 模型）
python scripts/minimax_tts.py "Great news!" -o happy.mp3 -v female-shaonv --emotion happy --model speech-2.6-hd
```

## 编程使用

```python
from minimax_tts import tts

# 基本用法
audio_bytes = tts("Hello world")

# 带选项
audio_bytes = tts(
    text="Welcome to our product.",
    voice_id="female-shaonv",
    model="speech-2.8-hd",
    speed=0.9,
    fmt="mp3",
)

# 保存到文件
with open("output.mp3", "wb") as f:
    f.write(audio_bytes)
```

## 限制

- **同步 TTS：** 每次请求最多 10,000 个字符
- **暂停标记：** 插入 `<#1.5#>` 表示 1.5 秒暂停（范围：0.01–99.99 秒）

## 模型选择

| 模型 | 最佳用途 |
|------|----------|
| `speech-2.8-hd` | 最高质量，自动情绪（推荐） |
| `speech-2.8-turbo` | 快速，良好质量 |
| `speech-2.6-hd` | 需要手动情绪控制 |
| `speech-2.6-turbo` | 快速 + 手动情绪 |

## 选择声音

完整列表参见 [minimax-voice-catalog.md](minimax-voice-catalog.md)。

常用声音：

| Voice ID | 性别 | 风格 |
|----------|------|------|
| `male-qn-qingse` | 男 | 年轻，温柔 |
| `male-qn-jingying` | 男 | 精英，权威 |
| `male-qn-badao` | 男 | 霸道，强力 |
| `female-shaonv` | 女 | 年轻，明亮 |
| `female-yujie` | 女 | 成熟，优雅 |
| `female-chengshu` | 女 | 精致 |
| `presenter_male` | 男 | 新闻主持人 |
| `presenter_female` | 女 | 新闻主持人 |
| `audiobook_male_1` | 男 | 有声书旁白 |
| `audiobook_female_1` | 女 | 有声书旁白 |

## 最佳实践

- 使用 `speech-2.8-hd` 并让情绪自动匹配——除非有需要，否则不要手动设置情绪
- 网页音频使用 32000 采样率（质量和文件大小平衡良好）
- 长文本（>10,000 字符）需拆分成块并用 FFmpeg 合并