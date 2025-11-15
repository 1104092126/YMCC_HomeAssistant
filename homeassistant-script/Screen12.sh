#!/bin/bash
# 切换显示器1到MacOS
/opt/homebrew/bin/betterdisplaycli set --namelike="LG ULTRAGEAR" --ddcAlt=144 --vcp=inputSelectAlt

# 记录当前状态为macOS
rm -f /tmp/monitor1_windows
