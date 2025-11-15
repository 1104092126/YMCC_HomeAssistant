# 🚀 Home Assistant 自动化项目部署指南（小白友好版）

这份指南将一步一步教你部署完整的Home Assistant自动化项目，包含显示器输入源切换、远程PC开关机、巴法云MQTT远程控制等功能。

---

## 📋 前置条件检查

在开始部署之前，请确保你已经准备好以下内容：

1. **Home Assistant已安装**：
   - 可以是树莓派、虚拟机或Docker安装
   - 确保Home Assistant可以访问互联网和局域网内的其他设备

2. **Windows 11电脑**：
   - 需要开启**SSH服务**（用于远程关机）
   - 需要开启**Wake-on-LAN(WOL)**（用于远程开机）

3. **一台Mac电脑**：
   - 用于运行`betterdisplaycli`工具控制显示器
   - 需要安装Homebrew包管理器

4. **两台支持DDC/CI的显示器**：
   - LG ULTRAGEAR
   - AG273QG3R3B

5. **巴法云(BEMFA)账号**：
   - 用于MQTT远程控制

---

## 🔧 工具安装与准备

### 1. 安装betterdisplaycli（Mac端）

`betterdisplaycli`是用于控制显示器输入源的工具，需要在Mac上安装：

```bash
# 确保Homebrew已安装
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装betterdisplaycli
brew install betterdisplaycli
```

### 2. 开启Mac SSH服务

Home Assistant需要通过SSH连接到Mac来执行脚本，因此需要开启Mac的SSH服务：

1. 打开「系统偏好设置」→「共享」
2. 勾选「远程登录」选项
3. 在「允许访问」中选择「所有用户」或特定用户
4. 记住Mac的IP地址（在共享设置顶部显示：例如 `192.168.31.236`）

#### （可选但推荐）设置SSH免密码登录

为了让Home Assistant能无需密码连接到Mac，需要设置SSH密钥对：

```bash
# 在Home Assistant所在设备上生成SSH密钥
ssh-keygen -t rsa -b 4096 -C "homeassistant@your-device"

# 将公钥复制到Mac（替换为你的Mac用户名和IP）
ssh-copy-id YOUR_MAC_USERNAME@YOUR_MAC_IP

# 测试连接（无需输入密码即可登录则设置成功）
ssh YOUR_MAC_USERNAME@YOUR_MAC_IP
```

### 3. 配置Windows SSH服务

打开Windows PowerShell（管理员权限）并执行：

```powershell
# 安装OpenSSH服务
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# 启动SSH服务
Start-Service sshd

# 设置开机自启
Set-Service -Name sshd -StartupType 'Automatic'
```

### 4. 开启Windows WOL功能

1. **BIOS/UEFI设置**：开机按Del/ESC进入BIOS，找到"Wake-on-LAN"或"Power On by LAN"选项并开启
2. **Windows设置**：
   - 设备管理器 → 网络适配器 → 右键点击网卡 → 属性
   - 电源管理 → 勾选「允许此设备唤醒计算机」
   - 高级 → 找到「唤醒魔包」选项并设置为「启用」

### 5. 注册巴法云账号

1. 访问巴法云官网：https://bemfa.com
2. 注册账号并登录
3. 进入「MQTT物联网」→ 点击「添加新设备」→ 设备类型选择「MQTT」→ 设备名称任意填写
4. 记住你的**主题名**（格式：xxxxxx）和**巴法云MQTT服务器地址**：`bemfa.com:8344`

---

## 📦 项目文件部署

### 1. 下载项目文件

将项目文件夹`homeassistant-script`复制到**Mac电脑**的指定目录，例如：

```
/Users/[YOUR_MAC_USERNAME]/[YOUR_PROJECT_PATH]/
└── homeassistant-script/
    ├── Screen11.sh
    ├── Screen12.sh
    ├── Screen21.sh
    ├── Screen22.sh
    ├── automations.yaml
    ├── configuration.yaml
    └── shutdown-remote.sh
```

### 2. 配置文件修改

#### （1）修改`configuration.yaml`文件

在Home Assistant中创建一个新的配置文件或修改现有的`configuration.yaml`，添加以下内容：

```yaml
# 配置说明：
# - Home Assistant将通过SSH连接到Mac电脑执行脚本
# - YOUR_MAC_IP 是Mac电脑的IP地址
# - YOUR_MAC_USERNAME 是Mac电脑的用户名
# - /Users/[YOUR_MAC_USERNAME]/[YOUR_PROJECT_PATH]/homeassistant-script/ 是脚本在Mac上的路径

shell_command:
  # 切换显示器到Windows 11
  switch_monitor1_to_windows: 'ssh YOUR_MAC_USERNAME@YOUR_MAC_IP "bash /Users/[YOUR_MAC_USERNAME]/[YOUR_PROJECT_PATH]/homeassistant-script/Screen11.sh"'
  switch_monitor1_to_mac: 'ssh YOUR_MAC_USERNAME@YOUR_MAC_IP "bash /Users/[YOUR_MAC_USERNAME]/[YOUR_PROJECT_PATH]/homeassistant-script/Screen12.sh"'
  switch_monitor2_to_windows: 'ssh YOUR_MAC_USERNAME@YOUR_MAC_IP "bash /Users/[YOUR_MAC_USERNAME]/[YOUR_PROJECT_PATH]/homeassistant-script/Screen21.sh"'
  switch_monitor2_to_mac: 'ssh YOUR_MAC_USERNAME@YOUR_MAC_IP "bash /Users/[YOUR_MAC_USERNAME]/[YOUR_PROJECT_PATH]/homeassistant-script/Screen22.sh"'
  # 远程关机Windows 11
  shutdown_remote_windows: 'ssh YOUR_MAC_USERNAME@YOUR_MAC_IP "bash /Users/[YOUR_MAC_USERNAME]/[YOUR_PROJECT_PATH]/homeassistant-script/shutdown-remote.sh"'

# 替换为你的WOL设备MAC地址
light:
  - platform: template
    lights:
      remote_windows_shutdown: 
        # ... 其他配置 ...
        turn_on:
          - service: button.press
            target:
              entity_id: button.wake_on_lan_xxx  # 替换为你的WOL按钮实体ID
```

#### （2）修改`automations.yaml`文件

替换巴法云MQTT主题为你的主题名：

```yaml
- id: '1763024500001'
  alias: "巴法云MQTT消息控制开关机灯"
  triggers:
  - trigger: mqtt
    topic: "YOUR_BEMFA_MQTT_TOPIC"  # 替换为你的巴法云主题名
  # ... 其他配置 ...
```

#### （3）修改Shell脚本

在Mac电脑上修改`shutdown-remote.sh`文件，配置Windows PC的信息：

```bash
# shutdown-remote.sh 配置说明：
# - 该脚本存储在Mac电脑上，但会通过SSH连接到Windows PC执行关机命令
# - REMOTE_HOST 是Windows PC的IP地址
# - REMOTE_USER 是Windows PC的用户名

# 替换为你的Windows PC IP地址和用户名
REMOTE_HOST="YOUR_REMOTE_WINDOWS_IP"
REMOTE_USER="YOUR_REMOTE_WINDOWS_USERNAME"
```

---

## 🎛️ Home Assistant配置

### 1. 导入Automations配置文件

在Mac电脑上找到项目的`automations.yaml`文件，复制其完整内容，然后在Home Assistant中：

1. 点击「配置」→「设备与服务」→「辅助集成」→ 搜索「File editor」并安装
2. 使用File editor打开Home Assistant的`/config/automations.yaml`文件
3. 将复制的`automations.yaml`内容粘贴到文件中并保存

#### 关于configuration.yaml配置

我们已经在「配置文件修改」步骤中指导您将shell命令和灯光控制配置添加到了Home Assistant的`configuration.yaml`中，因此无需重复导入该文件。

### 2. 配置MQTT集成

1. 点击「+ 添加集成」→ 搜索「MQTT」并安装
2. MQTT服务器配置：
   - 服务器：`bemfa.com`
   - 端口：`8344`
   - 用户名：你的巴法云用户名
   - 密码：你的巴法云密码
   - 客户端ID：任意填写

### 3. 创建WOL按钮

1. 点击「+ 添加集成」→ 搜索「Wake on LAN」并安装
2. 填写你的Windows PC的MAC地址
3. 创建完成后，记住生成的`button.wake_on_lan_xxx`实体ID

### 4. 重启Home Assistant

在「配置」→「服务器控制」→ 点击「重启」按钮重启Home Assistant使配置生效。

---

## ✅ 功能测试

### 1. 显示器输入源切换测试

在Home Assistant的「仪表板」中找到「LG显示器」和「AG显示器」的灯光控制：
- 点击「开」→ 显示器应切换到Windows输入源
- 点击「关」→ 显示器应切换到macOS输入源

### 2. 远程开关机测试

- 点击「Windows11」灯光控制的「开」→ Windows PC应被WOL唤醒
- 点击「关」→ Windows PC应通过SSH执行关机命令

### 3. 巴法云远程控制测试

使用巴法云的Web控制台或手机APP发送MQTT消息：
- 发送消息 `on` → 应执行开机操作
- 发送消息 `off` → 应执行关机操作

---

## 🛠️ 常见问题与 troubleshooting

### 1. SSH连接失败

SSH连接可能涉及两个层面：Home Assistant → Mac，或Mac → Windows PC

**解决方法**：
- 确保Mac电脑的防火墙允许SSH端口（默认22）
- 确保Windows PC的防火墙允许SSH端口（默认22）
- 检查Mac和Windows的SSH服务是否正在运行
- 尝试手动测试连接：
  ```bash
  # Home Assistant 到 Mac 的连接测试
  ssh YOUR_MAC_USERNAME@YOUR_MAC_IP  # 替换为你的Mac用户名和IP
  
  # Mac 到 Windows PC 的连接测试
  ssh YOUR_REMOTE_WINDOWS_USERNAME@YOUR_REMOTE_WINDOWS_IP  # 替换为你的Windows用户名和IP
  ```

### 2. WOL无法唤醒PC

**解决方法**：
- 确保BIOS/UEFI中的WOL已开启
- 检查网卡设置中的「唤醒魔包」是否启用
- 确保Home Assistant与PC在同一局域网

### 3. 显示器切换失败

**解决方法**：
- 确保`betterdisplaycli`已正确安装
- 检查显示器的DDC/CI功能是否开启
- 尝试手动运行脚本测试：`bash Screen11.sh`

---

## 🎉 部署完成

恭喜你完成了整个Home Assistant自动化项目的部署！现在你可以：
- 使用无线开关控制显示器输入源
- 通过巴法云远程控制PC开关机
- 实现PC状态与显示器输入源的联动

如果遇到任何问题，请查看上面的 troubleshooting 部分或参考项目的 `readme.md` 文件。

---

## 📝 隐私化说明
为了保护隐私，项目中的所有敏感信息都已替换为占位符，请在使用时根据实际情况修改：
- `YOUR_MAC_IP`: 你的Mac电脑IP地址
- `YOUR_MAC_USERNAME`: 你的Mac电脑用户名
- `YOUR_PROJECT_PATH`: 项目在Mac上的保存路径
- `YOUR_REMOTE_WINDOWS_IP`: 远程Windows PC的IP地址
- `YOUR_REMOTE_WINDOWS_USERNAME`: 远程Windows PC的用户名
- `YOUR_BEMFA_MQTT_TOPIC`: 你的巴法云MQTT主题名
- `YOUR_REVERSE_PROXY_IP`: 反向代理服务器IP（如果使用）
- `YOUR_WINDOWS_PC_MAC_ADDRESS`: 远程Windows PC的MAC地址

**作者**：Home Assistant爱好者  
**版本**：v1.1  
**更新日期**：2024-05-27