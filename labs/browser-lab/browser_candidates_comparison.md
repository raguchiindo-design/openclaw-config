# 浏览器候选对比总表（最简版）

## 固定目标
最终以**成功访问以下微信公众号正文**作为测试目标之一：
- `https://mp.weixin.qq.com/s/n-fbrFbuDyBx39JIDXY9WA?scene=1&click_id=24`

## 评分维度（极简）
- 轻：依赖/下载/维护成本是否低
- 稳：成功率是否稳定
- 云：是否适合云端长期运行
- 微：是否有希望拿到微信公众号正文

## 对比表

| 方案 | 轻 | 稳 | 云 | 微 | 当前判断 |
|---|---|---|---|---|---|
| wechat-mirror-extractor | 高 | 中高 | 高 | 中 | 当前默认优先方案 |
| Playwright Chromium | 中 | 中高 | 中高 | 中高 | 已通过首轮固定公众号测试，适合作为增强浏览器基线 |
| Camoufox | 低 | 未知 | 中 | 中 | 可实验，但重，不进默认层 |
| Mac Chrome relay | 低 | 高 | 低 | 高 | 高风控兜底，不做默认层 |

## 当前结论
1. 默认层：`wechat-mirror-extractor` + `openclaw` browser
2. 实验层：`Playwright Chromium` → `Camoufox`
3. 兜底层：`Mac Chrome relay`

## clawbot 读取规则
- 先轻后重
- 先云后真机
- 新候选先入 `candidates/`，实测结果写入 `results/`
- 任何候选若首跑下载过大、维护成本过高，不直接进入主环境
