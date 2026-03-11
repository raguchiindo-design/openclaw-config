# 统一SOP总表（多平台发文）

更新日期：2026-03-11  
适用平台：Substack / Patreon / Whop / Beehiiv

---

## A. 风控与验证总览（本轮实操结论）

### 1) Beehiiv
- **机器人检测**：有（Cloudflare「按住确认是人类」）
- **验证码/人工动作**：需要人工完成挑战
- **协作规则**：放在 cron 链路最后；墨衍发信号后，小雪手动过验证，再继续自动流程

### 2) Substack
- **机器人检测**：有概率触发（登录阶段出现 reCAPTCHA）
- **验证码/人工动作**：可能需要（邮箱魔法链接 / 密码登录 + reCAPTCHA）
- **协作规则**：优先复用 chrome profile 登录态；遇风控由小雪配合一次

### 3) Patreon
- **机器人检测**：本轮未遇到强制机器人挑战
- **验证码/人工动作**：本轮未遇到
- **协作规则**：正常登录后可直接编辑与发布

### 4) Whop
- **机器人检测**：本轮未遇到
- **验证码/人工动作**：本轮未遇到
- **协作规则**：注意在正确业务空间发文，发布后回流验证

---

## B. 全平台通用发布标准

1. 先确认登录态与正确账号/空间  
2. 先写标题，再写正文  
3. 正文统一英文终稿，金额口径统一（按当前规则：只写正确换算后的美元）  
4. 图片位置由文本语义决定（不是机械按序号）  
5. 每张图后加一句英文注解（公司/产品 + 来源类型）  
6. 结尾 CTA **统一前置「*」**  
7. 发布后二次验证：必须看到已发布状态（非 Draft）+ 可访问链接

---

## C. 平台执行SOP（精简）

### Substack
1) 进 /publish 编辑器  
2) 先填 Title（重点：再回读确认未丢）  
3) 填 Subtitle 与正文  
4) 插图 + 图注  
5) 发布并确认 “Your post is live” + 回传链接

### Patreon
1) 进入 Device Brief 创作者后台 → 创建帖子  
2) 先标题后正文  
3) 插图（上传或URL）+ 图注  
4) 检查受众/评论设置  
5) 发布后回列表确认新帖已上线

### Whop
1) 进入 Device Brief 正确发布区域  
2) 标题 + 正文 + 图文对应  
3) 图注 + 结尾 CTA（*开头）  
4) 发布并在 feed 中确认“刚刚”出现

### Beehiiv
1) 如遇 Cloudflare，先人工过验证  
2) 进入 posts/new：标题、Subtitle、正文  
3) Insert from URL 插图 + 图注 + tags  
4) Next → Audience → Email → Web → Review  
5) 完成最终发布动作并在 Posts 列表确认 Published

---

## D. 当前固定Tag风格（Beehiiv）
- #PhysicalAI
- #EmbodiedAI
- #FundingUpdates
- #CommercializationSignals

---

## E. 浏览器与接管模式（固定）

1) **默认首选：chrome profile（本机真实 Chrome）**
- 优先复用真实登录态
- 人机验证由小雪手动配合（验证码/Cloudflare/reCAPTCHA）

2) **备用：openclaw 托管浏览器**
- 仅在需要全自动处理服务器本地文件时使用
- 若登录态或风控不稳定，回切 chrome profile

## F. 异常排查顺序（固定）

1. 检查 Relay 是否附着当前 tab（扩展徽章 ON）
2. 检查是否出现 `no attached Chrome tabs`
3. 检查是否掉登录态（是否进入后台编辑页）
4. 检查是否触发风控（reCAPTCHA / Cloudflare）
5. 检查是否发生重定向异常（如重定向过多）
6. 检查 Title/Subtitle 是否真实保存（逐字输入+失焦+回读）
7. 检查发布后状态是否为 Published/live（非 Draft）

## G. 失败回退规则
- 任一平台发布失败：
  1) 立即保留草稿（不丢稿）
  2) 回报卡点（具体按钮/页面/错误）
  3) 切人工一步后继续自动化
