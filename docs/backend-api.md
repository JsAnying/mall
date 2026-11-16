# 拾光闲置 · 后端 REST API 对接文档

版本 v1.7 · 商品售价与浏览量契约更新于 2026-11-09（北京时间）。

本文对照 `E:/shop` 前端和 `E:/shiguang-server/market` 后端源码维护。后端使用 Java 17、Spring Boot 3、MyBatis-Plus，根包 `com.zhf.mall`。当前已实现的业务接口包括注册、登录、退出、查询资料、修改资料、上传头像、读取头像、分类目录、首页推荐、商品列表和个人中心概览。文中的“已实现”指存在对应源码，标为“规划”的接口待开发。

账号与资料使用 MySQL `user`（用户表）；JWT 校验与退出撤销使用 `revoked_token`（令牌撤销表）；头像二进制保存在 `user_avatar`（头像文件表）。相关脚本为 [用户表](../../shiguang-server/market/sql/01-user-schema.sql)、[撤销表](../../shiguang-server/market/sql/03-revoked-token.sql)、[头像表及用户头像字段](../../shiguang-server/market/sql/04-user-avatar.sql)。新环境需先确认这些表和字段已准备好。旧市场业务表见 [SQL 说明](sql/README.md)，存在表或实体不等于对应接口已实现。

Redis 目前只有依赖和连接配置，业务代码未使用 Redis：Token 撤销、头像存储均仍走 MySQL，分类和首页也没有 Redis 缓存。

2026-11-08 开发库已统一账号外键。商品的 `goods.seller_id`（商品表的卖家标识）、订单的 `orders.buyer_id`（订单表的买家标识）和 `orders.seller_id`（订单表的卖家标识）等账号引用均指向 `user.id`（用户表的用户主键）。`users`（旧用户表）已删除。商品和订单接口的实现状态见下方接口清单。

## 0. 当前页面实际调用了什么

| 当前界面功能 | 当前实现 | 后端对接要求 |
| --- | --- | --- |
| 登录/注册 | 已调用 POST /auth/login、POST /auth/register | 登录保存 Token；注册成功后进入登录页，不自动登录 |
| 点击顶部用户名 | 进入 `/user/profile`，默认显示「我的拾光」，调用 `GET /users/me` | 头像、昵称、账号取自当前用户资料。会话失效时返回登录页，其余读取错误可重试 |
| 个人中心的宝贝、信用及评价 | 商品和评价是单独标注的展示示例，名片标明信用和关注数据待开放 | 真实宝贝、名片摘要、评价接口见第 3.1 节 |
| 个人中心的交易、收藏与账号安全 | 交易入口展示服务状态并链接发布页或订单页。收藏读取本机示例商品，账号安全显示只读账号 | 发布、订单和收藏查询待开发。安全设置尚未开放 |
| 保存个人资料 | 名片「编辑资料」和「账户设置 → 个人资料」进入同一表单，调用 `PATCH /users/me` | 保存成功后返回个人主页，用响应同步名片的头像、昵称与页头显示名 |
| 更换头像 | 选图先本地预览，点击保存时 POST /users/me/avatar，再 PATCH /users/me | 上传与设置头像是两步；图片通过 GET /media/avatars/{id} 显示 |
| 退出 | 仅清除本地 Token、资料并回到首页 | 后端 POST /auth/logout 已实现，但前端尚未调用，旧 Token 不会因本地退出而被撤销 |
| 首页首屏 | 分类目录、搜索框下的热搜和竖版 Banner 来自接口；四个频道卡及卡内商品取自前端示例 | GET /categories 和 GET /home/recommendations 已接入；频道无独立接口 |
| 首页全宽商品流 | 胶囊标签和搜索关键词筛选本地示例，卡片显示售价、地点和浏览量 | GET /goods 已实现，前端待接入；映射 `q`（搜索关键词）/`category`（前端分类选项）/`type`（前端商品类型），接入后用分页 `total`（匹配记录总数）显示总件数 |
| 分类商品页 | `/browse` 读取分类目录并在本地按分类、分组、类型筛选商品，页内支持价格排序 | GET /goods 已实现，前端待接入；分类目录使用 GET /categories |
| 最近搜索 | 浏览器保存搜索历史，可清空及撤销清空 | 无需后端接口 |
| 保存/恢复/清除草稿 | 当前用户在本浏览器的 localStorage | 不调用 POST /goods；跨设备草稿未纳入本版 |
| 发布信息预览 | 本地校验后打开预览弹窗，无上传图片 | 正式发布需完成图片上传、字段转换、版本处理与提交 |
| 商品详情 | `/goods/:id` 读取真实详情，示例卡片通过 `?demo=1` 保留本地展示 | GET /goods/{id} 已接入；游客点击交易或收藏入口后登录并回到原详情 |
| 我的订单 | `role=buy/sell`（交易角色为买入或卖出）保存在 URL，准确提示服务未开放 | GET /users/me/orders；失败不能显示“没有订单” |
| 反馈及撤销 | 只保存/撤销当前浏览器建议 | POST /feedback 待接入；当前撤销不涉及服务器 |
| 首页快捷工具栏 | 发闲置沿用发布入口，消息显示未开放提示，反馈仅保存到本机，客服打开使用帮助 | 无新增接口；消息、在线反馈及客服服务尚未接入 |
| 使用帮助/快捷键 | 前端静态说明 | 不需要后端接口 |

源码入口：[前端 API](../src/api/user.js)、[账号表单](../src/components/AccountForm.vue)、[个人中心](../src/views/ProfileView.vue)、[用户状态](../src/stores/user.js)、[账号 Controller](../../shiguang-server/market/src/main/java/com/zhf/mall/controller/UserController.java)、[个人资料 Controller](../../shiguang-server/market/src/main/java/com/zhf/mall/controller/ProfileController.java)。

## 1. 通用约定

| 项目 | 约定 |
| --- | --- |
| 开发地址 | `http://localhost:8080/api` |
| 前端请求前缀 | `/api`，Vite 保留前缀代理到 Spring Boot |
| 请求格式 | `application/json`；图片上传使用 `multipart/form-data` |
| 字符集 | UTF-8 |
| 鉴权 | 受保护接口使用 `Authorization: Bearer <token>`；后端校验签名、有效期和撤销状态 |
| ID | 商品、用户、订单、上传文件 ID 均使用 JSON 字符串，避免 Java Long 精度丢失 |
| 时间（规划业务） | ISO 8601 UTC，例如 `2026-10-06T10:00:00Z`；当前账号和资料响应没有时间字段 |
| 金额（规划业务） | 人民币元，JSON number，最多两位小数；后端使用 BigDecimal 或整数分存储/计算 |
| 分页（规划业务） | `page`（页码）从 1 开始，默认 1；`size`（每页条数）默认 20，范围 1～50；当前尚无分页接口 |
| 空结果（规划列表） | `records: []`（记录列表为空）、`total: 0`（总记录数为零），不返回 404 |
| 写操作用户身份 | 从 Token 获取，不能信任客户端传入的 `userId`（用户标识）、`sellerId`（卖家标识）或 `buyerId`（买家标识） |

JSON 接口成功使用 HTTP 200 和业务码 200，规划的创建与删除接口也沿用此约定。前端兼容成功业务码 0，但当前后端使用 200。**读取头像成功时直接返回图片二进制，不包裹 JSON。** 下文的 `data`（返回数据）指统一响应中的业务内容。

当前可匿名访问的业务接口包括注册、登录、GET 头像、GET 分类目录、GET 首页推荐、GET 商品列表和详情。其余路径默认要求认证。实现规划中的公开查询接口时，需同步配置 SecurityConfig。

只要请求带了 Authorization，JWT 过滤器就会校验，即使目标是公开接口。无效/过期/已撤销 Token 当前统一返回 401“请先登录”；查询撤销表发生数据库异常时返回 503。登录、注册、分类目录和首页推荐的前端请求使用 `skipAuth`，不会带旧 Token。

### 1.1 成功响应

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {}
}
```

**返回字段**　`code`（业务状态码）、`msg`（提示消息）、`data`（返回数据）。

无返回内容时使用 `data: null`（返回数据为空）。当前 `utils/request.js` 会直接返回 `data`（返回数据），业务页面无需再次读取 `response.data`（原始响应体）。

### 1.2 失败响应

```json
{
  "code": 409,
  "msg": "用户名已存在，请前往登录或更换用户名",
  "data": null
}
```

当前 Controller 的 JSON 成功响应、全局异常处理器和 JWT/未登录错误响应均使用 `code`（业务状态码）、`msg`（提示消息）、`data`（返回数据）三个字段，无数据时保留 `data: null`（返回数据为空）。`code`（业务状态码）与 HTTP 状态一致；`msg`（提示消息）为中文提示，无堆栈、SQL、密码、字段错误数组或额外业务标识。不要依赖中文提示判断业务分支。Spring Security 尚未配置统一的 AccessDeniedHandler，因此不能把所有过滤器级 403 都视为已保证此格式。

| HTTP / `code`（业务状态码） | 含义（包含规划业务） | 后端 ResultCode 枚举示例 |
| --- | --- | --- |
| 400 | 参数校验失败 | BAD_REQUEST、INVALID_JSON |
| 401 | 缺少、无效或过期 Token；登录凭据错误 | UNAUTHORIZED、TOKEN_EXPIRED、INVALID_CREDENTIALS |
| 403 | 无操作权限 | FORBIDDEN |
| 404 | 资源不存在或已删除 | NOT_FOUND、GOODS_NOT_FOUND、ORDER_NOT_FOUND |
| 405 | 请求方法不支持 | METHOD_NOT_ALLOWED |
| 406 | 请求的响应格式不支持 | NOT_ACCEPTABLE |
| 409 | 重复注册、商品抢购冲突、状态冲突 | USERNAME_EXISTS、GOODS_UNAVAILABLE、INVALID_STATE、IDEMPOTENCY_CONFLICT |
| 413 | 文件过大 | FILE_TOO_LARGE |
| 415 | 上传类型不支持 | UNSUPPORTED_FILE_TYPE |
| 429 | 请求过于频繁 | RATE_LIMITED |
| 500 | 服务内部错误 | INTERNAL_ERROR |
| 503 | 账号/交易等服务暂不可用 | SERVICE_UNAVAILABLE |

HTTP 401 会使前端清除登录态并跳转登录。登录、注册请求已设置例外，凭据错误只提示，不跳转。资源权限错误应返回 403，不能用 401 代替。

表中枚举存在不代表业务已实现。例如商品/订单冲突和限流仅有预留枚举；当前头像的大小、格式和归属校验返回 400，不能按枚举名称推断为 413/415/403。只有超出框架 multipart 限制时才可能先返回 413。数据库资源或暂时性故障由全局处理器返回 503，其他未预期异常返回 500；不是所有数据库异常都会返回 503。

登录/注册设置 inlineError，由表单持续显示 `msg`（提示消息）与重试操作，不额外弹相同错误 toast。取消等待用 AbortSignal 中止客户端请求，不提示为网络故障；服务端可能已经完成注册，不能据此宣称“注册已撤销”。用户名唯一约束保证重试不会重复创建同一账号，重复注册时提示前往登录。

### 1.3 分页响应 `data`（返回数据）

```json
{
  "records": [],
  "page": 1,
  "size": 20,
  "total": 0,
  "pages": 0
}
```

**分页字段**　`records`（当前页记录）、`page`（页码）、`size`（每页条数）、`total`（匹配记录总数）、`pages`（总页数）。

排序需要稳定：同一排序值相同时以 ID 排序。分页数据在并发发布、成交时可能变化，前端按 ID 去重。

## 2. 接口总览

完整地址是在下表路径前加 `/api` 前缀，例如 `/api/auth/login`。“鉴权”一列对未实现接口表示规划要求，当前安全配置见第 1 节。

| 模块 | 方法 | 路径 | 鉴权 | 后端状态 | 用途 / 当前前端状态 |
| --- | --- | --- | --- | --- | --- |
| 认证 | POST | `/auth/register` | 否 | 已实现 | 创建账号；注册表单已调用 |
| 认证 | POST | `/auth/login` | 否 | 已实现 | 返回 Token 和 `userInfo`（基础用户资料）；登录表单已调用 |
| 认证 | POST | `/auth/logout` | 是 | 已实现 | 撤销当前 Token；退出按钮未调用 |
| 用户 | GET | `/users/me` | 是 | 已实现 | 获取个人资料；个人中心已调用 |
| 用户 | PATCH | `/users/me` | 是 | 已实现 | 修改昵称、头像；保存资料已调用 |
| 用户 | POST | `/users/me/avatar` | 是 | 已实现 | 上传个人头像；保存选中的头像时调用 |
| 用户 | GET | `/media/avatars/{id}` | 否 | 已实现 | 返回头像图片；img 标签加载 |
| 用户 | GET | `/users/me/overview` | 是 | 已实现、前端待接入 | 名片地区、粉丝数、关注数和信用标签；信用规则未实现，标签为 null |
| 评价 | GET | `/users/me/reviews` | 是 | 规划 | 个人主页「信用及评价」列表和总数 |
| 分类 | GET | `/categories` | 否 | 已实现、已接入 | 首页分类菜单和分类商品页使用；发布表单仍用本地选项 |
| 首页 | GET | `/home/recommendations` | 否 | 已实现、已接入 | 提供热搜和 Banner 内容 |
| 商品 | GET | `/goods` | 否 | 已实现 | 首页商品流和分类商品页；前端目前读取本地示例 |
| 商品 | GET | `/goods/{id}` | 可选 | 已实现、已接入 | 商品详情、多图、卖家摘要及登录用户的收藏状态 |
| 商品 | POST | `/goods` | 是 | 未实现 | 正式发布；当前只有本机草稿和预览 |
| 商品 | PUT | `/goods/{id}` | 是 | 未实现 | 修改已发布商品；当前只有本地预填和草稿 |
| 商品 | PATCH | `/goods/{id}/status` | 是 | 未实现 | 上下架；暂无操作入口 |
| 商品 | DELETE | `/goods/{id}` | 是 | 未实现 | 软删除商品；暂无操作入口 |
| 商品 | GET | `/users/me/goods` | 是 | 未实现 | 「宝贝」展示和「我发布的」管理列表 |
| 卖家 | GET | `/users/{id}` | 否 | 未实现 | 个人主页读取卖家公开资料 |
| 购物车 | PUT | `/users/me/cart/items/{goodsId}` | 是 | 未实现 | 将闲置商品加入当前用户的购物车 |
| 收藏 | GET | `/users/me/favorites` | 是 | 规划 | 当前账号的收藏列表，替代本机示例收藏 |
| 收藏 | PUT / DELETE | `/users/me/favorites/{goodsId}` | 是 | 未实现 | 收藏或取消收藏商品 |
| 图片 | POST | `/uploads/images` | 是 | 未实现 | 通用商品图片/头像上传规划；当前头像走专用接口 |
| 订单 | POST | `/orders` | 是 | 未实现 | 详情页“立即购买”确认后创建订单 |
| 订单 | GET | `/users/me/orders` | 是 | 未实现 | 个人中心买入、卖出记录与订单页 |
| 订单 | GET | `/orders/{id}` | 是 | 未实现 | 订单详情；暂无详情页 |
| 订单 | POST | `/orders/{id}/confirm` | 是 | 未实现 | 卖家确认交易；暂无操作入口 |
| 订单 | POST | `/orders/{id}/complete` | 是 | 未实现 | 买家确认完成；暂无操作入口 |
| 订单 | POST | `/orders/{id}/cancel` | 是 | 未实现 | 取消待确认订单；暂无操作入口 |
| 反馈 | POST | `/feedback` | 是 | 未实现 | 在线提交反馈；目前仅保存本机 |
| 开发验证 | GET | `/health` | 否 | 未实现，仅教程示例 | 判断服务是否可访问；前端不调用 |

消息聊天、支付、物流、退款和实名认证不在本版接口范围内，需要另行定义业务流程后扩展。

## 3. 注册、登录与用户（已实现）

### POST `/auth/register`

**用途与页面：** 创建新账号。用户在 `/register` 点击“注册账号”时调用；此接口只创建账号，不签发 Token，也不登录。无需鉴权。

```json
{ "username": "xiaolin", "password": "example123" }
```

| 字段 | 类型 | 必填 | 校验 |
| --- | --- | --- | --- |
| `username`（用户名） | `string`（字符串） | 是 | 去除首尾空白，3～32 位字母、数字或下划线；唯一性由数据库约束保证，项目建表排序规则不区分大小写 |
| `password`（密码） | `string`（字符串） | 是 | 必须非空白，6～64 位，UTF-8 编码不超过 72 字节，不自动 trim；只将 BCrypt 哈希存入 `user.password_hash`（密码哈希） |

当前 AccountForm 已校验用户名格式、密码 6～64 位、UTF-8 最多 72 字节及两次密码一致。确认密码仅前端使用，不发送到接口。后端仍需独立校验；BCrypt 不能静默截断超过 72 字节的密码。长度上限按前端 JS string.length / Java String.length 保持一致，UTF-8 字节数另行检查。

成功 `data`（返回数据）：

```json
{ "id": "10001", "username": "xiaolin" }
```

**返回字段**　`id`（新用户标识）、`username`（登录用户名）。

注册后不自动登录，前端转到登录页。重复用户名返回 409 / USERNAME_EXISTS。

**常见失败：** 参数格式不正确为 400；用户名已存在为 409。注册时新用户昵称初始化为用户名，响应不返回密码哈希、昵称或头像。

### POST `/auth/login`

**用途与页面：** 验证账号密码，领取后续受保护接口需要的 Token。用户在 `/login` 点击“登录并继续”时调用。无需鉴权。

请求体与注册相同。当前复用注册 DTO，用户名先去除首尾空白；密码不 trim，遵循注册字段校验。账号不存在和密码错误均返回 401，但当前提示文字不同。

成功返回三字段响应，`data`（返回数据）如下：

```json
{ "token": "server-issued-access-token", "userInfo": { "id": "10001", "username": "xiaolin" } }
```

**返回字段**　`token`（登录凭证）、`userInfo`（基础用户资料）。`userInfo.id`（用户标识）和 `userInfo.username`（用户名）来自 `user.id`（用户主键）和 `user.username`（登录用户名）。

JWT 包含 `sub`（用户名）、唯一 `jti`（令牌唯一标识）和 `exp`（过期时间），源码配置有效期为 2 小时，实际以运行配置为准。响应没有 `expiresIn`（有效时长）、`refreshToken`（刷新令牌）；当前也没有刷新 Token 接口。前端保存 `market_token` 和 `market_user`，然后跳回站内 redirect 指定页面，未指定则回首页。

**注意资料差别：** 登录的 `userInfo`（基础用户资料）仅有 `id`（用户标识）、`username`（用户名）；没有 `nickname`（昵称）、`avatarUrl`（头像地址）。个人中心调用 `GET /users/me` 后才取得完整资料并更新本地缓存，不应把两种响应当成相同字段集合。

**常见失败：** 参数校验 400；账号不存在 401“用户名或密码错误”；密码不匹配 401“密码错误”。

### POST `/auth/logout`

**用途与页面：** 让当前登录凭证立即失效，供“退出”按钮调用。后端已实现，但目前前端 `user.logout()` 只清除本地状态，未发送此请求。

携带 Bearer Token，无请求体。后端从验证后的 JWT 获取 `jti`（令牌唯一标识）、`exp`（令牌过期时间），写入 MySQL 的 `revoked_token`（令牌撤销表）。其中 `jti`（令牌唯一标识）对应 `revoked_token.jti`（撤销的令牌标识），`exp`（令牌过期时间）转换后对应 `revoked_token.expires_at`（过期时间），`revoked_token.created_at`（撤销记录写入时间）由服务端填写。成功返回：

```json
{ "code": 200, "msg": "操作成功", "data": null }
```

只撤销本次请求的 Token，不会退出该账号的其他设备。正常重复请求会被过滤器判定为已撤销并返回 401；Service 对并发写入同一 `jti`（令牌唯一标识）的主键冲突视为成功，并不表示 HTTP 层重复退出一定返回 200。无效、过期、缺少或已撤销 Token 返回 401；数据库写失败不返回成功。

### GET `/users/me`

**用途与页面：** 查询“我是谁、昵称和头像是什么”。登录后点击顶部用户名进入 `/user/profile`，页面加载或点击“重新加载”时调用。需要 Bearer Token，无参数；用户身份来自 Token，不传 `userId`（用户标识）。

成功 `data`（返回数据）为当前用户资料，不包含密码或私密联系方式：

```json
{ "id": "10001", "username": "xiaolin", "nickname": "小林", "avatarUrl": null }
```

**返回字段**　`id`（用户标识）、`username`（用户名）、`nickname`（昵称）、`avatarUrl`（头像地址）。其中 `nickname`（昵称）读取 `user.nickname`（用户昵称），`avatarUrl`（头像地址）根据 `user.avatar_file_id`（当前头像文件标识）生成。

`avatarUrl`（头像地址）没有头像时为 `null`，有头像时为 `/api/media/avatars/{id}`。响应没有 `avatarFileId`（头像文件标识）、`createdAt`（创建时间）或 `updatedAt`（最后更新时间）。个人中心据此显示名片、填充编辑表单并同步本地缓存。昵称为空时，名片以用户名作为显示名。Token 无效或对应用户不存在返回 401。

### PATCH `/users/me`

**用途与页面：** 保存当前用户的昵称和头像。个人中心点击“保存资料”时调用；只修改资料，不修改登录用户名或密码。需要 Bearer Token。

```json
{ "nickname": "周末听歌", "avatarFileId": "上传接口返回的ID" }
```

| 字段 | 是否必填 | 实际校验 / 行为 |
| --- | --- | --- |
| `nickname`（昵称） | 否 | 必须是字符串，trim 后 1～32 位；不能为 null 或全空白 |
| `avatarFileId`（头像文件标识） | 否 | 必须是当前用户上传的头像 ID，字符串最长 64 位；null 表示清除头像关联 |

必须是 JSON 对象，两个字段至少提供一个。额外字段、空对象、非法昵称、图片不存在或不属于本人均返回 400。未提供的字段保持原值。成功 `data`（返回数据）与 `GET /users/me` 相同。前端保存成功后更新个人名片和全局用户状态并返回「我的拾光」，无需重新查询资料。收到 401 时沿用统一登录处理，其余保存错误保留编辑视图、输入与头像预览供重试。

仅改昵称可发送 `{ "nickname": "周末听歌" }`；仅清除头像可发送 `{ "avatarFileId": null }`。清除只移除用户表中的头像引用，不删除已上传图片。

### POST `/users/me/avatar`

**用途与页面：** 先把选择的图片上传，取得后续 PATCH 所需的头像 ID。个人中心选图时只本地预览，点击“保存资料”后才上传。需要 Bearer Token。

使用 `multipart/form-data`，唯一必填字段为 `file`（文件）；不传 `purpose`（文件用途），也不传 `userId`（用户标识）。客户端交由浏览器生成 multipart boundary。

| 项目 | 当前限制 |
| --- | --- |
| 格式 | PNG / JPEG，后端使用 ImageIO 检查真实内容，不只看后缀 |
| 文件大小 | 非空且不超过 512 KiB，即 524288 字节 |
| 图片宽高 | 宽和高均不超过 4096 像素 |
| 存储位置 | MySQL `user_avatar.data`（头像文件表的图片二进制内容），随行记录 `user_avatar.user_id`（上传用户标识）、`user_avatar.content_type`（图片媒体类型）等；不是 Redis、磁盘目录或云对象存储 |

成功 `data`（返回数据）：

```json
{ "avatarFileId": "服务器生成的UUID", "avatarUrl": "/api/media/avatars/服务器生成的UUID" }
```

**返回字段**　`avatarFileId`（头像文件标识）来自 `user_avatar.id`（头像文件表主键），`avatarUrl`（头像地址）用于显示图片。

上传成功只创建图片记录，**不会自动替换当前头像**；还需调用 PATCH /users/me 绑定 `avatarFileId`（头像文件标识）。页面顺序是“上传 → 保存资料 → 显示更新结果”。上传成功但 PATCH 失败时，图片可能仍留在数据库，当前没有自动清理接口或任务。

文件为空、超过业务大小限制、格式或尺寸不合规通常返回 400；超出框架 multipart 大小限制可能先返回 413。缺少 `file`（文件）返回 400，错误的请求 Content-Type 返回 415。

### GET `/media/avatars/{id}`

**用途与页面：** 根据 `avatarUrl`（头像地址）显示头像。前端把 URL 交给 img 标签，由浏览器加载，不通过返回 JSON 的 Axios 封装。公开访问，无需 Token。

路径 `id`（头像文件标识）是上传返回的 `avatarFileId`（头像文件标识）。成功为 HTTP 200 + 图片二进制，Content-Type 为 image/png 或 image/jpeg，并带 `X-Content-Type-Options: nosniff`。找不到图片返回 404 的三字段 JSON 错误体。当前按图片 ID 读取，没有要求图片必须正被某个用户设为头像，因此清除头像关联不会让原图片 URL 自动失效。

### 3.1 个人中心的数据接入（概览已实现，其余规划）

以下查询均需要登录，当前用户从 Token 获取。页面会继续用已实现的 `GET /users/me` 获取账号、昵称与头像。「宝贝」与「信用及评价」角标在接入后取各自分页的 `total`（匹配记录总数），成功查询后才显示真实数量。分页为空时显示空状态，请求失败时显示错误并提供重试。

开发库已准备个人中心和购物车依赖的五张表。表与接口的对应关系见 [数据库增量建表说明](sql/README.md#个人中心与商品操作增量)。概览接口后端已实现、前端待接入，其余下列业务接口仍待实现。

| 个人中心入口 | 规划数据源 | 展示规则 |
| --- | --- | --- |
| 我的拾光 · 名片 | `GET /users/me/overview` | 读取地区、关注数据和信用标签。缺失字段不填示例值 |
| 我的拾光 · 宝贝 | `GET /users/me/goods?scope=showcase` | 展示方形封面、标题、价格、卖家信息。`status=SOLD`（商品状态为已售）时显示「卖掉了」印章 |
| 我的拾光 · 信用及评价 | `GET /users/me/reviews` | 显示已收到且可展示的交易评价 |
| 我发布的 | `GET /users/me/goods` | 显示自己的全部未删除商品，可按状态筛选 |
| 我卖出的 / 我买到的 | `GET /users/me/orders?role=sell` / `?role=buy` | 按角色读取订单。商品已售与订单完成分别使用各自的状态字段 |
| 我的收藏 | `GET /users/me/favorites` | 返回当前账号的收藏。现有浏览器收藏是示例，不自动写入账号收藏 |

#### GET `/users/me/overview`

**当前实现：** 从登录身份的用户名查询当前用户 ID，读取 `user_public_profiles.region_label`，并分别统计 `user_follows` 中被关注和发起关注的记录数。没有公开资料时地区返回 `null`；统计无记录时数量返回 `0`；查询异常走统一错误响应。信用规则尚未实现，`creditLabel` 当前返回 `null`。本接口不创建公开资料记录。

无请求参数。成功 `data`（返回数据）示例如下。

```json
{ "regionLabel": "广东省", "followerCount": 0, "followingCount": 1, "creditLabel": null }
```

**返回字段**　`regionLabel`（公开地区）、`followerCount`（粉丝数）、`followingCount`（关注数）、`creditLabel`（信用标签）。

`regionLabel`（公开地区）使用用户允许展示的地区。关注数与粉丝数是非负整数，`0` 表示实际为零，`null` 表示暂无数据。`creditLabel`（信用标签）由后端根据信用规则提供，无评级时为 `null`。

#### GET `/users/me/reviews`

接收 `page`（页码）和 `size`（每页条数），按 `createdAt DESC, id DESC`（先按创建时间倒序，再按标识倒序）返回统一分页。只查询当前用户作为被评价方收到的可展示评价。评价人只提供昵称和公开头像，不返回联系方式或私有订单信息。

```json
{
  "id": "8001",
  "reviewer": { "nickname": "拾光买家", "avatarUrl": null },
  "rating": "POSITIVE",
  "comment": "包装仔细，商品与描述一致。",
  "createdAt": "2026-11-08T09:15:00Z"
}
```

**评价记录字段**　`id`（评价标识）、`reviewer`（评价人）、`reviewer.nickname`（评价人昵称）、`reviewer.avatarUrl`（评价人头像地址）、`rating`（评价等级）、`comment`（评价正文）、`createdAt`（评价提交时间）。

以上为单条 `records`（当前页记录）元素。`rating`（评价等级）取 `POSITIVE`（好评）、`NEUTRAL`（中评）、`NEGATIVE`（差评）。`comment`（评价正文）可为 `null`，非空时按纯文本显示。

## 4. 分类与首页推荐

这两个接口解决不同问题：`/categories` 提供“商品按什么分类”，供分类菜单、筛选和发布表单复用；`/home/recommendations` 提供首页热搜与 Banner。商品列表的 `/goods` 接口仍为规划，当前页面使用本地示例。

### GET `/categories`

**用途与页面：** 公开接口，供首页首屏分类菜单和 `/browse` 分类商品页读取分类目录。首页紧凑分类入口优先显示 `hint`（分类入口提示），为空时使用 `name`（名称）；展开后显示分组及类型。发布表单暂用本地分类选项。

**当前状态：** 后端已实现 Controller 和 Service，从 MySQL 的 `categories`（一级分类表）、`category_groups`（二级分组表）、`category_types`（三级商品类型表）读取目录。一级分类和三级类型仅返回启用记录，各层按 `sort_order`（显示顺序）升序、`id`（标识）升序展示。响应形状为 `data[].groups[].items[]`（分类列表 → 二级分组列表 → 组内商品类型列表），分类和类型的 `id`（标识）为字符串；分组响应提供 `title`（标题）和 `items`（组内商品类型列表）。

无请求参数。返回数组，顺序为显示顺序；一级分类使用稳定字符串 ID：`digital`（手机数码）、`fashion`（服装鞋包）、`toys`（潮玩手办）、`beauty`（美妆个护）、`books`（图书文娱）、`home`（家居生活）、`sports`（运动户外）、`music`（乐器设备）。

```json
[
  {
    "id": "digital",
    "name": "手机数码",
    "icon": "phone",
    "hint": "手机 / 相机 / 电脑",
    "groups": [
      { "title": "手机与电脑", "items": [{ "id": "phone", "name": "手机" }, { "id": "tablet", "name": "平板电脑" }] },
      { "title": "影音与游戏", "items": [{ "id": "camera", "name": "相机" }, { "id": "headphones", "name": "耳机" }] }
    ]
  }
]
```

**分类字段**　`id`（一级分类标识）、`name`（一级分类名称）、`icon`（图标名称）、`hint`（分类入口提示）、`groups`（二级分组列表）。

每个分组含 `title`（分组标题）和 `items`（组内商品类型列表）。每个类型含 `id`（商品类型标识）和 `name`（商品类型名称）。

示例省略了其他组和分类。类型 ID 在一级分类内唯一，例如 `digital`（手机数码）和 `music`（乐器设备）下都可有 `speaker`（音箱），商品接口应通过 `(categoryId, typeId)`（一级分类标识与商品类型标识）联合识别。`icon`（图标名称）使用前端支持的图标名。

**跳转与筛选：** “全部好物”进入 `/browse`，一级分类传 `category`（前端分类选项），二级分组另传 `group`（分组标题），三级类型另传 `type`（前端商品类型）。分组标题是当前前端路由参数，商品查询契约尚未定义分组参数。首页分类加载失败时提供重试，空目录显示“暂无分类”。

### GET `/home/recommendations`

公开接口。后端从 `home_hot_searches`（首页热搜配置表）返回已启用的热搜，按 `sort_order`（显示顺序）和 `id`（标识）升序，从 `home_banners`（首页海报配置表）取一条启用记录。没有启用的 Banner 时 `banner`（首页海报）为 `null`，没有热搜时 `hotSearches`（热搜词列表）为空数组。当前约定只启用一条 Banner。成功响应的 `data`（返回数据）示例：

```json
{
  "hotSearches": ["iPhone 15", "相机"],
  "banner": {
    "title": "让喜欢的好物，续写新的故事。",
    "subtitle": "在这里，遇见有故事的物件。",
    "buttonText": "发现心动好物",
    "imageUrl": "/images/editorial-hero.png",
    "targetCategoryId": null
  }
}
```

**推荐字段**　`hotSearches`（热搜词列表）、`banner`（首页海报）。海报含 `title`（主标题）、`subtitle`（副标题）、`buttonText`（按钮文案）、`imageUrl`（海报图片地址）和 `targetCategoryId`（按钮跳转的一级分类标识）。

搜索框下最多展示前四条热搜。首页竖版海报使用 Banner 的标题、副文案、按钮和图片；没有 Banner 或推荐请求失败时使用前端默认海报。按钮按 `targetCategoryId`（目标一级分类标识）筛选首页商品流，值为 `null` 时定位到全部好物。示例图片地址由前端同源静态资源提供。

“数码捡漏、穿搭鞋包、潮玩手办、居家好物”四个频道是前端配置，每个卡片展示两件本地示例商品并跳转至对应的 `/browse?category=...`。接口响应只包含 `hotSearches`（热搜词列表）和 `banner`（首页海报），历史频道表保留为旧数据。

## 5. 商品

后端已实现公开商品列表 `GET /goods`，本节其余接口为规划。当前首页、分类商品页和详情读取本地示例商品，发布页提供表单、预览和本机草稿。

### 5.1 商品字段模型

```json
{
  "id": "10003",
  "categoryId": "fashion",
  "typeId": "shoe",
  "title": "New Balance 530 复古运动鞋 37码",
  "description": "个人自用，穿过两次，无明显磨损。",
  "price": 239,
  "condition": "LIKE_NEW",
  "conditionLabel": "95新",
  "coverUrl": "/api/media/goods/shoe.webp",
  "images": [{ "fileId": "file-2001", "url": "/api/media/goods/shoe.webp" }],
  "seller": { "id": "10001", "nickname": "小林的衣橱", "avatarUrl": null },
  "sellerType": "PERSONAL",
  "location": "南京",
  "viewCount": 0,
  "status": "ON_SALE",
  "createdAt": "2026-10-06T10:00:00Z",
  "updatedAt": "2026-10-06T10:00:00Z",
  "version": 1
}
```

| 业务内容 | 接口字段与中文释义 | 对应数据库字段 |
| --- | --- | --- |
| 商品标识与分类 | `id`（商品标识）、`categoryId`（一级分类标识）、`typeId`（商品类型标识） | `goods.id`（商品主键）、`goods.category_id`（一级分类标识）、`goods.type_id`（商品类型标识） |
| 商品正文与售价 | `title`（商品标题）、`description`（商品描述）、`price`（当前售价） | `goods.title`（商品标题）、`goods.description`（商品描述）、`goods.price`（当前售价） |
| 成色 | `condition`（商品成色编码）、`conditionLabel`（成色显示文案） | `goods.condition_code`（成色编码），显示文案由后端转换 |
| 封面与多图 | `coverUrl`（封面地址）、`images`（商品图片列表）、`images[].fileId`（文件标识）、`images[].url`（图片访问地址） | `goods_images.file_id`（关联的上传文件标识）、`uploaded_files.url`（文件访问地址）。`goods_images.sort_order`（图片展示位置）为 1 的图片是封面 |
| 卖家资料 | `seller`（卖家资料）、`seller.id`（卖家标识）、`seller.nickname`（卖家昵称）、`seller.avatarUrl`（卖家头像地址）、`sellerType`（卖家类型） | `goods.seller_id`（卖家标识）关联 `user.id`（用户主键）。昵称取 `user.nickname`（用户昵称），头像地址根据 `user.avatar_file_id`（当前头像文件标识）生成。卖家类型取 `goods.seller_type`（卖家类型） |
| 地点、浏览量与状态 | `location`（商品所在城市）、`viewCount`（累计浏览次数）、`status`（商品状态） | `goods.location`（商品所在城市）、`goods.view_count`（累计浏览次数）、`goods.status`（商品状态） |
| 时间和版本 | `createdAt`（创建时间）、`updatedAt`（最后更新时间）、`version`（数据版本） | `goods.created_at`（创建时间）、`goods.updated_at`（最后更新时间）、`goods.version`（数据版本） |

列表响应省略 `description`（商品描述）、`images`（商品图片列表）、`version`（数据版本）。`seller.avatarUrl`（卖家头像地址）可为 `null`。`viewCount`（累计浏览次数）为非空的非负整数，对应 `goods.view_count`（商品表的累计浏览次数），初始值为 0。列表读取已存的累计浏览次数，详情浏览事件的写入待开发。

已有库升级时执行 [商品浏览量迁移](../../shiguang-server/market/sql/10-goods-view-count.sql)。旧原价和想要人数作为历史数据保留，浏览量单独从 0 开始。新版空库初始化已包含浏览量列。

| 枚举 | 可选值 |
| --- | --- |
| `condition`（商品成色编码） | `NEW`（全新）、`NEAR_NEW`（几乎全新/99新）、`LIKE_NEW`（95新）、`GOOD`（9成新）、`USED`（有使用痕迹） |
| `status`（商品状态） | `ON_SALE`（在售）、`RESERVED`（订单占用）、`SOLD`（已售）、`OFF_SHELF`（下架） |
| `sellerType`（卖家类型） | 本版只允许 `PERSONAL`（个人闲置） |

成色展示由 `conditionLabel`（成色显示文案）提供；后端根据 `condition`（商品成色编码）生成。消耗品余量等细节写入 `description`（商品描述），不能把“余量8成”用作通用成色枚举。

### GET `/goods`

**用途与页面。** 公开接口，供首页商品流和分类商品页使用。前端接入后在首次加载及切换条件时请求数据，用分页 `total`（匹配记录总数）更新件数，卡片用 `viewCount`（累计浏览次数）展示「N 次浏览」。

示例：`/api/goods?categoryId=digital&typeId=phone&keyword=iPhone&page=1&size=20&sort=latest`

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `keyword`（搜索关键词） | 否 | 搜索标题/描述，去除首尾空白，最长 100 位 |
| `categoryId`（一级分类标识） | 否 | 一级分类；省略表示全部，不能传 UI 专用的 `all`（全部） / `personal`（个人闲置） |
| `typeId`（商品类型标识） | 否 | 具体类型；提供时必须同时提供合法 `categoryId`（一级分类标识） |
| `sellerType`（卖家类型） | 否 | `PERSONAL`（个人闲置），对应“个人闲置”Tab |
| `minPrice`（最低价） / `maxPrice`（最高价） | 否 | 非负，最多两位小数，最小值不大于最大值 |
| `sort`（排序方式） | 否 | 默认 `latest`（最新发布）、`priceAsc`（价格升序）、`priceDesc`（价格降序）；拒绝未定义值 |
| `page`（页码） / `size`（每页条数） | 否 | 遵循统一分页 |

只返回 `ON_SALE`（在售）且未删除的商品；类型存在但暂时没有商品时返回空分页。成功 `data`（返回数据）为分页对象，`records`（当前页记录）每项采用商品列表字段。`latest`（最新发布）先按 `createdAt`（创建时间）倒序，再按 `id`（商品标识）倒序。`priceAsc`（价格升序）或 `priceDesc`（价格降序）先按 `price`（当前售价）排序，再按 `id`（商品标识）排序。前端使用 `recommended`（默认推荐）时，省略 `sort`（排序方式），由后端按最新发布排序；当前本地默认排序只是数据原顺序，不代表个性化推荐已实现。

当前没有 `minPrice`（最低价）/`maxPrice`（最高价）输入控件，参数为预留。清除分类时同时清除 `typeId`（商品类型标识）；切换关键词、分类、类型或排序时将 `page`（页码）重置为 1。请求失败与空分页是两种状态，失败显示可重试错误，不显示“没有商品”；并发请求需取消旧请求或只应用最近一次响应，避免旧搜索覆盖新条件。

### GET `/goods/{id}`

真实商品详情页 `/goods/:id` 读取商品、卖家公开信息和当前交易状态。首页和分类页目前仍是示例商品，卡片链接带 `?demo=1`，使用本地详情。编辑表单预填待接入。

返回完整商品详情。`ON_SALE`（在售）、`RESERVED`（订单占用）、`SOLD`（已售）可公开查看，以显示当前状态。`OFF_SHELF`（下架）仅卖家本人可查看，其他人返回 404；已软删除商品返回 404。可选 Token 无效时返回 401，不自动按匿名请求继续处理。

游客点击加入购物车、立即购买或收藏时，前端保存当前详情地址并跳转登录，登录成功后返回原详情。真实详情读取账号收藏状态，交易和收藏写接口待实现。详情查询读取已有浏览量，暂未接入浏览计数写入。

| 详情区域 | 字段与显示规则 |
| --- | --- |
| 顶部卖家通栏 | `seller.id`（卖家标识）、`seller.nickname`（卖家昵称）、`seller.avatarUrl`（卖家头像地址）用于身份区及“个人主页”入口。城市使用商品的 `location`（商品所在城市），表示交易地点。信用、活跃时间、加入时长、卖出数和好评率使用下表中的卖家摘要字段。 |
| 左侧缩略图与主图 | `images`（商品图片列表）按上传时的展示顺序返回 1～9 张，第一张为默认主图并与 `coverUrl`（封面地址）一致。前端直接使用各项的 `url`（访问地址）切换主图，复用同一地址作为缩略图。缩略栏可首屏展示 4～5 张并滚动查看其余图片；只有一张时只展示一个缩略图。 |
| 右侧价格与浏览量 | 价格区读取 `price`（当前售价）。`freeShipping`（是否包邮）为 `true` 时显示“包邮”。有浏览数据时可显示 `viewCount`（累计浏览次数），现有部分示例商品提供该字段。金额的货币符号和千分位由前端排版。 |
| 流式正文 | `conditionLabel`（成色显示文案）、`title`（商品标题）和 `description`（商品描述）依次展示。`description`（商品描述）使用纯文本和换行保留原始段落，可包含实际的成色细节、发货说明和沟通提示。成色标签、标题位置和正文样式由前端处理。 |
| 底部操作栏 | “加入购物车”和“立即购买”组合成双拼胶囊，“收藏”单独展示。前端根据 `status`（商品状态）、卖家身份和 `favorited`（是否已收藏）更新可用状态及文案。 |

详情响应在第 5.1 节模型上增加以下字段。缺少可选统计时返回 `null`，页面省略对应标签及相邻分隔符。

| 字段 | 类型 | 约定 |
| --- | --- | --- |
| `freeShipping`（是否包邮） | `boolean`（布尔值）或 null | `true` 表示包邮，`false` 表示未标记为包邮，`null` 表示未配置。 |
| `seller.creditLabel`（卖家信用标签） | `string`（字符串）或 null | 后端有公开信用评级时提供展示文本，例如“卖家信用极好”。 |
| `seller.lastActiveAt`（卖家最近活跃时间） | `string`（字符串）或 null | 允许公开时返回 UTC 时间，由前端格式化为“16 分钟前来过”。 |
| `seller.joinedAt`（卖家加入时间） | `string`（字符串）或 null | 允许公开时返回加入时间，由前端计算加入天数。 |
| `seller.soldCount`（卖家已卖出件数） | `integer`（整数）或 null | 已完成的卖家成交件数，已统计时为非负整数。 |
| `seller.positiveReviewRate`（卖家好评率） | `number`（数字）或 null | 好评率百分数，取值 0～100；无评价数据时为 `null`。 |
| `favorited`（是否已收藏） | `boolean`（布尔值）或 null | 登录后表示当前用户是否收藏；匿名读取返回 `null`，界面显示未选中的收藏按钮。 |

页面布局按同一份详情数据渲染。面包屑保留“返回商品列表 / 商品详情”，返回时由前端恢复原列表的筛选和滚动位置。桌面版心最大 1160px，卖家栏位于白色圆角卡片顶部。下方左侧画廊宽 520px，右侧正文占剩余宽度，栏间距 40px。左侧竖排缩略图为 76px 方形，主图保持原比例完整显示。右侧价格置顶，正文按段落自然排版，操作栏靠底。双拼按钮每半宽 135px、高 46px，收藏按钮独立。移动端可将画廊和正文改为上下排列。

### GET `/users/{id}`

“个人主页”使用详情中的 `seller.id`（卖家标识）打开对应卖家的页面，再调用此公开接口。成功 `data`（返回数据）与详情中的 `seller`（卖家资料）对象同结构，包含用户 ID、昵称、头像及可公开的卖家摘要；用户不存在时返回 404。个人主页路由和接口待实现。

### PUT `/users/me/cart/items/{goodsId}`

“加入购物车”调用此接口，无请求体，需要登录。每件闲置商品按单件加入，重复加入同一商品仍只有一条记录。只有在售商品允许加入，缺少商品返回 404，商品不可售返回 409，加入自己发布的商品返回 403。成功 `data`（返回数据）示例为 `{ "goodsId": "10003", "inCart": true }`。加入购物车不占用库存，实际占用仍由订单接口处理。

**返回字段**　`goodsId`（商品标识）、`inCart`（是否已加入购物车）。

### PUT / DELETE `/users/me/favorites/{goodsId}`

“收藏”使用 PUT，“已收藏”再次点击使用 DELETE。两者无请求体，需要登录，仅更新当前用户的收藏状态；重复设置同一状态可安全重试。收藏时商品不存在或不可见返回 404。取消收藏时若记录已不存在，仍返回未收藏状态。成功 `data`（返回数据）为 `{ "goodsId": "10003", "favorited": true }` 或 `{ "goodsId": "10003", "favorited": false }`，前端据此切换按钮状态。

**返回字段**　`goodsId`（商品标识）、`favorited`（是否已收藏）。

“立即购买”进入下单确认，确认后调用第 7 节的 `POST /orders`。加入购物车和立即购买对非在售商品及卖家本人不可用；未登录的用户操作时先登录。操作请求失败时保留原状态并显示服务端提示。

### GET `/users/me/favorites`

供个人中心「我的收藏」使用，接收 `page`（页码）和 `size`（每页条数），按收藏时间倒序，再按商品 ID 倒序。成功 `data`（返回数据）为统一分页，`records`（当前页记录）沿用商品列表对象。列表只含当前用户有权查看且未删除的商品，已售商品可继续显示并使用 `SOLD`（已售）状态。总数与相同可见范围的分页结果一致。

### POST `/goods`

**用途与页面：** 将完整商品资料正式保存并上架，供未来发布页的“发布”提交使用。需要登录。当前“保存草稿”和“预览信息”不调用它。

```json
{
  "categoryId": "fashion",
  "typeId": "shoe",
  "title": "New Balance 530 复古运动鞋 37码",
  "description": "个人自用，穿过两次，无明显磨损。",
  "price": 239,
  "condition": "LIKE_NEW",
  "imageIds": ["file-2001", "file-2002"],
  "location": "南京"
}
```

**发布字段**　`categoryId`（一级分类标识）、`typeId`（商品类型标识）、`title`（商品标题）、`description`（商品描述）、`price`（当前售价）、`condition`（商品成色编码）、`imageIds`（上传图片标识列表）、`location`（商品所在城市）。

示例字段均必填。标题 2～80 位，描述 10～2000 位，`location`（商品所在城市）为 1～50 位的城市名称，这些文本不能全为空白。`price`（当前售价）大于 0 且不超过 999999.99。`imageIds`（上传图片标识列表）为 1～9 个互不重复、属于当前用户、用途为 `GOODS`（商品图片）的有效图片 ID，首张作为封面。`categoryId`（一级分类标识）和 `typeId`（商品类型标识）必须为有效组合。

发布后为 `ON_SALE`（在售），成功返回完整商品对象。卖家身份、创建时间、状态、`version`（数据版本）和初始浏览量由服务端生成，不接受客户端覆盖。

当前“保存草稿”与“预览信息”都不调用此接口。正式提交后只有收到服务端成功响应才能显示“发布成功”。超时或客户端取消不等于提交回滚，不能自动重复 POST；应先核对发布记录，或在后续契约中补充发布幂等机制。

### PUT `/goods/{id}`

**用途与页面：** 保存对已发布商品的编辑，例如改价格、描述或照片。需要登录并且是卖家；未来编辑页加载详情后携带 `version`（数据版本）提交，区别于创建新商品。

仅卖家本人可操作。请求体与发布相同，另加必填 `version`（数据版本）；表示完整替换可编辑字段，缺字段返回 400。只有 `ON_SALE`（在售） / `OFF_SHELF`（下架）可编辑；`version`（数据版本）不匹配或订单占用返回 409。后端原子递增版本，返回更新后的完整对象。编辑请求不直接改变上架状态。

### PATCH `/goods/{id}/status`

**用途与页面：** 在“我发布的商品”中上架/下架，保留商品内容和记录，不等于删除或售出。需要登录，当前暂无操作入口。

```json
{ "status": "OFF_SHELF", "version": 1 }
```

**提交字段**　`status`（商品状态）、`version`（数据版本）。

仅卖家可操作，只允许 `ON_SALE`（在售） ↔ `OFF_SHELF`（下架）；不能通过此接口把商品设为 `RESERVED`（订单占用） / `SOLD`（已售），也不能重新上架已售商品。`version`（数据版本）必填，冲突返回 409；成功返回更新后的商品对象。

### DELETE `/goods/{id}`

**用途与页面：** 卖家从自己的商品管理列表移除商品；数据库做软删除，保留历史订单所需信息。需要登录，当前暂无删除入口。

必填查询参数 `version`（数据版本），例如 `/api/goods/10003?version=1`。仅卖家可软删除 `ON_SALE`（在售） / `OFF_SHELF`（下架）商品，其他状态返回 409。成功 `data: null`（返回数据为空）。删除不影响已存在订单的商品快照。

### GET `/users/me/goods`

**用途与页面**　为个人主页「宝贝」和「我发布的」提供当前用户自己的商品。只查询当前用户未删除商品，按 `createdAt DESC, id DESC`（先按创建时间倒序，再按标识倒序）排序，返回商品列表分页。

| 参数 | 是否必填 | 行为 |
| --- | --- | --- |
| `scope`（查询范围） | 否 | 默认 `all`（全部），允许全部四种状态。`showcase`（个人主页展示范围）仅包含 `ON_SALE`（在售）、`RESERVED`（订单占用）、`SOLD`（已售） |
| `status`（商品状态） | 否 | 在所选范围内按第 5 节的商品状态筛选。合法状态与范围无交集时返回空分页 |
| `page`（页码） / `size`（每页条数） | 否 | 统一分页，`total`（匹配记录总数）对应当前范围和筛选 |

## 6. 通用图片上传（规划，未实现）

### POST `/uploads/images`

**用途与页面：** 未来在发布/编辑商品时上传照片，取得 `fileId`（文件标识），再通过 `/goods` 的 `imageIds`（上传图片标识列表）绑定到商品。需要登录。该通用接口仍是规划；**现在更换头像必须使用第 3 节的 `/users/me/avatar`**，不能套用本节的 5 MiB、WebP 或 `purpose`（文件用途）规则。

multipart 表单字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| `file`（文件） | `binary`（二进制文件） | 是 | 单张 JPEG、PNG 或 WebP，最大 5 MiB |
| `purpose`（文件用途） | `string`（字符串） | 是 | `GOODS`（商品图片）或 `AVATAR`（头像） |

后端检查实际图片内容而非只看扩展名/客户端 MIME，生成自己的文件名，并记录上传者和用途。文件不存为可执行资源；原始文件名不直接用于路径。客户端不设置 multipart 的 boundary，由浏览器生成。

成功 `data`（返回数据）：

```json
{
  "fileId": "file-2001",
  "url": "/api/media/goods/shoe.webp",
  "width": 1200,
  "height": 1200,
  "size": 245760
}
```

**上传返回字段**　`fileId`（文件标识）、`url`（文件访问地址）、`width`（图片宽度，单位为像素）、`height`（图片高度，单位为像素）、`size`（文件大小，单位为字节）。

发布/修改提交 `fileId`（文件标识），不提交任意图片 URL。未被商品或头像引用的文件建议定期清理；被订单快照引用的媒体按订单留存策略保留，不随商品删除立即移除。

## 7. 订单与买入 / 卖出记录（规划，均未实现）

当前订单页只有 `buy`（买入）/`sell`（卖出）页签和服务未开放提示，不发送订单请求。本节定义后续线下交付的最小交易流程，不包含在线支付。订单只有一件闲置商品、数量固定为 1。在线支付与退款接入前不能把此流程描述为付款成功或资金托管。

### 7.1 状态与操作权限

| 当前状态 | 操作 | 操作人 | 新状态 / 商品状态 |
| --- | --- | --- | --- |
| 无订单，商品 `ON_SALE`（在售） | 创建 | 非卖家的登录买家 | `PENDING`（待确认） / `RESERVED`（订单占用） |
| `PENDING`（待确认） | 确认交易 | 卖家 | `CONFIRMED`（已确认） / `RESERVED`（订单占用） |
| `PENDING`（待确认） | 取消 | 买家或卖家 | `CANCELLED`（已取消） / `ON_SALE`（在售） |
| `PENDING`（待确认） | 超时未确认 | 服务端任务 | `CANCELLED`（已取消） / `ON_SALE`（在售） |
| `CONFIRMED`（已确认） | 确认完成 | 买家 | `COMPLETED`（已完成） / `SOLD`（已售） |

待确认有效期建议 30 分钟，由服务端配置并通过 `expiresAt`（过期时间）返回；`CONFIRMED`（已确认）后不自动超时释放。本版不支持已确认订单直接取消、完成后退款；非法迁移返回 409。任何订单释放只能释放自己占用的商品，不能覆盖其他订单状态。

### 7.2 订单对象

```json
{
  "id": "3001",
  "orderNo": "SG202610060001",
  "status": "PENDING",
  "amount": 239,
  "goods": { "id": "10003", "title": "New Balance 530 复古运动鞋 37码", "coverUrl": "/api/media/goods/shoe.webp", "conditionLabel": "95新", "price": 239 },
  "buyer": { "id": "10002", "nickname": "周末散步", "avatarUrl": null },
  "seller": { "id": "10001", "nickname": "小林的衣橱", "avatarUrl": null },
  "remark": "希望周末同城交付",
  "createdAt": "2026-10-06T10:00:00Z",
  "expiresAt": "2026-10-06T10:30:00Z",
  "confirmedAt": null,
  "completedAt": null,
  "cancelledAt": null,
  "cancelReason": null
}
```

| 业务内容 | 订单字段与中文释义 |
| --- | --- |
| 基本信息 | `id`（订单标识）、`orderNo`（对外订单编号）、`status`（订单状态）、`amount`（订单金额）、`remark`（下单备注） |
| 商品快照 | `goods`（商品快照）、`goods.id`（商品标识）、`goods.title`（下单时的商品标题）、`goods.coverUrl`（下单时的商品封面地址）、`goods.conditionLabel`（下单时的成色文案）、`goods.price`（下单时的商品售价） |
| 买卖双方 | `buyer`（买家资料）、`seller`（卖家资料）。两者都含 `id`（用户标识）、`nickname`（昵称）、`avatarUrl`（头像地址） |
| 交易时间与取消 | `createdAt`（下单时间）、`expiresAt`（待确认截止时间）、`confirmedAt`（确认时间）、`completedAt`（完成时间）、`cancelledAt`（取消时间）、`cancelReason`（取消原因） |

创建订单时保存 `goods`（商品快照）。之后编辑商品，订单中的标题、图片和价格仍为下单时的内容。`amount`（订单金额）来自服务端价格，不接受客户端指定。

### POST `/orders`

**用途与页面：** 买家在商品详情点击“立即购买”并确认后创建订单，同时占用这件闲置商品，防止被其他买家重复订走。需要登录，成功后进入订单详情。当前详情页交易尚未开放。

请求头：`Idempotency-Key: <客户端生成的唯一字符串>`（请求幂等键），必填，最长 64 位。同一次提交的重试必须复用相同 Key，新交易使用新 Key。

```json
{ "goodsId": "10003", "expectedPrice": 239, "remark": "希望周末同城交付" }
```

`goodsId`（商品标识）、`expectedPrice`（预期售价）必填，`remark`（下单备注）可选且最多 200 位。`expectedPrice`（预期售价）仅用于发现价格变化，不用于结算；与服务端价格不同返回 409（价格已变化）。不得购买自己的商品，返回 403。商品非 `ON_SALE`（在售）返回 409 / GOODS_UNAVAILABLE。

同一用户 + Key + 相同请求重复调用返回原订单；相同 Key 配不同请求返回 409 / IDEMPOTENCY_CONFLICT。Key 结果至少保留 24 小时，订单已取消时重复 Key 仍返回该原订单，不能创建新订单。

服务端在同一事务中原子检查可售状态、占用商品并创建订单；并发买家最多一人成功。成功返回订单对象。

### GET `/users/me/orders`

**用途与页面：** 给 `/user/orders` 的「我买到的」和「我卖出的」两个页签及个人中心对应入口提供订单列表。需要登录，按页面视图发送 `role`（交易角色），身份从 Token 获取。

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| `role`（交易角色） | 是 | `buy`（我买到的）、`sell`（我卖出的），与前端 Tab 一致 |
| `status`（订单状态） | 否 | `PENDING`（待确认）、`CONFIRMED`（已确认）、`COMPLETED`（已完成）、`CANCELLED`（已取消） |
| `page`（页码） / `size`（每页条数） | 否 | 统一分页 |

返回订单分页，按创建时间倒序。查询仅基于当前用户，不允许客户端指定其他用户 ID。

### GET `/orders/{id}`

**用途与页面：** 打开某一笔订单，查看商品快照、成交金额、买卖双方、状态和操作时间。需要登录，未来需新增订单详情界面。

只允许订单买卖双方读取，成功返回订单对象；非参与者返回 403，不存在返回 404。

### POST `/orders/{id}/confirm`

**用途与页面：** 卖家点击“确认交易”，表示接受这笔待确认交易。它不是支付回调，也不意味着商品已经交付。需要登录，当前暂无按钮调用。

无请求体。仅订单卖家可将 `PENDING`（待确认）转为 `CONFIRMED`（已确认），检查 `expiresAt`（过期时间）；已过期返回 409（订单已过期）。重复确认已为 `CONFIRMED`（已确认）的订单直接返回当前订单。

### POST `/orders/{id}/complete`

**用途与页面：** 买家在实际完成线下交付后点击“确认完成”，结束交易并把商品标为已售。需要登录，当前暂无按钮调用。

无请求体。仅订单买家可将 `CONFIRMED`（已确认）转为 `COMPLETED`（已完成），同时将该订单占用的商品设为 `SOLD`（已售）。重复完成直接返回当前订单。

### POST `/orders/{id}/cancel`

**用途与页面：** 买家或卖家取消尚未确认的交易，并释放该订单占用的商品。需要登录，不等于退款；当前暂无按钮调用。

```json
{ "reason": "暂时不需要了" }
```

`reason`（取消原因）必填，1～200 位；买卖双方仅能取消 `PENDING`（待确认）订单。重复取消返回当前订单，保留第一次取消原因。所有状态操作必须在事务中校验状态和身份；成功均返回订单对象。对于任意其他已终结或不允许迁移的状态，返回 409。

## 8. 反馈（规划，未实现）

### POST `/feedback`

**用途与页面：** 把用户建议发送给服务端留存，供后续运营查看。规划需要登录；当前悬浮栏的“反馈”仅保存在当前浏览器，不会发送到服务器。

```json
{ "content": "希望增加商品收藏功能", "pagePath": "/?category=digital" }
```

`content`（反馈内容）必填，1～500 位；`pagePath`（页面路径）可选，最长 500 位，仅站内路径。成功 `data`（返回数据）为 `{ "id": "4001", "createdAt": "2026-10-06T10:00:00Z" }`。提交人取自 Token；提交频率限制也属于待实现要求。当前本地保存/撤销不对应服务端创建/删除反馈。

**返回字段**　`id`（反馈记录标识）、`createdAt`（反馈提交时间）。

## 9. 前端对接映射

注册、登录、个人资料和头像已经通过 `src/api/user.js` 对接真实接口。下表说明**尚未接入的商品、订单业务**应如何转换当前本地字段；需要新增请求和适配后才能替换数据。

| 现有前端 | 后端字段 / 映射 |
| --- | --- |
| URL `q`（搜索关键词） | 商品查询 `keyword`（搜索关键词），最长 100 位 |
| URL `category=digital`（分类为手机数码） | `categoryId=digital`（一级分类为手机数码） |
| URL `category=all`（查看全部分类）或无分类 | 省略 `categoryId`（一级分类标识） |
| URL `category=personal`（查看个人闲置） | `sellerType=PERSONAL`（卖家类型为个人闲置），不传 `categoryId=personal`（一级分类为个人闲置） |
| URL `type`（前端商品类型） | `typeId`（商品类型标识），必须同时传有效 `categoryId`（一级分类标识） |
| `/browse` 的 URL `group`（二级分组标题） | 当前用分组标题从分类目录查找类型集合，尚无对应的商品查询参数 |
| `/browse` 的 URL `sort=priceAsc/priceDesc`（按价格升序或降序） | 原值传 `sort`（排序方式）；首页没有价格排序控件 |
| 无 `sort`（排序方式） / UI `recommended`（默认推荐） | 接入后省略 `sort`（排序方式），后端默认 `latest`（最新发布）；当前本地按原数据顺序 |
| 商品 `category`（前端分类选项） / `kind`（前端商品类型） | `categoryId`（一级分类标识） / `typeId`（商品类型标识） |
| 商品 `condition`（本地成色文案） | `conditionLabel`（成色显示文案）；表单提交 `condition`（商品成色编码）枚举 |
| 商品 `seller`（本地卖家昵称） | `seller.nickname`（卖家昵称）；组件需要适配 `seller`（卖家资料）对象 |
| 商品 `avatar`（头像占位颜色） | `seller.avatarUrl`（卖家头像地址）；为空时保留首字头像占位 |
| 商品 `viewCount`（累计浏览次数） | 后端 `viewCount`（累计浏览次数），列表显示「N 次浏览」；本地示例未提供时显示 0 |
| 商品 `imageUrl`（图片地址） / ProductVisual 类型图 / ProductArt SVG | 接入后把 `coverUrl`（封面地址）或详情选中的图片地址交给 ProductVisual 的 `imageUrl`（图片地址）；缺图时保留现有回退 |
| 商品个人闲置标记 | `sellerType=PERSONAL`（卖家类型为个人闲置） |
| 订单 Tab `buy`（买入） / `sell`（卖出） | `role=buy`（交易角色为买入） / `role=sell`（交易角色为卖出） |
| 草稿 `category`（前端分类选项） / `type`（前端商品类型） | 发布时转换为 `categoryId`（一级分类标识） / `typeId`（商品类型标识） |
| 草稿 `price`（当前售价）字符串 | 校验后转换为人民币元 JSON number；后端用 BigDecimal |
| 草稿 `condition`（中文成色文案） | 使用下表枚举转换，不能直接发送中文成色 |

订单提交发送商品 ID、预期价格和可选备注，客户端格式化价格不参与结算。当前编辑页面尚不保存后端 `version`（数据版本）；接入详情与编辑接口后需记录并提交该版本。当前 `/users/me` 在个人中心挂载时调用；刷新其他页面只从 localStorage 恢复资料，没有全站自动查询资料。受保护请求收到 401 沿用统一清除登录态处理。

### 9.1 发布草稿的字段转换

| 当前表单成色 | API `condition`（商品成色编码） |
| --- | --- |
| 全新 | `NEW`（全新） |
| 几乎全新 / 99新 | `NEAR_NEW`（几乎全新或 99 新） |
| 95新 | `LIKE_NEW`（95 新） |
| 9成新 | `GOOD`（9 成新） |
| 有使用痕迹 | `USED`（有使用痕迹） |

`NEAR_NEW`（几乎全新或 99 新）的两种前端文案在后端使用同一枚举，回显以服务端 `conditionLabel`（成色显示文案）为准。正式发布还需要上传组件以获得 `imageIds`（上传图片标识列表），编辑还需要获取 `version`（数据版本）。当前默认照片是生成的展示素材，不能作为用户已经上传的照片 ID。

### 9.2 本机草稿与撤销范围

本机键为 `market_draft_<userId或username>_<goodsId或new>`，值结构为 `{ "fields": { "category": "", "type": "", "title": "", "description": "", "condition": "", "price": "", "location": "" }, "savedAt": "ISO时间" }`。不完整或尚不合法的字段可以保存草稿；预览/正式发布另行校验。

**草稿字段**　`fields`（草稿字段对象）包含 `category`（分类选项）、`type`（商品类型）、`title`（商品标题）、`description`（商品描述）、`condition`（成色文案）、`price`（当前售价）和 `location`（商品所在城市）。`savedAt`（草稿保存时间）单独记录。

清除草稿、清除搜索历史、移除筛选、保存反馈的撤销均为本地行为，不增加服务器 DELETE/restore 接口。跨设备草稿同步和草稿发布事务不在本版契约中；以后若增加，需要单独定义草稿 ID、版本和归属，不能把未完成草稿混入公开商品列表。

### 9.3 接口错误与可用性状态

下表中分页、版本冲突和真实订单错误是接入后的展示要求，当前没有对应业务请求。

| 情况 | 服务端 / 前端行为 |
| --- | --- |
| 查询成功但无记录 | 200 + 空 `records`（当前页记录）；页面提供减少筛选或浏览全部 |
| 服务不可用 | 503 + 可行动 `msg`（提示消息）；页面保留当前条件并允许重试 |
| 字段校验失败 | 当前认证接口返回 400 和单条 `msg`（提示消息），无 `errors`（错误列表）数组；表单保留输入 |
| 版本/订单状态冲突 | 409；提供重新加载详情或返回列表，不静默覆盖 |
| 客户端停止等待 | 仅中止客户端等待，不保证服务端业务撤销；不显示成功或“已取消交易” |
| 真实订单服务失败 | 显示失败/未开放状态；不能伪装为没有订单 |

当前 request.js 将返回体中的 `msg`（提示消息）转为 JavaScript `Error.message`（异常提示消息），业务页面直接读取 `error.message`（异常提示消息）；原始三字段返回体保留在 `error.response.data`（原始错误响应体）中。

## 10. 联调验收与实现顺序

1. 先验收已经存在的注册、登录、资料、头像链路，以及 Token 过期和撤销行为；前端退出还需接入已有 logout，当前不算完成服务端退出联动。
2. 验证第 4 节已接入的分类目录和首页推荐，再接入已实现的商品列表，核对卡片的售价和浏览量。验收详情时覆盖匿名访问、单图与多图、缺少可选统计时隐藏对应内容，以及登录回到原详情后读取收藏状态。
3. 实现商品图片上传、发布、编辑、上下架；当前头像专用上传已实现，不等于商品上传已实现。验证只能修改自己的商品，版本冲突返回 409。
4. 接入卖家公开资料、加入购物车、收藏切换与立即购买。验证重复加购、收藏状态同步、不可售商品限制和服务端价格校验，再完成订单状态流转及并发下单、幂等重试、取消释放和超时验收。
5. 接入在线反馈；消息、支付、物流另行制定接口。

个人中心验收应覆盖资料加载失败重试、昵称修改、头像上传与移除，以及保存成功后名片和页头同步。接入第 3.1 节后，再用两个不同账号验证宝贝、评价、收藏和订单隔离，核对角标总数、真实空状态和 `SOLD`（已售）邮戳展示。

开发环境通过 Vite 同源代理访问 `/api/**`；部署时需反向代理到后端。若未来改为跨域直连，需配置 CORS 的前端 Origin 和请求头。401 已有 JSON 入口，403 的统一安全处理仍需补齐；本轮未修改后端鉴权配置。

### 登录与查询示例（PowerShell）

```powershell
$loginBody = @{ username = 'xiaolin'; password = 'example123' } | ConvertTo-Json
$loginResult = Invoke-RestMethod -Method Post -Uri 'http://localhost:8080/api/auth/login' -ContentType 'application/json' -Body $loginBody
$authHeaders = @{ Authorization = "Bearer $($loginResult.data.token)" }
Invoke-RestMethod -Uri 'http://localhost:8080/api/users/me' -Headers $authHeaders
```

这里的用户名和密码仅为示例，执行时换成已注册的测试账号；后端和数据库表需准备完成。命令只覆盖当前已存在的登录与资料查询，不代表本文已经执行过真实验收。

## 11. 本地建项目与联调验收

启动当前工程和检查首页公开接口，见 [本地后端开发说明](backend-setup.md#当前工程启动与首页联调)。先确认运行应用的数据源与表结构，再联调账号、个人资料、头像和退出撤销。草稿、搜索历史和帮助当前不需要服务端接口。

### GET `/health`（仅教程示例，当前未实现）

**用途：** 供开发或部署探测服务能否响应，不是用户页面接口。当前没有 Health Controller，也没有本文可保证的响应结构，不能把它作为现阶段启动成功的必需验收项。即使将来增加一个简单返回 200 的健康接口，也不能仅凭它判断数据库和业务表都可用。

个人中心页面已做前端测试与构建验证。数据库增量已在 MySQL 9.6.0 隔离库验证约束，并在开发库确认建表结果。规划接口仍待实现和 HTTP 联调。界面交互规范见 [可用性设计规范](usability-design.md)。

