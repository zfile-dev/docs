import { EDITION_DATA, REGISTRY_MAP } from './installConfig';

/**
 * 获取 Docker 镜像全名
 */
function getImage(edition, registry) {
  const data = EDITION_DATA[edition];
  return REGISTRY_MAP[registry](data.image);
}

/**
 * 生成 docker run 命令
 */
export function generateDockerRunCommand({ edition, registry, port, withConfig, dbDir, logDir, fileDir, configDir }) {
  const data = EDITION_DATA[edition];
  const image = getImage(edition, registry);
  const dir = `/root/${data.dir}`;
  const db = dbDir || `${dir}/db`;
  const logs = logDir || `${dir}/logs`;
  const file = fileDir || `${dir}/file`;

  let cmd = `docker run -d --name=${data.container} --restart=always \\
    -p ${port || '8080'}:8080 \\
    -v ${db}:/root/.zfile-v4/db \\
    -v ${logs}:/root/.zfile-v4/logs \\
    -v ${file}:/data/file \\`;

  if (withConfig) {
    const conf = configDir || `${dir}/application.properties`;
    cmd += `\n    -v ${conf}:/root/application.properties \\`;
  }

  cmd += `\n    ${image}`;
  return cmd;
}

/**
 * 生成 docker compose YAML
 */
export function generateDockerComposeYaml({ edition, registry, port, withConfig, dbDir, logDir, fileDir, configDir, dbType, mysqlPassword, mysqlDataDir }) {
  const data = EDITION_DATA[edition];
  const image = getImage(edition, registry);
  const dir = `/root/${data.dir}`;
  const db = dbDir || `${dir}/db`;
  const logs = logDir || `${dir}/logs`;
  const file = fileDir || `${dir}/file`;
  const useMysql = dbType === 'mysql';
  const mysqlPwd = mysqlPassword || 'CHANGE_ME';
  const mysqlDir = mysqlDataDir || `${dir}/mysql`;
  const mysqlContainer = `${data.container}-mysql`;

  let volumes = `            - '${db}:/root/.zfile-v4/db'
            - '${logs}:/root/.zfile-v4/logs'
            - '${file}:/data/file'`;

  if (withConfig) {
    const conf = configDir || `${dir}/application.properties`;
    volumes += `\n            - '${conf}:/root/application.properties'`;
  }

  let zfileExtras = '';
  if (useMysql) {
    zfileExtras = `        depends_on:
            - mysql
        environment:
            - SPRING_DATASOURCE_DRIVER_CLASS_NAME=com.mysql.cj.jdbc.Driver
            - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/zfile?characterEncoding=utf8&serverTimezone=Asia/Shanghai&useSSL=false&allowPublicKeyRetrieval=true&createDatabaseIfNotExist=true
            - SPRING_DATASOURCE_USERNAME=root
            - SPRING_DATASOURCE_PASSWORD=${mysqlPwd}
`;
  }

  let yaml = `version: '3.3'
services:
    zfile:
        container_name: ${data.container}
        restart: always
${zfileExtras}        ports:
            - '${port || '8080'}:8080'
        volumes:
${volumes}
        image: ${image}`;

  if (useMysql) {
    yaml += `

    mysql:
        container_name: ${mysqlContainer}
        image: mysql:8.0
        restart: always
        command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
        environment:
            - MYSQL_ROOT_PASSWORD=${mysqlPwd}
            - MYSQL_DATABASE=zfile
            - TZ=Asia/Shanghai
        volumes:
            - '${mysqlDir}:/var/lib/mysql'`;
  }

  return yaml;
}

/**
 * 生成配置文件下载命令（Docker 映射配置文件时使用）
 */
export function generateConfigDownloadCommand({ edition, configDir }) {
  const data = EDITION_DATA[edition];
  const dir = `/root/${data.dir}`;
  const conf = configDir || `${dir}/application.properties`;
  return `curl -k -o ${conf} ${data.configUrl}`;
}

/**
 * 生成 Linux 全新安装命令
 */
export function generateLinuxInstallCommand({ edition, arch, installPath }) {
  const data = EDITION_DATA[edition];
  const path = installPath || `~/${data.dir}`;
  const url = data.linuxUrl(arch);
  const tar = data.tarName(arch);

  return `export ZFILE_INSTALL_PATH=${path}                                       # 声明安装到的路径
mkdir -p $ZFILE_INSTALL_PATH && cd $ZFILE_INSTALL_PATH                  # 创建文件夹并进入
wget --no-check-certificate ${url}  # 下载最新版
tar -zxvf ${tar}                              # 解压
rm -rf ${tar}                                 # 删除压缩包
chmod +x $ZFILE_INSTALL_PATH/bin/*.sh                                   # 授权启动停止脚本`;
}

/**
 * 生成 Linux 启动命令
 */
export function generateLinuxStartCommand({ edition, installPath }) {
  const data = EDITION_DATA[edition];
  const path = installPath || `~/${data.dir}`;
  return `${path}/bin/start.sh       # 启动项目`;
}

/**
 * 生成 Linux 更新命令
 */
export function generateLinuxUpdateCommand({ edition, arch, installPath }) {
  const data = EDITION_DATA[edition];
  const path = installPath || `~/${data.dir}`;
  const url = data.linuxUrl(arch);
  const tar = data.tarName(arch);

  return `export ZFILE_INSTALL_PATH=${path}                                       # 声明安装路径

$ZFILE_INSTALL_PATH/bin/stop.sh                                         # 停止程序
rm -rf $ZFILE_INSTALL_PATH                                              # 删除安装文件夹

# 重新下载安装最新版
mkdir -p $ZFILE_INSTALL_PATH && cd $ZFILE_INSTALL_PATH                  # 创建文件夹并进入
wget --no-check-certificate ${url}  # 下载最新版
tar -zxvf ${tar}                              # 解压
rm -rf ${tar}                                 # 删除压缩包
chmod +x $ZFILE_INSTALL_PATH/bin/*.sh                                   # 授权启动停止脚本

$ZFILE_INSTALL_PATH/bin/start.sh                                        # 启动项目`;
}

/**
 * 生成 WatchDucker 手动更新命令（执行一次后退出）
 */
export function generateWatchduckerManual({ edition }) {
  const data = EDITION_DATA[edition];
  return `docker run --rm \\
    -v /var/run/docker.sock:/var/run/docker.sock \\
    naomi233/watchducker:latest \\
    watchducker --once --clean ${data.container}`;
}

/**
 * 生成 WatchDucker 自动更新命令（每天凌晨 2 点检查）
 */
export function generateWatchduckerAuto({ edition }) {
  const data = EDITION_DATA[edition];
  return `docker run -d \\
    --name watchducker \\
    --restart always \\
    -v /var/run/docker.sock:/var/run/docker.sock \\
    -e TZ=Asia/Shanghai \\
    naomi233/watchducker:latest \\
    watchducker --cron "0 2 * * *" --clean ${data.container}`;
}

/**
 * 获取配置文件路径
 */
export function getConfigFilePath({ edition, platform, installPath, configDir }) {
  const data = EDITION_DATA[edition];
  if (platform === 'docker') {
    const conf = configDir || `/root/${data.dir}/application.properties`;
    return `${conf}（宿主机）`;
  }
  if (platform === 'linux') {
    const path = installPath || `~/${data.dir}`;
    return `${path}/application.properties`;
  }
  return `application.properties`;
}
