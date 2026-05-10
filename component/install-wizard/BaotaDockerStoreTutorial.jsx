import React from 'react';
import { BaotaProxyFix, BaotaNginxLimit } from './BaotaCommon';

const stepCard = {
  padding: '12px 16px', borderRadius: '8px', marginBottom: '10px',
  background: 'var(--ifm-color-emphasis-100)',
};
const stepLabel = { fontWeight: 600, marginBottom: '4px' };

export default function BaotaDockerStoreTutorial() {
  return (
    <>
      <blockquote>
        <p>提示：宝塔应用商店需宝塔版本为 9.2.0 及以上版本，如果低于此版本请先升级宝塔或切换到「传统方式」安装。</p>
      </blockquote>

      <h2>运行</h2>
      <ol>
        <li>如未安装宝塔，可点击跳转至<a href="https://www.bt.cn/u/WYVNdM">官网</a>复制安装命令安装宝塔。</li>
        <li>
          登录宝塔面板，点击左侧菜单的 <code>Docker</code>，在应用商店搜索 <code>ZFile</code>，点击<strong>安装</strong>。
          <br/><img className="sm:w-6/12" src="/img/2024/10/24/baota-new-1.png" />
        </li>
        <li>
          填写<strong>基本信息</strong>，点击<strong>确定</strong>。
          <br/><img className="sm:w-6/12" src="/img/2024/10/24/baota-new-2.png" />
        </li>
        <li>运行起来后访问即可。</li>
      </ol>

      <h2>数据目录</h2>
      <p>可通过以下方式进入数据目录，包含数据库、日志等：</p>
      <img className="sm:w-6/12" src="/img/2024/10/24/baota-new-3.png" />

      <h3>在 ZFile 中访问宿主机文件</h3>
      <p>
        宝塔默认将上面的数据目录下的 <code>mnt</code> 目录映射到容器的 <code>/data/zfile</code> 目录，
        在 ZFile 本地存储填写路径时，填写 <code>/data/zfile</code> 即可。
      </p>
      <img className="sm:w-8/12" src="/img/2024/10/24/baota-new-4.png" />
      <img className="sm:w-8/12" src="/img/2024/10/24/baota-new-5.png" />

      <p>如想映射宿主机的其他目录，可编辑数据目录下的 <code>docker-compose.yml</code> 文件，如我想在容器内用 <code>/www/wwwroot/xxx.com</code>：</p>
      <img className="sm:w-8/12" src="/img/2024/10/24/baota-new-6.png" />
      <img className="sm:w-8/12" src="/img/2024/10/24/baota-new-7.png" />

      <h3>配置文件</h3>
      <p>
        <strong>如需修改配置文件</strong>则需要先在宿主机下载配置文件，然后映射到容器内：
        下载 <code>https://c.jun6.net/ZFILE/application.properties</code> 文件到数据目录下，然后编辑 <code>docker-compose.yml</code> 文件，
        添加 <code>{'- ${APP_PATH}/application.properties:/root/application.properties'}</code>，如下图：
      </p>
      <img className="sm:w-8/12" src="/img/2024/10/24/baota-new-8.png" />
      <img className="sm:w-8/12" src="/img/2024/10/24/baota-new-9.png" />
      <img className="sm:w-8/12" src="/img/2024/10/24/baota-new-10.png" />
      <p>第一次配置需重建容器后生效，之后修改配置文件 <code>application.properties</code> 的话，重启容器即可生效。</p>

      <BaotaProxyFix />

      <h2>其他设置</h2>
      <BaotaNginxLimit />

      <h3>更新程序</h3>
      <ol>
        <li>
          点击进入安装目录：
          <br/><img className="sm:w-6/12" src="/img/2024/10/24/baota-new-3.png" />
        </li>
        <li>
          点击终端
          <br/><img className="sm:w-6/12" src="/img/2025/5/11/baota-command.png" />
        </li>
        <li>
          输入以下命令后回车，等待拉取最新镜像：
          <br/><code>docker-compose pull</code>
        </li>
        <li>
          回到应用商店页，点击 <strong>重建</strong>:
          <br/><img className="sm:w-6/12" src="/img/2025/5/11/baota-rebuild.png" />
        </li>
        <li>等待 1-2 分钟，重建完成后，访问 ZFile 即可，<strong>如果页面异常，尝试清理浏览器缓存后再访问</strong></li>
      </ol>
    </>
  );
}
