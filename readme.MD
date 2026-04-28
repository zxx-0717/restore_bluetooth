可以采用手动和自动配置两种模式

=====================自动配置模式=====================

sudo chmod +x config.sh
修改config.sh中pwd为root密码，默认密码tj2022
命令行窗口运行 ./config.sh

=====================手动配置模式=====================

1、复制restore_bluetooth.service 到 /lib/systemd/system

2、cd ~

3、mkdir logs_bluetooth_restore

4、cd /opt

5、sudo mkdir systemd-sh

6、复制restore_bluetooth.sh 到 /opt/systemd-sh

7、sudo systemct damon-reload

8、sudo systemctl enable restore_bluetooth.service

9、reboot





# Bluetooth Auto-Restore Script

## 概述

这是一个用于 Linux 系统的蓝牙自动恢复监控脚本。主要功能是在设备充电期间，当检测到蓝牙异常断开时，自动执行一系列恢复操作，确保蓝牙功能恢复正常。

## 功能特性

- **自动监控**：在充电状态下持续监控蓝牙状态
- **条件触发**：通过标志文件控制监控和恢复的触发
- **多层次恢复**：
  - 应用层：`bluetoothctl` 电源控制
  - 服务层：`bluetooth.service` 重启
  - 驱动层：`btusb` 模块重载
  - 内核层：`rfkill` 阻塞解除
  - 设备层：`hciconfig` 设备激活
- **完整验证**：恢复后验证设备存在性和电源状态
- **日志记录**：详细的时间戳日志，便于问题追踪

## 系统要求

### 操作系统
- Linux (支持 systemd)
- 内核版本：3.0+ (支持 Bluetooth 子系统)

### 依赖软件包
```bash
# Ubuntu/Debian
sudo apt-get install bluez bluez-utils

# CentOS/RHEL
sudo yum install bluez bluez-libs

# Arch Linux
sudo pacman -S bluez bluez-utils