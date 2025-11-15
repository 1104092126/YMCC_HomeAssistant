#!/bin/bash
# 切换ag显示器到windows11
/opt/homebrew/bin/betterdisplaycli set --namelike="AG273QG3R3B" --ddc=17 --vcp=inputSelect

# 记录当前状态为Windows
touch /tmp/monitor2_windows
