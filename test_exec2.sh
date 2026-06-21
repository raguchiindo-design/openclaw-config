#!/bin/bash
echo "DEBUG: before exec" >&2
LOG_DIR="/home/ubuntu/.openclaw/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/test_exec2_$(date +%Y%m%d).log"
exec >>"$LOG_FILE" 2>&1
echo "After exec"
echo "More output"
