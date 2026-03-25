# 音乐生成指南

## CLI 使用

```bash
# 器乐（无人声）
python scripts/minimax_music.py --prompt "Jazz piano, smooth, relaxing" --instrumental -o jazz.mp3

# 带自定义歌词
python scripts/minimax_music.py --prompt "Indie folk, melancholic" --lyrics "[verse]\nStreetlights flicker\nOn empty roads" -o song.mp3

# 从提示词自动生成歌词
python scripts/minimax_music.py --prompt "Upbeat pop, energetic, summer vibes" --auto-lyrics -o pop.mp3

# 从歌词文件读取
python scripts/minimax_music.py --prompt "Soulful blues, rainy night" --lyrics-file lyrics.txt -o blues.mp3

# 自定义音频设置
python scripts/minimax_music.py --prompt "Lo-fi beats" --instrumental -o lofi.wav --format wav --sample-rate 44100 --bitrate 256000
```

## 编程使用

```python
from minimax_music import generate_music

# 器乐
result = generate_music(prompt="Jazz piano, smooth", is_instrumental=True)
with open("jazz.mp3", "wb") as f:
    f.write(result["audio_bytes"])

# 带歌词
result = generate_music(
    prompt="Indie folk, acoustic guitar",
    lyrics="[verse]\nWalking through the rain\n[chorus]\nI'll find my way home",
)

# 自动生成歌词
result = generate_music(
    prompt="Upbeat pop, summer anthem",
    lyrics_optimizer=True,
)

# 访问元数据
print(f"Duration: {result['duration']}ms")
print(f"Sample rate: {result['sample_rate']}")
print(f"Size: {result['size']} bytes")
```

## 模型

| 模型 | 特性 |
|------|------|
| `music-2.5+` | 推荐。支持器乐模式、完整歌曲结构、高保真音频 |
| `music-2.5` | 标准模型。无器乐模式 |

## 提示词写作

`prompt` 参数使用逗号分隔的描述符来描述音乐风格：

| 类别 | 示例 |
|------|------|
| 风格 | Blues、Pop、Rock、Jazz、Electronic、Hip-hop、Folk、Classical |
| 情绪 | Soulful、Melancholy、Upbeat、Energetic、Peaceful、Dark、Nostalgic |
| 场景 | Rainy night、Summer day、Road trip、Late night、Sunrise |
| 乐器 | Electric guitar、Piano、Acoustic、Synthesizer、Strings |
| 人声类型 | Male vocals、Female vocals、Soft vocals、Powerful vocals |
| 节奏 | Slow tempo、Fast tempo、Mid-tempo、Relaxed |

**提示词示例：**
```
"Soulful Blues, Rainy Night, Melancholy, Male Vocals, Slow Tempo"
"Upbeat Pop, Summer Vibes, Female Vocals, Energetic, Synth-heavy"
"Lo-fi Hip-hop, Chill, Relaxed, Instrumental, Piano samples"
"Cinematic Orchestral, Epic, Building tension, Strings and Brass"
```

## 歌词格式

使用方括号中的结构标签来组织歌曲段落：

### 结构标签

| 标签 | 用途 |
|------|------|
| `[Intro]` | 开场（可以是器乐） |
| `[Verse]` / `[Verse 1]` | 故事/叙事段落 |
| `[Pre-Chorus]` | 主歌前的铺垫 |
| `[Chorus]` | 主钩子，通常重复 |
| `[Post Chorus]` | 主歌后的延伸 |
| `[Bridge]` | 接近尾声的对比段落 |
| `[Interlude]` | 器乐间奏 |
| `[Solo]` | 器乐独奏（可加方向："slow, bluesy"） |
| `[Outro]` | 结尾段落 |
| `[Break]` | 短暂停或过渡 |
| `[Hook]` |  catchy 重复短语 |
| `[Build Up]` | 紧张感积累段落 |
| `[Inst]` | 器乐段落 |
| `[Transition]` | 段落转换 |

### 伴唱与方向说明

使用圆括号表示伴唱或表演注释：
```
(Ooh, yeah)
(Harmonize)
(Whispered)
(Fade out...)
```

### 歌词示例

```
[Intro]
(Soft piano)

[Verse 1]
Streetlights flicker on empty roads
The rain keeps falling, the wind still blows
I'm walking home with nowhere to go
Just memories of what I used to know

[Pre-Chorus]
And I can feel it coming back to me
(Coming back to me)

[Chorus]
Under the neon lights tonight
I'm searching for what feels right
(Oh, feels right)
These city streets will guide me home
I'm tired of feeling so alone

[Verse 2]
Coffee shops and midnight trains
The faces change but the feeling remains
...

[Bridge]
Maybe tomorrow will be different
Maybe I'll finally understand
(Understand...)

[Solo]
(Slow, mournful, bluesy guitar)

[Outro]
(Fade out...)
Under the neon lights...
```

## 音频设置

| 参数 | 选项 | 默认值 | 说明 |
|------|------|--------|------|
| `format` | mp3, wav, pcm | mp3 | WAV 最高质量 |
| `sample_rate` | 16000, 24000, 32000, 44100 | 44100 | 推荐 44100 |
| `bitrate` | 32000, 64000, 128000, 256000 | 256000 | 越高 = 越好质量 |

## 生成模式

### 1. 仅器乐
```bash
python scripts/minimax_music.py --prompt "Ambient electronic, space theme" --instrumental -o ambient.mp3
```
- 需要 `music-2.5+` 模型
- 只需 `prompt`，不需要歌词

### 2. 带自定义歌词
```bash
python scripts/minimax_music.py --prompt "Pop ballad, emotional" --lyrics "[verse]\nYour lyrics here" -o ballad.mp3
```
- 同时提供 `prompt`（风格）和 `lyrics`（文字+结构）

### 3. 自动生成歌词
```bash
python scripts/minimax_music.py --prompt "Rock anthem about freedom" --auto-lyrics -o rock.mp3
```
- 系统从提示词生成歌词
- 当歌词不是关键时适合快速生成

## 限制

- **提示词：** 最多 2,000 个字符
- **歌词：** 1–3,500 个字符
- **时长：** 每次生成约 25-30 秒（因内容而异）
- **URL 过期：** 24 小时（使用 URL 输出模式时）

## 最佳实践

1. **叠加风格描述符** — 结合风格 + 情绪 + 乐器以获得精确结果
2. **使用结构标签** — 即使简单的 `[verse]` `[chorus]` 也能改善编曲
3. **包含伴唱提示** — `(Ooh)`、`(Yeah)` 添加制作质感
4. **提示词与歌词情绪匹配** — 冲突的 prompt/lyrics 会产生不一致的结果
5. **背景音乐用器乐** — 使用 `--instrumental` 作为 BGM，避免人声干扰
6. **成品用高码率** — 最终资产用 256000，草稿用较低码率

## 常见用例

| 用例 | 命令 |
|------|------|
| 背景音乐 | `--prompt "Lo-fi, calm, ambient" --instrumental` |
| 落地页英雄区 | `--prompt "Cinematic, inspiring, building" --instrumental` |
| 播客开场 | `--prompt "Upbeat, energetic, short" --instrumental` |
| 演示歌曲 | `--prompt "Pop, catchy" --auto-lyrics` |
| 自定义 jingle | `--prompt "Happy, bright, corporate" --lyrics "[hook]\nYour brand name"` |

## 错误处理

| 错误码 | 含义 | 解决方案 |
|--------|------|----------|
| 1002 | 速率限制 | 等待后重试 |
| 1004 | 认证失败 | 检查 API 密钥 |
| 1008 | 余额不足 | 充值账户 |
| 1026 | 内容被拦截 | 重新措辞提示词/歌词 |
| 2013 | 参数无效 | 检查提示词/歌词长度 |