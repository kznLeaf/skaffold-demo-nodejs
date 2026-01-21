# 第一阶段：构建阶段，产物保存到临时镜像中

FROM node:20.18.1-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm ci --only=production

# 第二阶段:运行阶段，产物保存到文件系统

FROM alpine:3.20.3

# 使用 Alpine 的包管理器 apk 安装 Node.js 不缓存索引减小镜像大小
RUN apk add --no-cache nodejs 

WORKDIR /usr/src/app

# 复制第一阶段的 node_modules 产物到容器
COPY --from=builder /usr/src/app/node_modules ./node_modules

# 复制当前目录的所有文件到容器的工作目录
COPY . .

EXPOSE 3000

ENTRYPOINT [ "node", "src/index.js" ]