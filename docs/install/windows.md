---
sidebar_position: 4
sidebar_label: Windows
---

# Windows

### 安装依赖

安装 JDK8, 并配置环境变量, 可参考: https://jingyan.baidu.com/article/ce09321b85e8d62bff858f93.html

### 下载项目

下载文件 https://c.jun6.net/ZFILE/zfile-release.jar

### 启动项目

然后在文件所在路径下, 使用 `cmd` 执行命令 (不支持 `powershell`):

```bash
# 不可关闭命令行，关闭即停止程序，或使用 ctrl + c 命令停止程序
java -Dfile.encoding=utf-8 -jar -Dserver.port=8080 .\zfile-release.jar
```

> 如需要修改配置文件, 可去 Github 复制一份配置文件, <a href="https://github.com/zhaojun1998/zfile/blob/master/src/main/resources/application.yml">点击进入</a>, 放到 `jar` 文件同路径即可.

### **更新方式**

重新下载文件 https://c.jun6.net/ZFILE/zfile-release.jar 后，再次启动即可。
