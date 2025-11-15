#!/bin/bash

# 远程关机脚本
# 用于通过SSH连接到192.168.31.10并发送关机指令
# 适用于Windows 11系统

# 配置参数
REMOTE_HOST="YOUR_REMOTE_WINDOWS_IP"
REMOTE_USER="YOUR_REMOTE_WINDOWS_USERNAME"  # 请替换为远程主机的用户名

# 执行关机命令
echo "正在连接到 $REMOTE_HOST..."
ssh $REMOTE_USER@$REMOTE_HOST "shutdown /s /t 0"

# 检查命令执行结果
if [ $? -eq 0 ]; then
  echo "✅ 关机指令已成功发送到 $REMOTE_HOST"
else
  echo "❌ 关机指令发送失败"
  exit 1
fi