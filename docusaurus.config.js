// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require('prism-react-renderer').themes.github;
const darkCodeTheme = require('prism-react-renderer').themes.dracula;

/** @type {import('@docusaurus/types').Config} */
const config = {
    title: 'ZFile Docs',
    tagline: 'ZFile 在线云盘文档',
    url: 'https://docs.zfile.vip',
    baseUrl: '/',
    onBrokenLinks: 'throw',
    onBrokenMarkdownLinks: 'warn',
    favicon: 'img/favicon.ico',
    organizationName: 'zfile-dev', // Usually your GitHub org/user name.
    projectName: 'zfile', // Usually your repo name.
    i18n: {
        defaultLocale: "zh-Hans",
        locales: ["zh-Hans"],
    },
    scripts: [{
        src: '/script/script.js', async: true,
    }, {
        src: 'https://cdn.wwads.cn/js/makemoney.js'
    }, {
        src: '/script/ad.js'
    }],
    presets: [
        [
            'classic',
            /** @type {import('@docusaurus/preset-classic').Options} */
            ({
                docs: {
                    sidebarPath: require.resolve('./sidebars.js'),
                    // Please change this to your repo.
                    // Remove this to remove the "edit this page" links.
                    routeBasePath: "/",
                    showLastUpdateTime: true,
                    showLastUpdateAuthor: true,
                    editUrl: 'https://github.com/zfile-dev/docs',
                },
                blog: false,
                theme: {
                    customCss: require.resolve('./src/css/custom.css'),
                },
                sitemap: {
                    changefreq: "weekly",
                    priority: 0.5,
                },
            }),
        ],
    ],
    plugins: ['docusaurus-tailwindcss-loader', 'docusaurus-plugin-image-zoom'],
    themes: ['@docusaurus/theme-live-codeblock', [
        require.resolve("@easyops-cn/docusaurus-search-local"),
        {
            // ... Your options.
            // `hashed` is recommended as long-term-cache of index file is possible.
            hashed: true,
            indexBlog: false,
            language: ["en", "zh"],
            docsRouteBasePath: '/',
            highlightSearchTermsOnTargetPage: true,
            explicitSearchResultPath: true,
        }
    ]
    ],
    themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
        ({
            zoom: {
                selector: '.markdown img',
                background: {
                    light: 'rgb(255, 255, 255)',
                    dark: 'rgb(50, 50, 50)'
                },
                // options you can specify via https://github.com/francoischalifour/medium-zoom#usage
                config: {}
            },
            docs: {
                sidebar: {
                    hideable: true,
                    autoCollapseCategories: true,
                },
            },
            colorMode: {
                disableSwitch: false,
                respectPrefersColorScheme: true,
            },
            navbar: {
                title: 'ZFile',
                logo: {
                    alt: 'ZFile',
                    src: 'img/zfile.svg',
                },
                items: [
                    {
                        href: "https://zfile.vip",
                        label: "官网",
                    },
                    {
                        "label": "演示站",
                        "href": "https://demo.zfile.vip"
                    },
                    {
                        type: "dropdown",
                        label: "QQ 交流群",
                        items: [
                            {
                                "label": "QQ 交流群(1群已满)",
                                "href": "https://jq.qq.com/?_wv=1027&k=7f4iEaje"
                            },
                            {
                                "label": "QQ 交流群(2群)",
                                "href": "https://qm.qq.com/cgi-bin/qm/qr?k=JJcfuIVYiPJ5GDa5_gm8UFLrgWwC9ptD&jump_from=webapi&authKey=dSdYtP2MZxQuTF+Z0+XhWuARuVFUhmoRWWUYRa8/JHLZ8H8bqPzLdabkOc7l5eO8"
                            },
                        ]
                    },
                    {
                        "label": "服务器推荐✨",
                        "href": "/ad/"
                    },
                    {
                        "label": "技术支持",
                        "href": "/support/"
                    },
                    {
                        href: 'https://github.com/zfile-dev/zfile',
                        position: 'right',
                        className: 'header-github-link'
                    }
                ]
            },
            footer: {
                style: 'dark',
                links: [
                    {
                        title: '关于',
                        items: [
                            {
                                label: '官网',
                                to: 'https://zfile.vip',
                            },
                            {
                                label: 'Github (后端)',
                                to: 'https://github.com/zfile-dev/zfile',
                            },
                            {
                                label: 'Github (前端)',
                                to: 'https://github.com/zfile-dev/zfile-vue',
                            },
                            {
                                label: 'Github (文档)',
                                to: 'https://github.com/zfile-dev/docs',
                            }
                        ],
                    },
                    {
                        title: '社区',
                        items: [
                            {
                                label: 'QQ 群',
                                href: 'https://jq.qq.com/?_wv=1027&k=7f4iEaje',
                            },
                            {
                                label: 'Github Issues',
                                href: 'https://github.com/zfile-dev/zfile/issues',
                            },
                        ],
                    }
                ],
                copyright: `Copyright © ${new Date().getFullYear()} ZFile, Inc. Built with Docusaurus.`,
            },
            prism: {
                theme: lightCodeTheme,
                darkTheme: darkCodeTheme,
                additionalLanguages: ['bash', 'properties'],
                magicComments: [
                    // 要记得复制默认的高亮类！
                    {
                        className: 'theme-code-block-highlighted-line',
                        line: 'highlight-next-line',
                        block: {start: 'highlight-start', end: 'highlight-end'},
                    },
                    {
                        className: 'code-block-primary-line',
                        line: 'highlight blue next',
                    },
                    {
                        className: 'code-block-warning-line',
                        line: 'highlight yellow next',
                    },
                ]
            },
        }),
};

module.exports = config;
