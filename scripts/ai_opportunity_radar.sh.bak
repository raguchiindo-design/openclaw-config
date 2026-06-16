#!/bin/bash
# Daily AI Opportunity Radar script
# Generates 20 items with titles, ~20-char points, meaning for Xiao Xue, and short links
# Uses AnySearch, TinyURL, and simple scoring

LOG_DIR="/home/ubuntu/.openclaw/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ai_opportunity_radar_$(date +%Y%m%d).log"
exec >>"$LOG_FILE" 2>&1

echo "=== AI Opportunity Radar started at $(date) ==="

# Sources and max per source
SOURCES=(
    "TLDR AI:tldr.tech/ai"
    "The Rundown AI:rundown.ai"
    "Agentic Daily:agenticdaily.ai"
    "The Batch:deeplearning.ai/the-batch"
    "Product Hunt AI:producthunt.com/topics/artificial-intelligence"
    "Latent Space:latent.space"
    "Import AI:importai.net"
    "OpenAI Blog:openai.com/blog"
    "Google DeepMind Blog:deepmind.com/blog"
    "NVIDIA Blog:blogs.nvidia.com"
    "YC Work at a Startup:workatastartup.com"
    "Wellfound AI Jobs:wellfound.com"
)
MAX_PER_SOURCE=2
TODAY=$(date +%Y-%m-%d)

# Temporary file for raw results
TMP_RESULTS=$(mktemp)
for pair in "${SOURCES[@]}"; do
    IFS=':' read -r NAME DOMAIN <<< "$pair"
    echo "Searching $NAME..."
    python3 /home/ubuntu/.openclaw/workspace/skills/anysearch-skill/scripts/anysearch_cli.py search "site:$DOMAIN AI" --max_results $MAX_PER_SOURCE >> "$TMP_RESULTS" 2>&1
    sleep 0.4
done

# Parse AnySearch output to get title and url
TMP_PARSED=$(mktemp)
while IFS= read -r line; do
    if [[ $line =~ ^\ \ \ \ ([0-9]+)\.\ (.+) ]]; then
        TITLE="${BASH_REMATCH[2]}"
        CURRENT_TITLE="$TITLE"
    elif [[ $line =~ ^\ \ \ \ -\ \*\*URL\*\*: ]]; then
        URL=$(echo "$line" | grep -oE 'https?://[^ ]+')
        if [[ -n "$CURRENT_TITLE" && -n "$URL" ]]; then
            echo "$CURRENT_TITLE|$URL" >> "$TMP_PARSED"
            CURRENT_TITLE=""
        fi
    fi
done < "$TMP_RESULTS"

# Scoring function
score_title() {
    local t="$1"
    local score=0
    local low=$(echo "$t" | tr '[:upper:]' '[:lower:]')
    # categories
    if [[ $low =~ (platform|agent|multi-agent|framework|sdk|api|launch|release|open\s+source|beta) ]]; then ((score++)); fi
    if [[ $low =~ (browser|ide|search|desktop\s+assistant|workflow|copilot|assistant|interface|ui|ux) ]]; then ((score++)); fi
    if [[ $low =~ (api|sdk|plugin|marketplace|app\s+store|deploy|host|github|npm|pip|docker|extension) ]]; then ((score++)); fi
    if [[ $low =~ (remote|hire|jobs|career|team|hiring|freelance|contract|work\s+from\s+home|distributed) ]]; then ((score++)); fi
    if [[ $low =~ (world\s+model|physical\s+ai|robotics|agent\s+os|simulation|embodied|robot|ros) ]]; then ((score++)); fi
    if [[ $low =~ ai\ agent ]]; then ((score++)); fi
    echo "$score"
}

# Process each line
TMP_ENRICHED=$(mktemp)
while IFS='|' read -r TITLE URL; do
    if [[ -z "$TITLE" || -z "$URL" ]]; then continue; fi
    SCORE=$(score_title "$TITLE")
    # Fetch snippet for points (first 200 chars of text)
    SNIPPET=$(curl -s --max-time 8 "$URL" | sed -e 's/<[^>]*>//g' | tr -s '[:space:]' ' ' | head -c 200)
    # Extract ~20 Chinese chars
    POINTS=$(echo "$SNIPPET" | grep -oE '[\u4e00-\u9fff]{20,}' | head -1 | cut -c1-20)
    if [[ -z "$POINTS" ]]; then
        # fallback: first 20 chars of title
        POINTS=$(echo "$TITLE" | cut -c1-20)
    fi
    MEANING="作为个人开发者，可关注此项以获取技术、工具或机会。"
    SHORT=$(curl -s "https://tinyurl.com/api-create.php?url=$(echo -n "$URL" | jq -sRr @uri)" 2>/dev/null)
    if [[ ! "$SHORT" =~ ^http ]]; then
        SHORT="$URL"
    fi
    echo "$SCORE|$TITLE|$POINTS|$MEANING|$SHORT" >> "$TMP_ENRICHED"
done < "$TMP_PARSED"

# Sort by score desc, then title
TMP_SORTED=$(mktemp)
sort -t'|' -k1,1nr -k2,2 "$TMP_ENRICHED" > "$TMP_SORTED"

# Take top 20
OUTPUT_FILE="/tmp/ai_opportunity_radar_${TODAY}.txt"
> "$OUTPUT_FILE"
COUNT=0
while IFS='|' read -r SCORE TITLE POINTS MEANING SHORT && [[ $COUNT -lt 20 ]]; do
    echo "$((COUNT+1)). $TITLE" >> "$OUTPUT_FILE"
    echo "要点：$POINTS" >> "$OUTPUT_FILE"
    echo "对小雪的意义：$MEANING" >> "$OUTPUT_FILE"
    echo "来源：$SHORT" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    ((COUNT++))
done < "$TMP_SORTED"

# Send via message tool (Telegram)
if [[ -f "$OUTPUT_FILE" && -s "$OUTPUT_FILE" ]]; then
    CONTENT=$(cat "$OUTPUT_FILE")
    # Use OpenClaw message tool via exec? We'll call the message tool via the agent's built-in? 
    # Since we are in a script, we cannot directly call the tool; we will output to stdout and let the cron's announce handle it.
    # However we have --announce in cron config, which will send the script's stdout as a message.
    # So just print the content.
    echo "$CONTENT"
else
    echo "No output generated."
fi

echo "=== AI Opportunity Radar finished at $(date) ==="
# Cleanup
rm -f "$TMP_RESULTS" "$TMP_PARSED" "$TMP_ENRICHED" "$TMP_SORTED"