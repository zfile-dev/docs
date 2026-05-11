export const EDITIONS = [
  { id: 'os', label: '开源版' },
  { id: 'pro', label: '捐赠版' },
];

export const PLATFORMS = [
  { id: 'docker', label: 'Docker' },
  { id: 'linux', label: 'Linux' },
  { id: 'script', label: 'Linux 一键脚本' },
  { id: 'windows', label: 'Windows' },
  { id: 'baota', label: '宝塔面板' },
  { id: 'synology', label: '群晖 NAS' },
  { id: 'onepanel', label: '1Panel' },
];

export const ARCHS = [
  { id: 'amd64', label: 'amd64', desc: '通用 PC / 云服务器' },
  { id: 'arm64', label: 'arm64', desc: '树莓派 / ARM 服务器' },
];

export const REGISTRIES = [
  { id: 'dockerhub', label: 'DockerHub' },
  { id: 'beijing', label: '北京镜像' },
  { id: 'hongkong', label: '香港镜像' },
];

export const DOCKER_MODES = [
  { id: 'run', label: 'docker run' },
  { id: 'compose', label: 'docker compose' },
];

export const DB_TYPES = [
  { id: 'sqlite', label: 'SQLite', desc: '默认，免安装' },
  { id: 'mysql', label: 'MySQL', desc: '仅 docker compose 模式' },
];

export const BAOTA_MODES = [
  { id: 'docker-store', label: 'Docker 应用商店', desc: '推荐，仅开源版' },
  { id: 'traditional', label: '传统方式', desc: '开源版/捐赠版均可' },
];

// 版本相关常量
export const EDITION_DATA = {
  os: {
    name: 'ZFile',
    dir: 'zfile',
    container: 'zfile',
    image: 'zfile',
    urlPrefix: 'ZFILE',
    filePrefix: 'zfile-release',
    configUrl: 'https://c.jun6.net/ZFILE/application.properties',
    linuxUrl: (arch) =>
      `https://c.jun6.net/ZFILE/zfile-release_linux_${arch === 'arm64' ? 'arm' : 'amd64'}.tar.gz`,
    winUrl: 'https://c.jun6.net/ZFILE/zfile-release_windows_amd64.zip',
    tarName: (arch) => `zfile-release_linux_${arch === 'arm64' ? 'arm' : 'amd64'}.tar.gz`,
  },
  pro: {
    name: 'ZFile Pro',
    dir: 'zfile-pro',
    container: 'zfile-pro',
    image: 'zfile-pro',
    urlPrefix: 'ZFILE-PRO',
    filePrefix: 'zfile-pro-release',
    configUrl: 'https://c.jun6.net/ZFILE-PRO/application.properties',
    linuxUrl: (arch) =>
      `https://c.jun6.net/ZFILE-PRO/zfile-pro-release_linux_${arch === 'arm64' ? 'arm' : 'amd64'}.tar.gz`,
    winUrl: 'https://c.jun6.net/ZFILE-PRO/zfile-pro-release_windows_amd64.zip',
    tarName: (arch) => `zfile-pro-release_linux_${arch === 'arm64' ? 'arm' : 'amd64'}.tar.gz`,
  },
};

// 镜像仓库地址映射
export const REGISTRY_MAP = {
  dockerhub: (image) => `zhaojun1998/${image}:latest`,
  beijing: (image) => `swr.cn-north-1.myhuaweicloud.com/zfile-dev/${image}:latest`,
  hongkong: (image) => `swr.ap-southeast-1.myhuaweicloud.com/zfile-dev/${image}:latest`,
};

// localStorage 缓存 key
export const STORAGE_KEY = 'zfile-wizard-state';

// 生成强随机密码：20 位字母+数字（避开特殊字符以免 shell/yaml 转义麻烦）
export function generateRandomPassword(length = 20) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  let pwd = '';
  if (typeof window !== 'undefined' && window.crypto && window.crypto.getRandomValues) {
    const arr = new Uint32Array(length);
    window.crypto.getRandomValues(arr);
    for (let i = 0; i < length; i++) pwd += chars[arr[i] % chars.length];
  } else {
    for (let i = 0; i < length; i++) pwd += chars[Math.floor(Math.random() * chars.length)];
  }
  return pwd;
}

// 安装/更新模式
export const INSTALL_MODES = [
  { id: 'install', label: '全新安装' },
  { id: 'update', label: '更新版本' },
];

// 初始状态
export const INITIAL_STATE = {
  edition: 'os',
  platform: 'docker',
  baotaMode: 'docker-store',
  arch: 'amd64',
  registry: 'dockerhub',
  dockerMode: 'run',
  withConfig: false,
  port: '8080',
  dataDir: '',
  installPath: '',
  dbDir: '',
  logDir: '',
  fileDir: '',
  configDir: '',
  installMode: 'install',
  dbType: 'sqlite',
  mysqlPassword: '',
  mysqlDataDir: '',
};

// Reducer
export function wizardReducer(state, action) {
  switch (action.type) {
    case 'SET_EDITION':
      return {
        ...state,
        edition: action.payload,
        dataDir: state.dataDir ? state.dataDir : '',
        installPath: state.installPath ? state.installPath : '',
        // 捐赠版时宝塔自动切换到传统方式
        baotaMode: action.payload === 'pro' ? 'traditional' : state.baotaMode,
      };
    case 'SET_PLATFORM':
      return { ...state, platform: action.payload };
    case 'SET_BAOTA_MODE':
      return { ...state, baotaMode: action.payload };
    case 'SET_ARCH':
      return { ...state, arch: action.payload };
    case 'SET_REGISTRY':
      return { ...state, registry: action.payload };
    case 'SET_DOCKER_MODE':
      return {
        ...state,
        dockerMode: action.payload,
        // 切换到 run 模式时，MySQL 不可用，回退到 sqlite
        dbType: action.payload === 'run' ? 'sqlite' : state.dbType,
      };
    case 'TOGGLE_CONFIG':
      return { ...state, withConfig: !state.withConfig };
    case 'SET_PORT':
      return { ...state, port: action.payload };
    case 'SET_DATA_DIR':
      return { ...state, dataDir: action.payload };
    case 'SET_INSTALL_PATH':
      return { ...state, installPath: action.payload };
    case 'SET_DB_DIR':
      return { ...state, dbDir: action.payload };
    case 'SET_LOG_DIR':
      return { ...state, logDir: action.payload };
    case 'SET_FILE_DIR':
      return { ...state, fileDir: action.payload };
    case 'SET_CONFIG_DIR':
      return { ...state, configDir: action.payload };
    case 'SET_INSTALL_MODE':
      return { ...state, installMode: action.payload };
    case 'SET_DB_TYPE':
      return { ...state, dbType: action.payload };
    case 'SET_MYSQL_PASSWORD':
      return { ...state, mysqlPassword: action.payload };
    case 'SET_MYSQL_DATA_DIR':
      return { ...state, mysqlDataDir: action.payload };
    case 'INIT_FROM_HASH':
      return { ...state, ...action.payload };
    default:
      return state;
  }
}