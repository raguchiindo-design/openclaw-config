#!/usr/bin/env python3
import re, base64, sys

# 获取 mcporter 输出（支持管道或参数）
if len(sys.argv) > 1:
    with open(sys.argv[1]) as f:
        raw = f.read()
else:
    raw = sys.stdin.read()

# 正则提取 base64 数据
m = re.search(r"data:\s*'([A-Za-z0-9+/=]+)'", raw)
if m:
    b64 = m.group(1)
    img = base64.b64decode(b64)
    with open("xhs_login.png", "wb") as f:
        f.write(img)
    print("✅ QR code saved: xhs_login.png ({} bytes)".format(len(img)))
else:
    print("❌ No base64 image data found")
    sys.exit(1)
