#!/bin/bash

# ============================================================
#                     ZFile 管理脚本
# ============================================================

# --------------- 初始化设置 ---------------
export TZ='Asia/Shanghai'
set -e

SCRIPT_PATH=$(readlink -f "$0")
BASEDIR=$(dirname "$(realpath "$0")")

# --------------- 颜色定义 ---------------
if [ -t 1 ]; then
    RED=$(printf '\033[31m')
    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m')
    BLUE=$(printf '\033[34m')
    CYAN=$(printf '\033[36m')
    GRAY=$(printf '\033[37m')
    BOLD=$(printf '\033[1m')
    DIM=$(printf '\033[2m')
    RESET=$(printf '\033[0m')
else
    RED="" GREEN="" YELLOW="" BLUE="" CYAN="" GRAY="" BOLD="" DIM="" RESET=""
fi

# --------------- 系统信息 ---------------
get_opsy() {
    [ -f /etc/redhat-release ] && awk '{print ($1,$3~/^[0-9]/?$3:$4)}' /etc/redhat-release && return
    [ -f /etc/os-release ] && awk -F'[= "]' '/PRETTY_NAME/{print $3,$4,$5}' /etc/os-release && return
    [ -f /etc/lsb-release ] && awk -F'[="]+' '/DESCRIPTION/{print $2}' /etc/lsb-release && return
}

OPSY=$(get_opsy)
LBIT=$(getconf LONG_BIT)
KERN=$(uname -r)
ARCH=$(uname -m)
HOME_DIR=$(cd ~ && pwd)

case "$ARCH" in
    x86_64)         ARCH="amd64" ;;
    aarch64|arm64)  ARCH="arm64" ;;
    armv7l|armv6l)  ARCH="arm" ;;
esac

DOCKER_COMPOSE_TYPE=$(
    if docker compose version &>/dev/null; then echo "docker compose"
    elif docker-compose --version &>/dev/null; then echo "docker-compose"
    else echo "none"
    fi
)

# --------------- 脚本元信息 ---------------
SCRIPT_NAME="ZFile 管理脚本"
WEB_URL="https://www.zfile.vip"
GITHUB_URL="https://github.com/zfile-dev/zfile"
AUTHOR="Zhao Jun <873019219@qq.com>, QQ: 873019219"
VERSION="1.0.2"

# --------------- 日志 ---------------
STEP_NAME=""
mkdir -p "$HOME_DIR/.zfile-script"
LOG_FILE="$HOME_DIR/.zfile-script/zfile-script.log"

log_level() {
    local level=$1 content=$2 stdout=${3:-true} stdoutPrefix=${4:-false}
    local prefix color
    prefix="[${level}] $(date '+%Y-%m-%d %H:%M:%S') ${STEP_NAME}"
    case "$level" in
        ERROR) color=$RED ;;
        WARN)  color=$YELLOW ;;
        INFO)  color=$GREEN ;;
        *)     color=$GRAY ;;
    esac
    if [ "$stdout" = true ]; then
        if [ "$stdoutPrefix" = true ]; then
            echo -e "${color}${prefix} ${content}${RESET}"
        else
            echo -e "${color}${content}${RESET}"
        fi
    fi
    echo "${prefix} ${content}" >> "$LOG_FILE"
}

log_debug() { log_level "DEBUG" "$1" "$2" "$3"; }
log_info()  { log_level "INFO"  "$1" "$2" "$3"; }
log_warn()  { log_level "WARN"  "$1" "$2" "$3"; }
log_error() { log_level "ERROR" "$1" "$2" "$3"; }

# --------------- UI 辅助 ---------------
DIVIDER_WIDTH=66

print_divider() {
    local char="${1:--}"
    printf "%b" "${DIM}"
    printf "%${DIVIDER_WIDTH}s\n" | tr ' ' "$char"
    printf "%b" "${RESET}"
}

print_section() {
    printf "\n%b\n" "${BOLD}${CYAN}>>> $1${RESET}"
}

print_kv() {
    printf "  %b%-18s%b : %s\n" "${BOLD}" "$1" "${RESET}" "$2"
}

# 中文 key 每字符显示 2 列，按字符数动态补齐到 18 列
print_kv_cn() {
    local cn_key=$1 value=$2 pad spaces=""
    pad=$((18 - ${#cn_key} * 2))
    [ "$pad" -gt 0 ] && printf -v spaces "%${pad}s" ""
    printf "  %b%s%s%b : %s\n" "${BOLD}" "$cn_key" "$spaces" "${RESET}" "$value"
}

# --------------- 全局变量 ---------------
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

IS_SCRIPT_INSTALL=false
INSTALL_VERSION=""
INSTALL_TYPE=""
ZFILE_RUNNING_STATUS=""
INSTALL_FINISH_EXTRA_TIPS=""

INSTALL_INFO_FILE="$HOME_DIR/.zfile-script/.zfile-install-info.ini"

# 非交互模式（CLI/CI 调用），由 ZFILE_NON_INTERACTIVE=1 启用
is_non_interactive() {
    [ "${ZFILE_NON_INTERACTIVE:-0}" = "1" ]
}

# --------------- 工具方法 ---------------
get_install_info() {
    local key=$1
    [ -f "$INSTALL_INFO_FILE" ] || { echo ""; return; }
    grep "^$key=" "$INSTALL_INFO_FILE" | cut -d'=' -f2-
}

save_install_info() {
    : > "$INSTALL_INFO_FILE"
    local kv
    for kv in "$@"; do
        echo "$kv" >> "$INSTALL_INFO_FILE"
    done
}

clear_install_info() {
    : > "$INSTALL_INFO_FILE"
}

get_container_name() {
    [ "$1" = "1" ] && echo "zfile" || echo "zfile-pro"
}

get_image_name() {
    local version=$1 mirror=$2
    [ "$version" = "1" ] && echo "$mirror:latest" || echo "$mirror-pro:latest"
}

get_download_file_name() {
    local release_arch="$ARCH"
    [ "$release_arch" = "arm64" ] && release_arch="arm"
    [ "$1" = "1" ] && echo "zfile-release_linux_${release_arch}.tar.gz" \
                   || echo "zfile-pro-release_linux_${release_arch}.tar.gz"
}

get_download_url() {
    local file_name
    file_name=$(get_download_file_name "$1")
    [ "$1" = "1" ] && echo "https://c.jun6.net/ZFILE/$file_name" \
                   || echo "https://c.jun6.net/ZFILE-PRO/$file_name"
}

check_port_in_use() {
    local port=$1
    if command -v netstat &>/dev/null && netstat -tuln 2>/dev/null | grep -q ":$port "; then return 0; fi
    if command -v ss      &>/dev/null && ss      -tuln 2>/dev/null | grep -q ":$port "; then return 0; fi
    if command -v lsof    &>/dev/null && lsof -i :"$port" &>/dev/null; then return 0; fi
    return 1
}

download_file() {
    local url=$1 file_name=$2
    log_debug "从 $url 下载文件到 $file_name"
    if command -v wget &>/dev/null; then
        wget --no-check-certificate -O "$file_name" "$url"
    elif command -v curl &>/dev/null; then
        curl -L -o "$file_name" "$url"
    else
        log_error "未安装 wget 或 curl"
        exit 1
    fi
}

# --------------- 输入读取 ---------------
read_port() {
    local msg=$1 default_port=$2 port prompt
    if is_non_interactive && [ -n "$ZFILE_PORT" ]; then
        port="$ZFILE_PORT"
    else
        if [ -n "$default_port" ]; then prompt="${msg}（默认：${default_port}）[1-65535]: "
        else prompt="${msg} [1-65535]: "
        fi
        echo -n "$prompt"
        read -r port
        port=${port:-$default_port}
    fi
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        log_error "端口号 ${port} 无效，请输入一个有效的端口号（1-65535）"
        is_non_interactive && exit 1
        read_port "$msg" "$default_port"
        return
    fi
    if check_port_in_use "$port"; then
        log_error "端口 $port 已被占用"
        is_non_interactive && exit 1
        read_port "$msg" "$default_port"
        return
    fi
    INPUT_PORT="$port"
}

read_path() {
    local msg=$1 default_path=$2 create_path=${3:-false} allow_path_not_empty=${4:-false} env_var=${5:-}
    local input_path prompt env_value

    if is_non_interactive && [ -n "$env_var" ]; then
        env_value="${!env_var:-}"
        if [ -n "$env_value" ]; then
            input_path="$env_value"
        elif [ -n "$default_path" ]; then
            input_path="$default_path"
        else
            log_error "非交互模式下未设置 $env_var 且无默认值"
            exit 1
        fi
    else
        if [ -n "$default_path" ]; then prompt="${msg}（默认：${default_path}）: "
        else prompt="${msg}: "
        fi
        echo -n "$prompt"
        read -r input_path
        input_path=${input_path:-$default_path}
    fi

    if [ "${input_path:0:1}" != "/" ]; then
        log_error "输入的目录 ${input_path} 不合法，目录必须以 / 开头"
        is_non_interactive && exit 1
        read_path "$msg" "$default_path" "$create_path" "$allow_path_not_empty" "$env_var"
        return
    fi

    if [ "$allow_path_not_empty" = false ] && [ -d "$input_path" ] \
       && [ -n "$(ls -A "$input_path" 2>/dev/null)" ]; then
        log_error "目录 $input_path 不为空，请检查或重新填写！"
        is_non_interactive && exit 1
        read_path "$msg" "$default_path" "$create_path" "$allow_path_not_empty" "$env_var"
        return
    fi

    if [ ! -d "$input_path" ]; then
        if [ "$create_path" = true ]; then
            if ! mkdir -p "$input_path" 2>/dev/null; then
                log_error "创建目录 $input_path 失败！"
                is_non_interactive && exit 1
                read_path "$msg" "$default_path" "$create_path" "$allow_path_not_empty" "$env_var"
                return
            fi
        else
            log_error "目录 $input_path 不存在！"
            is_non_interactive && exit 1
            read_path "$msg" "$default_path" "$create_path" "$allow_path_not_empty" "$env_var"
            return
        fi
    fi

    INPUT_PATH=$(echo "$input_path" | sed 's/\/\{1,\}/\//g' | sed 's/\/$//')
}

# 通用选择菜单：read_choice <提示> <变量名> <选项1> <选项2> ...
read_choice() {
    local prompt=$1 var_name=$2
    shift 2
    local options=("$@") n=$#
    local i choice

    for ((i=0; i<n; i++)); do
        printf "  %b%d.%b %s\n" "${BOLD}${GREEN}" "$((i+1))" "${RESET}" "${options[$i]}"
    done
    echo -n "${prompt} [1-${n}]: "
    read -r choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$n" ]; then
        log_error "选项 ${choice} 无效，请重新选择"
        read_choice "$prompt" "$var_name" "${options[@]}"
        return
    fi
    printf -v "$var_name" '%s' "$choice"
}

read_install_version() {
    if is_non_interactive && [ -n "$ZFILE_VERSION" ]; then
        INPUT_INSTALL_VERSION="$ZFILE_VERSION"
        return
    fi
    read_choice "请选择安装版本" INPUT_INSTALL_VERSION "开源版" "捐赠版"
}

read_install_type() {
    if is_non_interactive && [ -n "$ZFILE_INSTALL_TYPE" ]; then
        INPUT_INSTALL_TYPE="$ZFILE_INSTALL_TYPE"
        return
    fi
    read_choice "请选择安装方式" INPUT_INSTALL_TYPE "直接安装" "docker 安装" "docker-compose 安装"
}

read_docker_image_mirror() {
    local choice
    if is_non_interactive && [ -n "$ZFILE_DOCKER_MIRROR" ]; then
        choice="$ZFILE_DOCKER_MIRROR"
    else
        read_choice "请选择 Docker 镜像源" choice \
            "DockerHub(仅推荐国外机器使用)" \
            "华为香港镜像" \
            "华为北京镜像"
    fi
    case "$choice" in
        1) INPUT_DOCKER_IMAGE_MIRROR="zhaojun1998/zfile" ;;
        2) INPUT_DOCKER_IMAGE_MIRROR="swr.ap-southeast-1.myhuaweicloud.com/zfile-dev/zfile" ;;
        3) INPUT_DOCKER_IMAGE_MIRROR="swr.cn-north-1.myhuaweicloud.com/zfile-dev/zfile" ;;
        *) log_error "无效的镜像源选项: $choice"; exit 1 ;;
    esac
}

read_yn() {
    local msg=$1 default_choice=$2 choice
    if is_non_interactive; then
        choice="${ZFILE_AUTO_YES:-$default_choice}"
    else
        echo -n "${msg}（默认：${default_choice}）[y/n]: "
        read -r choice
        choice=${choice:-$default_choice}
    fi
    case "$choice" in
        [yY][eE][sS]|[yY]) INPUT_YN="y" ;;
        [nN][oO]|[nN])     INPUT_YN="n" ;;
        *)
            log_error "确认选项 ${choice} 无效，请重新选择"
            is_non_interactive && exit 1
            read_yn "$msg" "$default_choice"
            ;;
    esac
}

# --------------- 已安装版本检测 ---------------
check_container_name_is_compose() {
    local container_name=$1 compose_version
    if docker inspect "$container_name" &>/dev/null; then
        compose_version=$(docker inspect --format '{{ index .Config.Labels "com.docker.compose.version" }}' "$container_name")
        [ -n "$compose_version" ] && return 0
    fi
    return 1
}

check_container_name_is_running() {
    docker ps --format '{{.Names}}' | grep -q "^$1$"
}

# 检测某个 docker 容器（包括 docker-compose 创建的）
detect_docker_install() {
    local container_name=$1 version=$2
    docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${container_name}$" || return 1
    INSTALL_VERSION="$version"
    if check_container_name_is_running "$container_name"; then
        ZFILE_RUNNING_STATUS="启动"
    else
        ZFILE_RUNNING_STATUS="未启动"
    fi
    if check_container_name_is_compose "$container_name"; then
        INSTALL_TYPE="3"
    else
        INSTALL_TYPE="2"
    fi
    return 0
}

# 检测本地进程
detect_process_install() {
    local pattern=$1 version=$2 install_type=$3
    if ps -ef | grep -F "$pattern" | grep -v grep >/dev/null 2>&1; then
        INSTALL_VERSION="$version"
        INSTALL_TYPE="$install_type"
        ZFILE_RUNNING_STATUS="启动"
        return 0
    fi
    return 1
}

detect_running_version() {
    if [ -x "$(command -v docker)" ]; then
        detect_docker_install "zfile"     "1" && return 0
        detect_docker_install "zfile-pro" "2" && return 0
    fi

    detect_process_install 'ZfileApplication'   "1" "4" && return 0
    detect_process_install 'zfile-launch'       "2" "5" && return 0
    detect_process_install 'zfile/zfile --'     "1" "1" && return 0
    detect_process_install 'zfile/zfile-pro --' "2" "1" && return 0
}

reset_variable() {
    INPUT_PORT="" INPUT_PATH="" INPUT_INSTALL_VERSION="" INPUT_INSTALL_TYPE=""
    INPUT_DOCKER_IMAGE_MIRROR="" INPUT_YN=""
    IS_SCRIPT_INSTALL=false
    INSTALL_VERSION="" INSTALL_TYPE="" ZFILE_RUNNING_STATUS=""
    INSTALL_FINISH_EXTRA_TIPS=""
}

get_install_type_and_version() {
    if [ -f "$INSTALL_INFO_FILE" ]; then
        INSTALL_VERSION=$(get_install_info "install_version")
        INSTALL_TYPE=$(get_install_info "install_type")
        if [ -n "$INSTALL_VERSION" ] && [ -n "$INSTALL_TYPE" ]; then
            IS_SCRIPT_INSTALL=true
            ZFILE_RUNNING_STATUS="未启动"
        fi
    fi
    # 未检测到已安装实例是正常状态，不能因 set -e 退出脚本
    detect_running_version || true
}

# --------------- Header / Menu ---------------
print_tips() {
    if [ -n "$INSTALL_TYPE" ] && [ -n "$INSTALL_VERSION" ] && [ "$IS_SCRIPT_INSTALL" = false ]; then
        local container_name
        container_name=$(get_container_name "$INSTALL_VERSION")
        log_error "已运行版本不是通过脚本安装的 ZFile，请手动${BOLD}停止并卸载${RESET}${RED}后再使用脚本！${RESET}"
        if [ "$INSTALL_TYPE" = "2" ] || [ "$INSTALL_TYPE" = "3" ]; then
            log_debug "tips: 可使用 docker rm -f $container_name 命令卸载 ZFile！"
        else
            log_debug "tips: 请使用 安装目录/bin/stop.sh 停止 ZFile！(然后备份该目录下的文件再删除该目录即可)"
            log_debug "安装目录一般为 $HOME_DIR/$container_name (如果你没修改过的话)"
        fi
        return 0
    fi
    echo -e "${DIM}tips: 如这里自动检测已安装版本或安装方式不对(如果不是通过脚本安装且停止的ZFile，检测不到)，不要继续操作，请反馈给作者！${RESET}"
}

show_header() {
    local docker_info docker_compose_info status_color version_text type_text

    if command -v docker >/dev/null 2>&1; then
        docker_info=$(docker -v 2>/dev/null)
    else
        docker_info="${YELLOW}未安装${RESET}"
    fi
    case "$DOCKER_COMPOSE_TYPE" in
        "docker compose")  docker_compose_info=$(docker compose version 2>/dev/null) ;;
        "docker-compose")  docker_compose_info=$(docker-compose --version 2>/dev/null) ;;
        *)                 docker_compose_info="${YELLOW}未安装${RESET}" ;;
    esac

    print_divider "="
    printf "%b\n" "${BOLD}${CYAN}                  ${SCRIPT_NAME}  v${VERSION}${RESET}"
    print_divider "="
    print_kv "Author"          "$AUTHOR"
    print_kv "Website"         "$WEB_URL"
    print_kv "GitHub"          "$GITHUB_URL"
    print_divider
    print_kv "Script Path"     "$SCRIPT_PATH"
    print_kv "OS"              "$OPSY"
    print_kv "Arch"            "$ARCH ($LBIT Bit)"
    print_kv "Kernel"          "$KERN"
    print_kv "User"            "$(whoami)"
    print_kv "Docker"          "$docker_info"
    print_kv "Docker Compose"  "$docker_compose_info"
    print_divider

    if [ -z "$INSTALL_VERSION" ]; then
        version_text="${YELLOW}未安装${RESET}"
    else
        version_text="${GREEN}${INSTALL_VERSION_MAP[$INSTALL_VERSION]}${RESET}"
    fi
    if [ -z "$INSTALL_TYPE" ]; then
        type_text="${YELLOW}未安装${RESET}"
    else
        type_text="${GREEN}${INSTALL_TYPE_MAP[$INSTALL_TYPE]}${RESET}"
    fi
    print_kv_cn "当前安装版本" "$version_text"
    print_kv_cn "当前安装方式" "$type_text"
    if [ -n "$ZFILE_RUNNING_STATUS" ]; then
        if [ "$ZFILE_RUNNING_STATUS" = "启动" ]; then
            status_color=$GREEN
        else
            status_color=$YELLOW
        fi
        print_kv_cn "当前运行状态" "${status_color}${ZFILE_RUNNING_STATUS}${RESET}"
    fi

    echo
    print_tips
    print_divider
}

# --------------- 安装 ---------------
install() {
    if [ -n "$INSTALL_VERSION" ] && [ -n "$INSTALL_TYPE" ]; then
        log_error "已安装 ZFile，无法重复安装，请先卸载"
        return 0
    fi
    print_section "选择安装版本与方式"
    read_install_version
    read_install_type

    case "$INPUT_INSTALL_TYPE" in
        1) install_zfile ;;
        2) install_docker_zfile ;;
        3) install_docker_compose_zfile ;;
    esac

    log_info "安装完成, 访问 $INPUT_PORT 端口即可访问，如无法访问请检查防火墙/安全组是否开放！"
    if [ -n "$INSTALL_FINISH_EXTRA_TIPS" ]; then
        log_info "$INSTALL_FINISH_EXTRA_TIPS"
    fi
}

install_zfile() {
    local install_path install_db_path install_port path_name url file_name

    path_name=$(get_container_name "$INPUT_INSTALL_VERSION")
    url=$(get_download_url "$INPUT_INSTALL_VERSION")
    file_name=$(get_download_file_name "$INPUT_INSTALL_VERSION")

    read_path "请输入 ZFile 程序存放目录" "$HOME_DIR/$path_name/" true false "ZFILE_INSTALL_PATH"
    install_path="$INPUT_PATH"
    read_path "请输入 ZFile 数据库及日志目录，没有会自动创建" "$HOME_DIR/.zfile-v4/" true true "ZFILE_DB_PATH"
    install_db_path="$INPUT_PATH"
    read_port "请输入 ZFile 端口号" 8080
    install_port="$INPUT_PORT"

    download_file "$url" "$install_path/$file_name"
    tar -zxf "$install_path/$file_name" -C "$install_path"
    rm -f "$install_path/$file_name"
    if [ ! -f "$install_path/application.properties" ] && [ -f "$install_path/application.properties.example" ]; then
        cp "$install_path/application.properties.example" "$install_path/application.properties"
    fi
    sed -i "s/8080/$install_port/g" "$install_path/application.properties"
    sed -i "s|\${user.home}/.zfile-v4|$install_db_path|g" "$install_path/application.properties"
    chmod +x "$install_path"/bin/*.sh
    "$install_path/bin/start.sh"

    save_install_info \
        "install_type=$INPUT_INSTALL_TYPE" \
        "install_version=$INPUT_INSTALL_VERSION" \
        "install_path=$install_path" \
        "install_db_path=$install_db_path" \
        "install_port=$install_port" \
        "install_download_url=$url"
}

install_docker_zfile() {
    local container_name install_image install_command install_db_path install_data_path
    if ! command -v docker &>/dev/null; then
        log_error "未安装 Docker"
        exit 1
    fi

    read_docker_image_mirror
    read_path "请输入 ZFile 数据库及日志目录，没有会自动创建" "$HOME_DIR/.zfile-v4/" true true "ZFILE_DB_PATH"
    install_db_path="$INPUT_PATH"
    read_port "请输入 ZFile 端口号" 8080
    if is_non_interactive; then
        [ -n "$ZFILE_DATA_PATH" ] && INPUT_YN="y" || INPUT_YN="n"
    else
        read_yn "是否需向 Docker 容器内挂载文件目录(如不配置，使用本地存储无法在Docker容器内读取到宿主机内的文件目录)" "n"
    fi
    if [ "$INPUT_YN" = "y" ]; then
        read_path "请输入想将服务器哪个目录挂载到 Docker 容器内(不存在会自动创建)" "" true true "ZFILE_DATA_PATH"
        install_data_path="$INPUT_PATH"
        INSTALL_FINISH_EXTRA_TIPS="在 ZFile 添加本地存储类型的存储源时基路径填写 /data/file/ 对应宿主机的 $install_data_path 目录！"
    fi

    container_name=$(get_container_name "$INPUT_INSTALL_VERSION")
    install_image=$(get_image_name "$INPUT_INSTALL_VERSION" "$INPUT_DOCKER_IMAGE_MIRROR")

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
    if [ "$INPUT_YN" = "y" ]; then
        eval "$install_command"
    else
        log_error "已取消安装"
        exit 1
    fi

    save_install_info \
        "install_type=$INPUT_INSTALL_TYPE" \
        "install_version=$INPUT_INSTALL_VERSION" \
        "install_db_path=$install_db_path" \
        "install_data_path=$install_data_path" \
        "install_port=$INPUT_PORT" \
        "install_image=$install_image" \
        "install_command=$install_command"
}

install_docker_compose_zfile() {
    local container_name install_image compose_content compose_path install_data_path
    if ! command -v docker &>/dev/null; then
        log_error "未安装 Docker"
        exit 1
    fi

    container_name=$(get_container_name "$INPUT_INSTALL_VERSION")

    read_path "请输入 ZFile Docker-Compose 配置文件、日志、数据库所在目录，没有会自动创建" "$HOME_DIR/docker/$container_name/" true true "ZFILE_COMPOSE_PATH"
    compose_path="$INPUT_PATH"

    if [ -f "$compose_path/docker-compose.yml" ]; then
        read_yn "检测到目录 $compose_path 下已存在 docker-compose.yml 文件，是否直接使用该文件启动" "y"
        if [ "$INPUT_YN" = "y" ]; then
            INPUT_PORT='Docker-Compose 文件中配置的'
            cd "$compose_path" || exit
            eval "${DOCKER_COMPOSE_TYPE} up -d"
            return
        fi
        read_yn "是否允许覆盖 $compose_path/docker-compose.yml 文件" "n"
        if [ "$INPUT_YN" = "n" ]; then
            log_error "请手动删除 $compose_path/docker-compose.yml 文件后重新执行安装！"
            exit 1
        fi
    fi

    read_docker_image_mirror
    install_image=$(get_image_name "$INPUT_INSTALL_VERSION" "$INPUT_DOCKER_IMAGE_MIRROR")

    read_port "请输入 ZFile 端口号" 8080
    if is_non_interactive; then
        [ -n "$ZFILE_DATA_PATH" ] && INPUT_YN="y" || INPUT_YN="n"
    else
        read_yn "是否需向 Docker 容器内挂载文件目录(如不配置，使用本地存储无法在Docker容器内读取到宿主机内的文件目录)" "n"
    fi
    if [ "$INPUT_YN" = "y" ]; then
        read_path "请输入想要挂载到 Docker 容器内的文件目录(填写宿主机内的目录，不存在会自动创建)" "" true true "ZFILE_DATA_PATH"
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
    if [ "$INPUT_YN" = "y" ]; then
        echo "$compose_content" > "$compose_path/docker-compose.yml"
        cd "$compose_path" || exit
        eval "${DOCKER_COMPOSE_TYPE} up -d"
    else
        log_error "已取消安装"
        exit 1
    fi

    save_install_info \
        "install_type=$INPUT_INSTALL_TYPE" \
        "install_version=$INPUT_INSTALL_VERSION" \
        "compose_path=$compose_path" \
        "install_data_path=$install_data_path" \
        "install_port=$INPUT_PORT" \
        "install_image=$install_image" \
        "compose_content=$compose_content"
}

# --------------- start / stop / restart ---------------
start() {
    local install_path install_port container_name
    if [ -z "$INSTALL_VERSION" ] || [ -z "$INSTALL_TYPE" ]; then
        log_error "未安装 ZFile，无法启动"
        return 0
    fi
    if [ "$ZFILE_RUNNING_STATUS" = "启动" ]; then
        log_error "ZFile 已经启动，请勿重复启动"
        return 0
    fi

    install_path=$(get_install_info "install_path")
    install_port=$(get_install_info "install_port")
    container_name=$(get_container_name "$INSTALL_VERSION")

    case "$INSTALL_TYPE" in
        2|3) docker start "$container_name" ;;
        1|4|5)
            if [ -z "$install_path" ]; then
                log_error "安装路径未找到，请检查安装信息文件: $INSTALL_INFO_FILE"
                return 0
            fi
            "$install_path/bin/start.sh"
            ;;
    esac

    ZFILE_RUNNING_STATUS="启动"
    log_info "ZFile 启动完成，访问 $install_port 端口即可访问，如无法访问请检查防火墙/安全组是否开放！"
}

# 询问后再执行：confirm_then <force?> <提示> <命令> [参数...]
confirm_then() {
    local force=$1 msg=$2
    shift 2
    if [ "$force" = true ]; then
        "$@"
        return
    fi
    read_yn "$msg" "y"
    [ "$INPUT_YN" = "y" ] && "$@"
}

kill_9_pid() {
    local pid=$1
    if [ -z "$pid" ] || ! [[ "$pid" =~ ^[0-9]+$ ]]; then
        log_warn "未找到有效进程 ID，跳过停止操作"
        return 0
    fi
    kill -9 "$pid" 2>/dev/null || true
    sleep 2
    if ps -p "$pid" >/dev/null 2>&1; then
        log_error "停止进程 id $pid 失败"
    else
        log_info "停止进程 id $pid 成功"
        ZFILE_RUNNING_STATUS="未启动"
    fi
}

stop_docker_container() {
    docker stop "$1"
    ZFILE_RUNNING_STATUS="未启动"
}

# 根据 version+type 返回 "<进程匹配模式>|<描述>"，仅适用于本地安装 1/4/5
get_local_install_meta() {
    case "$1:$2" in
        1:1) echo 'zfile/zfile --|直接安装的开源版' ;;
        1:4) echo 'ZfileApplication|直接安装(4.1.5及以前版本)的开源版' ;;
        2:1) echo 'zfile/zfile-pro --|直接安装的捐赠版' ;;
        2:5) echo 'zfile-launch|直接安装(4.1.6 Pro及以前版本)的捐赠版' ;;
    esac
}

stop() {
    local forceStop=${1:-false} pid container_name version_text meta pattern desc
    if [ -z "$INSTALL_VERSION" ] || [ -z "$INSTALL_TYPE" ]; then
        log_error "未安装 ZFile，无法停止"
        return 0
    fi
    if [ "$ZFILE_RUNNING_STATUS" != "启动" ]; then
        log_info "ZFile 未启动，无需停止"
        return 0
    fi

    container_name=$(get_container_name "$INSTALL_VERSION")
    version_text="${INSTALL_VERSION_MAP[$INSTALL_VERSION]}"

    case "$INSTALL_TYPE" in
        2)
            confirm_then "$forceStop" \
                "是否确认停止 docker 安装的${version_text} ZFile, 容器名: $container_name" \
                stop_docker_container "$container_name"
            ;;
        3)
            confirm_then "$forceStop" \
                "是否确认停止 docker-compose 安装的${version_text} ZFile, 容器名: $container_name" \
                stop_docker_container "$container_name"
            ;;
        1|4|5)
            meta=$(get_local_install_meta "$INSTALL_VERSION" "$INSTALL_TYPE")
            pattern="${meta%%|*}"
            desc="${meta##*|}"
            pid="$(ps -ef | grep -F "$pattern" | grep -v grep | awk '{print $2}')"
            confirm_then "$forceStop" \
                "是否确认停止${desc} ZFile，进程 id: ${pid}" \
                kill_9_pid "$pid"
            ;;
    esac
}

restart() {
    read_yn "是否确认重启 ZFile" "y"
    [ "$INPUT_YN" = "y" ] || return 0
    stop true
    start
}

# --------------- 卸载 ---------------
# 通过运行中的进程定位安装路径（仅本地安装类型 1/4/5 用于兜底）
detect_install_path_by_process() {
    local install_version=$1 install_type=$2 pattern
    case "$install_type" in
        1)
            [ "$install_version" = "1" ] && pattern='zfile/zfile --' || pattern='zfile/zfile-pro --'
            ps -ef | awk -v pat="$pattern" 'index($0, pat) && !/grep/ {print $2}' \
                | xargs -I{} ls -l "/proc/{}/exe" 2>/dev/null \
                | awk '{print $NF}' | xargs dirname 2>/dev/null | xargs dirname 2>/dev/null
            ;;
        4)
            ps -ef | grep 'ZfileApplication' | grep -v grep \
                | grep -o -- '-classpath [^:]*' | cut -d' ' -f2 \
                | xargs dirname 2>/dev/null | xargs dirname 2>/dev/null
            ;;
        5)
            ps -ef | grep 'zfile-launch' | grep -v grep | awk '{print $11}' \
                | awk -F'/' '{for(i=1;i<NF;i++) printf $i"/"}'
            ;;
    esac
}

uninstall() {
    local install_path container_name version_text install_method meta desc
    if [ -z "$INSTALL_VERSION" ] || [ -z "$INSTALL_TYPE" ]; then
        log_error "未安装 ZFile，无法卸载"
        return 0
    fi

    container_name=$(get_container_name "$INSTALL_VERSION")
    version_text="${INSTALL_VERSION_MAP[$INSTALL_VERSION]}"

    case "$INSTALL_TYPE" in
        2|3)
            install_method="docker"
            [ "$INSTALL_TYPE" = "3" ] && install_method="docker-compose"
            read_yn "是否确认卸载 ${install_method} 安装的${version_text} ZFile, 容器名: $container_name" "y"
            if [ "$INPUT_YN" = "y" ]; then
                docker rm -f "$container_name"
                clear_install_info
            fi
            ;;
        1|4|5)
            meta=$(get_local_install_meta "$INSTALL_VERSION" "$INSTALL_TYPE")
            desc="${meta##*|}"
            read_yn "是否确认卸载${desc} ZFile" "y"
            [ "$INPUT_YN" = "y" ] || return 0

            if [ "$ZFILE_RUNNING_STATUS" = "启动" ]; then
                install_path=$(detect_install_path_by_process "$INSTALL_VERSION" "$INSTALL_TYPE")
                stop true
            else
                install_path=$(get_install_info "install_path")
            fi

            if [ -z "$install_path" ]; then
                log_error "未找到安装目录，请手动删除程序目录"
                return 0
            fi

            read_yn "停止${desc} ZFile 完成，是否删除程序安装目录 $install_path 来完成卸载" "y"
            if [ "$INPUT_YN" = "y" ]; then
                rm -rf "$install_path"
                clear_install_info
            fi
            ;;
    esac
}

# --------------- 更新 ---------------
update() {
    local install_path url file_name pid backup_path container_name pattern

    if [ -z "$INSTALL_VERSION" ] || [ -z "$INSTALL_TYPE" ]; then
        log_error "未安装 ZFile，无法更新"
        return 0
    fi

    container_name=$(get_container_name "$INSTALL_VERSION")

    # docker / compose 类型：使用 watchtower 更新
    if [ "$INSTALL_TYPE" = "2" ] || [ "$INSTALL_TYPE" = "3" ]; then
        read_yn "是否确认更新 ZFile，容器名: $container_name" "y"
        log_debug "将使用 watchtower 更新容器，请确保机器与 Docker Hub 之间网络通畅。"
        if [ "$INPUT_YN" = "y" ]; then
            docker run --rm \
                -v /var/run/docker.sock:/var/run/docker.sock \
                containrrr/watchtower \
                --run-once --cleanup \
                "$container_name"
            log_info "更新 Docker 运行的 ZFile 完成！"
        fi
        return 0
    fi

    if [ ! -f "$INSTALL_INFO_FILE" ]; then
        log_error "安装信息文件 $INSTALL_INFO_FILE 不存在，可能之前不是通过脚本安装的，无法更新，请使用卸载+安装的方式更新！"
        return 0
    fi

    install_path=$(get_install_info "install_path")
    url=$(get_download_url "$INSTALL_VERSION")
    file_name=$(get_download_file_name "$INSTALL_VERSION")

    if [ ! -d "$install_path" ]; then
        log_error "安装路径 $install_path 不存在，可能是安装目录被删除了，无法进行更新！"
        return 0
    fi
    if [ ! -f "$install_path/application.properties" ]; then
        log_error "安装目录 $install_path 下不存在 application.properties 文件，无法进行更新！"
        return 0
    fi

    if [ "$INSTALL_TYPE" = "1" ]; then
        [ "$INSTALL_VERSION" = "1" ] && pattern='zfile/zfile --' || pattern='zfile/zfile-pro --'
        pid="$(ps -ef | grep -F "$pattern" | grep -v grep | awk '{print $2}')"
    fi

    log_debug "更新会从 $url 下载更新包到 $install_path 目录，其他配置将沿用之前版本"
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

    download_file "$url" "$install_path/$file_name"
    tar -zxf "$install_path/$file_name" -C "$install_path"
    rm -f "$install_path/$file_name"
    chmod +x "$install_path"/bin/*.sh
    cp "$backup_path/application.properties" "$install_path/application.properties"
    "$install_path/bin/start.sh"

    log_info "更新完成，安装前程序备份目录为 $backup_path"
}

# --------------- self update ---------------
self_update() {
    local script_url="https://docs.zfile.vip/install.sh" tmp_file
    tmp_file=$(mktemp /tmp/script.XXXXXX)
    log_info "检查更新..."
    if curl -fsSL "$script_url" -o "$tmp_file"; then
        if ! cmp -s "$SCRIPT_PATH" "$tmp_file"; then
            log_debug "发现新版本，更新中..."
            mv "$tmp_file" "$SCRIPT_PATH"
            chmod +x "$SCRIPT_PATH"
            log_info "更新完成，按回车键重启脚本..."
            read -r
            exec "$SCRIPT_PATH"
            exit 0
        else
            log_info "当前已是最新版本。"
            rm -f "$tmp_file"
        fi
    else
        log_error "无法从 $script_url 下载新版本，请检查网络连接。"
        rm -f "$tmp_file"
        return 1
    fi
}

# --------------- status ---------------
cmd_status() {
    show_header

    if [ -z "$INSTALL_VERSION" ]; then
        log_warn "ZFile 未安装，无运行时详情可显示"
        return 0
    fi

    print_section "运行时详情"

    local container_name install_path install_port db_path data_path
    container_name=$(get_container_name "$INSTALL_VERSION")
    install_path=$(get_install_info "install_path")
    install_port=$(get_install_info "install_port")
    db_path=$(get_install_info "install_db_path")
    data_path=$(get_install_info "install_data_path")

    [ -n "$install_port" ] && print_kv_cn "监听端口" "$install_port"

    case "$INSTALL_TYPE" in
        2|3)
            local cid image started status
            cid=$(docker ps -a --filter "name=^${container_name}$" --format '{{.ID}}' 2>/dev/null | head -1)
            image=$(docker inspect --format '{{.Config.Image}}' "$container_name" 2>/dev/null)
            started=$(docker inspect --format '{{.State.StartedAt}}' "$container_name" 2>/dev/null)
            status=$(docker inspect --format '{{.State.Status}}' "$container_name" 2>/dev/null)
            print_kv_cn "容器名称" "$container_name"
            [ -n "$cid" ]     && print_kv_cn "容器 ID" "$cid"
            [ -n "$image" ]   && print_kv_cn "镜像" "$image"
            [ -n "$status" ]  && print_kv_cn "容器状态" "$status"
            [ -n "$started" ] && print_kv_cn "启动时间" "$started"
            ;;
        1|4|5)
            [ -n "$install_path" ] && print_kv_cn "安装目录" "$install_path"
            local meta pattern pid
            meta=$(get_local_install_meta "$INSTALL_VERSION" "$INSTALL_TYPE")
            pattern="${meta%%|*}"
            pid=$(ps -ef | grep -F "$pattern" | grep -v grep | awk '{print $2}' | head -1)
            [ -n "$pid" ] && print_kv_cn "进程 ID" "$pid"
            ;;
    esac

    [ -n "$db_path" ]   && print_kv_cn "数据目录" "$db_path"
    [ -n "$data_path" ] && print_kv_cn "挂载目录" "$data_path"

    # systemd service 状态
    if [ "$INSTALL_TYPE" = "1" ] && command -v systemctl &>/dev/null; then
        local sn sf
        sn=$(get_container_name "$INSTALL_VERSION")
        sf="/etc/systemd/system/${sn}.service"
        if [ -f "$sf" ]; then
            local active enabled
            active=$(systemctl is-active "$sn" 2>/dev/null)
            enabled=$(systemctl is-enabled "$sn" 2>/dev/null)
            print_kv_cn "systemd 服务" "$sn (active=$active, enabled=$enabled)"
        fi
    fi

    print_divider
}

# --------------- logs ---------------
# 返回直接安装方式的日志目录
get_local_log_dir() {
    local db_path
    db_path=$(get_install_info "install_db_path")
    [ -z "$db_path" ] && db_path="$HOME_DIR/.zfile-v4"
    echo "$db_path/logs"
}

cmd_logs() {
    local follow=false lines=100
    while [ $# -gt 0 ]; do
        case "$1" in
            -f|--follow) follow=true ;;
            -n)          shift; lines="${1:-100}" ;;
            -n*)         lines="${1#-n}" ;;
            -h|--help)
                echo "用法: $0 logs [-f] [-n N]"
                echo "  -f, --follow  跟随日志输出"
                echo "  -n N          显示最后 N 行 (默认 100)"
                return 0
                ;;
            *) log_warn "忽略未知参数: $1" ;;
        esac
        shift
    done

    if [ -z "$INSTALL_VERSION" ]; then
        log_error "未安装 ZFile，无日志可查看"
        return 1
    fi

    local container_name log_dir log_file
    container_name=$(get_container_name "$INSTALL_VERSION")

    case "$INSTALL_TYPE" in
        2|3)
            if [ "$follow" = true ]; then
                docker logs -f --tail "$lines" "$container_name"
            else
                docker logs --tail "$lines" "$container_name"
            fi
            ;;
        1|4|5)
            log_dir=$(get_local_log_dir)
            log_file=$(ls -t "$log_dir"/*.log 2>/dev/null | head -1)
            if [ -z "$log_file" ]; then
                log_error "未找到日志文件，预期路径: $log_dir/*.log"
                return 1
            fi
            log_info "日志文件: $log_file"
            if [ "$follow" = true ]; then
                tail -n "$lines" -f "$log_file"
            else
                tail -n "$lines" "$log_file"
            fi
            ;;
    esac
}

# --------------- reset-admin ---------------
cmd_reset_admin() {
    if [ -z "$INSTALL_VERSION" ] || [ -z "$INSTALL_TYPE" ]; then
        log_error "未检测到已安装的 ZFile，无法重置管理员登录信息"
        return 1
    fi
    if [ "$ZFILE_RUNNING_STATUS" != "启动" ]; then
        log_error "reset-admin 需要 ZFile 主服务正在运行，请先启动服务"
        return 1
    fi

    local container_name install_path binary wrapper
    container_name=$(get_container_name "$INSTALL_VERSION")
    install_path=$(get_install_info "install_path")

    case "$INSTALL_TYPE" in
        2|3)
            [ "$INSTALL_VERSION" = "1" ] && binary="/root/zfile" || binary="/root/zfile-pro"
            docker exec "$container_name" "$binary" reset-admin "$@"
            ;;
        1)
            if [ -z "$install_path" ]; then
                log_error "未找到安装目录，请检查安装信息文件: $INSTALL_INFO_FILE"
                return 1
            fi
            wrapper="$install_path/bin/reset-admin.sh"
            if [ "$INSTALL_VERSION" = "2" ] && [ -x "$wrapper" ]; then
                "$wrapper" "$@"
                return $?
            fi
            [ "$INSTALL_VERSION" = "1" ] && binary="$install_path/zfile/zfile" || binary="$install_path/zfile/zfile-pro"
            if [ ! -x "$binary" ]; then
                log_error "未找到 reset-admin 可执行文件: $binary"
                return 1
            fi
            "$binary" reset-admin "$@"
            ;;
        4|5)
            log_error "当前旧版安装包不支持 reset-admin，请升级后使用"
            return 1
            ;;
    esac
}

# --------------- doctor ---------------
DOCTOR_PASS=0
DOCTOR_WARN=0
DOCTOR_FAIL=0

doctor_check() {
    local result=$1 msg=$2 hint=${3:-}
    case "$result" in
        OK)
            printf "  %b[ OK ]%b  %s\n" "${GREEN}" "${RESET}" "$msg"
            DOCTOR_PASS=$((DOCTOR_PASS + 1))
            ;;
        WARN)
            printf "  %b[WARN]%b  %s\n" "${YELLOW}" "${RESET}" "$msg"
            DOCTOR_WARN=$((DOCTOR_WARN + 1))
            if [ -n "$hint" ]; then
                printf "          %b%s%b\n" "${DIM}" "$hint" "${RESET}"
            fi
            ;;
        FAIL)
            printf "  %b[FAIL]%b  %s\n" "${RED}" "${RESET}" "$msg"
            DOCTOR_FAIL=$((DOCTOR_FAIL + 1))
            if [ -n "$hint" ]; then
                printf "          %b%s%b\n" "${DIM}" "$hint" "${RESET}"
            fi
            ;;
    esac
    return 0
}

doctor_summary() {
    echo
    print_divider
    printf "  诊断结果: %b%d 通过%b  %b%d 警告%b  %b%d 失败%b\n" \
        "${GREEN}"  "$DOCTOR_PASS" "${RESET}" \
        "${YELLOW}" "$DOCTOR_WARN" "${RESET}" \
        "${RED}"    "$DOCTOR_FAIL" "${RESET}"
    print_divider
    [ "$DOCTOR_FAIL" -gt 0 ] && return 1
    return 0
}

cmd_doctor() {
    DOCTOR_PASS=0
    DOCTOR_WARN=0
    DOCTOR_FAIL=0

    print_section "ZFile 诊断"

    if [ -z "$INSTALL_VERSION" ]; then
        doctor_check FAIL "ZFile 未安装" "运行 $0 install 进行安装"
        doctor_summary
        return $?
    fi
    doctor_check OK "ZFile 已安装：${INSTALL_VERSION_MAP[$INSTALL_VERSION]} / ${INSTALL_TYPE_MAP[$INSTALL_TYPE]}"

    if [ "$ZFILE_RUNNING_STATUS" = "启动" ]; then
        doctor_check OK "ZFile 服务运行中"
    else
        doctor_check FAIL "ZFile 服务未启动" "运行 $0 start 启动"
    fi

    if [ "$INSTALL_TYPE" = "2" ] || [ "$INSTALL_TYPE" = "3" ]; then
        if command -v docker &>/dev/null; then
            doctor_check OK "Docker 可用 ($(docker -v 2>/dev/null | awk '{print $3}' | tr -d ,))"
            local cn restart_count
            cn=$(get_container_name "$INSTALL_VERSION")
            restart_count=$(docker inspect --format '{{.RestartCount}}' "$cn" 2>/dev/null)
            if [ "${restart_count:-0}" -gt 5 ]; then
                doctor_check WARN "容器 $cn 重启次数过多 ($restart_count 次)" "运行 $0 logs 查看异常"
            fi
        else
            doctor_check FAIL "Docker 不可用" "请检查 Docker 是否启动"
        fi
    fi

    local install_port
    install_port=$(get_install_info "install_port")
    if [ -n "$install_port" ] && [[ "$install_port" =~ ^[0-9]+$ ]]; then
        if check_port_in_use "$install_port"; then
            if command -v curl &>/dev/null && curl -fsS --max-time 3 "http://127.0.0.1:$install_port" >/dev/null 2>&1; then
                doctor_check OK "端口 $install_port HTTP 响应正常"
            else
                doctor_check WARN "端口 $install_port 监听中但 HTTP 无响应" "服务可能正在启动，稍候重试"
            fi
        else
            doctor_check FAIL "端口 $install_port 未被监听" "运行 $0 start 启动服务"
        fi
    fi

    local install_path avail_kb avail_mb
    install_path=$(get_install_info "install_path")
    [ -z "$install_path" ] && install_path="$HOME_DIR"
    avail_kb=$(df -P "$install_path" 2>/dev/null | tail -1 | awk '{print $4}')
    if [ -n "$avail_kb" ]; then
        avail_mb=$((avail_kb / 1024))
        if [ "$avail_mb" -lt 200 ]; then
            doctor_check FAIL "磁盘空间不足 (剩 ${avail_mb}MB)" "请清理 $install_path 所在分区"
        elif [ "$avail_mb" -lt 1024 ]; then
            doctor_check WARN "磁盘空间偏低 (剩 ${avail_mb}MB)"
        else
            doctor_check OK "磁盘空间充足 (剩 ${avail_mb}MB)"
        fi
    fi

    if [ "$INSTALL_TYPE" = "1" ] || [ "$INSTALL_TYPE" = "4" ] || [ "$INSTALL_TYPE" = "5" ]; then
        if [ -n "$install_path" ] && [ -f "$install_path/application.properties" ]; then
            doctor_check OK "配置文件存在"
        else
            doctor_check FAIL "配置文件缺失: $install_path/application.properties"
        fi
    fi

    if command -v firewall-cmd &>/dev/null && firewall-cmd --state &>/dev/null; then
        if [ -n "$install_port" ] && firewall-cmd --query-port="$install_port/tcp" &>/dev/null; then
            doctor_check OK "firewalld 已放行端口 $install_port"
        elif [ -n "$install_port" ]; then
            doctor_check WARN "firewalld 未放行端口 $install_port" \
                "firewall-cmd --add-port=$install_port/tcp --permanent && firewall-cmd --reload"
        fi
    fi

    if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
        if [ -n "$install_port" ] && ufw status 2>/dev/null | grep -q "$install_port"; then
            doctor_check OK "ufw 已放行端口 $install_port"
        elif [ -n "$install_port" ]; then
            doctor_check WARN "ufw 未放行端口 $install_port" "ufw allow $install_port/tcp"
        fi
    fi

    doctor_summary
    return $?
}

# --------------- systemd service ---------------
service_check_supported() {
    case "$INSTALL_TYPE" in
        1|4|5) ;;
        "")
            log_error "尚未安装 ZFile，请先运行 install"
            return 1
            ;;
        *)
            log_error "systemd service 仅支持直接安装方式（当前: ${INSTALL_TYPE_MAP[$INSTALL_TYPE]:-未知}）"
            return 1
            ;;
    esac
    if ! command -v systemctl &>/dev/null; then
        log_error "未检测到 systemctl，当前系统不支持 systemd"
        return 1
    fi
    return 0
}

service_name()      { get_container_name "$INSTALL_VERSION"; }
service_file_path() { echo "/etc/systemd/system/$(service_name).service"; }
service_sudo()      { [ "$EUID" -eq 0 ] && echo "" || echo "sudo"; }

service_install() {
    service_check_supported || return 1

    local install_path sn sf sudo_cmd current_user content
    install_path=$(get_install_info "install_path")
    if [ -z "$install_path" ] || [ ! -d "$install_path" ]; then
        log_error "未找到安装目录"
        return 1
    fi

    sn=$(service_name)
    sf=$(service_file_path)
    sudo_cmd=$(service_sudo)
    current_user=$(whoami)

    log_info "将创建 systemd service: $sf"
    log_debug "  服务名:   $sn"
    log_debug "  运行用户: $current_user"
    log_debug "  工作目录: $install_path"
    [ -n "$sudo_cmd" ] && log_debug "  注意: 创建 service 需 sudo 权限"

    read_yn "是否确认创建" "y"
    [ "$INPUT_YN" = "y" ] || return 0

    if [ "$ZFILE_RUNNING_STATUS" = "启动" ]; then
        log_info "正在停止当前运行的 ZFile，由 systemd 接管..."
        stop true
    fi

    content="[Unit]
Description=ZFile File Manager ($sn)
After=network.target

[Service]
Type=forking
User=$current_user
WorkingDirectory=$install_path
ExecStart=$install_path/bin/start.sh
ExecStop=$install_path/bin/stop.sh
Restart=on-failure
RestartSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
"
    echo "$content" | $sudo_cmd tee "$sf" >/dev/null
    $sudo_cmd systemctl daemon-reload
    $sudo_cmd systemctl enable "$sn"
    $sudo_cmd systemctl start "$sn"

    sleep 2
    if $sudo_cmd systemctl is-active --quiet "$sn"; then
        log_info "service $sn 安装并启动成功"
        log_info "管理命令: systemctl {start|stop|restart|status} $sn"
    else
        log_error "service $sn 启动失败，请运行 systemctl status $sn 查看"
        return 1
    fi
}

service_uninstall() {
    service_check_supported || return 1
    local sn sf sudo_cmd
    sn=$(service_name)
    sf=$(service_file_path)
    sudo_cmd=$(service_sudo)

    if [ ! -f "$sf" ]; then
        log_warn "service 文件不存在: $sf"
        return 0
    fi
    read_yn "是否确认卸载 systemd service: $sn" "y"
    [ "$INPUT_YN" = "y" ] || return 0

    $sudo_cmd systemctl stop "$sn"    2>/dev/null || true
    $sudo_cmd systemctl disable "$sn" 2>/dev/null || true
    $sudo_cmd rm -f "$sf"
    $sudo_cmd systemctl daemon-reload
    log_info "service $sn 已卸载"
}

service_status() {
    service_check_supported || return 1
    systemctl status "$(service_name)" --no-pager
}

service_action() {
    service_check_supported || return 1
    $(service_sudo) systemctl "$1" "$(service_name)"
}

cmd_service() {
    local action="${1:-status}"
    case "$action" in
        install)            service_install ;;
        uninstall|remove)   service_uninstall ;;
        status)             service_status ;;
        start|stop|restart) service_action "$action" ;;
        *)
            log_error "未知 service 操作: $action（支持 install/uninstall/status/start/stop/restart）"
            return 1
            ;;
    esac
}

# --------------- help ---------------
show_help() {
    cat <<EOF
${BOLD}${SCRIPT_NAME} v${VERSION}${RESET}

${BOLD}用法:${RESET}
  $0                       进入交互式菜单
  $0 <command> [args...]   直接执行子命令（CLI 模式）

${BOLD}基础命令:${RESET}
  install                  安装 ZFile
  start                    启动 ZFile
  stop                     停止 ZFile
  restart                  重启 ZFile
  update                   更新到最新版本
  uninstall                卸载 ZFile
  self_update              更新本脚本

${BOLD}查看与诊断:${RESET}
  status                   查看安装信息和运行时详情
  logs [-f] [-n N]         查看日志 (-f 跟随, -n N 显示最后 N 行, 默认 100)
  doctor                   一键诊断健康状态
  reset-admin [选项]       重置管理员登录信息（服务需正在运行）

${BOLD}systemd 集成（仅直接安装方式）:${RESET}
  service install          创建并启用 systemd service（开机自启）
  service uninstall        禁用并删除 systemd service
  service status           查看 service 状态
  service start|stop|restart

${BOLD}非交互安装环境变量:${RESET}
  ZFILE_NON_INTERACTIVE=1     启用非交互模式（必须）
  ZFILE_VERSION=1|2           1=开源版, 2=捐赠版
  ZFILE_INSTALL_TYPE=1|2|3    1=直接, 2=docker, 3=docker-compose
  ZFILE_PORT=8080             端口号
  ZFILE_INSTALL_PATH=/path    程序安装目录（INSTALL_TYPE=1）
  ZFILE_DB_PATH=/path         数据库及日志目录
  ZFILE_DATA_PATH=/path       Docker 容器内挂载目录（可选，INSTALL_TYPE=2|3）
  ZFILE_COMPOSE_PATH=/path    docker-compose 目录（INSTALL_TYPE=3）
  ZFILE_DOCKER_MIRROR=1|2|3   1=DockerHub, 2=华为香港, 3=华为北京
  ZFILE_AUTO_YES=y|n          所有 y/n 询问的默认值

${BOLD}示例:${RESET}
  $0 status
  $0 logs -f -n 200
  $0 doctor
  $0 reset-admin
  $0 reset-admin --username admin --password '新密码'
  $0 service install
  ZFILE_NON_INTERACTIVE=1 ZFILE_VERSION=1 ZFILE_INSTALL_TYPE=2 \\
    ZFILE_PORT=8080 ZFILE_DOCKER_MIRROR=2 ZFILE_AUTO_YES=y $0 install
EOF
}

# --------------- 交互菜单 ---------------
show_menu() {
    print_section "操作菜单"
    printf "  %b1.%b 安装 install     %b2.%b 启动 start       %b3.%b 停止 stop\n" \
        "${BOLD}${GREEN}" "${RESET}" "${BOLD}${GREEN}" "${RESET}" "${BOLD}${GREEN}" "${RESET}"
    printf "  %b4.%b 重启 restart     %b5.%b 更新 update      %b6.%b 卸载 uninstall\n" \
        "${BOLD}${GREEN}" "${RESET}" "${BOLD}${GREEN}" "${RESET}" "${BOLD}${GREEN}" "${RESET}"
    printf "  %b7.%b 状态 status      %b8.%b 日志 logs        %bd.%b 诊断 doctor\n" \
        "${BOLD}${BLUE}" "${RESET}" "${BOLD}${BLUE}" "${RESET}" "${BOLD}${BLUE}" "${RESET}"
    printf "  %br.%b 重置管理员 reset-admin  %bs.%b 服务 service\n" \
        "${BOLD}${BLUE}" "${RESET}" "${BOLD}${BLUE}" "${RESET}"
    printf "  %b9.%b 更新脚本 self_update\n" \
        "${BOLD}${YELLOW}" "${RESET}"
    printf "  %bh.%b 帮助 help                            %b0.%b 退出 exit\n" \
        "${BOLD}${CYAN}" "${RESET}" "${BOLD}${RED}" "${RESET}"
}

# 在交互菜单中调用 service 时让用户继续选子操作
interactive_service() {
    local choice
    read_choice "请选择 service 操作" choice "install" "uninstall" "status" "start" "stop" "restart"
    case "$choice" in
        1) cmd_service install ;;
        2) cmd_service uninstall ;;
        3) cmd_service status ;;
        4) cmd_service start ;;
        5) cmd_service stop ;;
        6) cmd_service restart ;;
    esac
}

interactive_loop() {
    local choice
    while true; do
        reset_variable
        get_install_type_and_version
        show_header
        show_menu

        echo
        echo -n "请输入一个选项或命令 [0-9|r|s|d|h]: "
        read -r choice
        echo

        case "$choice" in
            1|install)            install ;;
            2|start)              start ;;
            3|stop)               stop ;;
            4|restart)            restart ;;
            5|update|upgrade)     update ;;
            6|uninstall|remove)   uninstall ;;
            7|status)             cmd_status ;;
            8|logs)               cmd_logs ;;
            9|self_update)        self_update ;;
            d|D|doctor|diagnose)  cmd_doctor ;;
            r|R|reset-admin)      cmd_reset_admin ;;
            s|S|service)          interactive_service ;;
            h|H|help|-h|--help)   show_help ;;
            0|exit|quit)
                printf "%b\n" "${BOLD}${CYAN}感谢使用，再见！${RESET}"
                exit 0
                ;;
            *) log_error "无效的选项" ;;
        esac

        printf "\n%b" "${DIM}按回车回到脚本首页...${RESET}"
        read -r
    done
}

# --------------- 入口 ---------------
main() {
    if [ $# -eq 0 ]; then
        interactive_loop
        return
    fi

    local cmd=$1
    shift

    case "$cmd" in
        help|-h|--help)
            show_help
            return 0
            ;;
    esac

    reset_variable
    get_install_type_and_version

    case "$cmd" in
        install)              install ;;
        start)                start ;;
        stop)                 stop ;;
        restart)              restart ;;
        update|upgrade)       update ;;
        uninstall|remove)     uninstall ;;
        self_update)          self_update ;;
        status)               cmd_status ;;
        logs)                 cmd_logs "$@" ;;
        doctor|diagnose)      cmd_doctor ;;
        reset-admin)          cmd_reset_admin "$@" ;;
        service)              cmd_service "$@" ;;
        *)
            log_error "未知命令: $cmd"
            echo
            show_help
            exit 1
            ;;
    esac
}

main "$@"
