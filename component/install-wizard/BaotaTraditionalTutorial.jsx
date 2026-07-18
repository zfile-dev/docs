import React, { useState } from 'react';
import ComputeCommandNew from '../ComputeCommandNew';
import { BaotaProxyFix, BaotaNginxLimit } from './BaotaCommon';
import { ArchSelector } from './SharedWidgets';

const stepCard = {
  padding: '12px 16px', borderRadius: '8px', marginBottom: '10px',
  background: 'var(--ifm-color-emphasis-100)',
};
const stepLabel = { fontWeight: 600, marginBottom: '4px' };

function SiteSetupSteps({ screenshotSrc, commandComponent }) {
  return (
    <>
      <img className="sm:w-2/3" src="/img/2022/07/25/G6K7ou.png" />
      <img className="sm:w-7/12" src={screenshotSrc} />
      <p>假如你 <code>解压路径</code> 为 <code>/www/wwwroot/demo.zfile.vip</code>，按下图填写各项：</p>
      <div style={stepCard}>
        <div style={stepLabel}>① 项目执行文件</div>
        写 <code>解压路径</code>，如 <code>/www/wwwroot/demo.zfile.vip</code>
        <br/><span style={{fontSize:'0.85em',color:'var(--ifm-color-emphasis-600)'}}>宝塔要求必须选择一个文件，请选择 <code>application.properties</code>，确定后手动删除掉末尾的 <code>/application.properties</code></span>
      </div>
      <div style={stepCard}>
        <div style={stepLabel}>② 项目名称</div>
        随便写，符合宝塔规则即可
      </div>
      <div style={stepCard}>
        <div style={stepLabel}>③ 项目端口</div>
        默认 <code>8080</code>。如修改了配置文件中的 <code>server.port</code>，则填修改后的端口。
        <br/><span style={{fontSize:'0.85em',color:'var(--ifm-color-danger)'}}>千万不要写 80 或 443，宝塔已占用这些端口。</span>
      </div>
      <div style={stepCard}>
        <div style={stepLabel}>④ 执行命令</div>
        将解压路径粘贴到下方输入框，点击「生成执行命令」，再复制结果粘贴到宝塔中。
        {commandComponent}
      </div>
      <div style={stepCard}>
        <div style={stepLabel}>⑤ 运行用户</div>选 <code>root</code>
      </div>
      <div style={stepCard}>
        <div style={stepLabel}>⑥ 开机自启</div>根据需要选择
      </div>
      <div style={stepCard}>
        <div style={stepLabel}>⑦ 绑定域名</div>
        使用域名 → 填域名（不写协议和端口）<br/>
        使用 IP + 端口 → 留空即可
      </div>
    </>
  );
}

export default function BaotaTraditionalTutorial() {
  const [arch, setArch] = useState('amd64');

  const downloadLinks = {
    amd64: 'https://c.jun6.net/ZFILE-PRO/zfile-pro-release_linux_amd64.tar.gz',
    arm64: 'https://c.jun6.net/ZFILE-PRO/zfile-pro-release_linux_arm.tar.gz',
  };
  const screenshot1 = '/img/2024/11/09/pro-baota-1.png';
  const screenshot2 = '/img/2024/11/09/pro-baota-2.png';

  return (
    <>
      {/* ===== 前言 ===== */}
      <h2>1.前言</h2>
      <ul>
        <li>当前安装包未填写授权码时使用免费功能，填写有效授权码后启用捐赠版功能。</li>
        <li>统一安装包支持从 4.x 版本兼容升级，不支持从 3.x 或更早版本带数据升级。</li>
      </ul>

      {/* ===== 下载 ===== */}
      <h2 id="2下载">2.下载</h2>
      <p>选择系统架构，然后下载对应文件到服务器上。</p>
      <ArchSelector arch={arch} setArch={setArch} />
      <div style={{ marginTop: '12px' }}>
        <a href={downloadLinks[arch]}
           style={{ display: 'inline-block', padding: '8px 20px', borderRadius: '6px', background: 'var(--ifm-color-primary)', color: 'white', textDecoration: 'none', fontWeight: 500 }}>
          点击下载
        </a>
      </div>

      {/* ===== 解压 ===== */}
      <h2 id="3解压">3.解压</h2>
      <p>可以用宝塔自带的文件管理器解压:</p>
      <img className="sm:w-2/3" src={screenshot1} />

      {/* ===== 新建网站 ===== */}
      <h2>4.新建网站</h2>
      <SiteSetupSteps screenshotSrc={screenshot2} commandComponent={<ComputeCommandNew />} />

      <BaotaProxyFix />

      {/* ===== 配置文件 ===== */}
      <h2 id="config">配置文件路径</h2>
      <p>宝塔传统方式下，配置文件路径为：<code>解压路径/application.properties</code>。</p>
      <p>例如解压路径是 <code>/www/wwwroot/demo.zfile.vip</code>，则配置文件路径为 <code>/www/wwwroot/demo.zfile.vip/application.properties</code>。</p>

      {/* ===== 更新 ===== */}
      <h2>5.更新版本</h2>
      <ol>
        <li>宝塔中停止 ZFile 程序（务必先停止，且尝试访问网页无法访问再继续下面的操作）</li>
        <li>删除旧版本程序文件夹中内容</li>
        <li>重复前面的 <a href="#2下载">2.下载</a>、<a href="#3解压">3.解压</a> 步骤，将新版本文件解压到原来的文件夹中</li>
        <li>启动项目，访问验证。（一般启动需要 1-3 分钟，访问如果还是之前的版本，请清除浏览器缓存！）</li>
      </ol>

      {/* ===== 其他 ===== */}
      <h2>6.其他设置</h2>
      <BaotaNginxLimit />

      <h2>7.帮我安装</h2>
      <p><a href="#help-install">查看代安装服务</a></p>
    </>
  );
}
