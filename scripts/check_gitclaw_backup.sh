#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="$HOME/.openclaw/gitclaw/backup.log"
REPO_DIR="$HOME/.openclaw/workspace"
MAX_AGE_SECONDS=$((2 * 3600))

now_ts=$(date -u +%s)
issues=()

if [ ! -f "$LOG_FILE" ]; then
  echo "⚠️ GitClaw 备份告警：未找到备份日志 $LOG_FILE，请检查 GitClaw 是否仍已部署。"
  exit 0
fi

last_ok_line_num=$(grep -n 'Backup OK\.' "$LOG_FILE" | tail -n 1 | cut -d: -f1 || true)
last_ok_line=$(grep 'Backup OK\.' "$LOG_FILE" | tail -n 1 || true)

if [ -z "$last_ok_line" ]; then
  issues+=("日志中未找到任何成功备份记录")
  post_ok_log=$(tail -n 80 "$LOG_FILE")
else
  last_ok_ts=$(echo "$last_ok_line" | awk '{print $1}')
  last_ok_epoch=$(date -u -d "$last_ok_ts" +%s 2>/dev/null || echo 0)
  age=$((now_ts - last_ok_epoch))
  if [ "$last_ok_epoch" -eq 0 ]; then
    issues+=("无法解析最近一次成功备份时间：$last_ok_ts")
  elif [ "$age" -gt "$MAX_AGE_SECONDS" ]; then
    issues+=("最近一次成功备份距今已超过 $((MAX_AGE_SECONDS/3600)) 小时（UTC: $last_ok_ts）")
  fi
  post_ok_log=$(tail -n +$((last_ok_line_num + 1)) "$LOG_FILE" 2>/dev/null || true)
fi

if echo "$post_ok_log" | grep -Eq 'ERROR: push failed after|fatal:|RPC failed|GH001:|GH013:'; then
  issues+=("最近一次成功备份之后又出现新的 push/远端拒绝类错误")
fi

if [ -d "$REPO_DIR/.git" ]; then
  cd "$REPO_DIR"
  branch=$(git branch --show-current 2>/dev/null || echo master)
  local_sha=$(git rev-parse --short HEAD 2>/dev/null || echo unknown)
  remote_sha=$(git ls-remote origin "refs/heads/$branch" 2>/dev/null | awk '{print substr($1,1,7)}')
  if [ -n "$remote_sha" ] && [ "$local_sha" != "$remote_sha" ]; then
    issues+=("本地 HEAD($local_sha) 与远端 HEAD($remote_sha) 不一致")
  fi
else
  issues+=("未找到 Git 仓库目录：$REPO_DIR/.git")
fi

if [ ${#issues[@]} -eq 0 ]; then
  exit 0
fi

printf '⚠️ GitClaw 备份告警\n'
printf '时间（UTC）: %s\n' "$(date -u '+%Y-%m-%d %H:%M:%S')"
printf '仓库: raguchiindo-design/openclaw-config\n'
for issue in "${issues[@]}"; do
  printf -- '- %s\n' "$issue"
done
printf '建议：检查 ~/.openclaw/gitclaw/backup.log 与仓库远端状态。\n'
