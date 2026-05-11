FROM debian:stable-slim
# 设置清华大学或阿里云镜像源（可选，国内环境加速）
# RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources
RUN apt update && apt install -y --no-install-recommends \
    git curl wget procps ca-certificates vim htop iproute2 iputils-ping  && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["/bin/bash"]
