#!/usr/bin/env python3
import json
import os

# Keywords to find
target_keywords = ["送礼", "送领导", "送妈妈", "送客户", "2026年马年祝福", "年货", "马年", "除夕", "情人节", "致歉", "送上级"]

platform_files = {
    "全民k歌": "test_results_kg.json",
    "美篇": "test_results_meipian.json",
    "微博": "test_results.json",
    "知乎": "test_results_zhihu.json",
    "快手": "test_results_kuaishou.json"
}

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
            for keyword in target_keywords:
                if keyword in title or keyword in description:
                    print(f"Platform: {platform}")
                    print(f"  Title: {title}")
                    print(f"  URL: {url}")
                    print(f"  Keyword: {keyword}")
                    print(f"  Description: {description[:100]}...")
                    print()