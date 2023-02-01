// 兼容旧版文档相关链接进行跳转
let hash = window.location.hash;


let hashMap = {
    '#/question?id=reset-pwd': '/config/config-debug',
    '#/advanced?id=onedrive-cf': 'advanced/cf-worker',
    '#/example': '/example',
    '#/pro': '/install/pro-linux',
}

if (hashMap[hash]) {
    window.location.href = hashMap[hash];
}

let path = window.location.href.replace(window.location.origin, "");

let pathMap = {
    '/advanced#only-office': '/advanced/only-office',
    '/advanced#google-drive-api': '/advanced/google-drive-api',

}

if (pathMap[path]) {
    debugger
    window.location.href = pathMap[path];
}


// 百度统计
var _hmt = _hmt || [];
(function() {
    var hm = document.createElement("script");
    hm.src = "https://hm.baidu.com/hm.js?e73e6c1d4f6b625ef90d78262c28cbb1";
    var s = document.getElementsByTagName("script")[0];
    s.parentNode.insertBefore(hm, s);
})();