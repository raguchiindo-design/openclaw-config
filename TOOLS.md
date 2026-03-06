# TOOLS.md - Local Notes

Skills define _how_ tools work. This file is for _your_ specifics — the stuff that's unique to your setup.

## What Goes Here

Things like:

- Camera names and locations
- SSH hosts and aliases
- Preferred voices for TTS
- Speaker/room names
- Device nicknames
- Anything environment-specific

## Examples

```markdown
### Cameras

- living-room → Main area, 180° wide angle
- front-door → Entrance, motion-triggered

### SSH

- home-server → 192.168.1.100, user: admin

### TTS

- Preferred voice: "Nova" (warm, slightly British)
- Default speaker: Kitchen HomePod
```

## Why Separate?

Skills are shared. Your setup is yours. Keeping them apart means you can update skills without losing your notes, and share skills without leaking your infrastructure.

---

Add whatever helps you do your job. This is your cheat sheet.

## Browser Configuration

### Singapore Server Settings
- **Executable path**: `/usr/bin/google-chrome-unstable`
- **Profile**: `openclaw` (当前服务器环境下可用的 profile)
- **User data directory**: `/home/ubuntu/.openclaw/browser/openclaw/user-data`
- **Mode**: Headless, no sandbox
- **Note**: `chrome` profile 在本机无头 VPS 环境下不适用，请始终使用 `openclaw`

### Session Loss Alert
- **Action required**: If browser session is lost during cron jobs, alert via Telegram immediately
- **Alert chat ID**: `7656385011`
- **Message format**: "⚠️ Browser session lost on Singapore server. Please re-scan QR code to restore access."
- **Check frequency**: Before each cron job execution
