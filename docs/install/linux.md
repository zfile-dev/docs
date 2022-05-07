---
sidebar_position: 1
sidebar_label: Linux
---

# Linux

### 安装依赖

```bash
# CentOS系统
yum install -y java-1.8.0-openjdk unzip

# Debian/Ubuntu系统
apt update
apt install -y openjdk-8-jre-headless unzip
```

### 下载项目

#### 安装说明

下面命令中第一行表示默认安装到用户目录下: `~/zfile` 下。

对于 `root` 用户, `~`  = `/root`,  `~/zfile` 表示在 `/root/zfile` 路径下。

对于其他用户,  `~` = `/hone/用户名` 表示在 `/home/用户名/` 路径下。如对于 `oracle` 用户,  `~/zfile` 则表示安装在 `/home/oracle/zfile` 下。

如需更改安装路径, 请自行修改，如 `export ZFILE_INSTALL_PATH=/data/zfile`，表示安装在 `/data/zfile` 路径下。

```bash
export ZFILE_INSTALL_PATH=~/zfile
mkdir -p $ZFILE_INSTALL_PATH && cd $ZFILE_INSTALL_PATH
wget https://c.jun6.net/ZFILE/zfile-release.war
unzip zfile-release.war && rm -rf zfile-release.war
chmod +x $ZFILE_INSTALL_PATH/bin/*.sh
```

### 常用命令

:::info
以下为默认未修改安装路径下的情况，如修改了安装路径请自行更改命令所在路径。
:::

```bash
 ~/zfile/bin/start.sh       # 启动项目
 ~/zfile/bin/stop.sh        # 停止项目
 ~/zfile/bin/restart.sh     # 重启项目
```

### **更新方式**

如果没修改过安装路径，则停止程序后，删除安装文件夹即可，默认命令为：

（如修改过安装路径，则替换下方命令中的 `~/zfile` 部分为你的安装路径即可）

```bash
# 停止程序
~/zfile/bin/stop.sh
# 删除安装文件夹 
rm -rf ~/zfile
```


```bash
# 重新下载安装最新版
export ZFILE_INSTALL_PATH=~/zfile
mkdir -p $ZFILE_INSTALL_PATH && cd $ZFILE_INSTALL_PATH
wget https://c.jun6.net/ZFILE/zfile-release.war
unzip zfile-release.war && rm -rf zfile-release.war
chmod +x $ZFILE_INSTALL_PATH/bin/*.sh
```
