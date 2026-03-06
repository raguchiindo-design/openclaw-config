# 🌐 网页交互能力整合方案

## 📋 当前可用工具

| 工具 | 状态 | 主要功能 |
|------|------|----------|
| **browser** | ✅ 已启动 | Chrome 浏览器控制（导航、点击、填写、截图） |
| **web_search** | ✅ 可用 | Brave Search API（搜索最新信息） |
| **web_fetch** | ✅ 可用 | 网页内容提取（Markdown/纯文本） |
| **Agent-Reach** | ✅ 已安装 | 视频/图片下载、RSS、语义搜索 |
| **MCP 服务器** | ✅ 2个运行 | 抖音、小红书内容访问 |

---

## 🔄 工具组合策略

### 1️⃣ **搜索 + 浏览 + 提取** (完整信息流)

**场景**: 查找最新新闻、竞品信息、市场动态

```
步骤:
1. web_search → 获取相关 URL 列表
2. browser.open → 打开最相关的页面
3. browser.snapshot → 获取结构化页面元素（支持 aria-ref 定位）
4. browser.act → 点击、滚动、填写表单
5. web_fetch → 快速提取完整文章内容（备用）
```

**示例**: 搜索"三八妇女节 花束 促销"
```bash
- web_search(query="三八妇女节 花束 促销 2026", count=5)
- 打开 top 3 结果
- 提取促销文案、图片链接、活动时间
- 截图保存证据
```

---

### 2️⃣ **快速内容获取** (轻量级)

**场景**: 阅读新闻、文章、博客

```
web_fetch(url="https://example.com/article", extractMode="markdown")
→ 返回 Markdown 格式的文本，包含图片链接
```

**优势**: 无需启动浏览器，速度快，适合批量处理

---

### 3️⃣ **交互式任务** (复杂操作)

**场景**: 登录、提交表单、跟帖、下载

```
browser.snapshot(refs="aria") → 获取元素 refs
browser.act(kind="type", ref="e12", text="用户名")
browser.act(kind="click", ref="e15")  # 点击登录
browser.act(kind="fill", ref="e20", values=["选项1"])
browser.screenshot() → 保存验证码或结果截图
```

**支持的操作**:
- `click` - 点击按钮/链接
- `type` - 输入文本
- `fill` - 选择下拉框
- `press` - 按键盘键（Enter, Tab等）
- `hover` - 悬停
- `drag` - 拖拽
- `wait` - 等待元素出现

---

### 4️⃣ **媒体下载** (视频/图片)

**场景**: 下载抖音/小红书视频、YouTube 视频

```bash
agent-reach + yt-dlp → 支持 1000+ 视频网站
→ 返回无水印下载链接
→ curl/wget 下载到本地
```

---

## 🎯 针对祥云花店的实际应用

### ✅ **可立即执行的任务**

1. **节日营销内容收集**
   - 搜索"妇女节 鲜花 祝福语"
   - 浏览小红书、微博热门贴
   - 提取高赞评论和图片风格
   - 整理成内容日历

2. **竞品监控**
   - 搜索竞品小程序/花店
   - 截图保存他们的活动页面
   - 提取价格、礼品种类、文案

3. **用户反馈收集**
   - 打开小程序二维码页面
   - 搜索"卡美心礼 评价"
   - 提取用户评论（知乎、小红书）

4. **自动化跟帖** (需谨慎)
   - 扫描相关帖子
   - 生成个性评论（基于内容）
   - 批量发布（需遵守平台规则）

---

## ⚙️ 配置说明

### 当前浏览器配置
- **路径**: `/usr/bin/google-chrome-unstable`
- **模式**: Headless (无界面)
- **用户数据**: `/home/ubuntu/.openclaw/browser/chrome/user-data`
- **CDP 端口**: 9222
- **已启动 PID**: 2245954

### 访问限制
- ✅ 可以访问公开网站
- ✅ 可以处理登录（需要先保存 cookies）
- ⚠️ 验证码需要人工干预或 OCR（暂未配置）
- ❌ 不能绕过 Cloudflare 等反爬机制

---

## 🔧 使用示例代码

### 示例 1: 搜索并截图热门内容

```python
# 1. 搜索
results = web_search("三八妇女节 送妈妈 鲜花", count=5)

# 2. 打开第一个结果
browser.open(results[0].url)

# 3. 等待页面加载
browser.act(kind="wait", timeMs=2000)

# 4. 截图
screenshot = browser.screenshot(fullPage=True)

# 5. 提取可见文本
snapshot = browser.snapshot(refs="aria")
```

### 示例 2: 填写表单并提交

```python
# 打开页面
browser.open("https://example.com/contact")

# 定位并填写字段
browser.act(kind="type", ref="e12", text="小雪")
browser.act(kind="type", ref="e13", text="xiaowei@example.com")
browser.act(kind="fill", ref="e14", values=["鲜花咨询"])

# 提交
browser.act(kind="click", ref="e15")

# 确认提交成功
browser.wait(timeMs=1000)
screenshot = browser.screenshot()
```

---

## 🚀 下一步建议

1. **小红书内容抓取**:
   - 使用 MCP 服务器（端口 18060）
   - 扫码登录获取 session
   - 搜索"数字花束"、"送妈妈花"等关键词

2. **微博热搜监控**:
   - browser 访问 weibo.com
   - 提取热搜榜
   - 筛选与节日、鲜花相关话题

3. **自动报告生成**:
   - 定时搜索 + 截图 + web_fetch 提取
   - 生成每日营销简报
   - 自动发送到 Telegram

---

## 📊 能力矩阵

| 能力 | browser | web_search | web_fetch | agent-reach | MCP |
|------|---------|------------|-----------|-------------|-----|
| 搜索信息 | ⚪ | ✅ | ⚪ | ⚪ | ⚪ |
| 浏览页面 | ✅ | ⚪ | ⚪ | ⚪ | ⚪ |
| 内容提取 | ✅ (结构化) | ⚪ | ✅ (全文) | ⚪ | ⚪ |
| 点击/填写 | ✅ | ⚪ | ⚪ | ⚪ | ⚪ |
| 视频下载 | ⚪ | ⚪ | ⚪ | ✅ | ⚪ |
| 社交媒体 | ✅ | ⚪ | ⚪ | ✅ | ✅ |
| 截图 | ✅ | ⚪ | ⚪ | ⚪ | ⚪ |

✅ = 支持 | ⚪ = 不支持/不需要

---

*最后更新: 2026-03-05*
*墨衍整理*
