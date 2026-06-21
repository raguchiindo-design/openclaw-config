#!/bin/bash
echo "DEBUG: before" >&2
LOG_DIR="/home/ubuntu/.openclaw/logs"
LOG_FILE="$LOG_DIR/ai_opportunity_radar_$(date +%Y%m%d).log"
echo "LOG_FILE=$LOG_FILE" >&2
exec >>"$LOG_FILE" 2>&1
echo "After exec" >&2
