import React from 'react';
import CodeBlock from '@theme/CodeBlock';

const stepCard = {
  padding: '12px 16px', borderRadius: '8px', marginBottom: '10px',
  background: 'var(--ifm-color-emphasis-100)',
};
const stepLabel = { fontWeight: 600, marginBottom: '4px' };

export default function DsmTutorial() {
  const image = 'zfile-pro';

  const composeYaml = `version: '3.3'
services:
    zfile:
        container_name: zfile
        restart: always
        ports:
            - '8080:8080'   # 左侧的端口可以自定义，表示实际访问的端口，右侧的不要动。如 9090:8080 表示通过 9090 端口访问 zfile
        volumes:
            - './db:/root/.zfile-v4/db'
            - './logs:/root/.zfile-v4/logs'

             # 因 Docker 具有隔离性，这里表示将群辉的哪个目录挂载到 zfile 中，可自行修改，见下图
            - '/volume1:/volume1'
            - '/var/run/docker.sock:/var/run/docker.sock:ro'
        image: swr.cn-north-1.myhuaweicloud.com/zfile-dev/${image}:latest`;
  const deleteImage = `swr.cn-north-1.myhuaweicloud.com/zfile-dev/${image}:latest`;

  return (
    <>
      <h2>安装</h2>
      <p>下文示例为 DSM 7.2 版本，其他版本也基本类似。</p>

      <div style={stepCard}>
        <div style={stepLabel}>① 准备数据目录</div>
        打开 <code>File Station</code>，在 <code>docker</code> 目录下新建 <code>zfile</code> 文件夹，
        并在其中创建 <code>db</code> 和 <code>logs</code> 两个子目录。
        <img className="sm:w-2/3" src="/img/2025/9/6/dsm-install-1.png" />
      </div>

      <div style={stepCard}>
        <div style={stepLabel}>② 安装 Container Manager</div>
        打开「套件中心」，搜索并安装「Container Manager」。
        <img className="sm:w-2/3" src="/img/2025/9/6/dsm-install-2.png" />
      </div>

      <div style={stepCard}>
        <div style={stepLabel}>③ 新建项目</div>
        打开「Container Manager」→「项目」→「新增」，填写以下信息：
        <ul style={{ marginBottom: '8px' }}>
          <li><strong>项目名称</strong>：随便起一个名字，比如 <code>zfile</code></li>
          <li><strong>路径</strong>：选择第一步创建的文件夹，如 <code>/docker/zfile</code>（注意选上级目录，不是 <code>db</code> 或 <code>logs</code>）</li>
          <li><strong>来源</strong>：创建 docker-compose.yml</li>
          <li><strong>内容</strong>：复制下面的配置</li>
        </ul>
        <CodeBlock language="yaml">{composeYaml}</CodeBlock>
        <p style={{ fontSize: '0.85em', color: 'var(--ifm-color-emphasis-700)', marginTop: '4px' }}>
          配置已只读挂载 <code>docker.sock</code>，用于在「系统监控」中读取容器名称、镜像和宿主机挂载源。
        </p>
        <img className="sm:w-2/3" src="/img/2025/9/6/dsm-install-3.png" />
        <img className="sm:w-2/3" src="/img/2025/9/6/dsm-install-4.png" />
      </div>

      <div style={stepCard}>
        <div style={stepLabel}>④ 完成创建</div>
        一直点击「下一步」，会询问是否通过 Web Station 设置网页门户，不用设置，直接点「下一步」→「完成」。
        <img className="sm:w-2/3" src="/img/2025/9/6/dsm-install-5.png" />
      </div>

      <div style={stepCard}>
        <div style={stepLabel}>⑤ 访问 ZFile</div>
        通过 <code>{'http://你的群辉IP:8080'}</code> 访问（如修改了端口号则用修改后的），设置站点名称、管理员账号和密码即可。
      </div>

      <div style={stepCard}>
        <div style={stepLabel}>⑥ 添加存储源</div>
        进入 ZFile 后台，新增存储源，存储策略选「本地存储」，「基路径」填第 ③ 步中挂载的目录，如 <code>/volume1/你的目录</code>。
      </div>

      <h2>更新</h2>

      <div style={stepCard}>
        <div style={stepLabel}>① 清除旧项目</div>
        打开「Container Manager」→「项目」，右键 <code>zfile</code> 项目，点击「清除」。
        <br/><span style={{fontSize:'0.85em',color:'var(--ifm-color-emphasis-600)'}}>放心，这不会删除你的数据。</span>
      </div>

      <div style={stepCard}>
        <div style={stepLabel}>② 删除旧镜像</div>
        点击左侧「映像」，删除 <code>{deleteImage}</code> 镜像。
        <img className="sm:w-2/3" src="/img/2025/9/6/dsm-install-6.png" />
      </div>

      <div style={stepCard}>
        <div style={stepLabel}>③ 重新构建</div>
        回到「项目」，右键 <code>zfile</code> 项目，点击「构建」，会自动拉取最新镜像并启动。
      </div>
    </>
  );
}
