#!/bin/bash
LOG_DIR="/home/ubuntu/.openclaw/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test_exec_$(date +%Y%m%d).log"
exec >>"$LOG_FILE" 2>&1
echo "Test started at $(date)"
sleep 1
echo "Test ended at $(date)"
