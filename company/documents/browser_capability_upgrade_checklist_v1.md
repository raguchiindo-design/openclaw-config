# 浏览器能力升级执行清单 v1

## 目标
让这台 OpenClaw 服务器形成三层浏览器能力：
1. 云端默认浏览器层（当前 openclaw headless）
2. 云端增强浏览器实验层（browser-lab）
3. 本机真实浏览器接管层（Mac Chrome relay，仅高风控站点兜底）

---

## 第一阶段：基础设施补齐（现在做）

### 1. 安装隔离环境基础能力
- [ ] 安装 `python3-venv`
- [ ] 验证 `python3 -m venv` 可用
- [ ] 约定隔离实验目录：`workspace/labs/browser-lab/`

### 2. 建立浏览器实验区
- [ ] 创建 `labs/browser-lab/README.md`
- [ ] 创建 `labs/browser-lab/candidates/`
- [ ] 创建 `labs/browser-lab/results/`
- [ ] 记录每个候选方案的：依赖、体积、首跑下载、成功率、维护成本

### 3. 固定网页任务路由
- [ ] Route A：轻量读取（web_fetch / openclaw browser / 现有提取 skill）
- [ ] Route B：云端增强尝试（未来 browser-lab 中候选）
- [ ] Route C：Mac 真浏览器 relay（高风控兜底）

---

## 第二阶段：能力分层（近期）

### 4. 将网页任务按难度分类
- [ ] A类：必须云端独立完成
- [ ] B类：优先云端，失败再请求 relay
- [ ] C类：默认 relay（微信、强风控后台等）

### 5. 为 cron 设计自动回退规则
- [ ] 轻量失败时记录失败原因
- [ ] 满足条件时进入增强浏览器尝试
- [ ] 再失败才触发 relay / 人工接管提醒

---

## 第三阶段：专项能力（按需）

### 6. 微信公众号专项策略
- [ ] 镜像/替代源方案长期保留
- [ ] 云端增强浏览器只做专项实验，不直接并入主环境
- [ ] 真机 relay 保留为高成功率兜底

### 7. 结果文档化
- [ ] 维护《候选浏览器方案对比表》
- [ ] 维护《已验证可用站点清单》
- [ ] 维护《必须 relay 的高风控站点清单》

---

## 当前判断
- `web-content-fetcher`：不建议进入主环境
- `jackwener/wechat-article-to-markdown`：方向对，但过重
- `x-reader`：实现偏薄，暂不作为重点投入对象
- 当前最优：保留现有 openclaw + 镜像提取 + Mac relay 三层组合
