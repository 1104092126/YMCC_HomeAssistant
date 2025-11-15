#!/bin/bash
# 切换显示器1到windows11
/opt/homebrew/bin/betterdisplaycli set --namelike="LG ULTRAGEAR" --ddcAlt=208 --vcp=inputSelectAlt

# 记录当前状态为Windows
touch /tmp/monitor1_windows
