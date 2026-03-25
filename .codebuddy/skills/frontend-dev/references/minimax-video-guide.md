# 视频生成指南

## CLI 使用

```bash
# 基本用法
python scripts/minimax_video.py "A cat playing piano in a cozy room" -o cat.mp4

# 带相机控制
python scripts/minimax_video.py "Ocean waves crashing on rocks [Truck left]" -o waves.mp4

# 10 秒，1080P
python scripts/minimax_video.py "City skyline at sunset [Push in]" -o city.mp4 --duration 10 --resolution 1080P

# 禁用提示词自动优化
python scripts/minimax_video.py "Exact prompt I want used" -o out.mp4 --no-optimize
```

## 编程使用

```python
from minimax_video import generate, create_task, poll_task, download_video

# 完整流程（阻塞式）
generate("A cat playing piano", "cat.mp4", model="MiniMax-Hailuo-2.3", duration=6)

# 分步执行
task_id = create_task("A cat playing piano")
file_id = poll_task(task_id, interval=10, max_wait=600)
download_video(file_id, "cat.mp4")
```

## 模型

| 模型 | 分辨率 | 时长 | 说明 |
|------|--------|------|------|
| `MiniMax-Hailuo-2.3` | 768P, 1080P | 6秒、10秒（仅768P） | 最新，推荐 |
| `MiniMax-Hailuo-02` | 768P, 1080P | 6秒、10秒（仅768P） | 上一代 |
| `T2V-01-Director` | 720P | 6秒 | 相机控制优化版 |
| `T2V-01` | 720P | 6秒 | 基础模型 |

## 相机命令

在提示词文本中插入 `[命令]` 以控制相机运动：

| 命令 | 效果 |
|------|------|
| `[Truck left]` | 相机左移 |
| `[Truck right]` | 相机右移 |
| `[Push in]` | 相机向主体推进 |
| `[Pull out]` | 相机远离主体 |
| `[Pan left]` | 相机原地左转 |
| `[Pan right]` | 相机原地右转 |
| `[Tilt up]` | 相机向上倾斜 |
| `[Tilt down]` | 相机向下倾斜 |
| `[Pedestal up]` | 相机垂直上升 |
| `[Pedestal down]` | 相机垂直下降 |
| `[Zoom in]` | 镜头拉近 |
| `[Zoom out]` | 镜头拉远 |
| `[Static shot]` | 无相机运动 |
| `[Tracking shot]` | 相机跟随主体 |
| `[Shake]` | 手持晃动效果 |

示例：`"A runner sprints through a forest trail [Tracking shot]"`

## 流程

脚本处理完整的异步流程：

1. **创建任务** — `POST /v1/video_generation` → 返回 `task_id`
2. **轮询状态** — `GET /v1/query/video_generation?task_id=xxx` → 轮询直到 `Success`
   - 状态值：`Preparing` → `Queueing` → `Processing` → `Success` / `Fail`
3. **下载** — `GET /v1/files/retrieve?file_id=xxx` → 获取 `download_url`（有效期1小时）→ 保存文件

典型生成时间：1–5 分钟，取决于时长和分辨率。

## 限制

- 提示词：最多 2,000 个字符
- 1080P：仅支持 6 秒时长
- 10 秒时长：仅在 768P 分辨率下可用（Hailuo-2.3/02）
- 下载 URL 有效期为 1 小时