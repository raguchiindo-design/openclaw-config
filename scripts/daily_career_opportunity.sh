#!/usr/bin/env python3
import subprocess
import re
import time
import json
import urllib.parse
from datetime import datetime

# Configuration - queries for career-relevant AI news
QUERIES = [
    "AI company outbound international expansion",
    "AI agent platform launch",
    "AI workflow automation tool",
    "AI IDE or AI-powered editor release",
    "AI browser or AI search product",
    "AI application distribution channel",
    "AI hardware product export",
    "AI BD partnership channel",
    "AI product new user entry point",
    "World Model Physical AI Robotics Agent OS"
]

MAX_PER_QUERY = 2

def anysearch_search(query, max_results=5):
    """Run anysearch CLI and parse results."""
    cmd = [
        "python3", "/home/ubuntu/.openclaw/workspace/skills/anysearch-skill/scripts/anysearch_cli.py",
        "search", query,
        "--max_results", str(max_results)
    ]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        output = result.stdout
    except Exception as e:
        print(f"AnySearch error: {e}")
        return []
    # Parse lines like "### 1. Title\n- **URL**: https://..."
    items = []
    current_title = None
    for line in output.splitlines():
        line = line.strip()
        if line.startswith("###") and "." in line:
            # extract title after number and dot
            # e.g., "### 1. Sam Altman's new 'social contract' for AI"
            parts = line.split(".", 1)
            if len(parts) == 2:
                title_part = parts[1].strip()
                # remove leading/trailing spaces
                title = title_part
                current_title = title
        elif line.startswith("- **URL**:") and current_title:
            url_match = re.search(r"https?://[^\s]+", line)
            if url_match:
                url = url_match.group(0)
                items.append({"title": current_title, "url": url})
                current_title = None
    return items[:max_results]

def fetch_article_text(url):
    """Fetch article text via curl and simple extraction."""
    try:
        cmd = ["curl", "-s", "--max-time", "10", url]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=15)
        html = result.text
        # Extract text between <p> tags
        paragraphs = re.findall(r"<p[^>]*>(.*?)</p>", html, re.IGNORECASE | re.DOTALL)
        text = " ".join([re.sub(r"<[^>]+>", "", p) for p in paragraphs[:3]])
        text = re.sub(r"\s+", " ", text).strip()
        return text[:500]  # first 500 chars
    except Exception as e:
        print(f"Fetch error for {url}: {e}")
        return ""

def extract_points(text):
    """Get approx 20 Chinese characters from text."""
    # Find first sequence of Chinese characters
    chinese_seq = re.findall(r"[\u4e00-\u9fff]{20,}", text)
    if chinese_seq:
        return chinese_seq[0][:20]
    # If not enough, take first 20 chars of text (may include English)
    if len(text) >= 20:
        return text[:20]
    return text

def compute_score(title, text):
    score = 0
    combined = (title + " " + text).lower()
    # Category keywords
    categories = [
        (["platform", "agent", "multi-agent", "framework", "sdk", "api", "launch", "release", "open source", "beta"], 1),
        (["browser", "ide", "search", "desktop assistant", "workflow", "copilot", "assistant", "interface", "ui", "ux"], 1),
        (["api", "sdk", "plugin", "marketplace", "app store", "deploy", "host", "github", "npm", "pip", "docker", "extension"], 1),
        (["remote", "hire", "jobs", "career", "team", "hiring", "freelance", "contract", "work from home", "distributed"], 1),
        (["world model", "physical ai", "robotics", "agent os", "simulation", "embodied", "robot", "ros"], 1),
    ]
    for kwlist, weight in categories:
        if any(kw in combined for kw in kwlist):
            score += weight
    # Bonus for explicit AI Agent
    if "ai agent" in combined:
        score += 1
    return score

def shorten_url(long_url):
    """Use TinyURL API to get short link."""
    try:
        encoded = urllib.parse.quote(long_url, safe='')
        api_url = f"https://tinyurl.com/api-create.php?url={encoded}"
        cmd = ["curl", "-s", "--max-time", "5", api_url]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        short = result.text.strip()
        if short.startswith("http"):
            return short
        else:
            return long_url  # fallback
    except Exception as e:
        print(f"Shorten error: {e}")
        return long_url

def get_direction(title):
    t = title.lower()
    if any(k in t for k in ["outbound", "international", "global", "expansion", "海外", "出海"]):
        return "国际市场/出海机会"
    elif any(k in t for k in ["agent", "multi-agent", "platform"]):
        return "新AI平台/Agent平台"
    elif any(k in t for k in ["workflow", "automation", "sop"]):
        return "AI工作流/自动化工具"
    elif any(k in t for k in ["ide", "editor", "code"]):
        return "AI IDE/编辑器"
    elif any(k in t for k in ["browser", "search"]):
        return "AI浏览器/AI搜索入口"
    elif any(k in t for k in ["distribution", "marketplace", "app store", "plugin"]):
        return "应用分发渠道/插件生态"
    elif any(k in t for k in ["hardware", "robot", "robotics"]):
        return "AI硬件/机器人产品"
    elif any(k in t for k in ["bd", "partnership", "channel", "gtm"]):
        return "商务拓展/渠道合作机会"
    elif any(k in t for k in ["user entry", "entry point", "onboarding"]):
        return "新用户入口/交互界面"
    elif any(k in t for k in ["world model", "physical ai", "agent os"]):
        return "World Model/Physical AI/Agent OS"
    else:
        return "AI产品/技术更新"

def get_company(title):
    # Try to find a pattern like "Company X" or "Product Y"
    m = re.search(r"([A-Z][a-zA-Z0-9]+(?:\s+[A-Z][a-zA-Z0-9]+)*)", title)
    if m:
        return m.group(1)
    return "未知公司"

def get_why(direction):
    if direction == "国际市场/出海机会":
        return "该公司正在布局海外市场，为国际业务BD提供切入点。"
    elif direction == "新AI平台/Agent平台":
        return "新平台提供集成机会，个人开发者可上架作品或获取合作。"
    elif direction == "AI工作流/自动化工具":
        return "工作流工具提升开发效率，可作为技能点或远程岗位依据。"
    elif direction == "AI IDE/编辑器":
        return "新IDE降低开发门槛，适合个人开发者快速原型。"
    elif direction == "AI浏览器/AI搜索入口":
        return "新入口增加流量获取渠道，有利于产品推广。"
    elif direction == "应用分发渠道/插件生态":
        return "分发渠道帮助作品触达用户，可考虑上架或合作。"
    elif direction == "AI硬件/机器人产品":
        return "硬件产品伴随软件生态，提供硬件+软件结合的岗位。"
    elif direction == "商务拓展/渠道合作机会":
        return "明确BD需求，可申请相关实习或合作项目。"
    elif direction == "新用户入口/交互界面":
        return "新交互形式是产品经理方向的切入点。"
    elif direction == "World Model/Physical AI/Agent OS":
        return "长期趋势，需关注其开发者社区和应用场景。"
    else:
        return "具备技术或市场机遇，值得持续关注。"

def get_action(direction):
    if direction == "国际市场/出海机会":
        return "关注该公司的国际岗位招聘或BD合作公告。"
    elif direction == "新AI平台/Agent平台":
        return "注册开发者账号，查看文档和上架流程。"
    elif direction == "AI工作流/自动化工具":
        return "试用该工具，制作简历中的项目案例。"
    elif direction == "AI IDE/编辑器":
        return "下载体验，评估其对个人开发的助力。"
    elif direction == "AI浏览器/AI搜索入口":
        return "使用其搜索功能，观察收录情况和SEO机会。"
    elif direction == "应用分发渠道/插件生态":
        return "了解上架要求，尝试提交一个小作品。"
    elif direction == "AI硬件/机器人产品":
        return "关注其开发者套件或硬件兼容性信息。"
    elif direction == "商务拓展/渠道合作机会":
        return "投递实习或岗位，准备相关市场分析材料。"
    elif direction == "新用户入口/交互界面":
        return "分析其用户流程，撰写可用性改进建议。"
    elif direction == "World Model/Physical AI/Agent OS":
        return "追踪其技术博客，学习相关概念和潜在应用。"
    else:
        return "保持关注，定期查看更新。"

def get_importance(direction):
    if direction in ["国际市场/出海机会", "新AI平台/Agent平台", "应用分发渠道/插件生态", "商务拓展/渠道合作机会", "新用户入口/交互界面"]:
        return "高"
    elif direction in ["AI工作流/自动化工具", "AI IDE/编辑器", "AI浏览器/AI搜索入口", "AI硬件/机器人产品"]:
        return "中"
    else:
        return "低"

def main():
    all_items = []
    for query in QUERIES:
        print(f"Searching: {query}")
        items = anysearch_search(query, max_results=MAX_PER_QUERY)
        print(f"  got {len(items)} items")
        for it in items:
            it["query"] = query
            all_items.append(it)
        time.sleep(0.5)  # be gentle
    print(f"Total items fetched: {len(all_items)}")
    if len(all_items) == 0:
        print("No items fetched, exiting.")
        return
    # Enrich each item
    enriched = []
    for it in all_items:
        title = it["title"]
        url = it["url"]
        print(f"Processing: {title}")
        text = fetch_article_text(url)
        points = extract_points(text)
        direction = get_direction(title)
        company = get_company(title)
        why = get_why(direction)
        action = get_action(direction)
        importance = get_importance(direction)
        short_url = shorten_url(url)
        enriched.append({
            "title": title,
            "url": url,
            "short_url": short_url,
            "points": points,
            "direction": direction,
            "company": company,
            "why": why,
            "action": action,
            "importance": importance
        })
        time.sleep(0.3)
    # Sort by importance: 高 > 中 > 低
    order = {"高": 1, "中": 2, "低": 3}
    enriched.sort(key=lambda x: (order[x["importance"]], x["title"]))
    # Limit to 10 items
    top = enriched[:10]
    # Build output
    lines = []
    for i, item in enumerate(top, 1):
        lines.append(f"{i}. {item['title']}")
        lines.append(f"要点：{item['points']}")
        lines.append(f"对小雪的意义：{item['why']}")
        lines.append(f"Cici可以做的小行动：{item['action']}")
        lines.append(f"重要程度：{item['importance']}")
        lines.append("")  # blank line
    output = "\n".join(lines)
    # Write to file
    out_path = "/tmp/daily_career_opportunity.txt"
    with open(out_path, "w", encoding="utf-8") as f:
        f.write(output)
    print(f"Output written to {out_path}")
    print(output[:500])
    return output

if __name__ == "__main__":
    main()
EOF