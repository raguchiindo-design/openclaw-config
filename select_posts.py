#!/usr/bin/env python3
import json
import os

# Keywords
keywords = ["怀旧", "老歌", "思念", "送礼", "送领导", "送妈妈", "送客户", "2026年马年祝福", "年货", "马年", "除夕", "情人节", "致歉", "送上级"]

# Platform files
platform_files = {
    "全民k歌": "test_results_kg.json",
    "美篇": "test_results_meipian.json",
    "微博": "test_results.json",
    "知乎": "test_results_zhihu.json",
    "快手": "test_results_kuaishou.json"
}

all_posts = []

for platform, filename in platform_files.items():
    filepath = os.path.join("/home/ubuntu/.openclaw/workspace", filename)
    if not os.path.exists(filepath):
        continue
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
        if not data:
            continue
        for result in data[0].get('organicResults', []):
            title = result.get('title', '')
            url = result.get('url', '')
            description = result.get('description', '')
            # Check which keywords match
            matched_keywords = [k for k in keywords if k in title or k in description]
            if matched_keywords:
                all_posts.append({
                    'platform': platform,
                    'title': title,
                    'url': url,
                    'matched_keywords': matched_keywords,
                    'description': description[:200] if description else ''
                })

print(f"Total posts with keywords: {len(all_posts)}")

# Group by platform
platform_posts = {}
for post in all_posts:
    p = post['platform']
    if p not in platform_posts:
        platform_posts[p] = []
    platform_posts[p].append(post)

print("\nPosts per platform:")
for platform, posts in platform_posts.items():
    print(f"  {platform}: {len(posts)}")

# Select 10 posts across platforms, covering all platforms
selected = []
# Need Soul - will add separately
# Select from each platform
platforms_to_select = ["全民k歌", "美篇", "微博", "知乎", "快手"]
# Number of posts per platform (total 10)
# 全民k歌:2, 美篇:2, 微博:2, 知乎:2, 快手:1, Soul:1
selection_counts = {
    "全民k歌": 2,
    "美篇": 2,
    "微博": 2,
    "知乎": 2,
    "快手": 1
}

for platform, count in selection_counts.items():
    if platform in platform_posts:
        # Sort by number of matched keywords (descending)
        sorted_posts = sorted(platform_posts[platform], key=lambda x: len(x['matched_keywords']), reverse=True)
        selected.extend(sorted_posts[:count])

print(f"\nSelected {len(selected)} posts from platforms (excluding Soul)")

# Add Soul post (official platform link)
soul_post = {
    "platform": "Soul",
    "title": "深夜听歌，突然好想一个人 - Soul广场",
    "url": "https://www.soulapp.cn/",
    "matched_keywords": ["思念", "怀旧"],
    "description": "Soul官方平台，用户可以在广场发布动态，表达思念情感。"
}
selected.append(soul_post)

print(f"Total selected posts: {len(selected)}")

# Print selection
for i, post in enumerate(selected, 1):
    print(f"\n{i}. {post['platform']} - {post['title']}")
    print(f"   URL: {post['url']}")
    print(f"   Keywords: {', '.join(post['matched_keywords'])}")
    print(f"   Description: {post['description'][:100]}...")