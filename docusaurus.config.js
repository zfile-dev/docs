// @ts-check
// Note: type annotations allow type checking and IDEs autocompletion

const lightCodeTheme = require('prism-react-renderer/themes/github');
const darkCodeTheme = require('prism-react-renderer/themes/dracula');

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
  themes: [
    [
      require.resolve("@easyops-cn/docusaurus-search-local"),
      {
        // `hashed` is recommended as long-term-cache of index file is possible.
        hashed: true,
        docsRouteBasePath: '/',
        // For Docs using Chinese, The `language` is recommended to set to:
        language: ["zh"],
      },
    ],
  ],
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

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
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
            href: "https://bbs.zfile.vip",
            label: "论坛",
          },
          {
            href: "https://github.com/zfile-dev/zfile",
            label: "GitHub",
            position: "right",
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
                label: '论坛',
                href: 'https://bbs.zfile.vip/',
              },
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
      },
    }),
};

module.exports = config;
