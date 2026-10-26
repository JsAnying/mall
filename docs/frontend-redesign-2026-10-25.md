# 前端重构与技能安装记录

日期：2026-10-25（北京时间）。用户确认本次优先目标为“更快找到商品：商品、搜索和分类优先”。

## 安装的技能

| 仓库 | 实际技能名及位置 | 状态 |
| --- | --- | --- |
| [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | C:/Users/com/.codex/skills/design-taste-frontend | 官方 skill-installer 脚本通过 Git 稀疏检出安装，SKILL.md、references、scripts、library、assets 均存在 |
| [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | C:/Users/com/.codex/skills/impeccable | 官方 skill-installer 脚本安装 .agents/skills/impeccable，技能版本 4.7.1，reference、scripts、agents 均存在 |

技能文件下轮可自动识别；本轮直接阅读安装后的文件应用规则。Impeccable 的 context 和 concept-seed 启动器均无法下载 Windows 引擎 0.1.17，退出 1；因此没有生成该引擎的方向卡或检测报告，也没有安装自动设计 hook。已依照其文档提供的降级流程直接读取项目、确认用户目标、应用 craft-floor/operate 规范，并进行独立审查。Taste 的脚本能够正常运行。

## 设计与实现

采用 Taste 的 framed-sheet，seed 1103829787：浅绿灰外框、白色内容区、深绿价格与当前操作，保留已有中文字体栈。现有个人闲置图片是主体，界面围绕检索和比较商品展开。没有迁移框架、添加依赖、改动后端业务或覆盖用户原有未提交的接口相关工作。

- 首页压缩品牌宣传，商品列表提前；兴趣频道保留在商品之后。
- 页头合并搜索、账号、订单与发布入口；分类在桌面侧栏，手机横向入口可展开全部类型。
- CSS Grid 直接渲染商品源顺序，4/3/2 列随宽度切换，避免原先按列重分组造成视觉和键盘顺序不同。
- 商品卡突出价格、成色、城市，统一字号和对比度；浮动工具栏改为页尾快捷操作，手机商品不再被浮层遮住。
- 登录/注册、详情、发布和订单统一使用同一套颜色、边距、表单及状态样式。
- 用户名在提交校验前 trim；全空白密码在前端阻止；密码本身不 trim。规则通过 aria-describedby 关联输入框。
- 账号页及帮助纠正了“注册未开放”的旧提示，明确注册已开放、登录暂未开放。
- 分类浮层保留鼠标悬停，同时修复 hover 后点击反而关闭、触摸设备被 mouseleave 意外关闭的问题；Esc 关闭后恢复触发按钮焦点。
- 样式常量集中在 src/assets/main.css，清理大量 body 高优先级覆盖；保留减少动态效果偏好和既有图片失败回退。

产品事实见 [PRODUCT.md](../PRODUCT.md)，方向约束见 [.impeccable/surfaces/storefront.md](../.impeccable/surfaces/storefront.md)。独立文档整理已完成 [DESIGN.md](../DESIGN.md) 与 [.impeccable/design.json](../.impeccable/design.json)：包括与源码一致的颜色、字体、圆角、间距及组件规范，sidecar 为 schemaVersion 2；这一步只做文档和静态一致性核对，没有新增浏览器/业务测试。

## 实际验证

| 检查 | 实际结果 |
| --- | --- |
| npm.cmd test | 重构前后均为 4 个文件、18 项通过 |
| npm.cmd run build | 生产构建通过；保留已有 Element Plus 主包大于 500 kB 的警告，本轮未更换组件库或分包策略 |
| Taste 生产源码 lint | 29 个非测试源码文件，0 FAIL、2 WARN；两处阴影仅用于搜索下拉与分类浮层，属于浮层层级 |
| Taste 生产页面 inspect | 1440/768/390 像素，0 FAIL、1 WARN；390px 辅助副行文字 12px 较多，标题 14px、价格 22px，最低 11px，保留此提示而不隐藏检测 |
| Chromium 生产预览交互检查 | 80 个断言通过，0 失败；截图覆盖 19 个页面/状态；截取时等待图片和字体完成加载 |
| git diff --check | 通过；Git 提示现有 LF/CRLF 转换，不是格式错误 |

源码 lint 的全 src 初次尝试把既有单测中的 example.com 当作占位内容；最终范围明确为生产源码，不为消除误报修改用户测试。

### 交互检查范围

- 桌面、平板和手机的商品顺序、分类菜单、类型选择与 URL；页面无横向溢出或 JavaScript 未捕获异常。
- 价格升降序、空搜索、清除与撤销筛选、搜索历史清除与恢复。
- 商品详情进入、返回后筛选保持，键盘 Enter 展开分类、Esc 关闭并恢复焦点。
- 未登录时发布/订单守卫保留；注册空值/空白密码阻止请求，用户名 trim、密码保持原值。
- 注册 409 在表单中展示且保留输入；200 转到登录页并说明登录尚未开放。
- 隔离浏览器会话中的草稿保存、重载恢复、清除/撤销；订单买卖页签与 URL 同步。
- 手机帮助抽屉、反馈本机保存/撤销，以及缺失商品、未知页面等状态。

### 首屏与边距测量

| 视口 | 首件商品距页面顶部 | 首件价格距页面顶部 | 左/右外边距 |
| --- | --- | --- | --- |
| 1440×900 | 582px | 869px | 80 / 80px |
| 768×1024 | 456px | 723px | 24 / 24px |
| 390×844 | 407px | 614px | 16 / 16px |

重构前桌面和手机的首屏主要为导航/分类/宣传，未显示实际商品卡；重构后均能在首屏开始比较商品。

本机生产预览：http://127.0.0.1:4173/；开发服务：http://127.0.0.1:5173/（/api 仍代理到 8080）。生产预览用于静态构建验收，真实接口联调使用开发服务。

## 证据与边界

本机证据保存在 .taste-skill/before/、.taste-skill/after/、.taste-skill/checks/ui-results.json 以及 .impeccable/review/，已排除运行截图和临时检查脚本的 Git 跟踪。根目录的设计规范和方向文件供后续维护。

本轮注册交互测试拦截网络，以 200/409 测试响应验证前端分支，没有新增真实 MySQL 账号。发布和订单截图/操作采用隔离浏览器的本机测试会话，没有实现或验证真实登录授权。此前后端真实 MySQL 24 个 HTTP 场景的验收与本轮 UI 测试是独立结论。没有真实交易、图片上传或正式发布。

未新增、下载或生成图片；保留现有本地商品素材与缺图回退，不把示例图片或示例价格声明为真实在售。

## 独立审查

独立 finish-reviewer 查看 19 张截图并复核源码、方向约束与断言范围，结论为 **ship**，没有 material fixes。手机辅助字号 WARN 被判定为非阻断项，仍如实保留。详细结论见 [.impeccable/critique/storefront-2026-10-25.md](../.impeccable/critique/storefront-2026-10-25.md)。设计规范整理是另一独立步骤，不把整理文档等同于新增视觉检测。
