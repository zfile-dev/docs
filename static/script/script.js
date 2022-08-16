// 兼容旧版文档相关链接进行跳转
let hash = window.location.hash;

let map = {
    '#/question?id=reset-pwd': '/question#reset-pwd',
    '#/advanced?id=onedrive-cf': '/advanced#onedrive-cf',
    '#/example': '/example',
    '#/pro': '/install/pro-linux',
}

if (map[hash]) {
    window.location.href = map[hash];
}

// 百度统计
var _hmt = _hmt || [];
(function() {
    var hm = document.createElement("script");
    hm.src = "https://hm.baidu.com/hm.js?e73e6c1d4f6b625ef90d78262c28cbb1";
    var s = document.getElementsByTagName("script")[0];
    s.parentNode.insertBefore(hm, s);
})();