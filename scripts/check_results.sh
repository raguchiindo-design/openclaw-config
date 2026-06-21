#!/bin/bash
LOG_DIR="/home/ubuntu/.openclaw/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ai_opportunity_radar_$(date +%Y%m%d).log"
exec >>"$LOG_FILE" 2>&1

echo "=== AI Opportunity Radar started at $(date) ==="

# Sources and max per source
SOURCES=(
    "TLDR AI:tldr.tech/ai"
    "The Rundown AI:rundown.ai"
    "Product Hunt AI:producthunt.com/topics/artificial-intelligence"
)
MAX_PER_SOURCE=1
TODAY=$(date +%Y-%m-%d)

# Temporary file for raw results
TMP_RESULTS=$(mktemp)
for pair in "${SOURCES[@]}"; do
    IFS=':' read -r NAME DOMAIN <<< "$pair"
    echo "Searching $NAME..."
    timeout 5 python3 /home/ubuntu/.openclaw/workspace/skills/anysearch-skill/scripts/anysearch_cli.py search "site:$DOMAIN AI" --max_results $MAX_PER_SOURCE >> "$TMP_RESULTS" 2>&1
    sleep 0.1
done

echo "=== TMP_RESULTS content ==="
cat "$TMP_RESULTS"
echo "=== End TMP_RESULTS ==="

# Keep the temp file for inspection
echo "TMP_RESULTS saved at: $TMP_RESULTS"
