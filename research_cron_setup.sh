#!/bin/bash
# 数字花束趋势调研定时任务设置脚本

echo "正在设置数字花束与春节送礼趋势深度调研定时任务..."

# 确保工作目录存在
mkdir -p /home/ubuntu/.openclaw/workspace/marketing/analysis
mkdir -p /home/ubuntu/.openclaw/workspace/logs

# 清理现有的相关定时任务（如果有的话）
crontab -l 2>/dev/null | grep -v "research_trend_analyzer" | crontab -

# 添加新的定时任务：每2小时执行一次分析
(crontab -l 2>/dev/null; echo "# 数字花束与春节送礼趋势深度调研 - 每2小时执行") | crontab -
(crontab -l 2>/dev/null; echo "0 */2 * * * cd /home/ubuntu/.openclaw/workspace && python3 research_trend_analyzer.py >> /home/ubuntu/.openclaw/workspace/logs/research_analysis.log 2>&1") | crontab -

echo "定时任务设置完成！"
echo "任务执行时间：每2小时（00:00, 02:00, 04:00, 06:00, 08:00, 10:00, 12:00, 14:00, 16:00, 18:00, 20:00, 22:00）"
echo "日志文件：/home/ubuntu/.openclaw/workspace/logs/research_analysis.log"
echo "分析结果：/home/ubuntu/.openclaw/workspace/marketing/analysis/"

# 显示当前的定时任务
echo -e "\n当前定时任务列表："
crontab -l
echo -e "\n设置完成！"