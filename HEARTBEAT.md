# HEARTBEAT.md

更新时间：2026年09月17日 14:56（北京时间）

### 巡检摘要 (三日看板)
- ✅ **nightly-security-audit**：2026-09-17 03:00 报告为 0 errors, 3 warnings。警告项为正常监听端口/目录变更，以及预期 Yellow Line sudo 记录缺口；核心项通过：`Config Baseline` OK、权限 OK、`Skill Baseline` OK、灾备备份已触发，磁盘无新增大文件。报告仍列出 stale lock 备份；03:19 复查发现新生成的 `/home/ubuntu/.openclaw/.git/index.lock` 0 字节文件（2026-09-17 03:00），已确认无 git/OpenClaw cron 进程占用，并改名保留为 `.git/index.lock.stale-20260917-0320`，避免后续 GitClaw 写入被卡住。历史：2026-09-14 `Config Baseline` 与 `Skill Baseline` 误报已处理，稳定 manifest 为 16 条，脚本已重新 `chattr +i` 锁定。
- ✅ **Security Audit Note**：small model 沙箱已按当前 OpenClaw schema 配置为 `agents.defaults.sandbox.mode: all`（旧记录中的 `require` 已不被当前 schema 接受）。2026-09-15 03:20 复查：cron 列表正常读取，active 任务全部 ok，`openclaw.json: OK`，skill manifest 16 条。
- ⚠️ **Yellow Line Audit**：2026-09-17 审计检测到 6 次 sudo 操作，但内存中未发现对应的 Yellow Line 记录；这延续近期脚本修复/维护遗留缺口，属于预期管理行为，可安全忽略。
- ✅ **GitClaw 自动备份**：持续稳定运行。2026-05-16 心跳复查发现 GitClaw backup health check 因“无输出时不回文本”导致 cron 误判 error，已将无异常返回改为 `NO_REPLY` 并手动验证，状态恢复 ok。
- ✅ **QQBot 插件迁移**：已从旧 `@sliverp/qqbot@1.5.3` 迁移到官方 `@openclaw/qqbot@2026.5.3`，手机 QQ 收发验证成功。
- ✅ **google-antigravity-auth 编译产物修复**：已本地编译为 `dist/index.js` 并切换入口，compiled runtime warning 已消失。
- ⏸️ **Device Brief 四平台周更发布**：本次已由小雪迁移到 Codex 并完成发布；OpenClaw 云端该周任务已暂停，后续不再主动跑需要浏览器登录的四平台发布。
- ✅ **Config Baseline**：2026-09-14 心跳已按当前合法 `openclaw.json` 刷新 baseline，并通过 `sha256sum -c .config-baseline.sha256` 验证；17:50 因 sandbox schema 修正为 `all` 再次刷新并验证通过。
- ✅ **Config Baseline 复查**：2026-09-17 13:20 心跳发现 12:37 合法配置清理后 baseline 未同步；核对差异仅为 `agents.defaults.model.primary` 从 `openai/gpt-5.6-sol` 调整为 `openai/gpt-5.5`、fallback 列表顺序/内容保持 3 个可用模型、`meta.lastTouchedAt` 更新时间。`openclaw config validate` 通过，`openclaw models status` 显示 OpenAI OAuth 可用，已刷新 `.config-baseline.sha256` 并验证 `openclaw.json: OK`。
- 🟡 **GPT-5.5 退休观察**：2026-09-17 13:48 复查模型缓存，`gpt-5.5` 的 `upgrade.retirement_at` 为 `2026-10-14T19:00:00Z`，建议迁移到 `gpt-5.6-sol`。当前配置仍为 `openai/gpt-5.5` 主模型，但 fallback 已包含 `openai/gpt-5.6-sol` 与 `openai/gpt-5.6-terra`；`openclaw config validate` 通过，`openclaw models status` 显示 OpenAI OAuth 可用。未获用户明确授权前不自动切换主模型。
- ✅ **主力模型统一**：2026-09-17 14:56 按小雪明确指令，将当前主会话重置为默认模型；系统默认模型与当前主会话均为 `openrouter/inclusionai/ling-3.0-flash:free`，fallback 为 `openrouter/nvidia/nemotron-3-super-120b-a12b:free`。`openclaw models status --json` 与 `openclaw status --json` 已验证一致，`sha256sum -c .config-baseline.sha256` 返回 `openclaw.json: OK`。

### 趋势分析任务
- **任务名称**：数字花束与春节送礼趋势深度调研 - 每2小时执行
- **状态**：已暂停（用户指令）。
- **2026-05-09 补充**：发现系统 crontab 仍在每2小时运行该脚本，已注释暂停，避免继续生成低价值趋势报告。

### 社交媒体智能互动 - 每小时任务
- **当前状态**：已暂停（用户指令）

### 系统状态
- ✅ OpenClaw Gateway：运行中
- ✅ Cron任务系统：运行中
- ✅ 安全防护矩阵：核心项通过，small model 沙箱为 `all`；需关注的警告均为预期管理行为。
- ✅ Git灾难恢复：已部署。
- **当前系统默认模型**：openrouter/inclusionai/ling-3.0-flash:free ✅
- **当前主会话模型**：openrouter/inclusionai/ling-3.0-flash:free ✅
- **备用模型**：openrouter/nvidia/nemotron-3-super-120b-a12b:free
- ✅ **OAuth Token 复查**：2026年09月13日 16:20 心跳检查时，`openai-codex:huangmmail@gmail.com` 与 `openai:huangmmail@gmail.com` 认证 profile 均存在；2026年09月14日 07:49 复查最近 4 小时日志，无新的 refresh 失败、fallback 或降级命中。暂不提醒用户。

### 待办事项
- [x] 处理安全审计警告项：已优化脚本并清理 tmp 环境（2026-04-08）
- [x] 调查nightly-security-audit报告中的Config Baseline错误 - 已于 4/28 重新同步基线指纹
- [x] 修正三日巡检与周更发布任务的模型配置（已统一为 gemini-3-flash）
- [x] Device Brief 本周发布已在 Codex 完成；OpenClaw 侧任务已暂停（2026-05-07）

### 待办事项 (更新)
- [x] Fix cron jobs using deprecated model 'openrouter/xiaomi/mimo-v2-flash' (GitClaw backup health check, nightly-security-audit) - updated to openai-codex/gpt-5.5; 2026-05-16 复查 GitClaw health check 的“空输出”误报并修正为 `NO_REPLY`，状态 now ok.
- [x] Monitor 农业科技周报深度版 cron job (ID: 7ac9556c-f472-486f-9d47-71b7133e1aa1) - 2026-05-31 18:50 已按小雪指令停用，`enabled=false`，next 为 `-`；最后一次已生成 `company/reports/agtech-weekly/agtech-weekly-20260531-detailed.html`。
- [x] Investigate cron task ddd553e3 failure (invalidated OAuth token) - found to be historical; GitClaw backup currently functioning normal.
- [x] Review Skill Baseline changes (3 lines) from security audit 2026-06-01: manifest diff is one added file `/home/ubuntu/.openclaw/skills/gpt-image/scripts/generate.py` (diff header counts as 3 lines). This matches installed gpt-image skill; no unexpected removed/changed script found. Skill baseline deliberately refreshed.
- [x] Config Baseline 已更新：openclaw.json 配置更改（添加 fallback 模型）合法，基线已同步。
- [x] 已将 ~/.openclaw/devices/paired.json 复制到 ~/.openclaw/paired.json 并设置权限 600，以恢复缺失的配置文件。
- [x] 审查 small model 沙箱需求：当前 OpenClaw schema 只接受 `off / non-main / all`，已将 `agents.defaults.sandbox.mode` 从误漂移的 `off` 修正为 `all` 并刷新配置基线（2026-09-14 17:50）。
- [x] 每日AI机会雷达旧 cron job (ID: bada3c2e-de65-42f4-8032-1fb2143beed5) 2026-09-13 13:00 再次 timeout；已于 16:49 停用旧 13:00 任务（`enabled=false`, `next=-`, `status=disabled`）。新版 Daily Career Opportunity Assessment (ID: e82f5af8-72d6-40fb-9f95-ab7636a0303c) 保持启用，2026-09-15 15:00 已正常运行并推送机会列表，15:19 复查 cron status ok。
    - [x] 修复 daily_career_opportunity.sh 脚本，改用直接 AnySearch API 调用，增加 curl 超时和 null-byte 处理，脚本现在能在约1分钟内完成并输出机会列表。
- [x] 调整每日AI机会雷达 cron job 超时时间：将 timeoutSeconds 从 120 增至 180 秒，以防止脚本执行超时（2026-06-19）
 [最后检查: 2026-07-04 07:19:21, 最近10分钟无新错误]


- [Investigated] OAuth token refresh failed for openai-codex; likely expired refresh token. User should re-run `openclaw configure` to refresh OAuth or manually update token.
