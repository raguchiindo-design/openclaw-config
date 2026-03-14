# 实验结果：2026-03-14 Playwright Chromium 基线实验

## 基本信息
- 时间：2026-03-14
- 候选方案：Playwright Chromium
- 执行环境：`labs/browser-lab/venvs/baseline-playwright`
- 是否隔离：是（venv）

## 测试目标
验证普通 Playwright Chromium headless 在当前云端服务器上，是否能直接访问并提取固定微信公众号正文。

## 测试输入
- 链接 1：`https://mp.weixin.qq.com/s/n-fbrFbuDyBx39JIDXY9WA?scene=1&click_id=24`

## 执行过程
1. 创建独立 venv：`baseline-playwright`
2. 安装 `playwright`
3. 安装 Chromium runtime
4. 使用 headless Chromium 打开固定公众号链接
5. 提取 `#js_content` / body 文本并保存 HTML、截图、结果 JSON

## 结果
- 是否成功：**成功**
- HTTP 状态：`200`
- 页面标题：`香港秋电展观察：机器人军团远征，银发科技突围，外贸人迎风前行`
- `#js_content`：存在
- 正文提取长度：约 `4851` 字符
- 输出质量：可读，已成功拿到正文主体
- 失败点：无明显失败
- 工件位置：
  - `results/artifacts/playwright-baseline/page.html`
  - `results/artifacts/playwright-baseline/page.png`
  - `results/artifacts/playwright-baseline/result.json`

## 成本
- 安装依赖：中等
- 首跑下载：中到大（Chromium runtime）
- 维护复杂度：中等

## 结论
- [ ] 不建议采用
- [ ] 仅适合隔离实验
- [x] 可进入下一轮验证
- [ ] 可考虑纳入生产

## 备注
- 这次结果说明：**至少对当前这条微信公众号链接，普通 Playwright Chromium headless 已经能在云端拿到正文**。
- 这对后续判断很重要：说明“公众号=必须真机 relay”这个结论不能一刀切。
- 下一轮应继续测试：
  1. 是否对更多公众号文章稳定成功
  2. 是否会在 cron 场景中稳定
  3. 是否会触发验证码/环境异常
  4. 图片、排版、作者信息是否需要进一步结构化提取
