import React from 'react';
import CodeBlock from '@theme/CodeBlock';
import { generateWatchduckerManual, generateWatchduckerAuto } from './commandGenerator';

/** Docker 容器更新组件（基于 WatchDucker） */
export default function DockerUpdate() {
  return (
    <div>
      <div style={{ marginBottom: '12px', padding: '10px 14px', borderRadius: '8px', background: 'var(--ifm-color-warning-contrast-background)', fontSize: '0.85em' }}>
        更新前请先备份数据库、配置文件和本地存储文件，并确认数据库、日志目录已持久化到宿主机。
      </div>
      <div style={{ fontSize: '0.85em', opacity: 0.7, marginBottom: '4px' }}>
        手动更新（执行一次后自动退出）：
      </div>
      <CodeBlock language="bash">{generateWatchduckerManual()}</CodeBlock>

      <div style={{ fontSize: '0.85em', opacity: 0.7, marginBottom: '4px', marginTop: '12px' }}>
        自动更新（每天凌晨 2 点检查）：
      </div>
      <CodeBlock language="bash">{generateWatchduckerAuto()}</CodeBlock>

      <div style={{
        marginTop: '8px',
        fontSize: '0.8em',
        opacity: 0.6,
      }}>
        更新工具：<a
          href="https://github.com/naomi233/watchducker"
          target="_blank"
          rel="noopener noreferrer"
        >WatchDucker</a> — 基于 Docker API 的容器镜像自动更新工具，支持 15+ 种通知渠道。
      </div>
    </div>
  );
}
