---
name: tts-voice
description: edge-tts 合成中文语音 + Telegram Bot API 发送音频。语音合成走 /opt/edge-tts，发送走 curl。When user asks to generate speech from Chinese text and send it as audio via Telegram, or any TTS + Telegram audio workflow.
metadata: { "openclaw": { "emoji": "🎙️" } }
triggers:
  - 语音
  - TTS
  - 合成语音
  - 发语音
  - 语音消息
  - 文字转语音
  - text to speech
---

# TTS 语音合成 + Telegram 发送

## 环境信息

| 项目 | 值 |
|------|-----|
| edge-tts 解释器 | `/opt/edge-tts/bin/python3` (Python 3.11.2) |
| edge-tts 版本 | 7.2.8 |
| edge-tts CLI | 语音合成 CLI |
| **重要** | 包的目录在 python3.12，解释器是 3.11，**必须加 PYTHONPATH** |

## 合成语音

```bash
PYTHONPATH=/opt/edge-tts/lib/python3.12/site-packages \
 /opt/edge-tts/bin/python3 /opt/edge-tts/bin/edge-tts \
 -t "要朗读的文字" \
 -v zh-CN-YunyangNeural \
 --write-media /tmp/tts-output.mp3
```

### 推荐语音

| Voice | 性别 | 风格 | 备注 |
| --- | --- | --- | --- |
| zh-CN-YunyangNeural | 男 | News / Professional | ✅ 稳定推荐，无中文拼写问题 |
| zh-CN-YunjianNeural | 男 | Sports / Passion | 稳定 |
| zh-CN-YunxiNeural | 男 | Novel / Lively | 稳定 |
| zh-CN-YunxiaNeural | 男 | Cartoon / Cute | 稳定 |
| zh-CN-XiaoxiaoNeural | 女 | News / Warm | ⚠️ 有会重复念"Chinese letters" 的 bug |
| zh-CN-XiaoyiNeural | 女 | Cartoon / Lively | 待验证 |

## 发送到 Telegram

使用 curl 发送（Python urllib 对 Token 编码有兼容问题）：

```bash
curl -s -X POST "https://api.telegram.org/bot<token>/sendAudio" \
 -F chat_id=<chat_id> \
 -F audio=@/tmp/tts-output.mp3 \
 --max-time 30
```

### 注意事项

- Token 和 chat_id 不要硬编码，通过环境变量或参数传入
- 发送成功后立即清理临时文件：`rm -f /tmp/tts-output.mp3`
- Telegram Bot Token 只包含 ASCII 字符

## 完整流程

1. 合成：`PYTHONPATH=... edge-tts -t "..." -v zh-CN-YunyangNeural --write-media /tmp/tts-output.mp3`
2. 发送：`curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendAudio" -F chat_id=$TG_CHAT_ID -F audio=@/tmp/tts-output.mp3`
3. 清理：`rm -f /tmp/tts-output.mp3`

## 故障排查

| 问题 | 原因 | 解决 |
| --- | --- | --- |
| ModuleNotFoundError: No module named 'edge_tts' | 没加 PYTHONPATH | 加 PYTHONPATH=/opt/edge-tts/lib/python3.12/site-packages |
| 404 Not Found | Token 无效或过期 | @BotFather 检查 Token |
| UnicodeEncodeError | Token 含非 ASCII 字符 | 用 curl 发而非 Python urllib |
| 音频含重复"Chinese letters" | 声音特有问题 | 换 zh-CN-YunyangNeural |
