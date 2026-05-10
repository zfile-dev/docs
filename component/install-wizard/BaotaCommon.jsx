import React from 'react';

export function BaotaProxyFix() {
  return (
    <>
      <blockquote>
        <p>
          注意：如果你使用 9.x 的宝塔，可能会遇到宝塔的一个 bug，导致直链/短链跳转到 127.0.0.1，解决方法是在<strong>宝塔上</strong> 修改这个站点配置文件(不是ZFile配置文件)，将 <code>{'proxy_set_header Host 127.0.0.1:$server_port;'}</code> 修改为 <code>{'proxy_set_header Host $host:$server_port;'}</code>，保存即可。
        </p>
      </blockquote>
      <img className={'sm:w-6/12 '} src="/img/2024/12/5/baota-fix1.png" />
      <img className={'sm:w-6/12 '} src="/img/2024/12/5/baota-fix2.png" />
      <p>
        如果你的站点是 HTTPS 的，还建议你添加一行 <code>{'proxy_set_header X-Forwarded-Proto $scheme;'}</code> 到上面红框的下一行，不然可能直链会先跳转到 HTTP，再跳转到 HTTPS，会被浏览器提示不安全链接。
      </p>
    </>
  );
}

export function BaotaNginxLimit() {
  return (
    <>
      <p>宝塔 <code>nginx</code> 默认只支持上传最大 <code>50MB</code> 的文件，可去以下页面进行设置:</p>
      <img className={'sm:w-10/12 '} src="/img/2022/08/16/uxPAXY.png" />
      <img className={'sm:w-6/12 '} src="/img/2022/08/16/Jx2P2s.png" />
    </>
  );
}
