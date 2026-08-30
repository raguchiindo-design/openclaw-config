#!/bin/bash
# Daily AI Opportunity Radar script
# Generates timely AI opportunity items with titles, short points, meaning for Xiao Xue, and links.
# Uses AnySearch; filters generic home/category pages so the cron sends higher-signal items.

LOG_DIR="/home/ubuntu/.openclaw/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ai_opportunity_radar_$(date +%Y%m%d).log"
# Keep cron-visible stdout on fd 3, while detailed logs go to file.
exec 3>&1
exec >>"$LOG_FILE" 2>&1

echo "=== AI Opportunity Radar started at $(date) ==="

# Sources and max per source
SOURCES=(
    "OpenAI News:openai.com"
    "Google DeepMind Blog:deepmind.google"
    "NVIDIA Robotics:developer.nvidia.com/blog"
    "Product Hunt AI:producthunt.com"
    "Agentic Daily:agenticdaily.ai"
    "The Batch:deeplearning.ai"
    "Latent Space:latent.space"
    "Import AI:importai.net"
    "TechCrunch AI:techcrunch.com"
    "CoinDesk AI Crypto:coindesk.com"
    "The Block Web3 AI:theblock.co"
)
MAX_PER_SOURCE=3
TODAY=$(date +%Y-%m-%d)
YEAR=$(date +%Y)
MONTH=$(LC_ALL=C date +%B)

# Temporary files
TMP_RESULTS=$(mktemp)
TMP_PARSED=$(mktemp)
TMP_ENRICHED=$(mktemp)
TMP_SORTED=$(mktemp)
trap 'rm -f "$TMP_RESULTS" "$TMP_PARSED" "$TMP_ENRICHED" "$TMP_SORTED"' EXIT
for pair in "${SOURCES[@]}"; do
    IFS=':' read -r NAME DOMAIN <<< "$pair"
    echo "Searching $NAME..."
    timeout 8 python3 /home/ubuntu/.openclaw/workspace/skills/anysearch-skill/scripts/anysearch_cli.py search --max_results $MAX_PER_SOURCE "site:$DOMAIN $MONTH $YEAR AI agent launch release product robotics marketing crypto" >> "$TMP_RESULTS" 2>&1
    sleep 0.1
done

# Parse AnySearch output to get title and url
while IFS= read -r line; do
    if [[ $line =~ ^\#\#\#[[:space:]]+[0-9]+\.[[:space:]]*(.+) ]]; then
        TITLE="${BASH_REMATCH[1]}"
        CURRENT_TITLE="$TITLE"
    elif [[ $line =~ ^\-\ \*\*URL\*\*\: ]]; then
        URL=$(echo "$line" | grep -oE 'https?://[^ ]+')
        if [[ -n "$CURRENT_TITLE" && -n "$URL" ]]; then
            low_title=$(echo "$CURRENT_TITLE" | tr '[:upper:]' '[:lower:]')
            low_url=$(echo "$URL" | tr '[:upper:]' '[:lower:]')
            if [[ ! $low_title =~ ^(openai|google deepmind|nvidia blog|import ai|latent\.space|the batch|agenticdaily\.ai|artificial intelligence|product hunt|wellfound).*$ ]] \
               && [[ ! $low_url =~ /(topics/artificial-intelligence|blog/?$|news/?$|the-batch/?$|category/robotics/?$|/?$) ]]; then
                echo "$CURRENT_TITLE|$URL" >> "$TMP_PARSED"
            fi
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
    if [[ $low =~ (platform|agent|multi-agent|framework|sdk|api|launch|release|open\s+source|beta) ]]; then ((score+=2)); fi
    if [[ $low =~ (browser|ide|search|desktop\s+assistant|workflow|copilot|assistant|interface|ui|ux|voice|ads|marketing) ]]; then ((score+=2)); fi
    if [[ $low =~ (api|sdk|plugin|marketplace|app\s+store|deploy|host|github|npm|pip|docker|extension|open.source) ]]; then ((score++)); fi
    if [[ $low =~ (world\s+model|physical\s+ai|robotics|agent\s+os|simulation|embodied|robot|ros|jetson|edge) ]]; then ((score+=2)); fi
    if [[ $low =~ (crypto|web3|wallet|stablecoin|payment|defi|blockchain) ]]; then ((score++)); fi
    if [[ $low =~ (2026|august|$MONTH|launch|introduc|expand|new) ]]; then ((score++)); fi
    echo "$score"
}

# Process each line
sort -u "$TMP_PARSED" -o "$TMP_PARSED"
while IFS='|' read -r TITLE URL; do
    if [[ -z "$TITLE" || -z "$URL" ]]; then continue; fi
    SCORE=$(score_title "$TITLE")
    POINTS=$(echo "$TITLE" | sed 's/[[:space:]]\+/ /g' | cut -c1-48)
    low=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]')
    if [[ $low =~ (ads|marketing|growth|social|commerce) ]]; then
        MEANING="适合跟踪获客入口变化，可借鉴到祥云花店推广。"
    elif [[ $low =~ (robot|physical|edge|jetson|vision|world) ]]; then
        MEANING="软硬件结合信号，适合观察可产品化场景。"
    elif [[ $low =~ (crypto|web3|wallet|payment|stablecoin|blockchain|defi) ]]; then
        MEANING="Web3 与 Agent 支付/交易结合，机会和风险都要看。"
    elif [[ $low =~ (browser|workflow|assistant|agent|sdk|api|open.source) ]]; then
        MEANING="可评估是否能接入现有自动化和内容生产流程。"
    else
        MEANING="保留观察，若连续出现再投入时间验证。"
    fi
    echo "$SCORE|$TITLE|$POINTS|$MEANING|$URL" >> "$TMP_ENRICHED"
done < "$TMP_PARSED"

# Sort by score desc, then title
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
    # Print the final report to the original stdout so cron announce can deliver it,
    # while keeping noisy search logs in LOG_FILE.
    echo "$CONTENT" >&3
else
    echo "No output generated." >&3
fi

echo "=== AI Opportunity Radar finished at $(date) ==="
# Cleanup handled by trap