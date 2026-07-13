import React, { useReducer, useEffect, useRef } from 'react';
import CodeBlock from '@theme/CodeBlock';
import {
  PLATFORMS, ARCHS, REGISTRIES, DOCKER_MODES, INSTALL_MODES, DB_TYPES,
  RELEASE_DATA, INITIAL_STATE, STORAGE_KEY, wizardReducer,
  generateRandomPassword,
} from './installConfig';
import {
  generateDockerRunCommand, generateDockerComposeYaml,
  generateConfigDownloadCommand,
  generateLinuxInstallCommand, generateLinuxStartCommand,
  generateLinuxUpdateCommand,
} from './commandGenerator';
import DockerUpdate from './DockerUpdate';
import { OptionCard, ArchHint } from './SharedWidgets';
import BaotaTraditionalTutorial from './BaotaTraditionalTutorial';
import DsmTutorial from './DsmTutorial';
import { PLATFORM_ICONS } from './PlatformIcons';

function SectionTitle({ children }) {
  return (
    <h3 style={{
      marginBottom: '12px', marginTop: '24px', fontSize: '1.1em',
      fontWeight: 600, borderLeft: '4px solid var(--ifm-color-primary)', paddingLeft: '12px',
    }}>{children}</h3>
  );
}

function DirInput({ label, value, onChange }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
      <span style={{ fontSize: '0.85em', whiteSpace: 'nowrap', minWidth: '80px' }}>{label}</span>
      <input type="text" value={value} onChange={(e) => onChange(e.target.value)} style={{
        flex: 1, padding: '6px 10px', borderRadius: '6px',
        border: '1px solid var(--ifm-color-emphasis-300)',
        background: 'var(--ifm-background-color)', color: 'inherit',
        fontSize: '0.85em', fontFamily: 'monospace',
      }} />
    </div>
  );
}

function saveState(state) {
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); } catch (e) { /* noop */ }
}

export default function InstallWizard() {
  const [state, dispatch] = useReducer(wizardReducer, INITIAL_STATE);
  const ready = useRef(false);

  // 客户端初始化：先从 localStorage 恢复，再用 URL 参数覆盖。
  // edition 参数只用于兼容旧链接，统一发行后不再参与安装包选择。
  useEffect(() => {
    const restored = {};
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) Object.assign(restored, JSON.parse(saved));
    } catch (e) { /* SSR safe */ }
    try {
      const searchParams = new URLSearchParams(window.location.search);
      const hash = window.location.hash.replace('#', '');
      const hashParams = new URLSearchParams(hash);
      const platform = searchParams.get('platform') || hashParams.get('platform');
      if (platform) restored.platform = platform;
    } catch (e) { /* SSR safe */ }
    delete restored.edition;
    delete restored.baotaMode;
    delete restored.withDockerSock;
    // 没有历史 MySQL 密码时，生成一个强随机密码作为默认值
    if (!restored.mysqlPassword) {
      restored.mysqlPassword = generateRandomPassword();
    }
    dispatch({ type: 'INIT_FROM_HASH', payload: restored });
    ready.current = true;
  }, []);

  // 状态变更时缓存到 localStorage（跳过初始化前的渲染）
  useEffect(() => {
    if (ready.current) saveState(state);
  }, [state]);

  const data = RELEASE_DATA;
  const dir = `/root/${data.dir}`;

  // 计算 Docker 目录的有效值（用于输入框显示）
  const effectivePort = state.port || '8080';
  const effectiveDbDir = state.dbDir || `${dir}/db`;
  const effectiveLogDir = state.logDir || `${dir}/logs`;
  const effectiveFileDir = state.fileDir || `${dir}/file`;
  const effectiveConfigDir = state.configDir || `${dir}/application.properties`;
  const effectiveMysqlDataDir = state.mysqlDataDir || `${dir}/mysql`;
  const effectiveMysqlPassword = state.mysqlPassword;
  const isComposeMode = state.dockerMode === 'compose';
  const useMysql = isComposeMode && state.dbType === 'mysql';

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
      <div style={{ padding: '12px 16px', borderRadius: '8px', background: 'var(--ifm-color-emphasis-100)', fontSize: '0.9em', lineHeight: 1.7 }}>
        ZFile 现已统一为一个版本：未填写授权码时使用免费功能，填写有效授权码后自动启用捐赠版功能。
      </div>

      {/* 安装模式 */}
      <SectionTitle>安装模式</SectionTitle>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '12px' }}>
        {INSTALL_MODES.map((m) => (
          <OptionCard key={m.id} label={m.label} selected={state.installMode === m.id}
            onClick={() => dispatch({ type: 'SET_INSTALL_MODE', payload: m.id })} />
        ))}
      </div>

      {/* 平台选择 */}
      <SectionTitle>安装环境</SectionTitle>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(160px, 1fr))', gap: '10px' }}>
        {PLATFORMS.map((p) => (
          <OptionCard key={p.id} label={p.label} icon={PLATFORM_ICONS[p.id]} desc={p.desc}
            selected={state.platform === p.id}
            onClick={() => dispatch({ type: 'SET_PLATFORM', payload: p.id })} />
        ))}
      </div>

      {/* Docker 子选项 */}
      {state.platform === 'docker' && state.installMode === 'install' && (
        <div>
          <SectionTitle>Docker 配置</SectionTitle>
          <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
            <div>
              <div style={{ marginBottom: '8px', fontSize: '0.9em', fontWeight: 500 }}>部署方式</div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '10px' }}>
                {DOCKER_MODES.map((m) => (
                  <OptionCard key={m.id} label={m.label} selected={state.dockerMode === m.id}
                    onClick={() => dispatch({ type: 'SET_DOCKER_MODE', payload: m.id })} />
                ))}
              </div>
            </div>
            <div>
              <div style={{ marginBottom: '8px', fontSize: '0.9em', fontWeight: 500 }}>镜像源</div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(150px, 1fr))', gap: '10px' }}>
                {REGISTRIES.map((r) => (
                  <OptionCard key={r.id} label={r.label} selected={state.registry === r.id}
                    onClick={() => dispatch({ type: 'SET_REGISTRY', payload: r.id })} />
                ))}
              </div>
            </div>
            {isComposeMode && (
              <div>
                <div style={{ marginBottom: '8px', fontSize: '0.9em', fontWeight: 500 }}>数据库</div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '10px' }}>
                  {DB_TYPES.map((db) => (
                    <OptionCard key={db.id} label={db.label} desc={db.desc}
                      selected={state.dbType === db.id}
                      onClick={() => dispatch({ type: 'SET_DB_TYPE', payload: db.id })} />
                  ))}
                </div>
                {useMysql && (
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', marginTop: '12px' }}>
                    <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                      <span style={{ fontSize: '0.85em', whiteSpace: 'nowrap', minWidth: '80px' }}>MySQL 密码</span>
                      <input type="text" value={effectiveMysqlPassword}
                        onChange={(e) => dispatch({ type: 'SET_MYSQL_PASSWORD', payload: e.target.value })}
                        style={{
                          flex: 1, padding: '6px 10px', borderRadius: '6px',
                          border: '1px solid var(--ifm-color-emphasis-300)',
                          background: 'var(--ifm-background-color)', color: 'inherit',
                          fontSize: '0.85em', fontFamily: 'monospace',
                        }} />
                      <button type="button"
                        onClick={() => dispatch({ type: 'SET_MYSQL_PASSWORD', payload: generateRandomPassword() })}
                        style={{
                          padding: '6px 12px', borderRadius: '6px', cursor: 'pointer',
                          border: '1px solid var(--ifm-color-emphasis-300)',
                          background: 'var(--ifm-background-color)', color: 'inherit',
                          fontSize: '0.8em', whiteSpace: 'nowrap',
                        }}>重新生成</button>
                    </div>
                    <DirInput label="MySQL 目录" value={effectiveMysqlDataDir}
                      onChange={(v) => dispatch({ type: 'SET_MYSQL_DATA_DIR', payload: v })} />
                  </div>
                )}
              </div>
            )}
            <div>
              <label style={{ display: 'flex', alignItems: 'center', gap: '8px', cursor: 'pointer' }}>
                <input type="checkbox" checked={state.withConfig}
                  onChange={() => dispatch({ type: 'TOGGLE_CONFIG' })} />
                <span>映射配置文件到宿主机</span>
              </label>
              <div style={{ fontSize: '0.8em', opacity: 0.6, marginTop: '4px', marginLeft: '24px' }}>
                如需修改 Redis 或其他特殊设置时才需开启
              </div>
            </div>
            <div>
              <div style={{ marginBottom: '8px', fontSize: '0.9em', fontWeight: 500 }}>端口与目录</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <DirInput label="端口" value={effectivePort}
                  onChange={(v) => dispatch({ type: 'SET_PORT', payload: v })} />
                <DirInput label="数据库目录" value={effectiveDbDir}
                  onChange={(v) => dispatch({ type: 'SET_DB_DIR', payload: v })} />
                <DirInput label="日志目录" value={effectiveLogDir}
                  onChange={(v) => dispatch({ type: 'SET_LOG_DIR', payload: v })} />
                <DirInput label="文件目录" value={effectiveFileDir}
                  onChange={(v) => dispatch({ type: 'SET_FILE_DIR', payload: v })} />
                {state.withConfig && (
                  <DirInput label="配置文件" value={effectiveConfigDir}
                    onChange={(v) => dispatch({ type: 'SET_CONFIG_DIR', payload: v })} />
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Linux 子选项 */}
      {state.platform === 'linux' && (
        <div>
          <SectionTitle>Linux 配置</SectionTitle>
          <div style={{ marginBottom: '8px', fontSize: '0.9em', fontWeight: 500 }}>CPU 架构</div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: '10px' }}>
            {ARCHS.map((a) => (
              <OptionCard key={a.id} label={a.label} desc={a.desc}
                selected={state.arch === a.id}
                onClick={() => dispatch({ type: 'SET_ARCH', payload: a.id })} />
            ))}
          </div>
          <ArchHint />
        </div>
      )}

      {/* 宝塔面板 */}
      {state.platform === 'baota' && (
        <div>
          <SectionTitle>宝塔传统方式安装</SectionTitle>
          <div style={{ padding: '12px 16px', borderRadius: '8px', background: 'var(--ifm-color-emphasis-100)', fontSize: '0.9em', marginBottom: '16px' }}>
            宝塔 Docker 应用商店暂未提供统一安装包，请使用传统方式安装。
          </div>
          <BaotaTraditionalTutorial />
        </div>
      )}

      {/* 群晖 NAS */}
      {state.platform === 'synology' && (
        <div>
          <SectionTitle>群晖 Docker 安装教程</SectionTitle>
          <DsmTutorial />
        </div>
      )}

      {/* 1Panel */}
      {state.platform === 'onepanel' && (
        <div>
          <SectionTitle>1Panel 应用商店安装</SectionTitle>
          <div style={{ padding: '16px', borderRadius: '8px', border: '2px dashed var(--ifm-color-emphasis-300)', textAlign: 'center' }}>
            <p>1Panel 应用商店暂未提供统一安装包，请选择 Docker、Linux 或一键脚本安装。</p>
          </div>
        </div>
      )}

      {/* 命令输出区 */}
      {['docker', 'linux', 'script', 'windows'].includes(state.platform) && (
        <div>
          <SectionTitle>{state.installMode === 'update' ? '更新命令' : '安装命令'}</SectionTitle>

          {/* Docker 安装 */}
          {state.platform === 'docker' && state.installMode === 'install' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              {state.withConfig && (
                <div>
                  <div style={{ fontSize: '0.85em', opacity: 0.7, marginBottom: '4px' }}>先下载配置文件到宿主机：</div>
                  <CodeBlock language="bash">{generateConfigDownloadCommand(state)}</CodeBlock>
                </div>
              )}
              <div>
                <div style={{ fontSize: '0.85em', opacity: 0.7, marginBottom: '4px' }}>
                  {state.dockerMode === 'run' ? '启动容器：' : 'docker-compose.yml：'}
                </div>
                <CodeBlock language={state.dockerMode === 'run' ? 'bash' : 'yaml'}>
                  {state.dockerMode === 'run' ? generateDockerRunCommand(state) : generateDockerComposeYaml(state)}
                </CodeBlock>
              </div>
              {useMysql && (
                <div style={{ padding: '12px 16px', borderRadius: '8px', background: 'var(--ifm-color-emphasis-100)', fontSize: '0.9em', lineHeight: 1.7 }}>
                  保存为 <code>docker-compose.yml</code> 后，在同目录执行 <code>docker compose up -d</code> 启动。
                  首次启动 MySQL 初始化需 10–30 秒，请稍等再访问。
                </div>
              )}
            </div>
          )}

          {/* Docker 更新 */}
          {state.platform === 'docker' && state.installMode === 'update' && (
            <DockerUpdate />
          )}

          {/* Linux 安装 */}
          {state.platform === 'linux' && state.installMode === 'install' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div>
                <div style={{ fontSize: '0.85em', opacity: 0.7, marginBottom: '4px' }}>全新安装：</div>
                <CodeBlock language="bash">{generateLinuxInstallCommand(state)}</CodeBlock>
              </div>
              <div>
                <div style={{ fontSize: '0.85em', opacity: 0.7, marginBottom: '4px' }}>启动项目：</div>
                <CodeBlock language="bash">{generateLinuxStartCommand(state)}</CodeBlock>
              </div>
              <div style={{ padding: '12px 16px', borderRadius: '8px', background: 'var(--ifm-color-emphasis-100)', fontSize: '0.9em' }}>
                启动后浏览器访问 <code>http://ip:8080</code> 即可。如无法访问，请检查端口是否冲突或防火墙/安全组是否放行。
              </div>
            </div>
          )}

          {/* Linux 更新 */}
          {state.platform === 'linux' && state.installMode === 'update' && (
            <div>
              <div style={{ marginBottom: '12px', padding: '10px 14px', borderRadius: '8px', background: 'var(--ifm-color-warning-contrast-background)', fontSize: '0.85em' }}>
                更新前请先按备份文档备份数据库、配置文件和本地存储文件。下面的命令会保留安装目录中的 <code>application.properties</code>。
              </div>
              <CodeBlock language="bash">{generateLinuxUpdateCommand(state)}</CodeBlock>
            </div>
          )}

          {/* 一键脚本 */}
          {state.platform === 'script' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div style={{ padding: '12px 16px', borderRadius: '8px', background: 'var(--ifm-color-emphasis-100)', fontSize: '0.9em' }}>
                仅支持 Linux 系统。脚本提供交互式安装，支持 Docker / 直装 / 更新 / 卸载等操作。
              </div>
              <div>
                <div style={{ fontSize: '0.85em', opacity: 0.7, marginBottom: '4px' }}>下载并运行脚本：</div>
                <CodeBlock language="bash">
                  {`curl -sSL https://docs.zfile.vip/install.sh -o install.sh && chmod +x install.sh && ./install.sh`}
                </CodeBlock>
              </div>
              <div style={{ fontSize: '0.85em', opacity: 0.6 }}>
                再次使用时，在相同目录执行 <code>./install.sh</code> 即可。脚本还支持 <code>status</code>、
                <code>logs</code>、<code>doctor</code>、<code>reset-admin</code> 和 <code>service install</code> 等子命令，可执行
                <code>./install.sh --help</code> 查看完整说明。
              </div>
            </div>
          )}

          {/* Windows */}
          {state.platform === 'windows' && (
            <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
              <div style={{ padding: '16px', borderRadius: '8px', border: '1px solid var(--ifm-color-emphasis-300)' }}>
                <p><strong>1.</strong> <a href={data.winUrl}>点击下载 {data.name} 软件包</a></p>
                <p><strong>2.</strong> 解压后双击 <code>双击我启动.bat</code> 即可</p>
                <p><strong>3.</strong> 启动后访问 <a href="http://localhost:8080">http://localhost:8080</a></p>
                <p style={{ marginBottom: 0 }}><strong>4.</strong> 如需自定义配置，将解压目录下的 <code>application.properties.example</code> 复制为 <code>application.properties</code></p>
              </div>
              <div style={{ padding: '12px 16px', borderRadius: '8px', background: 'var(--ifm-color-emphasis-100)', fontSize: '0.9em' }}>
                <strong>注意：</strong>如果你的 Windows 用户名为中文，可能会启动失败。
                用记事本打开 <code>双击我启动.bat</code>，在第二行最后加个{' '}
                <code>-Dorg.sqlite.tmpdir=C:\tmp</code>（确保目录存在），保存后再启动。
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
