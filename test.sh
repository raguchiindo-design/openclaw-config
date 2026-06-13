#!/bin/bash
set -x
LOG_DIR="/home/ubuntu/.openclaw/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test_$(date +%Y%m%d).log"
exec 2>>"$LOG_FILE"

echo "=== Test started at $(date) ==="

export ANYSEARCH_API_KEY="as_sk_b1df60bd2ea90b833fac22494eb6da0c"

QUERIES=("AI company outbound international expansion")
MAX_PER_QUERY=1
TMP_PARSED=$(mktemp)
for q in "${QUERIES[@]}"; do
    echo "Searching: $q"
    timeout 2 python3 /home/ubuntu/.openclaw/workspace/skills/anysearch-skill/scripts/anysearch_cli.py search "$q" --max_results $MAX_PER_QUERY >>"$TMP_PARSED" 2>&1
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
        echo "Warning: AnySearch CLI failed for query: $q" >>"$LOG_FILE"
    fi
    sleep 0.3
done

echo "TMP_PARSED content:"
cat "$TMP_PARSED"

# Parse the combined output to extract title and URL
TMP_ITEMS=$(mktemp)
title=""
url=""
while IFS= read -r line; do
    if [[ $line =~ ^[[:space:]]*[#][#][#][[:space:]]+[0-9]+[[:space:]]*[.][[:space:]]*(.+) ]]; then
        title="${BASH_REMATCH[1]}"
    elif [[ $line =~ ^[[:space:]]*-[[:space:]]+\*\*URL\*\*\:[[:space:]]+(https?://[^[:space:]]+) ]]; then
        url="${BASH_REMATCH[1]}"
        if [[ -n "$title" && -n "$url" ]]; then
            echo "$title|$url" >> "$TMP_ITEMS"
            title=""
            url=""
        fi
    fi
done < "$TMP_PARSED"

echo "TMP_ITEMS content:"
cat "$TMP_ITEMS"

# Cleanup
rm -f "$TMP_PARSED" "$TMP_ITEMS"
echo "=== Test finished at $(date) ==="
