#!/bin/bash
echo "DEBUG: Script starting" >&2
LOG_DIR="/home/ubuntu/.openclaw/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/ai_opportunity_radar_$(date +%Y%m%d).log"
exec >>"$LOG_FILE" 2>&1
echo "After exec" >&2
