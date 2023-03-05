FROM node:15.7.0-alpine3.10
MAINTAINER yirufeng <yirufeng@foxmail.com>

# 切换中科大源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories
# 安装bash git openssh 以及c的编译工具
RUN apk add bash git openssh
# 安装hexo
RUN npm install hexo-cli -g
# 设置工作目录
WORKDIR /data
# 克隆仓库
RUN git clone https://github.com/sivanWu0222/sivanWu0222.github.io.git -b source
# 进入目录并安装
RUN cd ./sivanWu0222.github.io && npm install
# 暴露4000端口
EXPOSE 80
# 运行服务
ENTRYPOINT ["hexo", "server", "-p", "80"]


docker run -dp 80:80 --name=hexo-blog hexo/blog

git clone https://github.com/sivanWu0222/sivanWu0222.github.io.git -b source ./website
docker build -f ./Dockerfile -t hexo/blog .
docker run -itdp 9000:80 --name=hexo-blog -v /root/tmp/website:/data hexo/blog 