# 提供商参考 — MiniMax

所有资产生成均使用 MiniMax API。环境变量：`MINIMAX_API_KEY`（必填）。

## 音频（同步 TTS）

**脚本：** `scripts/minimax_tts.py`

```bash
python scripts/minimax_tts.py "Hello world" -o output.mp3
python scripts/minimax_tts.py "你好" -o hi.mp3 -v female-shaonv
python scripts/minimax_tts.py "Welcome" -o out.wav -v male-qn-jingying --speed 0.8 --format wav
```

**模型：** `speech-2.8-hd`（默认）。

| 参数 | 默认值 | 范围 / 选项 |
|------|--------|-------------|
| `-o` | （必填） | 输出文件路径 |
| `-v` | `male-qn-qingse` | 声音 ID |
| `--model` | `speech-2.8-hd` | speech-2.8-hd / speech-2.8-turbo / speech-2.6-hd / speech-2.6-turbo |
| `--speed` | 1.0 | 0.5–2.0 |
| `--volume` | 1.0 | 0.1–10 |
| `--pitch` | 0 | -12 到 12 |
| `--emotion` | （自动） | happy / sad / angry / fearful / disgusted / surprised / calm / fluent / whisper |
| `--format` | mp3 | mp3 / wav / flac |
| `--lang` | auto | 语言增强 |

**编程使用：**
```python
from minimax_tts import tts
audio_bytes = tts("Hello", voice_id="female-shaonv")
```


## 视频（文生视频）

**脚本：** `scripts/minimax_video.py`

```bash
python scripts/minimax_video.py "A cat playing piano" -o cat.mp4
python scripts/minimax_video.py "Ocean waves [Truck left]" -o waves.mp4 --duration 10
python scripts/minimax_video.py "City skyline [Push in]" -o city.mp4 --resolution 1080P
```

**模型：** `MiniMax-Hailuo-2.3`（默认）。异步处理：脚本自动处理创建 → 轮询 → 下载。

| 参数 | 默认值 | 选项 |
|------|--------|------|
| `-o` | （必填） | 输出文件路径（.mp4） |
| `--model` | `MiniMax-Hailuo-2.3` | MiniMax-Hailuo-2.3 / MiniMax-Hailuo-02 / T2V-01-Director / T2V-01 |
| `--duration` | 6 | 6 / 10（仅 768P 的 Hailuo 模型支持 10 秒） |
| `--resolution` | 768P | 720P / 768P / 1080P（1080P 仅 6 秒） |
| `--no-optimize` | false | 禁用提示词自动优化 |
| `--poll-interval` | 10 | 状态检查间隔（秒） |
| `--max-wait` | 600 | 最大等待时间（秒） |

**相机命令** — 在提示词中插入 `[命令]`：`[Push in]`、`[Truck left]`、`[Pan right]`、`[Zoom out]`、`[Static shot]`、`[Tracking shot]` 等。

**编程使用：**
```python
from minimax_video import generate
generate("A cat playing piano", "cat.mp4", model="MiniMax-Hailuo-2.3", duration=6)
```

完整相机命令列表和模型兼容性参见 [minimax-video-guide.md](minimax-video-guide.md)。

## 图片（文生图）

**脚本：** `scripts/minimax_image.py`

```bash
python scripts/minimax_image.py "A cat astronaut in space" -o cat.png
python scripts/minimax_image.py "Mountain landscape" -o hero.png --ratio 16:9
python scripts/minimax_image.py "Product icons, flat style" -o icons.png -n 4 --seed 42
```

**模型：** `image-01`。同步：立即返回图片 URL（或 base64）。

| 参数 | 默认值 | 选项 |
|------|--------|------|
| `-o` | （必填） | 输出文件路径（.png/.jpg） |
| `--ratio` | 1:1 | 1:1 / 16:9 / 4:3 / 3:2 / 2:3 / 3:4 / 9:16 / 21:9 |
| `-n` | 1 | 图片数量（1–9） |
| `--seed` | （随机） | 复现用种子 |
| `--optimize` | false | 启用提示词自动优化 |
| `--base64` | false | 返回 base64 而不是 URL |

**批量输出：** 使用 `-n > 1` 时，文件命名为 `out-0.png`、`out-1.png` 等。

**编程使用：**
```python
from minimax_image import generate_image, download_and_save
result = generate_image("A cat in space", aspect_ratio="16:9")
download_and_save(result["data"]["image_urls"][0], "cat.png")
```

比例尺寸和详情参见 [minimax-image-guide.md](minimax-image-guide.md)。

## 音乐（文生音乐）

**脚本：** `scripts/minimax_music.py`

```bash
python scripts/minimax_music.py --prompt "Indie folk, melancholic" --lyrics "[verse]\nStreetlights flicker" -o song.mp3
python scripts/minimax_music.py --prompt "Upbeat pop, energetic" --auto-lyrics -o pop.mp3
python scripts/minimax_music.py --prompt "Jazz piano, smooth, relaxing" --instrumental -o jazz.mp3
```

**模型：** `music-2.5+`（默认）。同步：返回音频 hex 或 URL。

| 参数 | 默认值 | 选项 |
|------|--------|------|
| `-o` | （必填） | 输出文件路径（.mp3/.wav） |
| `--prompt` | （空） | 音乐描述：风格、情绪、场景（最多 2000 字符） |
| `--lyrics` | （空） | 带结构标签的歌词（最多 3500 字符） |
| `--lyrics-file` | （空） | 从文件读取歌词 |
| `--model` | `music-2.5+` | music-2.5+ / music-2.5 |
| `--instrumental` | false | 仅生成器乐（无人声，仅 music-2.5+） |
| `--auto-lyrics` | false | 从提示词自动生成歌词 |
| `--format` | mp3 | mp3 / wav / pcm |
| `--sample-rate` | 44100 | 16000 / 24000 / 32000 / 44100 |
| `--bitrate` | 256000 | 32000 / 64000 / 128000 / 256000 |

**歌词结构标签：** `[Intro]`、`[Verse]`、`[Pre Chorus]`、`[Chorus]`、`[Interlude]`、`[Bridge]`、`[Outro]`、`[Post Chorus]`、`[Transition]`、`[Break]`、`[Hook]`、`[Build Up]`、`[Inst]`、`[Solo]`。

**编程使用：**
```python
from minimax_music import generate_music
result = generate_music(prompt="Jazz piano", is_instrumental=True)
with open("jazz.mp3", "wb") as f:
    f.write(result["audio_bytes"])
```