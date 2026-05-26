# Telegram 本地社区公告板 / 分类信息流 Bot - Codex 任务草稿

## 背景
参考项目：https://github.com/anton-novak/community-board-bot

该项目可作为 Telegram Bot + Mini App 交互参考，但不建议直接继承架构。目标是重新设计一个适合长期迭代的 Telegram 本地社区信息系统。

## 产品目标
在 Telegram 中构建：本地社区群聊 + 分类信息流 + 用户订阅规则 + 轻量 AI 摘要 + 命中词条相关资讯推送。

核心理念：Telegram 群聊负责自然交流，Bot 负责整理、归档、匹配和提醒。

## MVP 功能
- `/start` 用户注册与介绍
- `/post` 发布本地信息
- `/browse` 浏览分类信息
- `/subscribe` 设置订阅：分类 / 地区 / 关键词
- `/my_subscriptions` 查看与管理订阅
- `/summary` 今日摘要
- 用户删除自己的帖子
- 管理员删除任意帖子
- 基础举报与限流

## 技术建议
- Node.js + TypeScript
- Telegram Bot：优先 grammY，其次 Telegraf
- 后端：Fastify 或 Express
- 数据库：PostgreSQL + Prisma
- 队列：BullMQ + Redis，可第二阶段加入
- Mini App：React / Next.js，可第二阶段加入

## 核心数据模型
- User: telegramId, username, displayName, language
- Post: userId, title, category, location, description, imageFileId, contact, status
- Subscription: userId, type(category/keyword/location), value
- NotificationLog: userId, postId, reason, sentAt
- Report: postId, userId, reason

## 新帖子发布流程
1. 用户通过 Bot 提交帖子
2. 系统校验长度、频率、分类、图片数量
3. 保存 Post
4. 查询订阅规则
5. 判断分类 / 地区 / 关键词命中
6. 私聊推送命中用户
7. 写入 NotificationLog 避免重复推送
8. 纳入每日摘要

## 参考项目可借鉴点
- Bot 内发帖向导
- Telegram Mini App 浏览分类信息流
- Telegram file_id 图片处理
- 发布前预览确认

## 参考项目不建议复用点
- CouchDB 数据模型不适合复杂订阅规则
- 生产安全不足：CORS、auth_date、URL path 携带 initData、并发 user 存储方式等都需重做
- 缺少审核、限流、举报、订阅、摘要和资讯推送
- 比赛原型风格，不适合直接作为长期产品底座

## 交付要求给 Codex
先输出架构设计、MVP 功能清单、Prisma schema、Bot 命令设计、目录结构、关键流程伪代码、初始可运行代码骨架和 README，再开始实现。
