#!/usr/bin/env python3
import json, base64, sys

# 从参数读取 JSON 文件或 stdin
if len(sys.argv) > 1:
    with open(sys.argv[1]) as f:
        raw = f.read()
else:
    raw = sys.stdin.read()

# 提取 JSON 部分（如果包含额外文本）
start = raw.find('{')
if start != -1:
    raw = raw[start:]

data = json.loads(raw)

for item in data.get("content", []):
    if item.get("type") == "image":
        img = base64.b64decode(item["data"])
        with open("xhs_login.png", "wb") as f:
            f.write(img)
        print("✅ Saved: xhs_login.png")
        sys.exit(0)

print("❌ No image found")
sys.exit(1)
