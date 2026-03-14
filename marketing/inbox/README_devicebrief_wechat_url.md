# Device Brief 公众号网址输入说明

## 作用
这个文件用于给 `Device Brief 四平台周更发布（周一16:00）` cron 提供固定输入。

## 输入文件
- `devicebrief_wechat_url.txt`

## 使用方式
当小雪发来本周要处理的微信公众号文章网址后，将该链接写入：
- `/home/ubuntu/.openclaw/workspace/marketing/inbox/devicebrief_wechat_url.txt`

## 格式要求
- 只放 1 条链接
- 必须是有效的 `mp.weixin.qq.com` 文章 URL
- 不要附加说明文字

## cron 会做什么
1. 读取这个 URL
2. 抓取公众号正文
3. 清洗成纯中文正文
4. 按纯中文正文联网配图
5. 生成 Device Brief 名义的英文发表稿
6. 发布到四个平台
7. 成功后清空该输入文件，避免误读旧链接

## 当前约定
- 小雪发来 URL 后，由墨衍主会话负责落盘
- 这个文件是 cron 的正式输入源
