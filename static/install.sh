#!/bin/bash

# --------------- 初始化设置 ---------------
export TZ='Asia/Shanghai'

set -e  # 遇到错误立即退出
#set -x  # 打印执行的命令
# 获取脚本相关路径，分别为脚本运行路径，脚本日志路径，安装文件路径
SCRIPT_PATH=$(readlink -f "$0")  # 获取脚本绝对路径
BASEDIR=$(dirname "$(realpath "$0")")

# --------------- 获取系统信息 ---------------

get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

OPSY=$( get_opsy )
LBIT=$( getconf LONG_BIT )
KERN=$( uname -r )
ARCH=$( uname -m )
HOME_DIR=$( cd ~ && pwd )

if [ "$ARCH" = "x86_64" ]; then ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then ARCH="arm"
fi

DOCKER_COMPOSE_TYPE=$(
  if docker compose version &>/dev/null; then echo "docker compose"
  elif docker-compose --version &>/dev/null; then echo "docker-compose"
  else echo "none"
  fi
)

# --------------- 脚本头信息 ---------------
SCRIPT_NAME="ZFile 管理脚本"
WEB_URL="https://www.zfile.vip"
GITHUB_URL="https://github.com/zfile-dev/zfile"
AUTHOR="Zhao Jun <873019219@qq.com>, QQ: 873019219"
VERSION="1.0.1"

# --------------- 颜色定义及日志 -----------
if [ -t 1 ]; then
    RED=$(printf '\033[31m')
    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m')
    GRAY=$(printf '\033[37m')
    BOLD=$(printf '\033[1m')
    RESET=$(printf '\033[0m')
else
    RED=""
    GREEN=""
    YELLOW=""
    BOLD=""
    RESET=""
fi

STEP_NAME=""
mkdir -p "$HOME_DIR/.zfile-script"
LOG_FILE="$HOME_DIR/.zfile-script/zfile-script.log"

log_level() {
    local level=$1
    local content=$2
    local stdout=${3:-true}
    local stdoutPrefix=${4:-false}
    local prefixContent

    prefixContent="[${level}] $(date '+%Y-%m-%d %H:%M:%S') ${STEP_NAME}"

    if [ "$stdout" = true ]; then
        local color
        if [ "$level" = "ERROR" ]; then
            color=$RED
        elif [ "$level" = "WARN" ]; then
            color=$YELLOW
        elif [ "$level" = "INFO" ]; then
            color=$GREEN
        else
            color=$GRAY
        fi

        if [ "$stdoutPrefix" = true ]; then
            echo -e "${color}${prefixContent} ${content}${RESET}"
        else
            echo -e "${color}${content}${RESET}"
        fi
    fi

    echo "${prefixContent} ${content}" >> "$LOG_FILE"
}

log_debug() {
    log_level "DEBUG" "$1" $2 $3
}

log_info() {
    log_level "INFO" "$1" $2 $3
}

log_warn() {
    log_level "WARN" "$1" $2 $3
}

log_error() {
    log_level "ERROR" "$1" $2 $3
}

# --------------- 全局辅助变量 -----------------
## 定义 key, value 形式的版本映射
INSTALL_VERSION_MAP=(
    [1]="开源版"
    [2]="捐赠版"
)

INSTALL_TYPE_MAP=(
    [1]="直接安装"
    [2]="docker 安装"
    [3]="docker-compose 安装"
    [4]="直接安装(4.1.5及以前)"
    [5]="直接安装(4.1.6 Pro及以前)"
)

INPUT_PORT=""
INPUT_PATH=""
INPUT_INSTALL_VERSION=""
INPUT_INSTALL_TYPE=""
INPUT_DOCKER_IMAGE_MIRROR=""
INPUT_YN=""

# 自动检测当前安装的版本和方式
# 是否是通过脚本安装的
IS_SCRIPT_INSTALL=false
INSTALL_VERSION=""
INSTALL_TYPE=""
ZFILE_RUNNING_STATUS=""
INSTALL_FINISH_EXTRA_TIPS=""

INSTALL_INFO_FILE="$HOME_DIR/.zfile-script/.zfile-install-info.ini"
# --------------- 工具方法 -----------

get_install_info() {
  local key=$1
  local value
  if [ -f "$INSTALL_INFO_FILE" ]; then
    value=$(grep "^$key=" "$INSTALL_INFO_FILE" | cut -d'=' -f2)
    if [ -n "$value" ]; then
      echo "$value"
    else
      echo ""
    fi
  else
    echo ""
  fi
}

check_port_in_use() {
  local port=$1

  # 检测 netstat
  if command -v netstat &>/dev/null; then
    if netstat -tuln | grep ":$port" &>/dev/null; then
      return 0
    fi
  fi

  # 检测 ss
  if command -v ss &>/dev/null; then
    if ss -tuln | grep ":$port" &>/dev/null; then
      return 0
    fi
  fi

  # 检测 lsof
  if command -v lsof &>/dev/null; then
    if lsof -i :$port &>/dev/null; then
      return 0
    fi
  fi

  return 1
}

read_port() {
    local port
    local msg="${1}"
    local default_port="${2}"
    local prompt

    # 根据是否有默认端口号进行提示
    if [ -n "$default_port" ]; then prompt="${msg}（默认：${default_port}）[1-65535]:"
    else prompt="${msg} [1-65535]:"
    fi
    echo -n "$prompt"
    read -r port
    port=${port:-$default_port}
    # 检查输入的端口是否合法
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        log_error "端口号 ${port} 无效，请输入一个有效的端口号（1-65535）"
        read_port "$msg" "$default_port"
        return
    fi
    # 检查端口是否被占用
    if check_port_in_use "$port"; then
        log_error "端口 $port 已被占用"
        read_port "$msg" "$default_port"
        return
    fi
    INPUT_PORT="$port"
}
read_path() {
    local msg="${1}"
    local default_path="${2}"
    local create_path="${3:-false}"
    local allow_path_not_empty="${4:-false}"
    local input_path

    # 根据是否有默认目录进行提示
    if [ -n "$default_path" ]; then
        prompt="${msg}（默认：${default_path}）:"
    else
        prompt="${msg}:"
    fi
    echo -n "$prompt"
    read -r input_path
    input_path=${input_path:-$default_path}

    if [ "${input_path:0:1}" != "/" ]; then
        log_error "输入的目录 ${input_path} 不合法，目录必须以 / 开头"
        read_path "$msg" "$default_path" "$create_path" "$allow_path_not_empty"
        return
    fi

    # 根据是否允许目标目录非空（目录下有文件）进行判断
    if [ "$allow_path_not_empty" = false ]; then
        # 先判断目录本身是否存在，如果不存在就无所谓了，不需要判断目录下是否有文件
        if [ -d "$input_path" ]; then
            if [ "$(ls -A "$input_path")" ]; then
                log_error "目录 $input_path 不为空，请检查或重新填写！"
                read_path "$msg" "$default_path" "$create_path" "$allow_path_not_empty"
                return
            fi
        fi
    fi

    if [ ! -d "$input_path" ]; then
        if [ "$create_path" = true ]; then
            if [ "$(mkdir -p "$input_path")" ]; then
                log_error "创建目录 $input_path 失败！"
                read_path "$msg" "$default_path" "$create_path" "$allow_path_not_empty"
                return
            fi
        else
            log_error "目录 $input_path 不存在！"
            read_path "$msg" "$default_path" "$create_path" "$allow_path_not_empty"
            return
        fi
    fi

    # 去除最后所有的斜杠，且去掉中间重复的斜杠
    INPUT_PATH=$(echo "$input_path" | sed 's/\/\{1,\}/\//g' | sed 's/\/$//')
}
read_install_version() {
    local choice
    printf "%b\n" "${BOLD}${GREEN}1. 开源版${RESET}"
    printf "%b\n" "${BOLD}${GREEN}2. 捐赠版${RESET}"
    echo -n "请选择安装版本 [1-2]:"
    read -r choice
    if [ "$choice" != "1" ] && [ "$choice" != "2" ]; then
        log_error "安装版本选项 ${choice} 无效，请重新选择"
        read_install_version
    else
        INPUT_INSTALL_VERSION="$choice"
    fi
}
read_install_type() {
    local choice
    printf "%b\n" "${BOLD}${GREEN}1. 直接安装${RESET}"
    printf "%b\n" "${BOLD}${GREEN}2. docker 安装${RESET}"
    printf "%b\n" "${BOLD}${GREEN}3. docker-compose 安装${RESET}"
    echo -n "请选择安装方式 [1-3]:"
    read -r choice
    if [ "$choice" != "1" ] && [ "$choice" != "2" ] && [ "$choice" != "3" ]; then
        log_error "安装方式选项 ${choice} 无效，请重新选择"
        read_install_type
    else
        INPUT_INSTALL_TYPE="$choice"
    fi
}
read_docker_image_mirror() {
    local choice
    printf "%b\n" "${BOLD}${GREEN}1. DockerHub(仅推荐国外机器使用)${RESET}"
    printf "%b\n" "${BOLD}${GREEN}2. 华为香港镜像${RESET}"
    printf "%b\n" "${BOLD}${GREEN}3. 华为北京镜像${RESET}"
    echo -n "请选择 Docker 镜像源 [1-3]:"
    read -r choice
    if [ "$choice" != "1" ] && [ "$choice" != "2" ] && [ "$choice" != "3" ]; then
        log_error "Docker 镜像源选项 ${choice} 无效，请重新选择"
        read_docker_image_mirror
    else
        INPUT_DOCKER_IMAGE_MIRROR=$(
            if [ "$choice" = "1" ]; then
                echo "zhaojun1998/zfile"
            elif [ "$choice" = "2" ]; then
                echo "swr.ap-southeast-1.myhuaweicloud.com/zfile-dev/zfile"
            elif [ "$choice" = "3" ]; then
                echo "swr.cn-north-1.myhuaweicloud.com/zfile-dev/zfile"
            fi
        )
    fi
}
read_yn() {
    local msg="${1}"
    local default_choice="${2}"
    echo -n "${msg}（默认：${default_choice}）[y/n]:"
    read -r choice
    choice=${choice:-$default_choice}
    case "$choice" in
        [yY][eE][sS] | [yY])
            INPUT_YN="y"
            ;;
        [nN][oO] | [nN])
            INPUT_YN="n"
            ;;
        *)
            log_error "确认选项 ${choice} 无效，请重新选择"
            read_yn "$msg" "$default_choice"
            ;;
    esac
}

# 通过 docker inspect 命令获取容器的配置信息，判断是否是通过 docker-compose 创建的容器
check_container_name_is_compose() {
    local container_name=$1
    if docker inspect "$container_name" &>/dev/null; then
        local compose_version
        compose_version=$(docker inspect --format '{{ index .Config.Labels "com.docker.compose.version" }}' "$container_name")
        if [ -n "$compose_version" ]; then
            return 0
        fi
    fi
    return 1
}

check_container_name_is_running() {
    local container_name=$1
    if docker ps --format '{{.Names}}' | grep -q "^$container_name$"; then
        return 0
    else
        return 1
    fi
}

detect_running_version() {
   # 检查是不是 Docker 安装
    if [ -x "$(command -v docker)" ]; then
        # 检查是否有名为 zfile 的容器
        if docker ps -a --format '{{.Names}}' | grep -q '^zfile$'; then
            INSTALL_VERSION="1"
            ZFILE_RUNNING_STATUS=$(
                if check_container_name_is_running "zfile"; then echo "启动"
                else echo "未启动"
                fi
            )
            if check_container_name_is_compose "zfile"; then
                INSTALL_TYPE="3"
                return 0
            else
                INSTALL_TYPE="2"
                return 0
            fi
        elif docker ps -a --format '{{.Names}}' | grep -q '^zfile-pro$'; then
            INSTALL_VERSION="2"
            ZFILE_RUNNING_STATUS=$(
                if check_container_name_is_running "zfile-pro"; then echo "启动"
                else echo "未启动"
                fi
            )
            if check_container_name_is_compose "zfile-pro"; then
                INSTALL_TYPE="3"
                return 0
            else
                INSTALL_TYPE="2"
                return 0
            fi
        fi
    fi

    # 检测 4.1.6 及之前版本的社区版
    if ps -ef | grep ZfileApplication | grep -v grep &>/dev/null; then
        INSTALL_VERSION="1"
        INSTALL_TYPE="4"
        ZFILE_RUNNING_STATUS="启动"
        return 0
    fi

    # 检测 4.1.6 及之前版本的捐赠版
    if ps -ef | grep 'zfile-launch' | grep -v grep &>/dev/null; then
        INSTALL_VERSION="2"
        INSTALL_TYPE="5"
        ZFILE_RUNNING_STATUS="启动"
        return 0
    fi

    # 检测 4.2.0 及之后版本的社区版
    if ps -ef | grep 'zfile/zfile --' | grep -v grep &>/dev/null; then
        INSTALL_VERSION="1"
        INSTALL_TYPE="1"
        ZFILE_RUNNING_STATUS="启动"
        return 0
    fi

    # 检测 4.2.0 及之后版本的捐赠版
    if ps -ef | grep 'zfile/zfile-pro --' | grep -v grep &>/dev/null; then
        INSTALL_VERSION="2"
        INSTALL_TYPE="1"
        ZFILE_RUNNING_STATUS="启动"
        return 0
    fi
}

reset_variable() {
    INPUT_PORT=""
    INPUT_PATH=""
    INPUT_INSTALL_VERSION=""
    INPUT_INSTALL_TYPE=""
    INPUT_DOCKER_IMAGE_MIRROR=""
    INPUT_YN=""

    # 自动检测当前安装的版本和方式
    IS_SCRIPT_INSTALL=false
    INSTALL_VERSION=""
    INSTALL_TYPE=""
    ZFILE_RUNNING_STATUS=""
    INSTALL_FINISH_EXTRA_TIPS=""
}

get_install_type_and_version() {
     # 先从安装信息文件中读取安装信息
    if [ -f "$INSTALL_INFO_FILE" ]; then
        INSTALL_VERSION=$(get_install_info "install_version")
        INSTALL_TYPE=$(get_install_info "install_type")
        if [ -n "$INSTALL_VERSION" ] && [ -n "$INSTALL_TYPE" ]; then
            IS_SCRIPT_INSTALL=true
            ZFILE_RUNNING_STATUS="未启动"
        fi
    fi

    detect_running_version
}

print_tips() {
    # 如果 INSTALL_TYPE 和 INSTALL_VERSION 不为空，且 IS_SCRIPT_INSTALL 为 false，则说明不是脚本安装
    if [ -n "$INSTALL_TYPE" ] && [ -n "$INSTALL_VERSION" ] && [ "$IS_SCRIPT_INSTALL" = false ]; then
        log_error "已运行版本不是通过脚本安装的 ZFile，请手动${BOLD}停止并卸载${RESET}${RED}后再使用脚本！${RESET}"
        if [ "$INSTALL_TYPE" = "2" ] || [ "$INSTALL_TYPE" = "3" ]; then
            if [ "$INSTALL_VERSION" = "1" ]; then
                log_debug "tips: 可使用 docker rm -f zfile 命令卸载 ZFile！"
            elif [ "$INSTALL_VERSION" = "2" ]; then
                log_debug "tips: 可使用 docker rm -f zfile-pro 命令卸载 ZFile！"
            fi
        elif [ "$INSTALL_TYPE" = "1" ] || [ "$INSTALL_TYPE" = "4" ] || [ "$INSTALL_TYPE" = "5" ]; then
            log_debug "tips: 请使用 安装目录/bin/stop.sh 停止 ZFile！(然后备份该目录下的文件再删除该目录即可)"
            if [ "$INSTALL_VERSION" = "1" ]; then
                log_debug "安装目录一般为 $HOME_DIR/zfile，即 $HOME_DIR/zfile-pro/bin/stop.sh (如果你没修改过的话)"
            elif [ "$INSTALL_VERSION" = "2" ]; then
                log_debug "安装目录一般为 $HOME_DIR/zfile-pro，即 $HOME_DIR/zfile-pro/bin/stop.sh (如果你没修改过的话)"
            fi
        fi
        return 1
    fi

    echo -e "tips: 如这里自动检测已安装版本或安装方式不对(如果不是通过脚本安装且停止的ZFile，检测不到)，不要继续操作，请反馈给作者！"
}

show_header() {
#    clear
    echo "-------------------- ${SCRIPT_NAME} v${VERSION} --------------------"
    echo -e "Author              : ${AUTHOR}"
    echo -e "Website             : ${WEB_URL}"
    echo -e "GitHub              : ${GITHUB_URL}"
    echo "-------------------- System Information -----------------------"
    echo -e "Script Path         : ${SCRIPT_PATH}"
    echo -e "OS                  : ${OPSY}"
    echo -e "Arch                : ${ARCH} (${LBIT} Bit)"
    echo -e "Kernel              : ${KERN}"
    echo -e "User                : $(whoami)"
    if [ -x "$(command -v docker)" ]; then
        echo -e "Docker              : $(docker -v)"
    else
        echo -e "Docker              : ${YELLOW}未安装${RESET}"
    fi
    if [ "$DOCKER_COMPOSE_TYPE" = "docker compose" ]; then
        echo -e "Docker Compose      : $(docker compose version)"
    elif [ "$DOCKER_COMPOSE_TYPE" = "docker-compose" ]; then
        echo -e "Docker-Compose      : $(docker-compose --version)"
    else
        echo -e "Docker Compose      : ${YELLOW}未安装${RESET}"
    fi
    echo "---------------------------------------------------------------"
    if [ -z "$INSTALL_VERSION" ]; then
        echo -e "当前安装版本        : ${YELLOW}未安装${RESET}"
    else
        echo -e "当前安装版本        : ${INSTALL_VERSION_MAP[$INSTALL_VERSION]}"
    fi
    if [ -z "$INSTALL_TYPE" ]; then
        echo -e "当前安装方式        : ${YELLOW}未安装${RESET}"
    else
        echo -e "当前安装方式        : ${INSTALL_TYPE_MAP[$INSTALL_TYPE]}"
    fi
    if [ -n "$ZFILE_RUNNING_STATUS" ]; then
        echo -e "当前运行状态        : ${ZFILE_RUNNING_STATUS}"
    fi

    print_tips
    echo "---------------------------------------------------------------"
}

# 示例功能1
install() {
    # 如果已经安装了 ZFile，提示用户是否用户后退出
    if [ -n "$INSTALL_VERSION" ] && [ -n "$INSTALL_TYPE" ]; then
        log_error "已安装 ZFile，无法重复安装，请先卸载"
        return 0
    fi

    read_install_version
    read_install_type

    if [ "$INPUT_INSTALL_TYPE" = "1" ]; then
        install_zfile
    elif [ "$INPUT_INSTALL_TYPE" = "2" ]; then
        install_docker_zfile
    elif [ "$INPUT_INSTALL_TYPE" = "3" ]; then
        install_docker_compose_zfile
    fi

    echo "安装完成, 访问 $INPUT_PORT 端口即可访问，如无法访问请检查防火墙/安全组是否开放！
$INSTALL_FINISH_EXTRA_TIPS"
}

install_zfile() {
    local install_path
    local install_db_path
    local install_port
    local install_path_name
    local install_download_url
    local install_download_file_name

    if [ "$INPUT_INSTALL_VERSION" = "1" ]; then
        install_path_name="zfile"
        install_download_file_name="zfile-release_linux_${ARCH}.tar.gz"
        install_download_url="https://c.jun6.net/ZFILE/$install_download_file_name"
    elif [ "$INPUT_INSTALL_VERSION" = "2" ]; then
        install_path_name="zfile-pro"
        install_download_file_name="zfile-pro-release_linux_${ARCH}.tar.gz"
        install_download_url="https://c.jun6.net/ZFILE-PRO/$install_download_file_name"
    fi

    read_path "请输入 ZFile 程序存放目录" "$HOME_DIR/$install_path_name/" true
    install_path="$INPUT_PATH"
    read_path "请输入 ZFile 数据库及日志目录，没有会自动创建" "$HOME_DIR/.zfile-v4/" true true
    install_db_path="$INPUT_PATH"
    read_port "请输入 ZFile 端口号" 8080
    install_port="$INPUT_PORT"

    download_file $install_download_url "$install_path/$install_download_file_name"
    tar -zxf "$install_path/$install_download_file_name" -C "$install_path"
    rm -f "$install_path/$install_download_file_name"
    sed -i "s/8080/$install_port/g" "$install_path/application.properties"
    sed -i "s|\${user.home}\/.zfile-v4|$install_db_path|g" "$install_path/application.properties"
    chmod +x "${install_path}"/bin/*.sh
    "$install_path/bin/start.sh"

    # 写入安装信息到配置文件
    echo "install_type=$INPUT_INSTALL_TYPE" > "$INSTALL_INFO_FILE"
    echo "install_version=$INPUT_INSTALL_VERSION" >> "$INSTALL_INFO_FILE"
    echo "install_path=$install_path" >> "$INSTALL_INFO_FILE"
    echo "install_db_path=$install_db_path" >> "$INSTALL_INFO_FILE"
    echo "install_port=$install_port" >> "$INSTALL_INFO_FILE"
    echo "install_download_url=$install_download_url" >> "$INSTALL_INFO_FILE"
}

install_docker_zfile() {
    local container_name
    local install_image
    local install_command
    local install_db_path
    local install_data_path
    if ! command -v docker &> /dev/null; then
        printf "%b\n" "${RED}错误：未安装 Docker${RESET}"
        exit 1
    fi

    read_docker_image_mirror
    read_path "请输入 ZFile 数据库及日志目录，没有会自动创建" "$HOME_DIR/.zfile-v4/" true true
    install_db_path="$INPUT_PATH"
    read_port "请输入 ZFile 端口号" 8080
    read_yn "是否需向 Docker 容器内挂载文件目录(如不配置，使用本地存储无法在Docker容器内读取到宿主机内的文件目录)" "n"
    if [ "$INPUT_YN" = "y" ]; then
        read_path "请输入想讲服务器哪个目录挂载到 Docker 容器内(不存在会自动创建)" "" true true
        install_data_path="$INPUT_PATH"
        INSTALL_FINISH_EXTRA_TIPS="在 ZFile 添加本地存储类型的存储源时基路径填写 /data/file/ 对应宿主机的 $install_data_path 目录！"
    fi

    if [ "$INPUT_INSTALL_VERSION" = "1" ]; then
        container_name="zfile"
        install_image="$INPUT_DOCKER_IMAGE_MIRROR:latest"
    elif [ "$INPUT_INSTALL_VERSION" = "2" ]; then
        container_name="zfile-pro"
        install_image="$INPUT_DOCKER_IMAGE_MIRROR-pro:latest"
    fi

    install_command="docker run -d --name=$container_name --restart=always -p $INPUT_PORT:8080 \\
        -v $install_db_path/db/:/root/.zfile-v4/db/ \\
        -v $install_db_path/logs/:/root/.zfile-v4/logs/"
    if [ -n "$install_data_path" ]; then
        install_command="$install_command \\
        -v $install_data_path/:/data/file/"
    fi

    install_command="$install_command \\
        $install_image"

    log_debug "安装命令: $install_command"
    read_yn "是否确认安装 ZFile" "y"
    if [ $INPUT_YN = "y" ]; then
         eval "$install_command"
    else
        printf "%b\n" "${RED}已取消安装${RESET}"
        exit 1
    fi

    echo "install_type=$INPUT_INSTALL_TYPE" > "$INSTALL_INFO_FILE"
    echo "install_version=$INPUT_INSTALL_VERSION" >> "$INSTALL_INFO_FILE"
    echo "install_db_path=$install_db_path" >> "$INSTALL_INFO_FILE"
    echo "install_data_path=$install_data_path" >> "$INSTALL_INFO_FILE"
    echo "install_port=$INPUT_PORT" >> "$INSTALL_INFO_FILE"
    echo "install_image=$install_image" >> "$INSTALL_INFO_FILE"
    echo "install_command=$install_command" >> "$INSTALL_INFO_FILE"
}

install_docker_compose_zfile() {
    local container_name
    local install_image
    local compose_content
    local compose_path
    local install_data_path
    if ! command -v docker &> /dev/null; then
        printf "%b\n" "${RED}错误：未安装 Docker${RESET}"
        exit 1
    fi

    if [ "$INPUT_INSTALL_VERSION" = "1" ]; then
        container_name="zfile"
    elif [ "$INPUT_INSTALL_VERSION" = "2" ]; then
        container_name="zfile-pro"
    fi

    read_path "请输入 ZFile Docker-Compose 配置文件、日志、数据库所在目录，没有会自动创建" "$HOME_DIR/docker/$container_name/" true true
    compose_path="$INPUT_PATH"

    if [ "$(ls -A "$compose_path")" ]; then
        if [ -f "$compose_path/docker-compose.yml" ]; then
            read_yn "检测到目录 $compose_path 下已存在 docker-compose.yml 文件，是否直接使用该文件启动" "y"
            if [ "$INPUT_YN" = "y" ]; then
                INPUT_PORT='Docker-Compose 文件中配置的'
                cd "$compose_path" || exit
                eval "${DOCKER_COMPOSE_TYPE} up -d"
                return
            fi

            # 如果不直接使用，提示用户是否删除该文件
            read_yn "是否允许覆盖 $compose_path/docker-compose.yml 文件" "n"
            if [ "$INPUT_YN" = "n" ]; then
                log_error "请手动删除 $compose_path/docker-compose.yml 文件后重新执行安装！"
                exit 1
            fi
        fi
    fi

    read_docker_image_mirror
    if [ "$INPUT_INSTALL_VERSION" = "1" ]; then
        install_image="$INPUT_DOCKER_IMAGE_MIRROR:latest"
    elif [ "$INPUT_INSTALL_VERSION" = "2" ]; then
        install_image="$INPUT_DOCKER_IMAGE_MIRROR-pro:latest"
    fi

    read_port "请输入 ZFile 端口号" 8080
    read_yn "是否需向 Docker 容器内挂载文件目录(如不配置，使用本地存储无法在Docker容器内读取到宿主机内的文件目录)" "n"
    if [ "$INPUT_YN" = "y" ]; then
        read_path "请输入想要挂载到 Docker 容器内的文件目录(填写宿主机内的目录，不存在会自动创建)" "" true true
        install_data_path="$INPUT_PATH"
        INSTALL_FINISH_EXTRA_TIPS="在 ZFile 添加本地存储类型的存储源时基路径填写 /data/file/ 对应宿主机的 $install_data_path 目录！"
    fi

    compose_content="version: '3.1'
services:
    $container_name:
        image: $install_image
        container_name: $container_name
        restart: always
        ports:
        - $INPUT_PORT:8080
        volumes:
        - $compose_path/db/:/root/.zfile-v4/db/
        - $compose_path/logs/:/root/.zfile-v4/logs/"
        if [ -n "$install_data_path" ]; then
            compose_content="$compose_content
        - $install_data_path/:/data/file/"
        fi

        log_debug "将在 $compose_path 目录生成 Docker-Compose 配置文件来启动:"
        log_debug "$compose_content"
        read_yn "是否确认安装 ZFile" "y"
        if [ $INPUT_YN = "y" ]; then
            echo "$compose_content" > "$compose_path/docker-compose.yml"
            cd "$compose_path" || exit
            eval "${DOCKER_COMPOSE_TYPE} up -d"
        else
            printf "%b\n" "${RED}已取消安装${RESET}"
            exit 1
        fi

    echo "install_type=$INPUT_INSTALL_TYPE" > "$INSTALL_INFO_FILE"
    echo "install_version=$INPUT_INSTALL_VERSION" >> "$INSTALL_INFO_FILE"
    echo "compose_path=$compose_path" >> "$INSTALL_INFO_FILE"
    echo "install_data_path=$install_data_path" >> "$INSTALL_INFO_FILE"
    echo "install_port=$INPUT_PORT" >> "$INSTALL_INFO_FILE"
    echo "install_image=$install_image" >> "$INSTALL_INFO_FILE"
    echo "compose_content=$compose_content" >> "$INSTALL_INFO_FILE"
}

download_file() {
    local url=$1
    local file_name=$2
    log_debug "从 $url 下载文件到 $file_name"
    if command -v wget &>/dev/null; then
        wget --no-check-certificate -O "$file_name" "$url"
    elif command -v curl &>/dev/null; then
        curl -L -o "$file_name" "$url"
    else
        printf "%b\n" "${RED}错误：未安装 wget 或 curl${RESET}"
        exit 1
    fi
}

start() {
    local install_path
    local install_port
    if [ -z "$INSTALL_VERSION" ] || [ -z "$INSTALL_TYPE" ]; then
        log_error "未安装 ZFile，无法启动"
        return 0
    fi

    # 检测当前运行状态
    if [ "$ZFILE_RUNNING_STATUS" = "启动" ]; then
        log_error "ZFile 已经启动，请勿重复启动"
        return 0
    fi

    # 如果不为 Docker 安装方式，获取安装路径
    install_path=$(get_install_info "install_path")
    # 判断如果不为 Docker 安装
    if [ "$INSTALL_TYPE" != "2" ] && [ "$INSTALL_TYPE" != "3" ]; then
        if [ -z "$install_path" ]; then
            log_error "安装路径未找到，请检查安装信息文件: $INSTALL_INFO_FILE"
            return 0
        fi
    fi

    install_port=$(get_install_info "install_port")

    # 根据不同的安装方式执行不同的启动命令
    if [ "$INSTALL_VERSION" = "1" ]; then
        if [ "$INSTALL_TYPE" = "1" ]; then
            "$install_path/bin/start.sh"
        elif [ "$INSTALL_TYPE" = "2" ]; then
            docker start zfile
        elif [ "$INSTALL_TYPE" = "3" ]; then
            docker start zfile
        elif [ "$INSTALL_TYPE" = "4" ]; then
            "$install_path/bin/start.sh"
        fi
    elif [ "$INSTALL_VERSION" = "2" ]; then
        if [ "$INSTALL_TYPE" = "1" ]; then
            "$install_path/bin/start.sh"
        elif [ "$INSTALL_TYPE" = "2" ]; then
            docker start zfile-pro
        elif [ "$INSTALL_TYPE" = "3" ]; then
            docker start zfile-pro
        elif [ "$INSTALL_TYPE" = "5" ]; then
            "$install_path/bin/start.sh"
        fi
    fi

    ZFILE_RUNNING_STATUS="启动"

    echo "ZFile 启动完成，访问 $install_port 端口即可访问，如无法访问请检查防火墙/安全组是否开放！"
}

# 显示菜单
show_menu() {
    local i=0
    local MENU_ITEMS
    local item
    MENU_ITEMS=("安装 install" "启动 start" "停止 stop" "重启 restart" "更新 update" "卸载 uninstall")
    printf "%b\n" "${BOLD}主菜单：${RESET}"
    for item in "${MENU_ITEMS[@]}"; do
        printf "%b\n" "${BOLD}${GREEN}$((i + 1)). ${item}${RESET}"
        i=$((i + 1))
    done
    printf "%b\n" "${BOLD}${YELLOW}9. 更新脚本 self_update${RESET}"
    printf "%b\n" "${BOLD}${RED}0. 退出 exit${RESET}"
}

kill_9_pid() {
    local pid
    pid=$1
    kill -9 "$pid"
    sleep 2
    if ps -p "$pid" >/dev/null 2>&1; then
        log_error "停止进程 id $pid 失败"
    else
        log_info "停止进程 id $pid 成功"
        ZFILE_RUNNING_STATUS="未启动"
    fi
}

stop_docker_container() {
    local container_name
    container_name=$1
    docker stop "$container_name"
    ZFILE_RUNNING_STATUS="未启动"
}

stop() {
    local forceStop="${1:-false}"
    local pid
    if [ -z "$INSTALL_VERSION" ] || [ -z "$INSTALL_TYPE" ]; then
        log_error "未安装 ZFile，无法停止"
        return 0
    fi

    if [ "$ZFILE_RUNNING_STATUS" != "启动" ]; then
        log_info "ZFile 未启动，无需停止"
        return 0
    fi

    # 根据不同的安装方式执行不同的停止命令
    if [ "$INSTALL_VERSION" = "1" ]; then
        if [ "$INSTALL_TYPE" = "1" ]; then
            pid="$(ps -ef | grep 'zfile/zfile --' | grep -v grep | awk '{print $2}')"
            if [ "$forceStop" = true ]; then
                kill_9_pid "$pid"
            else
                read_yn "是否确认停止直接安装的开源版 ZFile，进程 id: ${pid}" "y"
                if [ "$INPUT_YN" = "y" ]; then
                    kill_9_pid "$pid"
                fi
            fi
        elif [ "$INSTALL_TYPE" = "2" ]; then
            if [ "$forceStop" = true ]; then
                stop_docker_container zfile
            else
                read_yn "是否确认停止 docker 安装的开源版 ZFile, 容器名: zfile" "y"
                if [ "$INPUT_YN" = "y" ]; then
                    stop_docker_container zfile
                fi
            fi
        elif [ "$INSTALL_TYPE" = "3" ]; then
            if [ "$forceStop" = true ]; then
                stop_docker_container zfile
            else
                read_yn "是否确认停止 docker-compose 安装的开源版 ZFile, 容器名: zfile" "y"
                if [ "$INPUT_YN" = "y" ]; then
                    stop_docker_container zfile
                fi
            fi
        elif [ "$INSTALL_TYPE" = "4" ]; then
            pid="$(ps -ef | grep ZfileApplication | grep -v grep | awk '{print $2}')"
            if [ "$forceStop" = true ]; then
                kill_9_pid "$pid"
            else
                read_yn "是否确认停止直接安装(4.1.5及以前版本)的开源版 ZFile，进程 id: ${pid}" "y"
                if [ "$INPUT_YN" = "y" ]; then
                    kill_9_pid "$pid"
                fi
            fi
        fi
    elif [ "$INSTALL_VERSION" = "2" ]; then
        if [ "$INSTALL_TYPE" = "1" ]; then
            pid="$(ps -ef | grep 'zfile/zfile-pro --' | grep -v grep | awk '{print $2}')"
            if [ "$forceStop" = true ]; then
                kill_9_pid "$pid"
            else
                read_yn "是否确认停止直接安装的捐赠版 ZFile，进程 id: ${pid}" "y"
                if [ "$INPUT_YN" = "y" ]; then
                    kill_9_pid "$pid"
                fi
            fi
        elif [ "$INSTALL_TYPE" = "2" ]; then
            if [ "$forceStop" = true ]; then
                stop_docker_container zfile-pro
            else
                read_yn "是否确认停止 docker 安装的捐赠版 ZFile, 容器名: zfile-pro" "y"
                if [ "$INPUT_YN" = "y" ]; then
                    stop_docker_container zfile-pro
                fi
            fi
        elif [ "$INSTALL_TYPE" = "3" ]; then
            if [ "$forceStop" = true ]; then
                stop_docker_container zfile-pro
            else
                read_yn "是否确认停止 docker-compose 安装的捐赠版 ZFile, 容器名: zfile-pro" "y"
                if [ "$INPUT_YN" = "y" ]; then
                    stop_docker_container zfile-pro
                fi
            fi
        elif [ "$INSTALL_TYPE" = "5" ]; then
            pid="$(ps -ef | grep 'zfile-launch' | grep -v grep | awk '{print $2}')"
            if [ "$forceStop" = true ]; then
                kill_9_pid "$pid"
            else
                read_yn "是否确认停止直接安装(4.1.6 Pro及以前版本)的捐赠版 ZFile，进程 id: ${pid}" "y"
                if [ "$INPUT_YN" = "y" ]; then
                    kill_9_pid "$pid"
                fi
            fi
        fi
    fi
}

restart() {
    read_yn "是否确认重启 ZFile" "y"
    if [ "$INPUT_YN" = "y" ]; then
        stop true
        start
    else
        return 0
    fi
}

uninstall() {
    local install_path
    if [ -z "$INSTALL_VERSION" ] || [ -z "$INSTALL_TYPE" ]; then
        log_error "未安装 ZFile，无法卸载"
        return 0
    fi

    if [ "$INSTALL_VERSION" = "1" ]; then
        if [ "$INSTALL_TYPE" = "1" ]; then
            read_yn "是否确认卸载直接安装的开源版 ZFile" "y"
            if [ "$INPUT_YN" = "y" ]; then
                if [ "$ZFILE_RUNNING_STATUS" = "启动" ]; then
                    install_path=$(ps -ef | awk '/zfile\/zfile --/ && !/grep/ {print $2}' | xargs -I{} ls -l /proc/{}/exe | awk '{print $NF}' | xargs dirname | xargs dirname)
                    stop true
                else
                    install_path=$(get_install_info "install_path")
                fi

                if [ -z "$install_path" ]; then
                    echo -e "${RED}未找到安装目录，请手动删除程序目录${RESET}"
                    return 0
                fi

                read_yn "停止直接安装的开源版 ZFile 完成，是否删除程序安装目录 $install_path 来完成卸载" "y"
                if [ "$INPUT_YN" = "y"  ]; then
                    rm -rf "$install_path"
                    echo "" > "$INSTALL_INFO_FILE"
                fi
            fi
        elif [ "$INSTALL_TYPE" = "2" ]; then
            read_yn "是否确认卸载 docker 安装的开源版 ZFile, 容器名: zfile" "y"
            if [ "$INPUT_YN" = "y" ]; then
                docker rm -f zfile
                echo "" > "$INSTALL_INFO_FILE"
            fi
        elif [ "$INSTALL_TYPE" = "3" ]; then
            read_yn "是否确认卸载 docker-compose 安装的开源版 ZFile, 容器名: zfile" "y"
            if [ "$INPUT_YN" = "y" ]; then
                docker rm -f zfile
                echo "" > "$INSTALL_INFO_FILE"
            fi
        elif [ "$INSTALL_TYPE" = "4" ]; then
            read_yn "是否确认卸载直接安装(4.1.5及以前版本)的开源版 ZFile" "y"
            if [ "$INPUT_YN" = "y" ]; then
                install_path=$(ps -ef | grep 'ZfileApplication' | grep -o -- '-classpath [^:]*' | cut -d' ' -f2 | xargs dirname | xargs dirname)
                stop true

                if [ -z "$install_path" ]; then
                    echo -e "${RED}未找到安装目录，请手动删除程序目录${RESET}"
                    return 0
                fi

                # 判断安装目录是否为空
                read_yn "停止直接安装(4.1.5及以前版本)的开源版 ZFile 完成，是否删除程序安装目录 $install_path 来完成卸载" "y"
                if [ "$INPUT_YN" = "y" ]; then
                    rm -rf "$install_path"
                    echo "" > "$INSTALL_INFO_FILE"
                fi
            fi
        fi
    elif [ "$INSTALL_VERSION" = "2" ]; then
        if [ "$INSTALL_TYPE" = "1" ]; then
            read_yn "是否确认卸载直接安装的捐赠版 ZFile" "y"
            if [ "$INPUT_YN" = "y" ]; then
                if [ "$ZFILE_RUNNING_STATUS" = "启动" ]; then
                    install_path=$(ps -ef | awk '/zfile\/zfile-pro --/ && !/grep/ {print $2}' | xargs -I{} ls -l /proc/{}/exe | awk '{print $NF}' | xargs dirname | xargs dirname)
                    stop true
                else
                    install_path=$(get_install_info "install_path")
                fi

                if [ -z "$install_path" ]; then
                    echo -e "${RED}未找到安装目录，请手动删除程序目录${RESET}"
                    return 0
                fi

                read_yn "停止直接安装的捐赠版 ZFile 完成，是否删除程序安装目录 $install_path 来完成卸载" "y"
                if [ "$INPUT_YN" = "y" ]; then
                    rm -rf "$install_path"
                    echo "" > "$INSTALL_INFO_FILE"
                fi
            fi
        elif [ "$INSTALL_TYPE" = "2" ]; then
            read_yn "是否确认卸载 docker 安装的捐赠版 ZFile, 容器名: zfile-pro" "y"
            if [ "$INPUT_YN" = "y" ]; then
                docker rm -f zfile-pro
                echo "" > "$INSTALL_INFO_FILE"
            fi
        elif [ "$INSTALL_TYPE" = "3" ]; then
            read_yn "是否确认卸载 docker-compose 安装的捐赠版 ZFile, 容器名: zfile-pro" "y"
            if [ "$INPUT_YN" = "y" ]; then
                docker rm -f zfile-pro
                echo "" > "$INSTALL_INFO_FILE"
            fi
        elif [ "$INSTALL_TYPE" = "5" ]; then
            read_yn "是否确认卸载直接安装(4.1.6 Pro及以前版本)的捐赠版 ZFile" "y"
            if [ "$INPUT_YN" = "y" ]; then
                install_path=$(ps -ef | grep 'zfile-launch' | grep -v grep | awk '{print $11}' | awk -F'/' '{for(i=1;i<NF;i++) printf $i"/"}')
                stop true

                # 判断安装目录是否为空
                if [ -z "$install_path" ]; then
                    echo -e "${RED}未找到安装目录，请手动删除${RESET}"
                    return 0
                fi

                read_yn "停止直接安装(4.1.6 Pro及以前版本)的捐赠版 ZFile 完成，是否删除程序安装目录 $install_path 来完成卸载" "y"
                if [ "$INPUT_YN" = "y" ]; then
                    rm -rf "$install_path"
                    echo "" > "$INSTALL_INFO_FILE"
                fi
            fi
        fi
    fi
}

update() {
    local install_path
    local install_download_url
    local install_download_file_name
    local pid
    local backup_path

    if [ -z "$INSTALL_VERSION" ] || [ -z "$INSTALL_TYPE" ]; then
        log_error "未安装 ZFile，无法更新"
        return 0
    fi

    # 如果是 docker 或 docker-compose 安装方式，用 watchtower 更新
    if [ "$INSTALL_TYPE" = "2" ] || [ "$INSTALL_TYPE" = "3" ]; then
        local container_name=""
        if [ "$INSTALL_VERSION" = "1" ]; then
            container_name="zfile"
        elif [ "$INSTALL_VERSION" = "2" ]; then
            container_name="zfile-pro"
        fi
        read_yn "是否确认更新 ZFile，容器名: $container_name" "y"
        log_debug "将使用 watchtower 更新容器，请确保机器与 Docker Hub 之间网络通畅。"
        if [ "$INPUT_YN" = "y" ]; then
            docker run --rm \
                -v /var/run/docker.sock:/var/run/docker.sock \
                containrrr/watchtower \
                --run-once \
                --cleanup \
                $container_name
            log_info "更新 Docker 运行的 ZFile 完成！"
        fi
        return 0
    fi

    # 判断安装信息文件是否为空，已安装的就不是通过脚本安装的
    if [ -f "$INSTALL_INFO_FILE" ]; then
        install_path=$(get_install_info "install_path")
        install_download_url=$(get_install_info "install_download_url")
        install_download_file_name=""

        if [ ! -d "$install_path" ]; then
            log_error "安装路径 $install_path 不存在，可能是安装目录被删除了，无法进行更新！"
            return 0
        fi
        if [ ! -f "$install_path/application.properties" ]; then
            log_error "安装目录 $install_path 下不存在 application.properties 文件，无法进行更新！"
        fi

        if [ "$INSTALL_VERSION" = "1" ]; then
            install_download_file_name="zfile-release_linux_${ARCH}.tar.gz"
        elif [ "$INSTALL_VERSION" = "2" ]; then
            install_download_file_name="zfile-pro-release_linux_${ARCH}.tar.gz"
        fi

        if [ "$INSTALL_VERSION" = "1" ]; then
            if [ "$INSTALL_TYPE" = "1" ]; then
                pid="$(ps -ef | grep 'zfile/zfile --' | grep -v grep | awk '{print $2}')"
            fi
        elif [ "$INSTALL_VERSION" = "2" ]; then
            if [ "$INSTALL_TYPE" = "1" ]; then
                pid="$(ps -ef | grep 'zfile/zfile-pro --' | grep -v grep | awk '{print $2}')"
            fi
        fi

        # 重新安装
        if [ "$INSTALL_VERSION" = "1" ]; then
            install_download_url="https://c.jun6.net/ZFILE/$install_download_file_name"
            install_download_file_name="zfile-release_linux_${ARCH}.tar.gz"
        elif [ "$INSTALL_VERSION" = "2" ]; then
            install_download_file_name="zfile-pro-release_linux_${ARCH}.tar.gz"
            install_download_url="https://c.jun6.net/ZFILE-PRO/$install_download_file_name"
        fi

        log_debug "更新会从 $install_download_url 下载更新包到 $install_path 目录，其他配置将沿用之前版本"
        read_yn "检测到当前安装的 ZFile 版本为${INSTALL_VERSION_MAP[$INSTALL_VERSION]}，将停止当前运行的 ZFile 并更新到最新版本，是否继续" "y"

        if [ "$INPUT_YN" = "n" ]; then
            log_info "已取消更新"
            return 0
        fi

        if [ -n "$pid" ]; then
            log_info "正在停止直接安装的 ZFile，进程 id: ${pid}"
            kill_9_pid "$pid"
        else
            log_info "当前不是启动状态，无需先停止服务。"
        fi

        backup_path="$install_path/backup/$(date +%Y-%m-%d_%H-%M-%S)"
        mkdir -p "$backup_path"
        find "$install_path" -maxdepth 1 -mindepth 1 -not -name "backup" -exec cp -r {} "$backup_path" \;

        download_file "$install_download_url" "$install_path/$install_download_file_name"
        tar -zxf "$install_path/$install_download_file_name" -C "$install_path"
        rm -f "$install_path/$install_download_file_name"
        chmod +x "${install_path}"/bin/*.sh
        cp "$backup_path/application.properties" "$install_path/application.properties"
        "$install_path/bin/start.sh"

        echo "更新完成，安装前程序备份目录为 $backup_path"
    else
        log_error "安装信息文件 $INSTALL_INFO_FILE 不存在，可能之前不是通过脚本安装的，无法更新，请使用卸载+安装的方式更新！"
        return 0
    fi
}


# 自更新函数
self_update() {
    local script_url="https://docs.zfile.vip/install.sh"  # 新版本下载地址
    local tmp_file=$(mktemp /tmp/script.XXXXXX)  # 创建临时文件

    echo "检查更新..."
    # 下载新版本，-fsSL 选项确保静默失败
    if curl -fsSL "$script_url" -o "$tmp_file"; then
        # 比较新旧文件内容，仅当不同时更新
        if ! cmp -s "$SCRIPT_PATH" "$tmp_file"; then
            log_debug "发现新版本，更新中..."
            mv "$tmp_file" "$SCRIPT_PATH"       # 替换原文件
            chmod +x "$SCRIPT_PATH"             # 确保可执行权限
            log_info "更新完成，按回车键重启脚本..."
            read -r
            exec "$SCRIPT_PATH"                 # 重启脚本，传递原有参数
            exit 0  # exec 执行后本行不会运行
        else
            echo "当前已是最新版本。"
            rm -f "$tmp_file"  # 清理临时文件
        fi
    else
        echo "错误：无法从 $script_url 下载新版本，请检查网络连接。"
        rm -f "$tmp_file"
        return 1
    fi
}


# --------------- 主逻辑 ---------------
main() {

    while true; do
        reset_variable
        get_install_type_and_version
        show_header
        show_menu

        echo -n "请输入一个选项或命令 [0-6|start|...]:"
        read -r choice

        case $choice in
            1|install)
                install ;;
            2|start)
                start ;;
            3|stop)
                stop ;;
            4|restart)
                restart ;;
            5|update|upgrade)
                update ;;
            6|uninstall|remove)
                uninstall ;;
            9|self_update)
                self_update ;;
            0|exit|quit)
                printf "%b\n" "${BOLD}感谢使用，再见！${RESET}"
                exit 0
                ;;
            *)
                printf "%b\n" "${RED}错误：无效的选项${RESET}"
                ;;
        esac

        printf "%b\n" "\n按回车回到脚本首页..."
        read -r
    done
}

# --------------- 脚本入口 ---------------
main "$@"