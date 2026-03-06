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
    ((ERRORS++))
fi

# 2. Process & Network
LISTENING_PORTS="$(ss -tuln 2>/dev/null | awk 'NR>1 {print $1":"$5}' | sort -u || true)"
OUTBOUND_CONNS="$(ss -tnp 2>/dev/null | awk '$5 ~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ {print $5}' | sort -u || true)"
if [ -z "$LISTENING_PORTS" ] && [ -z "$OUTBOUND_CONNS" ]; then
    report "✅" "Process & Network" "No anomalous outbound/listening ports"
else
    ANOMALIES=()
    [ -n "$LISTENING_PORTS" ] && ANOMALIES+=("Listening: $LISTENING_PORTS")
    [ -n "$OUTBOUND_CONNS" ] && ANOMALIES+=("Outbound: $OUTBOUND_CONNS")
    report "⚠️" "Process & Network" "$(printf '%s\n' "${ANOMALIES[@]}")"
    ((WARNINGS++))
fi

# 3. Directory Changes (24h)
CHANGED_FILES=()
for path in "$OC/" "/etc/" "$HOME/.ssh/" "$HOME/.gnupg/" "/usr/local/bin/"; do
    [ -e "$path" ] || continue
    while IFS= read -r file; do
        CHANGED_FILES+=("$file")
    done < <(find "$path" -type f -mtime -1 2>/dev/null || true)
done
if [ ${#CHANGED_FILES[@]} -eq 0 ]; then
    report "✅" "Directory Changes" "0 files modified in last 24h in sensitive paths"
else
    COUNT=${#CHANGED_FILES[@]}
    DETAILS="$COUNT files modified in last 24h"
    printf '%s\n' "${CHANGED_FILES[@]}" | head -20 >> "$REPORT_FILE" || true
    [ $COUNT -gt 20 ] && echo "... and $((COUNT-20)) more" >> "$REPORT_FILE" || true
    report "⚠️" "Directory Changes" "$DETAILS"
    ((WARNINGS++))
fi

# 4. System Cron
SYSTEM_CRON=()
[ -d "/etc/cron.d" ] && while IFS= read -r f; do SYSTEM_CRON+=("$f"); done < <(find /etc/cron.d -type f 2>/dev/null || true)
USER_CRONTAB="$(crontab -l 2>/dev/null || true)"
if [ ${#SYSTEM_CRON[@]} -eq 0 ] && [ -z "$USER_CRONTAB" ]; then
    report "✅" "System Cron" "No suspicious system-level tasks found"
else
    DETAILS="Detected cron entries:"
    for f in "${SYSTEM_CRON[@]}"; do DETAILS+=$'\n'"  $f"; done
    [ -n "$USER_CRONTAB" ] && DETAILS+=$'\n'"  (user crontab entries present)"
    report "⚠️" "System Cron" "$DETAILS"
    ((WARNINGS++))
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
    ((ERRORS++))
fi

# 6. SSH Security
FAILED_SSH="$(journalctl -u sshd --since '1 hour ago' 2>/dev/null | grep -c 'Failed password' || true)"
if [ "$FAILED_SSH" -eq 0 ]; then
    report "✅" "SSH Security" "0 failed brute-force attempts"
else
    report "⚠️" "SSH Security" "$FAILED_SSH failed SSH attempts in last hour"
    ((WARNINGS++))
fi

# 7. Config Baseline
BASELINE_FILE="$OC/.config-baseline.sha256"
if [ ! -f "$BASELINE_FILE" ]; then
    report "❌" "Config Baseline" "Baseline file missing — run sha256sum generation"
    ((ERRORS++))
else
    if sha256sum -c "$BASELINE_FILE" &>/dev/null; then
        report "✅" "Config Baseline" "Hash check passed"
    else
        report "❌" "Config Baseline" "Hash check FAILED — configuration tampered"
        ((ERRORS++))
    fi
fi
# Permissions
OPENCLAW_JSON_PERM="$(stat -c %a "$OC/openclaw.json" 2>/dev/null || echo 000)"
PAIRED_PERM="$(stat -c %a "$OC/devices/paired.json" 2>/dev/null || echo 000)"
if [ "$OPENCLAW_JSON_PERM" = "600" ]; then
    report "✅" "Permissions" "openclaw.json is 600"
else
    report "❌" "Permissions" "openclaw.json is $OPENCLAW_JSON_PERM (should be 600)"
    ((ERRORS++))
fi
if [ "$PAIRED_PERM" = "600" ]; then
    report "✅" "Permissions" "paired.json is 600"
else
    report "⚠️" "Permissions" "paired.json is $PAIRED_PERM (should be 600)"
    ((WARNINGS++))
fi

# 8. Yellow Line Cross-Validation
SUDO_COUNT="$(grep -c 'sudo' /var/log/auth.log 2>/dev/null || true)"
MEM_FILE="$OC/memory/$(date +%Y-%m-%d).md"
MEM_SUDO=0
[ -f "$MEM_FILE" ] && MEM_SUDO="$(grep -c 'sudo' "$MEM_FILE" || true)"
if [ "$SUDO_COUNT" -eq "$MEM_SUDO" ]; then
    report "✅" "Yellow Line Audit" "$SUDO_COUNT sudo executions (verified against memory logs)"
else
    report "⚠️" "Yellow Line Audit" "sudo count mismatch: auth.log=$SUDO_COUNT vs memory=$MEM_SUDO"
    ((WARNINGS++))
fi

# 9. Disk Capacity
ROOT_USAGE="$(df / | awk 'NR==2 {print $5}' | tr -d '%' 2>/dev/null || echo 0)"
LARGE_FILES="$(find / -type f -size +100M -mtime -1 2>/dev/null | wc -l || true)"
if [ "$ROOT_USAGE" -lt 85 ] && [ "$LARGE_FILES" -eq 0 ]; then
    report "✅" "Disk Capacity" "Root partition usage ${ROOT_USAGE}%, 0 new large files"
else
    [ "$ROOT_USAGE" -ge 85 ] && report "⚠️" "Disk Capacity" "Root usage ${ROOT_USAGE}% (>=85%)" && ((WARNINGS++))
    [ "$LARGE_FILES" -gt 0 ] && report "⚠️" "Disk Capacity" "$LARGE_FILES new large files (>100MB)" && ((WARNINGS++))
fi

# 10. Gateway Environment Variables
GATEWAY_PID="$(pgrep -f 'openclaw gateway' | head -1 || true)"
if [ -n "$GATEWAY_PID" ]; then
    ENV_VARS="$(tr '\0' '\n' < /proc/$GATEWAY_PID/environ 2>/dev/null | grep -iE 'KEY|TOKEN|SECRET|PASSWORD' | wc -l || true)"
    if [ "$ENV_VARS" -eq 0 ]; then
        report "✅" "Environment Vars" "No anomalous credential leaks in gateway env"
    else
        report "⚠️" "Environment Vars" "$ENV_VARS variables contain KEY/TOKEN/SECRET/PASSWORD"
        ((WARNINGS++))
    fi
else
    report "⚠️" "Environment Vars" "OpenClaw gateway process not running"
    ((WARNINGS++))
fi

# 11. Sensitive Credential Scan (DLP)
CRED_COUNT=0
while IFS= read -r pattern; do
    COUNT="$(grep -rE "$pattern" "$OC/workspace/" 2>/dev/null | wc -l || true)"
    CRED_COUNT=$((CRED_COUNT + COUNT))
done <<'EOF'
(priv(ate)?[_-]?key|mnemonic|seed\s+phrase)
(begin\s+(rsa\s+)?private|-----BEGIN)
[a-f0-9]{64}
[a-z0-9]{32,44}(?=\s|$)
[a-zA-Z0-9]{12}(?: [a-zA-Z0-9]{12}){11}
EOF
if [ "$CRED_COUNT" -eq 0 ]; then
    report "✅" "Sensitive Credential Scan" "No plaintext private keys/mnemonics found"
else
    report "❌" "Sensitive Credential Scan" "$CRED_COUNT potential credential patterns — CRITICAL ALERT"
    ((ERRORS++))
fi

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
        ((WARNINGS++))
    fi
    rm -f "$CURRENT_MANIFEST"
fi

# 13. Disaster Backup (Git)
if command -v git &>/dev/null && [ -d "$OC/.git" ]; then
    ( cd "$OC" && git add -A 2>/dev/null && git commit -m "Auto-backup $(date -Iseconds)" 2>/dev/null && git push 2>/dev/null ) &
    report "✅" "Disaster Backup" "Auto-backup triggered (async)"
else
    report "⚠️" "Disaster Backup" "Git not configured — set up private repo backup"
    ((WARNINGS++))
fi

# Final summary
{
    echo ""
    echo "📊 Summary: $ERRORS errors, $WARNINGS warnings"
    echo ""
    echo "📝 Detailed report saved: $REPORT_FILE"
} >> "$REPORT_FILE"

cat "$REPORT_FILE"