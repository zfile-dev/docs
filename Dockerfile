# 使用基础镜像
FROM nginx:alpine-slim

# 将本地的构建结果复制到镜像中的指定位置
COPY ./build /usr/share/nginx/html

COPY ./nginx-conf/default.conf /etc/nginx/conf.d/default.conf

# 开放容器的80端口
EXPOSE 80

# 运行 Nginx 服务器
CMD ["nginx", "-g", "daemon off;"]
