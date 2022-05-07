---
sidebar_position: 2
sidebar_label: Docker
---

# Docker


### 启动

镜像地址为：https://hub.docker.com/r/zhaojun1998/zfile

首次运行会自动创建数据库目录和日志文件目录，并映射到本地，分别为 `/root/zfile/db` (数据库文件) 和 `/root/zfile/logs` (日志文件). 后期迁移可直接将整个zfile目录备份恢复, 并再次执行以下命令.

```dockerfile
docker run -d --name=zfile --restart=always \
    -p 8080:8080 \
    -v /root/zfile/db:/root/.zfile/db \
    -v /root/zfile/logs:/root/.zfile/logs \
    zhaojun1998/zfile
```

### **更新**

**停止并删除现有 docker 容器，及删除本地镜像后**，重新执行上方命令即可。由于已经映射出数据库文件路径 `/root/zfile/db` 和日志文件路径 `/root/zfile/logs`，所以直接启动即可。 但为了保险起见还是建议启动前备份一份数据库文件到其他位置，再尝试启动，谨防数据丢失。
