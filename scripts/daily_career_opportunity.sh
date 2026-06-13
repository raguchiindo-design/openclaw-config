#!/bin/bash
# Daily Career Opportunity Assessment script - bash version
LOG_DIR="/home/ubuntu/.openclaw/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/daily_career_opportunity_$(date +%Y%m%d).log"
exec >>"$LOG_FILE" 2>&1

echo "=== Daily Career Opportunity Assessment started at $(date) ==="

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
for q in "${QUERIES[@]}"; do
    echo "Searching: $q"
    python3 /home/ubuntu/.openclaw/workspace/skills/anysearch-skill/scripts/anysearch_cli.py search "$q" --max_results $MAX_PER_QUERY >> "$TMP_RESULTS" 2>&1
    sleep 0.3
done

# Parse AnySearch output to get title and URL
TMP_PARSED=$(mktemp)
while IFS= read -r line; do
    if [[ $line =~ ^\###\ [0-9]+\.\ (.+) ]]; then
        TITLE="${BASH_REMATCH[1]}"
        CURRENT_TITLE="$TITLE"
    elif [[ $line =~ ^\-\ \*\*URL\*\*\:\ (https?://[^[:space:]]+) ]]; then
        URL="${BASH_REMATCH[1]}"
        if [[ -n "$CURRENT_TITLE" && -n "$URL" ]]; then
            echo "$CURRENT_TITLE|$URL" >> "$TMP_PARSED"
            CURRENT_TITLE=""
        fi
    fi
done < "$TMP_RESULTS"

# Function to derive fields from title
process_item() {
    local title="$1"
    local url="$2"
    # Determine opportunity direction (heuristic from title)
    local direction=""
    if [[ "$title" =~ (outbound|international|global|expansion|海外|出海) ]]; then direction="国际市场/出海机会"; 
    elif [[ "$title" =~ (agent|multi[-]agent|platform) ]]; then direction="新AI平台/Agent平台"; 
    elif [[ "$title" =~ (workflow|automation|SOP) ]]; then direction="AI工作流/自动化工具"; 
    elif [[ "$title" =~ (IDE|editor|code) ]]; then direction="AI IDE/编辑器"; 
    elif [[ "$title" =~ (browser|search) ]]; then direction="AI浏览器/AI搜索入口"; 
    elif [[ "$title" =~ (distribution|marketplace|app store|plugin) ]]; then direction="应用分发渠道/插件生态"; 
    elif [[ "$title" =~ (hardware|robot|robotics) ]]; then direction="AI硬件/机器人产品"; 
    elif [[ "$title" =~ (BD|partnership|channel|GTM) ]]; then direction="商务拓展/渠道合作机会"; 
    elif [[ "$title" =~ (user entry|entry point|onboarding) ]]; then direction="新用户入口/交互界面"; 
    elif [[ "$title" =~ (world model|physical AI|agent OS) ]]; then direction="World Model/Physical AI/Agent OS"; 
    else direction="AI产品/技术更新"; fi
    # Extract company/product (simple: look for capitalized words)
    local company=""
    # Try to find a pattern like "Company X" or "Product Y" from title
    if [[ "$title" =~ ([A-Z][a-zA-Z0-9]+(?:\s+[A-Z][a-zA-Z0-9]+)*) ]]; then
        company="${BASH_REMATCH[1]}"
    fi
    if [[ -z "$company" ]]; then company="未知公司"; fi
    # Why worth attention (<=50 Chinese chars)
    local why=""
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
    # Truncate why to 50 Chinese chars (approx)
    why=$(echo "$why" | cut -c1-50)
    # Small action for Cici
    local action=""
    if [[ "$direction" =~ 国际市场|出海 ]]; then action="关注该公司的国际岗位招聘或BD合作公告。"; 
    elif [[ "$direction" =~ 新AI平台|Agent平台 ]]; then action="注册开发者账号，查看文档和上架流程。"; 
    elif [[ "$direction" =~ AI工作流|自动化 ]]; then action="试用该工具，制作简历中的项目案例。"; 
    elif [[ "$direction" =~ AI IDE|编辑器 ]]; then action="下载体验，评估其对个人开发的助力。"; 
    elif [[ "$direction" =~ AI浏览器|AI搜索 ]]; then action="使用其搜索功能，观察收录情况和SEO机会。"; 
    elif [[ "$direction" =~ 应用分发|插件生态 ]]; then action="了解上架要求，尝试提交一个小作品。"; 
    elif [[ "$direction" =~ AI硬件|机器人 ]]; then action="关注其开发者套件或硬件兼容性信息。"; 
    elif [[ "$direction" =~ 商务拓展|渠道合作|BD|GTM ]]; then action="投递实习或岗位，准备相关市场分析材料。"; 
    elif [[ "$direction" =~ 新用户入口|交互界面 ]]; then action="分析其用户流程，撰写可用性改进建议。"; 
    elif [[ "$direction" =~ World Model|Physical AI|Agent OS ]]; then action="追踪其技术博客，学习相关概念和潜在应用。"; 
    else action="保持关注，定期查看更新。"; fi
    # Importance heuristic: high if direction matches top priorities
    local importance="中"
    if [[ "$direction" =~ (国际市场|出海|新AI平台|Agent平台|应用分发|插件生态|BD|渠道合作|新用户入口|交互界面) ]]; then importance="高"; 
    elif [[ "$direction" =~ (AI工作流|自动化|AI IDE|编辑器|AI浏览器|AI搜索|AI硬件|机器人) ]]; then importance="中"; 
    else importance="低"; fi
    # Output block
    echo "机会方向：$direction"
    echo "相关公司/产品：$company"
    echo "为什么值得关注：$why"
    echo "Cici可以做的小行动：$action"
    echo "重要程度：$importance"
    echo ""
}

# Process each parsed item
TMP_OUTPUT=$(mktemp)
while IFS='|' read -r title url; do
    if [[ -z "$title" || -z "$url" ]]; then continue; fi
    process_item "$title" "$url" >> "$TMP_OUTPUT"
done < "$TMP_PARSED"

# Sort by importance: 高 > 中 > 低
# We'll assign numeric weights for sorting
TMP_SORTED=$(mktemp)
awk -F'重要程度：' '{importance=$2; if(importance=="高") weight=1; else if(importance=="中") weight=2; else weight=3; print weight "|" $0}' "$TMP_OUTPUT" | sort -t'|' -k1,1n -k2 | cut -d'|' -f2- > "$TMP_SORTED"

# Limit to maybe 10 items
head -n 100 "$TMP_SORTED" > /tmp/daily_career_opportunity_$(date +%Y%m%d).txt
cat /tmp/daily_career_opportunity_$(date +%Y%m%d).txt

echo "=== Daily Career Opportunity Assessment finished at $(date) ==="
# Cleanup
rm -f "$TMP_RESULTS" "$TMP_PARSED" "$TMP_OUTPUT" "$TMP_SORTED"
