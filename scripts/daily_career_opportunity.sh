#!/bin/bash
# Daily Career Opportunity Assessment script - bash version
LOG_DIR="/home/ubuntu/.openclaw/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/daily_career_opportunity_$(date +%Y%m%d).log"
# Redirect only stderr to log file; keep stdout for cron agent
exec 2>>"$LOG_FILE"

echo "=== Daily Career Opportunity Assessment started at $(date) ===" >&2

# Set AnySearch API key to avoid quota exhaustion
export ANYSEARCH_API_KEY="as_sk_b1df60bd2ea90b833fac22494eb6da0c"

# Define queries targeting career-relevant AI news
QUERIES=(
    "AI company outbound international expansion"
    "AI agent platform launch"
    "AI workflow automation tool"
    "AI IDE or AI-powered editor release"
    "AI browser or AI search product"
    "AI application distribution channel"
    "AI hardware product export"
    "AI BD partnership channel"
    "AI product new user entry point"
    "World Model Physical AI Robotics Agent OS"
)

MAX_PER_QUERY=2
TMP_RESULTS=$(mktemp)
# We'll collect results as lines: title|url
for q in "${QUERIES[@]}"; do
    echo "Searching: $q" >&2
    # Run anysearch with timeout and capture output
    OUTPUT=$(PYTHONIOENCODING=utf-8 LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 timeout 10 python3 /home/ubuntu/.openclaw/workspace/skills/anysearch-skill/scripts/anysearch_cli.py search "$q" --max_results $MAX_PER_QUERY 2>&1)
    EXIT_CODE=$?
    if [[ $EXIT_CODE -ne 0 ]]; then
        echo "Warning: AnySearch CLI failed for query: $q (exit code $EXIT_CODE)" >>"$LOG_FILE"
        echo "Warning: AnySearch CLI failed for query: $q" >&2
        continue
    fi
    # Parse the output to extract title and URL pairs
    title=""
    url=""
    while IFS= read -r line; do
        if [[ $line =~ ^[[:space:]]*[#][#][#][[:space:]]+[0-9]+[[:space:]]*[.][[:space:]]*(.+) ]]; then
            title="${BASH_REMATCH[1]}"
        elif [[ $line =~ ^[[:space:]]*-[[:space:]]+\*\*URL\*\*\:[[:space:]]+(https?://[^[:space:]]+) ]]; then
            url="${BASH_REMATCH[1]}"
            if [[ -n "$title" && -n "$url" ]]; then
                echo "$title|$url" >>"$TMP_RESULTS"
                title=""
                url=""
            fi
        fi
    done <<< "$OUTPUT"
    sleep 0.3
done

# If no results, exit gracefully
if [[ ! -s "$TMP_RESULTS" ]]; then
    echo "No results found." >&2
    rm -f "$TMP_RESULTS"
    echo "=== Daily Career Opportunity Assessment finished at $(date) ===" >&2
    exit 0
fi

# Process each result: compute fields and store tab-separated data
TMP_ITEMS_DATA=$(mktemp)
while IFS='|' read -r title url; do
    if [[ -z "$title" || -z "$url" ]]; then continue; fi
    # Fetch content (text mode) with timeout and user-agent
    content=$(curl -s --max-time 3 --user-agent "Mozilla/5.0" "$url" | sed -e 's/<[^>]*>//g' | tr -s '[:space:]' ' ' | head -c 500)
    if [[ -z "$content" ]]; then
        content="$title"
    fi
    # Determine opportunity direction (heuristic from title)
    direction=""
    if [[ "$title" =~ (outbound|international|global|expansion|海外|出海) ]]; then direction="国际市场/出海机会"; 
    elif [[ "$title" =~ (agent|multi[-]agent|platform) ]]; then direction="新AI平台/Agent平台"; 
    elif [[ "$title" =~ (workflow|automation|SOP) ]]; then direction="AI工作流/自动化工具"; 
    elif [[ "$title" =~ (IDE|editor|code) ]]; then direction="AI IDE/编辑器"; 
    elif [[ "$title" =~ (browser|search) ]]; then direction="AI浏览器/AI搜索入口"; 
    elif [[ "$title" =~ (distribution|marketplace|app[[:space:]]store|plugin) ]]; then direction="应用分发渠道/插件生态"; 
    elif [[ "$title" =~ (hardware|robot|robotics) ]]; then direction="AI硬件/机器人产品"; 
    elif [[ "$title" =~ (BD|partnership|channel|GTM) ]]; then direction="商务拓展/渠道合作机会"; 
    elif [[ "$title" =~ (user[[:space:]]entry|entry[[:space:]]point|onboarding) ]]; then direction="新用户入口/交互界面"; 
    elif [[ "$title" =~ (world[[:space:]]model|physical[[:space:]]AI|agent[[:space:]]OS) ]]; then direction="World Model/Physical AI/Agent OS"; 
    else direction="AI产品/技术更新"; fi
    # Extract company/product (simple: look for capitalized words)
    company=""
    # Try to find a pattern like "Company X" or "Product Y" from title
    if [[ "$title" =~ ([A-Z][a-zA-Z0-9]+(?:\s+[A-Z][a-zA-Z0-9]+)*) ]]; then
        company="${BASH_REMATCH[1]}"
    fi
    if [[ -z "$company" ]]; then company="未知公司"; fi
    # Why worth attention (<=50 Chinese chars)
    why=""
    if [[ "$direction" == "国际市场/出海机会" ]]; then why="该公司正在布局海外市场，为国际业务BD提供切入点。"; 
    elif [[ "$direction" == "新AI平台/Agent平台" ]]; then why="新平台提供集成机会，个人开发者可上架作品或获取合作。"; 
    elif [[ "$direction" == "AI工作流/自动化工具" ]]; then why="工作流工具提升开发效率，可作为技能点或远程岗位依据。"; 
    elif [[ "$direction" == "AI IDE/编辑器" ]]; then why="新IDE降低开发门槛，适合个人开发者快速原型。"; 
    elif [[ "$direction" == "AI浏览器/AI搜索入口" ]]; then why="新入口增加流量获取渠道，有利于产品推广。"; 
    elif [[ "$direction" == "应用分发渠道/插件生态" ]]; then why="分发渠道帮助作品触达用户，可考虑上架或合作。"; 
    elif [[ "$direction" == "AI硬件/机器人产品" ]]; then why="硬件产品伴随软件生态，提供硬件+软件结合的岗位。"; 
    elif [[ "$direction" == "商务拓展/渠道合作机会" ]]; then why="明确BD需求，可申请相关实习或合作项目。"; 
    elif [[ "$direction" == "新用户入口/交互界面" ]]; then why="新交互形式是产品经理方向的切入点。"; 
    elif [[ "$direction" == "World Model/Physical AI/Agent OS" ]]; then why="长期趋势，需关注其开发者社区和应用场景。"; 
    else why="具备技术或市场机遇，值得持续关注。"; fi
    why=$(echo "$why" | cut -c1-50)
    # Small action for Cici
    action=""
    if [[ "$direction" =~ 国际市场|出海 ]]; then action="关注该公司的国际岗位招聘或BD合作公告。"; 
    elif [[ "$direction" =~ 新AI平台|Agent平台 ]]; then action="注册开发者账号，查看文档和上架流程。"; 
    elif [[ "$direction" =~ AI工作流|自动化 ]]; then action="试用该工具，制作简历中的项目案例。"; 
    elif [[ "$direction" =~ AI[[:space:]]IDE|编辑器 ]]; then action="下载体验，评估其对个人开发的助力。"; 
    elif [[ "$direction" =~ AI浏览器|AI搜索 ]]; then action="使用其搜索功能，观察收录情况和SEO机会。"; 
    elif [[ "$direction" =~ 应用分发|插件生态 ]]; then action="了解上架要求，尝试提交一个小作品。"; 
    elif [[ "$direction" =~ AI硬件|机器人 ]]; then action="关注其开发者套件或硬件兼容性信息。"; 
    elif [[ "$direction" =~ 商务拓展|渠道合作|BD|GTM ]]; then action="投递实习或岗位，准备相关市场分析材料。"; 
    elif [[ "$direction" =~ 新用户入口|交互界面 ]]; then action="分析其用户流程，撰写可用性改进建议。"; 
    elif [[ "$direction" =~ World[[:space:]]Model|Physical[[:space:]]AI|Agent[[:space:]]OS ]]; then action="追踪其技术博客，学习相关概念和潜在应用。"; 
    else action="保持关注，定期查看更新。"; fi
    # Importance heuristic
    importance="中"
    if [[ "$direction" =~ (国际市场|出海|新AI平台|Agent平台|应用分发|插件生态|BD|渠道合作|新用户入口|交互界面) ]]; then importance="高"; 
    elif [[ "$direction" =~ (AI工作流|自动化|AI[[:space:]]IDE|编辑器|AI浏览器|AI搜索|AI硬件|机器人) ]]; then importance="中"; 
    else importance="低"; fi
    # Extract approx 20 characters from content (bytes)
    points="${content:0:20}"
    if [[ ${#points} -gt 20 ]]; then
        points="${points:0:20}"
    fi
    # Shorten URL via TinyURL with timeout
    encoded_url=""
    encoded_url=$(python3 -c "import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))" "$url")
    short_url=""
    short_url=$(curl -s --max-time 3 "https://tinyurl.com/api-create.php?url=$encoded_url" 2>/dev/null)
    if [[ ! "$short_url" =~ ^http ]]; then
        short_url="$url"
    fi
    # Output a tab-separated line: title, direction, company, why, action, importance, points, short_url
    echo -e "${title}\t${direction}\t${company}\t${why}\t${action}\t${importance}\t${points}\t${short_url}"
done < "$TMP_RESULTS" > "$TMP_ITEMS_DATA"

# Now sort the items by importance (高 > 中 > 低) and then by title
# We'll create a temporary file with sort key
TMP_SORTED=$(mktemp)
awk -F'\t' '{
    imp = $6;
    if (imp == "高") weight = 1;
    else if (imp == "中") weight = 2;
    else weight = 3;
    printf "%d\t%s\t%s\n", weight, $1, $0;
}' "$TMP_ITEMS_DATA" | sort -t$'\t' -k1,1n -k2,2 | cut -f3- > "$TMP_SORTED"

# Now format the sorted items into the desired output
while IFS=$'\t' read -r title direction company why action importance points short_url; do
    echo "机会方向：$direction"
    echo "相关公司/产品：$company"
    echo "为什么值得关注：$why"
    echo "Cici可以做的小行动：$action"
    echo "重要程度：$importance"
    echo "要点：$points"
    echo "来源：$short_url"
    echo ""
done < "$TMP_SORTED"

echo "=== Daily Career Opportunity Assessment finished at $(date) ===" >&2
# Cleanup
rm -f "$TMP_RESULTS" "$TMP_ITEMS_DATA" "$TMP_SORTED"
