# 故障排除

## 快速参考

| 错误 | 原因 | 修复方法 |
|------|------|----------|
| `MINIMAX_API_KEY is not set` | 密钥未设置 | `export MINIMAX_API_KEY="key"` |
| `401 Unauthorized` | 密钥无效/过期 | 检查密钥有效性 |
| `429 Too Many Requests` | 速率限制 | 请求之间添加延迟 |
| `TimeoutError` | 网络问题或文本过长 | 对长文本使用异步 TTS，检查网络 |
| `invalid params, method t2a-v2 not have model` | 模型名称错误 | 使用 `speech-2.8-hd`（用连字符，不是下划线） |
| `brotli: decoder process called...` | 编码问题 | 已在 utils.py 中修复（Accept-Encoding 头） |

## 环境问题

### API 密钥未设置

```bash
export MINIMAX_API_KEY="<在此粘贴您的密钥>"

# 验证
echo $MINIMAX_API_KEY
```

### 未找到 FFmpeg

```bash
# macOS
brew install ffmpeg

# Ubuntu
sudo apt install ffmpeg

# 验证
ffmpeg -version
```

### 缺少 Python 包

```bash
pip install requests
```

## API 错误

### 认证失败 (401)

- 验证 API 密钥正确且未过期
- 检查密钥值中是否有额外的空格

### 速率限制 (429)

在请求之间添加延迟：
```python
import time
for text in texts:
    result = tts(text)
    time.sleep(1)
```

### 模型名称无效

有效名称（使用连字符，必须包含 -hd 或 -turbo）：
- `speech-2.8-hd`（推荐）
- `speech-2.8-turbo`
- `speech-2.6-hd`
- `speech-2.6-turbo`

错误示例：`speech_01`、`speech_2.6`、`speech-01`

## 音频问题

### 质量不佳

使用更高设置重新生成：
```bash
python scripts/minimax_tts.py "text" -o out.mp3 --sample-rate 32000 --model speech-2.8-hd
```

### 无效的情绪参数

有效的情绪值：
- 所有模型：happy、sad、angry、fearful、disgusted、surprised、calm
- 仅 speech-2.6：+ fluent、whisper
- speech-2.8：自动匹配（留空，推荐）