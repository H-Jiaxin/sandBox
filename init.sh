#!/bin/bash

# 基础配置
CPU_DEFAULT="2.0"
MEM_DEFAULT="2G"

# 生成随机UID (3位字母+3位数字)
generate_uid() {
    letters=$(LC_ALL=C tr -dc 'a-z' < /dev/urandom | head -c 3)
    numbers=$(LC_ALL=C tr -dc '0-9' < /dev/urandom | head -c 3)
    echo "${letters}${numbers}"
}

usage() {
    echo "使用方法:"
    echo "  ./init.sh create [cpu] [memory]  # 创建新沙箱 (例如: ./init.sh create 2.0 2G)"
    echo "  ./init.sh destroy <UID>          # 销毁指定沙箱"
    echo "  ./init.sh list                   # 列出所有运行中的沙箱"
    exit 1
}

case "$1" in
  create)
        NET_NAME="sandbox-shared-net"
        if ! sudo docker network inspect "$NET_NAME" >/dev/null 2>&1; then
            echo "首次运行，正在自动创建公共网络: $NET_NAME..."
            sudo docker network create "$NET_NAME"
        fi
        UID_STR=$(generate_uid)
        INSTANCE_NAME="sandbox-${UID_STR}"
        CPU_LIMIT=${2:-$CPU_DEFAULT}
        MEM_LIMIT=${3:-$MEM_DEFAULT}

        echo "正在创建沙箱实例: $INSTANCE_NAME (CPU: $CPU_LIMIT, MEM: $MEM_LIMIT)..."
        
        # 1. 创建目录
        sudo mkdir -p "./instances/$INSTANCE_NAME"
        
        sudo INSTANCE_NAME=$INSTANCE_NAME \
             docker compose -p "$INSTANCE_NAME" up -d
        
        echo "------------------------------------------------"
        echo "沙箱创建成功！"
        echo "进入命令: docker exec -it $INSTANCE_NAME /bin/bash"
        echo "销毁命令: ./init.sh destroy $UID_STR"
        ;;
    destroy)
        if [ -z "$2" ]; then
            echo "错误: 请提供要销毁的 UID"
            usage
        fi
        TARGET_NAME="sandbox-$2"
        
        echo "正在销毁实例: $TARGET_NAME..."
        
        # 显式传递 INSTANCE_NAME，防止 Docker Compose 解析 yml 时校验失败
        # 同时保持其他变量（如 CPU/MEM）有默认值，或者直接传入
        sudo INSTANCE_NAME=$TARGET_NAME \
             docker compose -p "$TARGET_NAME" down
        
        # 自动清理数据目录（建议保持手动决定）
        # 增加 -p 直接显示提示语，增加 -n 1 只读取一个字符
        read -p "是否清除数据目录 ./instances/$TARGET_NAME? (y/n): " -n 1 -r yon

        # 转换输入为小写进行匹配，并增加对回车的处理（默认不删）
        if [[ "$yon" =~ ^[Yy]$ ]]; then
            sudo rm -rf "./instances/$TARGET_NAME"
            echo "数据目录已清理"
        else
            echo "保留数据目录: ./instances/$TARGET_NAME"
        fi
        echo "实例 $TARGET_NAME 已清理。"
        ;;

    list)
        echo "当前运行中的沙箱实例："
        docker ps --filter "name=sandbox-" --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}"
        ;;

    *)
        usage
        ;;
esac
