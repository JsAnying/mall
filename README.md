# 二手闲置交易平台 Web 基础工程

Vue 3（Composition API / `<script setup>`）+ Vite + Element Plus + Pinia + Axios + Vue Router 4。

后端对接见 [REST API 接口文档](docs/backend-api.md)，包含已接入认证接口约定与待实现的商品、图片、订单、分类和反馈接口设计。

本地 IDE 创建后端、依赖、MySQL、JWT 配置与启动验证见 [Spring Boot 建项目步骤](docs/backend-setup.md)。

界面结构、交互状态和尼尔森十项原则的落地验收见 [可用性设计规范](docs/usability-design.md)。登录/注册有内联错误恢复，发布支持本机草稿与预览，交易和订单服务仍待后端开放。

## 启动与验证

Node.js 20.19+ 或 22.12+（推荐使用当前 LTS）。当前目录已经包含完整工程，无需再次运行脚手架。

```powershell
cd E:\shop
npm install
npm run dev
```

在 Windows PowerShell 的脚本策略限制 npm.ps1 时，可以使用 `npm.cmd` 替换 `npm`。

```bash
npm run test
npm run build
npm run preview
```

如果需要从其他空目录重新创建工程，等价的依赖安装命令为：

```bash
npm create vite@latest secondhand-market-web -- --template vue
cd secondhand-market-web
npm install
npm install element-plus pinia axios vue-router@4
npm install -D vitest
```

## 目录职责

```text
shop/
├── src/
│   ├── assets/main.css           # 全局样式与静态资源
│   ├── components/AppHeader.vue  # 公共组件
│   ├── views/                    # 页面：主页、登录、注册、详情、发布、订单、404
│   ├── api/user.js               # 按业务封装接口，路径不重复写 /api
│   ├── router/index.js           # 懒加载路由、登录守卫
│   ├── stores/
│   │   ├── index.js              # 共享 Pinia 实例
│   │   └── user.js               # token、userInfo、login/logout
│   ├── utils/
│   │   ├── auth.js               # 持久化与回跳路径校验
│   │   └── request.js            # Axios 与统一错误处理
│   ├── App.vue
│   └── main.js                   # 注册组件库、路由、Pinia 与 401 处理
├── .env.example
├── index.html
├── vite.config.js
├── package.json
└── package-lock.json             # 固定实际安装版本，CI 可使用 npm ci
```

这里统一采用 `stores/`（即需求中 store 目录的复数形式）。新增接口建议按业务拆分为 `api/goods.js`、`api/orders.js`。

## 请求约定

Axios 使用 `baseURL: '/api'`、15 秒超时，从持久化状态读取 Token 并发送 `Authorization: Bearer <token>`。普通 JSON 直接返回响应体；有 `code` 字段时按统一业务格式处理，成功只返回 `data`：

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "token": "后端签发的 Token",
    "userInfo": { "id": 1, "username": "demo", "nickname": "小闲" }
  }
}
```

约定 `code` 为 `0` 或 `200` 表示成功（兼容对应字符串），其他值表示失败。失败会弹出 Element Plus 提示并 reject；HTTP 401 或业务码 401 清除用户状态并跳转登录，保留当前路径。并发 401 在失效处理期间合并提示和跳转。取消请求不弹错误。

`main.js` 注入失效处理函数，使请求层无需依赖路由或 store。登录和注册接口设置 `skipAuth: true` 与 `authFailureRedirect: false`，凭据错误只提示，不触发跳转。

调用示例：

```js
import request from '@/utils/request.js'

// 返回已经解包的 data，无需再读取 response.data
const goods = await request.get('/goods', { params: { page: 1, size: 20 } })
```

后端待实现的认证接口：

| 方法 | 地址 | 请求体 | 成功 data |
| --- | --- | --- | --- |
| POST | `/api/auth/login` | `{ username, password }` | `{ token, userInfo }` |
| POST | `/api/auth/register` | `{ username, password }` | 按后端约定，页面无需读取 |

登录注册表单已接入这些接口，后端尚未运行时会显示请求失败。首页与商品详情采用本地 Mock 商品；发布和订单页面仍为骨架，没有模拟交易或虚构登录。注册密码至少 6 位只是前端初始规则，最终需与后端校验对齐。

## 首页 UI 与离线 Mock

暖白背景、砖红强调色、1200px 居中容器、摄影主视觉、四个精选频道、轻量浮动操作栏与四列商品流。平板切换三列、手机切换两列；CSS 使用 scoped 样式，支持键盘焦点与减少动画偏好。

- `src/data/market.js`：8 个分类、7 个热搜、4 个频道、15 件完整 Mock 商品及筛选函数。
- `src/components/ProductVisual.vue`：优先展示 `public/images/` 的本地摄影风格素材，缺少素材或加载失败时回退到 `ProductArt.vue` 的 SVG 插画，不加载远程图片、字体或 API。素材来源与提示词见 [视觉素材说明](docs/visual-assets.md)。
- `src/components/GoodsCard.vue`：成色、价格、卖家和悬停动效。
- `src/components/FloatingDock.vue`：发布、消息、手机端说明、反馈与回到顶部。
- `src/components/CategoryNav.vue`：悬停分类时在右侧展开分组商品类型；支持键盘焦点、Escape 关闭和触屏点击，小屏面板显示在分类下方。
- `src/data/categoryTypes.js`：8 个一级分类的商品类型数据；点击类型使用 URL 的 `type` 参数筛选商品，暂无对应 Mock 商品的类型显示空态。

搜索和分类状态保存在 URL 的 `q` / `category` 参数中，支持刷新和浏览器前进/后退。频道与商品卡片可进入本地详情页。反馈仅存入本机 localStorage，消息为待接入空态；发布、订单保留真实登录守卫。Mock 商品详情以展示为目的，不执行交易。

`login(credentials)` 请求成功后存入状态和 localStorage；`logout()` 清除本地登录态。后续如采用服务端 Token 撤销或 refresh token，需要补充退出/刷新接口。路由守卫只控制前端访问，Spring Boot 必须再次校验身份和资源权限。

## 路由

| 路径 | 页面 | 登录要求 |
| --- | --- | --- |
| `/` | 首页/商品列表 | 否 |
| `/login` | 登录 | 否 |
| `/register` | 注册 | 否 |
| `/goods/:id` | 商品详情，ID 通过 props 传入 | 否 |
| `/publish` | 发布闲置，`?id=123` 预留编辑入口 | 是 |
| `/user/orders` | 买入/卖出订单 | 是 |
| 其他 | 404 | 否 |

未登录进入受保护页面会跳转 `/login?redirect=原路径`，登录完成校验回跳地址后返回。

## Spring Boot 代理与部署

开发服务器把 `/api/**` 代理至 `http://localhost:8080`，保留 `/api` 前缀。如需修改目标，复制 `.env.example` 为 `.env.local`，修改 `VITE_API_TARGET` 并重启 Vite。后端若没有 `/api` 前缀，可在代理中添加 `rewrite: path => path.replace(/^\/api/, '')`。

生产构建输出到 `dist/`。Vite 开发代理不用于生产；生产服务器需要将 `/api/**` 反向代理至 Spring Boot，并为前端非 API 路由配置 history fallback 到 `index.html`，以支持详情和订单页面刷新。

参考：[Vite 入门](https://vite.dev/guide/)、[Element Plus 安装](https://element-plus.org/en-US/guide/installation.html)、[Pinia 入门](https://pinia.vuejs.org/getting-started)。
