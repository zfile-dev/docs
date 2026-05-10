import React from 'react';

export default function OnePanelTutorial() {
  return (
    <>
      <h2>安装</h2>
      <ol>
        <li>
          应用商店搜索 <code>zfile</code>：
          <br/><img className="sm:w-6/12" src="/img/2025/5/11/1panel-1.png" />
        </li>
        <li>
          点击安装，按提示信息填写：
          <br/><img className="sm:w-6/12" src="/img/2025/5/11/1panel-2.png" />
        </li>
        <li>
          等待安装完成（首次安装可能比较慢，因为要拉取镜像），然后访问上一步填写的{' '}
          <code>http://ip:端口</code> 即可（域名和 https 配置参考 1panel 官方教程）
        </li>
      </ol>

      <h2>更新</h2>
      <p>点击 <code>容器</code> → <code>更多</code> → <code>升级</code>：</p>
      <img className="sm:w-6/12" src="/img/2025/5/11/1panel-3.png" />
      <img className="sm:w-6/12" src="/img/2025/5/11/1panel-4.png" />

      <p>
        如果你从 4.1.5 升级过来的，升级后之前的数据丢失了，是因为 1panel 默认映射的目录变化了，按照以下操作：
      </p>
      <img className="sm:w-6/12" src="/img/2025/5/11/1panel-5.png" />

      <p>双击 <code>docker-compose.yml</code> 文件，检查下面的 <code>volumes</code> 块，最新版应该是：</p>
      <pre><code>{`        volumes:
            - ./data/db:/root/.zfile-v4/db
            - ./data/logs:/root/.zfile-v4/logs
            - ./data/mnt:/data/file`}</code></pre>

      <p>4.1.5 版本是：</p>
      <pre><code>{`        volumes:
            - /opt/zfile/data/db:/root/.zfile-v4/db
            - /opt/zfile/data/logs:/root/.zfile-v4/logs
            - /opt/zfile/data/mnt:/root/.zfile-v4/mnt`}</code></pre>

      <p>
        方式1：将 <code>/opt/zfile/data/</code> 目录下的文件迁移到 docker-compose.yml 文件所在目录下的 <code>data/</code> 目录下，然后重建容器即可。
      </p>
      <img className="sm:w-6/12" src="/img/2025/5/11/1panel-6.png" />
      <img className="sm:w-6/12" src="/img/2025/5/11/1panel-7.png" />

      <p>
        方式2：可以将 <code>docker-compose.yml</code> 文件中的 <code>volumes</code> 块替换成上面的内容，保存后，重建容器即可。
      </p>
      <img className="sm:w-6/12" src="/img/2025/5/11/1panel-7.png" />
    </>
  );
}
