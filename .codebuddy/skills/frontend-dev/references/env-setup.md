# 快速入门

## 1. 设置 API Key

```bash
export MINIMAX_API_KEY="<在此粘贴您的密钥>"
```

## 2. 安装依赖

```bash
pip install requests

# FFmpeg（可选，用于音频后处理）
# macOS：
brew install ffmpeg
# Ubuntu：
sudo apt install ffmpeg
```

## 3. 快速测试

```bash
python scripts/minimax_tts.py "Hello world" -o test.mp3
```

如果成功，您将看到 `OK: xxxxx bytes -> test.mp3`。

## 下一步

- **选择声音**：参见 [minimax-voice-catalog.md](minimax-voice-catalog.md)
- **TTS 工作流**：参见 [minimax-tts-guide.md](minimax-tts-guide.md)
- **故障排除**：参见 [troubleshooting.md](troubleshooting.md)