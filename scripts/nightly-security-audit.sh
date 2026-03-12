#!/bin/bash
# OpenClaw Nightly Security Audit Script (v2.7)
# Generated from SlowMist Security Practice Guide
# $OC = ${OPENCLAW_STATE_DIR:-$HOME/.openclaw}

set -euo pipefail

OC="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
REPORT_DIR="/tmp/openclaw/security-reports"
DATE="$(date +%Y-%m-%d)"
REPORT_FILE="$REPORT_DIR/report-$DATE.txt"
ERRORS=0
WARNINGS=0

mkdir -p "$REPORT_DIR"

report() {
    local status="$1"
    local title="$2"
    local details="$3"
    echo "$status $title" >> "$REPORT_FILE"
    if [ -n "$details" ]; then
        echo "$details" >> "$REPORT_FILE"
    fi
}

# 1. Platform Audit
if command -v uname &>/dev/null; then
    PLATFORM="$(uname -srv)"
    report "✅" "Platform Audit" "Native scan executed: $PLATFORM"
else
    report "❌" "Platform Audit" "Unable to detect platform"
    ((ERRORS+=1))
fi

# 2. Process & Network
LISTENING_PORTS_RAW="$(ss -tuln 2>/dev/null | awk 'NR>1 {print $1":"$5}' | sort -u || true)"
OUTBOUND_CONNS="$(ss -tnp 2>/dev/null | awk '$5 ~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print $5}' | sort -u || true)"
LISTENING_PORTS="$(printf '%s\n' "$LISTENING_PORTS_RAW" | grep -vE '^(tcp:(127\.0\.0\.1|\[::1\]):|udp:(127\.0\.0\.1|\[::1\]):|tcp:127\.0\.0\.53%lo:53|tcp:127\.0\.0\.54:53|udp:127\.0\.0\.53%lo:53|udp:127\.0\.0\.54:53|udp:10\.[0-9.]+:68)$' || true)"
KNOWN_OPEN_SERVICE=""
if printf '%s\n' "$LISTENING_PORTS" | grep -qE '^tcp:(0\.0\.0\.0|\[::\]):18060$'; then
    KNOWN_OPEN_SERVICE="Known open service: xiaohongshu-mcp on :18060"
    LISTENING_PORTS="$(printf '%s\n' "$LISTENING_PORTS" | grep -vE '^tcp:(0\.0\.0\.0|\[::\]):18060$' || true)"
fi
if [ -z "$LISTENING_PORTS" ]; then
    if [ -n "$KNOWN_OPEN_SERVICE" ]; then
        report "✅" "Process & Network" "$KNOWN_OPEN_SERVICE"
    else
        report "✅" "Process & Network" "No anomalous listening ports after allowlisting local/known services"
    fi
else
    ANOMALIES=()
    [ -n "$KNOWN_OPEN_SERVICE" ] && ANOMALIES+=("$KNOWN_OPEN_SERVICE")
    [ -n "$LISTENING_PORTS" ] && ANOMALIES+=("Listening: $LISTENING_PORTS")
    report "⚠️" "Process & Network" "$(printf '%s\n' "${ANOMALIES[@]}")"
    ((WARNINGS+=1))
fi

# 3. Directory Changes (24h)
CHANGED_FILES=()
for path in "$OC/" "/etc/" "$HOME/.ssh/" "$HOME/.gnupg/" "/usr/local/bin/"; do
    [ -e "$path" ] || continue
    while IFS= read -r file; do
        case "$file" in
            "$OC/.git/objects/"*|"$OC/browser/openclaw/user-data/"*|"$OC/browser/openclaw/Cache/"*) continue ;;
        esac
        CHANGED_FILES+=("$file")
    done < <(find "$path" -type f -mtime -1 2>/dev/null || true)
done
if [ ${#CHANGED_FILES[@]} -eq 0 ]; then
    report "✅" "Directory Changes" "0 material files modified in last 24h in sensitive paths (cache/git noise excluded)"
else
    COUNT=${#CHANGED_FILES[@]}
    DETAILS="$COUNT material files modified in last 24h"
    printf '%s\n' "${CHANGED_FILES[@]}" | head -20 >> "$REPORT_FILE" || true
    [ $COUNT -gt 20 ] && echo "... and $((COUNT-20)) more" >> "$REPORT_FILE" || true
    report "⚠️" "Directory Changes" "$DETAILS"
    ((WARNINGS+=1))
fi

# 4. System Cron
SYSTEM_CRON=()
[ -d "/etc/cron.d" ] && while IFS= read -r f; do SYSTEM_CRON+=("$f"); done < <(find /etc/cron.d -type f 2>/dev/null || true)
USER_CRONTAB="$(crontab -l 2>/dev/null || true)"
KNOWN_SYSTEM_CRON_RE='/(sysstat|e2scrub_all|\.placeholder)$'
SYSTEM_CRON_UNEXPECTED=()
for f in "${SYSTEM_CRON[@]}"; do
    if [[ ! "$f" =~ $KNOWN_SYSTEM_CRON_RE ]]; then
        SYSTEM_CRON_UNEXPECTED+=("$f")
    fi
done
USER_CRON_COUNT=0
[ -n "$USER_CRONTAB" ] && USER_CRON_COUNT="$(printf '%s\n' "$USER_CRONTAB" | sed '/^\s*#/d;/^\s*$/d' | wc -l)"
if [ ${#SYSTEM_CRON_UNEXPECTED[@]} -eq 0 ]; then
    if [ "$USER_CRON_COUNT" -gt 0 ]; then
        report "✅" "System Cron" "Known system cron entries only; user crontab has $USER_CRON_COUNT entries"
    else
        report "✅" "System Cron" "Known system cron entries only"
    fi
else
    DETAILS="Unexpected system cron entries:"
    for f in "${SYSTEM_CRON_UNEXPECTED[@]}"; do DETAILS+=$'\n'"  $f"; done
    [ "$USER_CRON_COUNT" -gt 0 ] && DETAILS+=$'\n'"  (user crontab has $USER_CRON_COUNT entries)"
    report "⚠️" "System Cron" "$DETAILS"
    ((WARNINGS+=1))
fi

# 5. Local Cron (OpenClaw)
if command -v openclaw &>/dev/null; then
    OPENCLAW_CRON="$(openclaw cron list 2>/dev/null || true)"
    if [ -z "$OPENCLAW_CRON" ]; then
        report "✅" "Local Cron" "No OpenClaw cron jobs configured"
    else
        report "✅" "Local Cron" "OpenClaw cron jobs present (expected):"
        echo "$OPENCLAW_CRON" | sed 's/^/  /' >> "$REPORT_FILE"
    fi
else
    report "❌" "Local Cron" "openclaw CLI not found"
    ((ERRORS+=1))
fi

# 6. SSH Security
FAILED_SSH="$(journalctl -u sshd --since '1 hour ago' 2>/dev/null | grep -c 'Failed password' || true)"
if [ "$FAILED_SSH" -eq 0 ]; then
    report "✅" "SSH Security" "0 failed brute-force attempts"
else
    report "⚠️" "SSH Security" "$FAILED_SSH failed SSH attempts in last hour"
    ((WARNINGS+=1))
fi

# 7. Config Baseline
BASELINE_FILE="$OC/.config-baseline.sha256"
if [ ! -f "$BASELINE_FILE" ]; then
    report "❌" "Config Baseline" "Baseline file missing — run sha256sum generation"
    ((ERRORS+=1))
else
    if (cd "$OC" && sha256sum -c "$BASELINE_FILE") &>/dev/null; then
        report "✅" "Config Baseline" "Hash check passed"
    else
        report "❌" "Config Baseline" "Hash check FAILED — configuration tampered or unreadable from audit context"
        ((ERRORS+=1))
    fi
fi
# Permissions
OPENCLAW_JSON_PERM="$(stat -c %a "$OC/openclaw.json" 2>/dev/null || echo 000)"
PAIRED_PERM="$(stat -c %a "$OC/devices/paired.json" 2>/dev/null || echo 000)"
if [ "$OPENCLAW_JSON_PERM" = "600" ]; then
    report "✅" "Permissions" "openclaw.json is 600"
else
    report "❌" "Permissions" "openclaw.json is $OPENCLAW_JSON_PERM (should be 600)"
    ((ERRORS+=1))
fi
if [ "$PAIRED_PERM" = "600" ]; then
    report "✅" "Permissions" "paired.json is 600"
else
    report "⚠️" "Permissions" "paired.json is $PAIRED_PERM (should be 600)"
    ((WARNINGS+=1))
fi

# 8. Yellow Line Cross-Validation
SUDO_COUNT="$(grep -c 'sudo' /var/log/auth.log 2>/dev/null || true)"
MEM_FILE_WORKSPACE="$OC/workspace/memory/$(date +%Y-%m-%d).md"
MEM_FILE_ROOT="$OC/memory/$(date +%Y-%m-%d).md"
MEM_SUDO=0
MEM_HAS_YELLOW=0
if [ -f "$MEM_FILE_WORKSPACE" ]; then
    MEM_SUDO="$(grep -c 'sudo' "$MEM_FILE_WORKSPACE" || true)"
    grep -qiE 'Yellow Line|完整命令|chattr|sudo' "$MEM_FILE_WORKSPACE" && MEM_HAS_YELLOW=1 || true
elif [ -f "$MEM_FILE_ROOT" ]; then
    MEM_SUDO="$(grep -c 'sudo' "$MEM_FILE_ROOT" || true)"
    grep -qiE 'Yellow Line|完整命令|chattr|sudo' "$MEM_FILE_ROOT" && MEM_HAS_YELLOW=1 || true
fi
if [ "$SUDO_COUNT" -eq 0 ]; then
    report "✅" "Yellow Line Audit" "0 sudo executions found"
elif [ "$MEM_HAS_YELLOW" -eq 1 ]; then
    report "✅" "Yellow Line Audit" "$SUDO_COUNT sudo executions observed; matching Yellow Line records present in memory"
else
    report "⚠️" "Yellow Line Audit" "sudo observed in auth.log ($SUDO_COUNT) but no corresponding Yellow Line record found in memory"
    ((WARNINGS+=1))
fi

# 9. Disk Capacity
ROOT_USAGE="$(df / | awk 'NR==2 {print $5}' | tr -d '%' 2>/dev/null || echo 0)"
LARGE_FILES="$(find / -path /proc -prune -o -path /sys -prune -o -type f -size +100M -mtime -1 -print 2>/dev/null | wc -l || true)"
if [ "$ROOT_USAGE" -lt 85 ] && [ "$LARGE_FILES" -eq 0 ]; then
    report "✅" "Disk Capacity" "Root partition usage ${ROOT_USAGE}%, 0 new large files (excluding /proc and /sys pseudo-files)"
else
    [ "$ROOT_USAGE" -ge 85 ] && report "⚠️" "Disk Capacity" "Root usage ${ROOT_USAGE}% (>=85%)" && ((WARNINGS+=1))
    [ "$LARGE_FILES" -gt 0 ] && report "⚠️" "Disk Capacity" "$LARGE_FILES new large files (>100MB, excluding /proc and /sys)" && ((WARNINGS+=1))
fi

# 10. Gateway Environment Variables
GATEWAY_PID="$(pgrep -f 'openclaw-gateway|openclaw gateway' | head -1 || true)"
if [ -n "$GATEWAY_PID" ] && [ -r "/proc/$GATEWAY_PID/environ" ]; then
    ENV_VARS="$(tr '\0' '\n' < /proc/$GATEWAY_PID/environ 2>/dev/null | grep -iE 'KEY|TOKEN|SECRET|PASSWORD' | wc -l || true)"
    if [ "$ENV_VARS" -eq 0 ]; then
        report "✅" "Environment Vars" "No anomalous credential leaks in gateway env"
    else
        report "⚠️" "Environment Vars" "$ENV_VARS variables contain KEY/TOKEN/SECRET/PASSWORD"
        ((WARNINGS+=1))
    fi
else
    report "⚠️" "Environment Vars" "OpenClaw gateway process not readable from audit context"
    ((WARNINGS+=1))
fi

# 11. Sensitive Credential Scan (DLP)
CRED_COUNT=0
DLP_SCAN_ROOT="$OC/workspace"
DLP_EXCLUDES=(
    --exclude="AGENTS.md"
    --exclude="MEMORY.md"
    --exclude-dir="memory"
    --exclude-dir="scripts"
    --exclude-dir="reports"
    --exclude="*.bak"
    --exclude="*.backup*"
    --exclude="*.bin"
    --exclude="xiaohongshu-login-linux-amd64"
    --exclude="xiaohongshu-mcp-linux-amd64"
)
while IFS= read -r pattern; do
    COUNT="$(grep -rIE --binary-files=without-match "${DLP_EXCLUDES[@]}" "$pattern" "$DLP_SCAN_ROOT" 2>/dev/null | wc -l || true)"
    CRED_COUNT=$((CRED_COUNT + COUNT))
done <<'EOF'
(priv(ate)?[_-]?key|mnemonic|seed\s+phrase)
(begin\s+(rsa\s+)?private|-----BEGIN)
EOF
if [ "$CRED_COUNT" -eq 0 ]; then
    report "✅" "Sensitive Credential Scan" "No plaintext private keys/mnemonics found in scoped workspace text files"
else
    report "❌" "Sensitive Credential Scan" "$CRED_COUNT potential plaintext credential patterns in scoped workspace files — review required"
    ((ERRORS+=1))
fi
# Note: high-entropy token/hash detection intentionally excluded here to reduce noisy false positives.
# Review config backups and credential stores separately if stronger DLP coverage is needed.

# 12. Skill/MCP Integrity Baseline
SKILL_MANIFEST="$OC/.skill-manifest.sha256"
if [ ! -f "$SKILL_MANIFEST" ]; then
    find "$OC/agents/" "$OC/skills/" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" \) 2>/dev/null | \
        xargs sha256sum 2>/dev/null | sort > "$SKILL_MANIFEST" || true
    report "✅" "Skill Baseline" "Baseline generated (first run)"
else
    CURRENT_MANIFEST="$(mktemp)"
    find "$OC/agents/" "$OC/skills/" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" \) 2>/dev/null | \
        xargs sha256sum 2>/dev/null | sort > "$CURRENT_MANIFEST"
    if diff -q "$SKILL_MANIFEST" "$CURRENT_MANIFEST" &>/dev/null; then
        report "✅" "Skill Baseline" "No suspicious extension changes"
    else
        CHANGED="$(diff -u "$SKILL_MANIFEST" "$CURRENT_MANIFEST" | grep '^[-+]' | wc -l || true)"
        report "⚠️" "Skill Baseline" "$CHANGED lines changed — review urgently"
        ((WARNINGS+=1))
    fi
    rm -f "$CURRENT_MANIFEST"
fi

# 13. Disaster Backup (Git)
if command -v git &>/dev/null && [ -d "$OC/.git" ]; then
    ( cd "$OC" && git add -A 2>/dev/null && git commit -m "Auto-backup $(date -Iseconds)" 2>/dev/null && git push 2>/dev/null ) &
    report "✅" "Disaster Backup" "Auto-backup triggered (async)"
else
    report "⚠️" "Disaster Backup" "Git not configured — set up private repo backup"
    ((WARNINGS+=1))
fi

# Final summary
{
    echo ""
    echo "📊 Summary: $ERRORS errors, $WARNINGS warnings"
    echo ""
    echo "📝 Detailed report saved: $REPORT_FILE"
} >> "$REPORT_FILE"

cat "$REPORT_FILE"