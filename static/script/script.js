// 兼容旧版文档相关链接进行跳转
let hash = window.location.hash;

let hashMap = {
    '#/question?id=reset-pwd': '/config/config-debug',
    '#/advanced?id=onedrive-cf': 'advanced/cf-worker',
    '#/example': '/category/存储源示例配置',
    '#/example/': '/category/存储源示例配置',
    '#/pro': '/install/guide?platform=linux',
};

if (hashMap[hash]) {
    window.location.href = hashMap[hash];
} else {
    let path = window.location.pathname + window.location.search + window.location.hash;

    let pathMap = {
        '/zfile': '/',
        '/advanced#only-office': '/advanced/only-office',
        '/advanced/#only-office': '/advanced/only-office',
        '/advanced#google-drive-api': '/advanced/google-drive-api',
        '/advanced/#google-drive-api': '/advanced/google-drive-api',
        '/question#reset-pwd': '/config/config-debug',
        '/question/#reset-pwd': '/config/config-debug',
        '/example': '/category/存储源示例配置',
        '/example/': '/category/存储源示例配置',
        '/changelog/pro': '/changelog/',
        '/changelog/pro/': '/changelog/',
        '/changelog/os': '/changelog/',
        '/changelog/os/': '/changelog/',
        // 旧安装页面 → 安装向导
        '/install/os-linux': '/install/guide?platform=linux',
        '/install/os-linux/': '/install/guide?platform=linux',
        '/install/pro-linux': '/install/guide?platform=linux',
        '/install/pro-linux/': '/install/guide?platform=linux',
        '/install/os-docker': '/install/guide?platform=docker',
        '/install/os-docker/': '/install/guide?platform=docker',
        '/install/pro-docker': '/install/guide?platform=docker',
        '/install/pro-docker/': '/install/guide?platform=docker',
        '/install/os-windows': '/install/guide?platform=windows',
        '/install/os-windows/': '/install/guide?platform=windows',
        '/install/pro-windows': '/install/guide?platform=windows',
        '/install/pro-windows/': '/install/guide?platform=windows',
        // 旧分类索引页 → 安装向导
        '/install-os': '/install/guide',
        '/install-os/': '/install/guide',
        '/install-pro': '/install/guide',
        '/install-pro/': '/install/guide',
        '/install': '/install/guide',
        '/install/': '/install/guide',
        // 旧图文教程页 → 安装向导
        '/install/os-dsm-docker': '/install/guide?platform=synology',
        '/install/os-dsm-docker/': '/install/guide?platform=synology',
        '/install/pro-dsm-docker': '/install/guide?platform=synology',
        '/install/pro-dsm-docker/': '/install/guide?platform=synology',
        '/install/os-baota': '/install/guide?platform=baota',
        '/install/os-baota/': '/install/guide?platform=baota',
        '/install/pro-baota': '/install/guide?platform=baota',
        '/install/pro-baota/': '/install/guide?platform=baota',
        '/install/baota': '/install/guide?platform=baota',
        '/install/baota/': '/install/guide?platform=baota',
        '/install/os-baota-new': '/install/guide?platform=baota',
        '/install/os-baota-new/': '/install/guide?platform=baota',
        '/install/dsm-docker': '/install/guide?platform=synology',
        '/install/dsm-docker/': '/install/guide?platform=synology',
        '/install/os-1panel': '/install/guide?platform=onepanel',
        '/install/os-1panel/': '/install/guide?platform=onepanel',
        '/install/script-install': '/install/guide?platform=script',
        '/install/script-install/': '/install/guide?platform=script',
        // 更早期（pre-2022）安装页 → 安装向导
        '/install/docker': '/install/guide?platform=docker',
        '/install/docker/': '/install/guide?platform=docker',
        '/install/linux': '/install/guide?platform=linux',
        '/install/linux/': '/install/guide?platform=linux',
        '/install/windows': '/install/guide?platform=windows',
        '/install/windows/': '/install/guide?platform=windows',
        // 原技术支持及“帮我安装”页面 → 安装向导内对应章节
        '/support': '/install/guide#support',
        '/support/': '/install/guide#support',
        '/support/support': '/install/guide#support',
        '/support/support/': '/install/guide#support',
        '/install/help-install': '/install/guide#help-install',
        '/install/help-install/': '/install/guide#help-install',
        '/install/help-install-sub': '/install/guide#help-install',
        '/install/help-install-sub/': '/install/guide#help-install',
    };

    // 精确匹配
    if (pathMap[path]) {
        window.location.href = pathMap[path];
    } else {
        // 带锚点的旧安装页面也跳转（如 /install/os-docker#config）
        let pathname = window.location.pathname.replace(/\/$/, '');
        if (pathMap[pathname]) {
            window.location.href = pathMap[pathname];
        }
    }
}

// 百度统计
var _hmt = _hmt || [];
(function() {
    var hm = document.createElement("script");
    hm.src = "https://hm.baidu.com/hm.js?e73e6c1d4f6b625ef90d78262c28cbb1";
    var s = document.getElementsByTagName("script")[0];
    s.parentNode.insertBefore(hm, s);
})();
