#!/bin/bash
echo "DEBUG: Script started at $(date)" >&2
echo "DEBUG: Past shebang" >&2
# Daily AI Opportunity Radar script
# Generates 20 items with titles, ~20-char points, meaning for Xiao Xue, and short links
# Uses AnySearch, TinyURL, and simple scoring
echo "DEBUG: Logging setup complete" >&2

LOG_DIR="/home/ubuntu/.openclaw/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ai_opportunity_radar_$(date +%Y%m%d).log"
exec >>"$LOG_FILE" 2>&1
echo "DEBUG: SOURCES defined" >&2

echo "=== AI Opportunity Radar started at $(date) ==="
echo "DEBUG: TMP_RESULTS created" >&2

# Sources and max per source
SOURCES=(
    "TLDR AI:tldr.tech/ai"
    "The Rundown AI:rundown.ai"
    "Agentic Daily:agenticdaily.ai"
    "The Batch:deeplearning.ai/the-batch"
    "Product Hunt AI:producthunt.com/topics/artificial-intelligence"
echo "DEBUG: Search loop completed" >&2
    "Latent Space:latent.space"
    "Import AI:importai.net"
    "OpenAI Blog:openai.com/blog"
    "Google DeepMind Blog:deepmind.com/blog"
    "NVIDIA Blog:blogs.nvidia.com"
    "YC Work at a Startup:workatastartup.com"
    "Wellfound AI Jobs:wellfound.com"
)
echo "DEBUG: TMP_PARSED created" >&2
MAX_PER_SOURCE=2
TODAY=$(date +%Y-%m-%d)

# Temporary file for raw results
TMP_RESULTS=$(mktemp)
for pair in "${SOURCES[@]}"; do
    IFS=':' read -r NAME DOMAIN <<< "$pair"
    echo "Searching $NAME..."
echo "DEBUG: Parsing loop completed" >&2
    python3 /home/ubuntu/.openclaw/workspace/skills/anysearch-skill/scripts/anysearch_cli.py search "site:$DOMAIN AI" --max_results $MAX_PER_SOURCE >> "$TMP_RESULTS" 2>&1
    sleep 0.4
done

# Parse AnySearch output to get title and url
TMP_PARSED=/tmp/tmp.ETmZBU4cLG
while IFS= read -r line; do
    if [[ $line =~ ^\#\#\#[[:space:]]+[0-9]+\.[[:space:]]*(.+) ]]; then
echo "DEBUG: TMP_ENRICHED created" >&2
        TITLE="${BASH_REMATCH[1]}"
        CURRENT_TITLE="$TITLE"
    elif [[ $line =~ ^\-\ \*\*URL\*\*\: ]]; then
        URL=$(echo "$line" | grep -oE 'https?://[^ ]+')
        if [[ -n "$CURRENT_TITLE" && -n "$URL" ]]; then
            echo "$CURRENT_TITLE|$URL" >> "$TMP_PARSED"
            CURRENT_TITLE=""
        fi
    fi
done < "$TMP_RESULTS"
echo "DEBUG: Enrichment loop completed" >&2

# Scoring function
score_title() {
echo "DEBUG: TMP_SORTED created" >&2
echo "DEBUG: Sort completed" >&2
    local t="$1"
    local score=0
    local low=$(echo "$t" | tr '[:upper:]' '[:lower:]')
echo "DEBUG: OUTPUT_FILE created" >&2
    # categories
    if [[ $low =~ (platform|agent|multi-agent|framework|sdk|api|launch|release|open\s+source|beta) ]]; then ((score++)); fi
    if [[ $low =~ (browser|ide|search|desktop\s+assistant|workflow|copilot|assistant|interface|ui|ux) ]]; then ((score++)); fi
    if [[ $low =~ (api|sdk|plugin|marketplace|app\s+store|deploy|host|github|npm|pip|docker|extension) ]]; then ((score++)); fi
    if [[ $low =~ (remote|hire|jobs|career|team|hiring|freelance|contract|work\s+from\s+home|distributed) ]]; then ((score++)); fi
    if [[ $low =~ (world\s+model|physical\s+ai|robotics|agent\s+os|simulation|embodied|robot|ros) ]]; then ((score++)); fi
    if [[ $low =~ ai\ agent ]]; then ((score++)); fi
    echo "$score"
}

echo "DEBUG: Output loop completed" >&2
# Process each line
TMP_ENRICHED=$(mktemp)
while IFS='|' read -r TITLE URL; do
echo "DEBUG: About to print final message" >&2
    if [[ -z "$TITLE" || -z "$URL" ]]; then continue; fi
    SCORE=$(score_title "$TITLE")
echo "DEBUG: Script finished" >&2
    # Fetch snippet for points (first 200 chars of text)
    SNIPPET=$(curl -s --max-time 8 "$URL" | sed -e 's/<[^>]*>//g' | tr -s '[:space:]' ' ' | head -c 200)
    # Extract ~20 Chinese chars
    # Extract ~20 Chinese chars
    POINTS=$(echo "$SNIPPET" | grep -oP '[\x{4e00}-\x{9fff}]{20,}' | head -1 | cut -c1-20)
    if [[ -z "$POINTS" ]]; then
        # fallback: first 20 chars of title
        POINTS=$(echo "$TITLE" | cut -c1-20)
    fi
    # URL-encode the URL for TinyURL API
    if command -v jq >/dev/null 2>&1; then
        URL_ENCODED=$(echo -n "$URL" | jq -sRr @uri 2>/dev/null) || URL_ENCODED=""
    else
        # Fallback URL encoding if jq is not available
        URL_ENCODED=$(echo -n "$URL" | sed 's/[^a-zA-Z0-9.-]/_/g')
    fi
    if [[ -z "$URL_ENCODED" ]]; then
        URL_ENCODED="$URL"
    fi
    # Call TinyURL API with timeout
    SHORT=$(curl -s --max-time 5 "https://tinyurl.com/api-create.php?url=$URL_ENCODED" 2>/dev/null) || SHORT=""
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
