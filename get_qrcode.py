#!/usr/bin/env python3
import json
import base64
import subprocess

# 调用 mcporter 获取二维码
result = subprocess.run(
    ["mcporter", "call", "xiaohongshu.get_login_qrcode"],
    capture_output=True,
    text=True,
    timeout=30
)

# 解析输出（可能包含额外文本，提取 JSON 部分）
output = result.stdout
try:
    # 尝试直接解析
    data = json.loads(output)
except json.JSONDecodeError:
    # 查找 JSON 开始位置
    start = output.find('{')
    if start != -1:
        data = json.loads(output[start:])
    else:
        print("❌ 无法解析输出")
        print(output)
        exit(1)

# 提取图片数据
for item in data.get("content", []):
    if item.get("type") == "image":
        img_b64 = item["data"]
        img_bytes = base64.b64decode(img_b64)
        with open("/home/ubuntu/.openclaw/workspace/xhs_login.png", "wb") as f:
            f.write(img_bytes)
        print("✅ 二维码已保存: xhs_login.png")
        exit(0)

print("❌ 未找到二维码图片数据")
exit(1)
