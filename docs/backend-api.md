# 拾光闲置 · 后端 REST API 对接文档

版本：v1.1 草案 · 更新日期：2026-10-12 · 后端计划：Java Spring Boot。

2026-10-24 调整：按当前开发要求，统一返回体只保留 `code`、`msg`、`data`。后端已实现注册；Spring Security 鉴权暂未启用，其他接口仍按本文规划逐步开发。

2026-10-25 架构调整：当前后端改为 Java 17、Spring Boot 3.5.16、MyBatis-Plus 3.5.17，根包 `org.example.aispingboot`。本轮只实现注册，路径和三字段响应保持不变；入参为 `UserRegisterCommandDTO`，出参为 `UserRegisterResponseDTO`。注册表改为 `user`，独立建表/旧账号复制步骤见[当前后端说明](../../shiguang-server/market/README.md)。登录、用户名或邮箱登录及 JWT 尚未实现。

当前注册使用 MyBatis-Plus 的 BaseMapper 和 LambdaQueryWrapper，使用 Lombok 简化数据对象。原生 MyBatis/XML 教程是历史参考，当前运行方式见 [工程教程](backend-setup.md) 开头的说明；这些实现调整不改变注册 HTTP 路径和三字段响应。

全部 15 张表及初始分类配置见 [建表脚本与执行说明](sql/README.md)。数据库数字 ID 在 API 中以字符串返回，订单/反馈示例也采用该格式。

本文根据本次可用性重构后的前端制定接口契约，不代表接口已实现或部署。登录、注册已写真实请求；首页、详情仍为本地展示数据。发布已实现表单、本机草稿与预览，但不上传或上架；订单页已实现买入/卖出切换与服务说明，但不查询真实记录。

## 0. 本版更新与接入边界

| 当前界面功能 | 当前实现 | 后端对接要求 |
| --- | --- | --- |
| 登录/注册 | 真实调用，内联错误，loading，停止等待，失败保留输入 | 实现认证接口及 JSON 错误；停止等待不保证服务端回滚 |
| 搜索/分类/价格排序 | 本地筛选，条件保存在 URL | GET /goods；映射 q/category/type/sort，切换条件重置分页 |
| 最近搜索/筛选撤销 | 本机记录/当前页面状态 | 不需要额外后端接口；不把撤销筛选当成撤销交易 |
| 保存/恢复/清除草稿 | 当前用户在本浏览器的 localStorage | 不调用 POST /goods；跨设备草稿未纳入本版 |
| 发布信息预览 | 本地校验后打开预览弹窗，无上传图片 | 正式发布需完成图片上传、字段转换、版本处理与提交 |
| 商品详情 | 本地数据，返回恢复列表与位置 | GET /goods/{id}；交易和联系卖家仍未开放 |
| 我的订单 | role=buy/sell 保存在 URL，准确提示服务未开放 | GET /users/me/orders；失败不能显示“没有订单” |
| 反馈及撤销 | 只保存/撤销当前浏览器建议 | POST /feedback 待接入；当前撤销不涉及服务器 |
| 使用帮助/快捷键 | 前端静态说明 | 不需要后端接口 |

本版保持已有业务路径，补齐状态、校验、映射与验收规则。IDE 创建与完整依赖配置见 [本地 Spring Boot 教程](backend-setup.md)。

## 1. 通用约定

| 项目 | 约定 |
| --- | --- |
| 开发地址 | `http://localhost:8080/api` |
| 前端请求前缀 | `/api`，Vite 保留前缀代理到 Spring Boot |
| 请求格式 | `application/json`；图片上传使用 `multipart/form-data` |
| 字符集 | UTF-8 |
| 鉴权 | `Authorization: Bearer <token>` |
| ID | 商品、用户、订单、上传文件 ID 均使用 JSON 字符串，避免 Java Long 精度丢失 |
| 时间 | ISO 8601 UTC，例如 `2026-10-06T10:00:00Z`；前端按用户时区显示 |
| 金额 | 人民币元，JSON number，最多两位小数；后端使用 BigDecimal 或整数分存储/计算 |
| 分页 | `page` 从 1 开始，默认 1；`size` 默认 20，范围 1～50 |
| 空结果 | `records: []`、`total: 0`，不返回 404 |
| 写操作用户身份 | 从 Token 获取，不能信任客户端传入的 userId、sellerId 或 buyerId |

所有成功响应使用 HTTP 200 和业务码 200，包括创建与删除，便于当前 Axios 统一处理。失败使用真实的 HTTP 4xx/5xx，并提供 JSON 错误体。前端也兼容成功业务码 0，但新后端统一使用 200。

### 1.1 成功响应

```json
{
  "code": 200,
  "msg": "操作成功",
  "data": {}
}
```

无返回内容时使用 `data: null`。当前 `utils/request.js` 会直接返回 `data`，业务页面无需再次读取 `response.data`。

### 1.2 失败响应

```json
{
  "code": 409,
  "msg": "商品已被预订，请选择其他商品",
  "data": null
}
```

成功和失败的返回体均严格只有 `code`、`msg`、`data` 三个字段，无数据时保留 `data: null`。`code` 使用 HTTP 状态对应的数字；`msg` 为可直接展示的中文提示，不返回堆栈、SQL 或密码等内部信息。后端通过 `pojo.ResultCode` 集中定义状态和默认提示，不额外返回业务标识、请求追踪或字段错误数组。同一状态下的不同业务提示通过枚举和 `msg` 区分，前端不要依赖中文提示判断业务分支。

| HTTP / code | 含义 | 后端 ResultCode 枚举示例 |
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

登录/注册设置 inlineError，由表单持续显示 msg 与重试操作，不额外弹相同错误 toast。取消等待用 AbortSignal 中止客户端请求，不提示为网络故障；服务端可能已经完成注册，不能据此宣称“注册已撤销”。用户名唯一约束保证重试不会重复创建同一账号，重复注册时提示前往登录。

### 1.3 分页响应 data

```json
{
  "records": [],
  "page": 1,
  "size": 20,
  "total": 0,
  "pages": 0
}
```

排序需要稳定：同一排序值相同时以 ID 排序。分页数据在并发发布、成交时可能变化，前端按 ID 去重。

## 2. 接口总览

完整地址是在下表路径前加 `/api` 前缀，例如 `/api/auth/login`。

| 模块 | 方法 | 路径 | 鉴权 | 用途 / 当前前端状态 |
| --- | --- | --- | --- | --- |
| 认证 | POST | `/auth/register` | 否 | 注册；已写调用代码 |
| 认证 | POST | `/auth/login` | 否 | 登录；已写调用代码 |
| 认证 | POST | `/auth/logout` | 是 | 撤销当前 Token；待接入 |
| 用户 | GET | `/users/me` | 是 | 当前用户资料；待接入 |
| 用户 | PATCH | `/users/me` | 是 | 修改昵称、头像；预留 |
| 分类 | GET | `/categories` | 否 | 一级分类及分组商品类型；目前 Mock |
| 首页 | GET | `/home/recommendations` | 否 | 热搜、Banner、频道；目前 Mock |
| 商品 | GET | `/goods` | 否 | 搜索、分类、商品流；目前 Mock |
| 商品 | GET | `/goods/{id}` | 否 | 商品详情；目前 Mock |
| 商品 | POST | `/goods` | 是 | 正式发布；已做本机草稿表单，尚未调用此接口 |
| 商品 | PUT | `/goods/{id}` | 是 | 正式编辑；本地预填/草稿展示，尚未调用此接口 |
| 商品 | PATCH | `/goods/{id}/status` | 是 | 上架 / 下架；预留 |
| 商品 | DELETE | `/goods/{id}` | 是 | 软删除商品；预留 |
| 商品 | GET | `/users/me/goods` | 是 | 我发布的商品；预留 |
| 图片 | POST | `/uploads/images` | 是 | 上传商品图片 / 头像；待接入 |
| 订单 | POST | `/orders` | 是 | 买家创建订单；待接入 |
| 订单 | GET | `/users/me/orders` | 是 | 已做买入/卖出切换，真实查询尚未接入 |
| 订单 | GET | `/orders/{id}` | 是 | 订单详情；预留 |
| 订单 | POST | `/orders/{id}/confirm` | 是 | 卖家确认交易；预留 |
| 订单 | POST | `/orders/{id}/complete` | 是 | 买家确认完成；预留 |
| 订单 | POST | `/orders/{id}/cancel` | 是 | 取消待确认订单；预留 |
| 反馈 | POST | `/feedback` | 是 | 在线提交反馈；目前仅保存本机 |
| 开发验证 | GET | `/health` | 否 | 教程提供的健康检查示例，前端不调用 |

消息聊天、支付、物流、退款和实名认证不在本版接口范围内，需要另行定义业务流程后扩展。

## 3. 注册、登录与用户

### POST `/auth/register`

```json
{ "username": "xiaolin", "password": "example123" }
```

| 字段 | 类型 | 必填 | 校验 |
| --- | --- | --- | --- |
| username | string | 是 | 去除首尾空白，3～32 位字母、数字或下划线；不区分大小写唯一 |
| password | string | 是 | 必须非空白，6～64 位，UTF-8 编码不超过 72 字节，不自动 trim；只保存 BCrypt 哈希 |

当前 AccountForm 已校验用户名格式、密码 6～64 位、UTF-8 最多 72 字节及两次密码一致。确认密码仅前端使用，不发送到接口。后端仍需独立校验；BCrypt 不能静默截断超过 72 字节的密码。长度上限按前端 JS string.length / Java String.length 保持一致，UTF-8 字节数另行检查。

成功 data：

```json
{ "id": "10001", "username": "xiaolin" }
```

注册后不自动登录，前端转到登录页。重复用户名返回 409 / USERNAME_EXISTS。

### POST `/auth/login`

请求体同注册，不包含确认密码。登录前端仅检查用户名/密码非空；服务端校验长度并按账号规则匹配，不能把注册页确认密码规则应用到登录。错误用户名或密码统一返回 401 / INVALID_CREDENTIALS，不透露账号是否存在。

成功 data 必须包含非空 `token` 和 `userInfo`：

```json
{
  "token": "server-issued-access-token",
  "expiresIn": 7200,
  "userInfo": {
    "id": "10001",
    "username": "xiaolin",
    "nickname": "小林的衣橱",
    "avatarUrl": null,
    "createdAt": "2026-10-06T10:00:00Z"
  }
}
```

`expiresIn` 为有效秒数，示例 7200 秒，实际由服务端配置。当前前端不刷新 Token，过期后重新登录。成功响应和密码字段不写入业务日志。

登录成功后前端返回经过安全校验的站内 redirect；注册后转登录，保留原目标路径。redirect 不属于 API 请求体，后端不能把客户端提供的任意地址用作登录重定向。

### POST `/auth/logout`

无请求体，成功 `data: null`。撤销当前 Token 至其原过期时间；再次对已失效 Token 调用可返回 401。当前前端 logout 仅清除本地状态，对接后应调用此接口并在 finally 中清理本地状态。

### GET `/users/me`

返回与登录响应中的 `userInfo` 相同的资料对象，不包含密码和私密联系方式。

### PATCH `/users/me`

```json
{ "nickname": "周末听歌", "avatarFileId": "file-1001" }
```

两个字段均可省略，但至少提供一个。昵称 1～32 位，头像引用当前用户上传且用途为 AVATAR 的文件。`avatarFileId: null` 表示清除头像。成功返回更新后的 userInfo。

## 4. 分类与首页推荐

### GET `/categories`

无请求参数。返回数组，顺序为显示顺序；一级分类使用稳定字符串 ID：`digital`、`fashion`、`toys`、`beauty`、`books`、`home`、`sports`、`music`。

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

示例省略了其他组和分类，完整类型表对应 `src/data/categoryTypes.js`。类型 ID 在一级分类内唯一；例如 digital 和 music 下都可有 speaker，后端通过 `(categoryId, typeId)` 联合识别并校验组合。`icon` 只能返回前端支持的图标名，不返回可执行 HTML。

### GET `/home/recommendations`

```json
{
  "hotSearches": ["iPhone 15", "富士 X100V", "复古", "Switch", "户外徒步", "香水", "吉他"],
  "banner": {
    "title": "让喜欢的好物，续写新的故事。",
    "subtitle": "不必全新，也能怦然心动。在这里，遇见有故事的物件。",
    "buttonText": "发现心动好物",
    "imageUrl": "/api/media/banner/daily-picks.webp",
    "targetCategoryId": null
  },
  "channels": [
    {
      "id": "fashion",
      "title": "衣橱捡漏",
      "subtitle": "好穿搭，不必花大价钱",
      "categoryId": "fashion",
      "decorationUrl": "/api/media/channels/fashion.webp",
      "backgroundColor": "#fff0ec",
      "goods": [
        { "id": "10003", "title": "复古运动鞋", "coverUrl": "/api/media/goods/shoe.webp", "price": 239 },
        { "id": "10007", "title": "法式复古托特包", "coverUrl": "/api/media/goods/bag.webp", "price": 159 }
      ]
    }
  ]
}
```

新版首页使用四个摄影频道卡片，decorationUrl 为频道主图；goods 为可选扩展数据，当前模板不渲染迷你商品。频道最多 4 个，每个最多 2 件可售商品；空频道不展示。图片 URL 应为同源地址或可信媒体域名。开发建议使用 `/api/media/**`，可直接经过现有 Vite `/api` 代理；若改用 `/media/**`，需另配 Vite 代理。链接目标由 categoryId 或 goods ID 决定，不允许任意跳转脚本。

## 5. 商品

### 5.1 商品字段模型

```json
{
  "id": "10003",
  "categoryId": "fashion",
  "typeId": "shoe",
  "title": "New Balance 530 复古运动鞋 37码",
  "description": "个人自用，穿过两次，无明显磨损。",
  "price": 239,
  "originalPrice": 799,
  "condition": "LIKE_NEW",
  "conditionLabel": "95新",
  "coverUrl": "/api/media/goods/shoe.webp",
  "images": [{ "fileId": "file-2001", "url": "/api/media/goods/shoe.webp" }],
  "seller": { "id": "10001", "nickname": "小林的衣橱", "avatarUrl": null },
  "sellerType": "PERSONAL",
  "location": "南京",
  "wantedCount": 37,
  "status": "ON_SALE",
  "createdAt": "2026-10-06T10:00:00Z",
  "updatedAt": "2026-10-06T10:00:00Z",
  "version": 1
}
```

`description`、`images`、`version` 仅详情必需，列表可省略；其他字段在列表和详情均返回。`originalPrice`、avatarUrl 可为 null，wantedCount 默认 0。本版未定义收藏/想要操作，不能把该字段视为已接入的互动功能。

| 枚举 | 可选值 |
| --- | --- |
| condition | NEW 全新、NEAR_NEW 几乎全新/99新、LIKE_NEW 95新、GOOD 9成新、USED 有使用痕迹 |
| status | ON_SALE 在售、RESERVED 订单占用、SOLD 已售、OFF_SHELF 下架 |
| sellerType | 本版只允许 PERSONAL |

成色展示由 conditionLabel 提供；后端根据 condition 生成。消耗品余量等细节写入 description，不能把“余量8成”用作通用成色枚举。

### GET `/goods`

示例：`/api/goods?categoryId=digital&typeId=phone&keyword=iPhone&page=1&size=20&sort=latest`

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| keyword | 否 | 搜索标题/描述，去除首尾空白，最长 100 位 |
| categoryId | 否 | 一级分类；省略表示全部，不能传 UI 专用的 all / personal |
| typeId | 否 | 具体类型；提供时必须同时提供合法 categoryId |
| sellerType | 否 | PERSONAL，对应“个人闲置”Tab |
| minPrice / maxPrice | 否 | 非负，最多两位小数，最小值不大于最大值 |
| sort | 否 | latest 默认、priceAsc、priceDesc；拒绝未定义值 |
| page / size | 否 | 遵循统一分页 |

只返回 ON_SALE 且未删除的商品；类型存在但暂时没有商品时返回空分页。成功 data 为分页对象，records 每项采用商品列表字段。latest 使用 createdAt DESC、id DESC；priceAsc/priceDesc 使用价格升/降序，再按 id 排序。当前 UI“默认推荐”内部值 recommended 映射为省略 sort（后端默认 latest），不代表个性化推荐已实现。

当前没有 minPrice/maxPrice 输入控件，参数为预留。清除分类时同时清除 typeId；切换关键词、分类、类型或排序时重置 page=1。请求失败与空分页是两种状态，失败显示可重试错误，不显示“没有商品”；并发请求需取消旧请求或只应用最近一次响应，避免旧搜索覆盖新条件。

### GET `/goods/{id}`

返回完整商品详情。ON_SALE、RESERVED、SOLD 可公开查看，以显示当前状态。OFF_SHELF 仅卖家本人可查看，其他人返回 404；已软删除商品返回 404。可选 Token 无效时返回 401，不自动按匿名请求继续处理。

### POST `/goods`

```json
{
  "categoryId": "fashion",
  "typeId": "shoe",
  "title": "New Balance 530 复古运动鞋 37码",
  "description": "个人自用，穿过两次，无明显磨损。",
  "price": 239,
  "originalPrice": 799,
  "condition": "LIKE_NEW",
  "imageIds": ["file-2001", "file-2002"],
  "location": "南京"
}
```

除 originalPrice 外均必填。标题 2～80 位；描述 10～2000 位；location 为城市名称，1～50 位；这些文本不能全为空白。price 大于 0 且不超过 999999.99；originalPrice 可为 null，非 null 时大于等于 price。imageIds 为 1～9 个互不重复、属于当前用户、用途为 GOODS 的有效图片 ID，首张作为封面。categoryId 和 typeId 必须为有效组合。

发布后为 ON_SALE，成功返回完整商品对象。卖家身份、创建时间、状态和 version 由服务端生成，不接受客户端覆盖。

当前“保存草稿”与“预览信息”都不调用此接口。正式提交后只有收到服务端成功响应才能显示“发布成功”。超时或客户端取消不等于提交回滚，不能自动重复 POST；应先核对发布记录，或在后续契约中补充发布幂等机制。

### PUT `/goods/{id}`

仅卖家本人可操作。请求体与发布相同，另加必填 `version`；表示完整替换可编辑字段，缺字段返回 400。只有 ON_SALE / OFF_SHELF 可编辑；version 不匹配或订单占用返回 409。后端原子递增版本，返回更新后的完整对象。编辑请求不直接改变上架状态。

### PATCH `/goods/{id}/status`

```json
{ "status": "OFF_SHELF", "version": 1 }
```

仅卖家可操作，只允许 ON_SALE ↔ OFF_SHELF；不能通过此接口把商品设为 RESERVED / SOLD，也不能重新上架已售商品。version 必填，冲突返回 409；成功返回更新后的商品对象。

### DELETE `/goods/{id}`

必填查询参数 `version`，例如 `/api/goods/10003?version=1`。仅卖家可软删除 ON_SALE / OFF_SHELF 商品，其他状态返回 409。成功 `data: null`。删除不影响已存在订单的商品快照。

### GET `/users/me/goods`

参数：status 可选，加 page / size。只查当前用户未删除商品，按创建时间倒序，返回商品列表分页。可返回全部四种状态。

## 6. 图片上传

### POST `/uploads/images`

multipart 表单字段：

| 字段 | 类型 | 必填 | 说明 |
| --- | --- | --- | --- |
| file | binary | 是 | 单张 JPEG、PNG 或 WebP，最大 5 MiB |
| purpose | string | 是 | GOODS 或 AVATAR |

后端检查实际图片内容而非只看扩展名/客户端 MIME，生成自己的文件名，并记录上传者和用途。文件不存为可执行资源；原始文件名不直接用于路径。客户端不设置 multipart 的 boundary，由浏览器生成。

成功 data：

```json
{
  "fileId": "file-2001",
  "url": "/api/media/goods/shoe.webp",
  "width": 1200,
  "height": 1200,
  "size": 245760
}
```

发布/修改提交 fileId，不提交任意图片 URL。未被商品或头像引用的文件建议定期清理；被订单快照引用的媒体按订单留存策略保留，不随商品删除立即移除。

## 7. 订单与买入 / 卖出记录

本版定义线下交付的最小交易流程，不包含在线支付。订单只有一件闲置商品、数量固定为 1。在线支付与退款接入前不能把此流程描述为付款成功或资金托管。

### 7.1 状态与操作权限

| 当前状态 | 操作 | 操作人 | 新状态 / 商品状态 |
| --- | --- | --- | --- |
| 无订单，商品 ON_SALE | 创建 | 非卖家的登录买家 | PENDING / RESERVED |
| PENDING | 确认交易 | 卖家 | CONFIRMED / RESERVED |
| PENDING | 取消 | 买家或卖家 | CANCELLED / ON_SALE |
| PENDING | 超时未确认 | 服务端任务 | CANCELLED / ON_SALE |
| CONFIRMED | 确认完成 | 买家 | COMPLETED / SOLD |

待确认有效期建议 30 分钟，由服务端配置并通过 expiresAt 返回；CONFIRMED 后不自动超时释放。本版不支持已确认订单直接取消、完成后退款；非法迁移返回 409。任何订单释放只能释放自己占用的商品，不能覆盖其他订单状态。

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

goods 为创建订单时保存的快照，后续商品编辑不改变订单标题、图片或价格。amount 来自服务端价格，不接受客户端指定。

### POST `/orders`

请求头：`Idempotency-Key: <客户端生成的唯一字符串>`，必填，最长 64 位。同一次提交的重试必须复用相同 Key，新交易使用新 Key。

```json
{ "goodsId": "10003", "expectedPrice": 239, "remark": "希望周末同城交付" }
```

goodsId、expectedPrice 必填，remark 可选且最多 200 位。expectedPrice 仅用于发现价格变化，不用于结算；与服务端价格不同返回 409 / PRICE_CHANGED。不得购买自己的商品，返回 403。商品非 ON_SALE 返回 409 / GOODS_UNAVAILABLE。

同一用户 + Key + 相同请求重复调用返回原订单；相同 Key 配不同请求返回 409 / IDEMPOTENCY_CONFLICT。Key 结果至少保留 24 小时，订单已取消时重复 Key 仍返回该原订单，不能创建新订单。

服务端在同一事务中原子检查可售状态、占用商品并创建订单；并发买家最多一人成功。成功返回订单对象。

### GET `/users/me/orders`

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| role | 是 | buy 我买到的、sell 我卖出的，与前端 Tab 一致 |
| status | 否 | PENDING、CONFIRMED、COMPLETED、CANCELLED |
| page / size | 否 | 统一分页 |

返回订单分页，按创建时间倒序。查询仅基于当前用户，不允许客户端指定其他用户 ID。

### GET `/orders/{id}`

只允许订单买卖双方读取，成功返回订单对象；非参与者返回 403，不存在返回 404。

### POST `/orders/{id}/confirm`

无请求体。仅订单卖家可将 PENDING 转为 CONFIRMED，检查 expiresAt；已过期返回 409 / ORDER_EXPIRED。重复确认已为 CONFIRMED 的订单直接返回当前订单。

### POST `/orders/{id}/complete`

无请求体。仅订单买家可将 CONFIRMED 转为 COMPLETED，同时将该订单占用的商品设为 SOLD。重复完成直接返回当前订单。

### POST `/orders/{id}/cancel`

```json
{ "reason": "暂时不需要了" }
```

reason 必填，1～200 位；买卖双方仅能取消 PENDING 订单。重复取消返回当前订单，保留第一次取消原因。所有状态操作必须在事务中校验状态和身份；成功均返回订单对象。对于任意其他已终结或不允许迁移的状态，返回 409。

## 8. 反馈

### POST `/feedback`

```json
{ "content": "希望增加商品收藏功能", "pagePath": "/?category=digital" }
```

content 必填，1～500 位；pagePath 可选，最长 500 位，仅站内路径。成功 data 为 `{ "id": "4001", "createdAt": "2026-10-06T10:00:00Z" }`。提交人取自 Token，服务端限制提交频率。本接口待前端接入；当前悬浮栏反馈仅保存在 localStorage。

## 9. 前端对接映射

除认证外，现有页面使用展示型 Mock 字段，需要新增 API 模块和适配层后再替换数据，不能直接假设已经兼容上述模型。

| 现有前端 | 后端字段 / 映射 |
| --- | --- |
| URL `q` | 商品查询 keyword，最长 100 位 |
| URL `category=digital` | categoryId=digital |
| URL `category=all` 或无分类 | 省略 categoryId |
| URL `category=personal` | sellerType=PERSONAL，不传 categoryId=personal |
| URL `type` | typeId，必须同时传有效 categoryId |
| URL `sort=priceAsc/priceDesc` | 原值传 sort |
| 无 sort / UI recommended | 省略 sort，后端默认 latest；不是个性化排序 |
| 商品 category / kind | categoryId / typeId |
| 商品 condition 文本 | conditionLabel；表单提交 condition 枚举 |
| 商品 original | originalPrice |
| 商品 seller 字符串 | seller.nickname；组件需要适配 seller 对象 |
| 商品 avatar 颜色 | avatarUrl；为空时保留首字头像占位 |
| 商品 wanted | wantedCount |
| ProductVisual 本地图片 / ProductArt SVG | coverUrl / images；组件需接收后端 URL，可保留本地素材作为失败占位 |
| 商品个人闲置标记 | sellerType=PERSONAL |
| 订单 Tab buy / sell | role=buy / role=sell |
| 草稿 category / type | 发布时转换为 categoryId / typeId |
| 草稿 price 字符串 | 校验后转换为人民币元 JSON number；后端用 BigDecimal |
| 草稿 condition 中文 | 使用下表枚举转换，不能直接发送中文成色 |

订单提交只发送商品 ID 与预期价格，客户端格式化价格不参与结算。当前编辑页面尚不保存后端 version；接入详情与编辑接口后需记录并提交该版本。刷新页面可调用 `/users/me` 恢复最新资料，收到 401 沿用统一退出处理。

### 9.1 发布草稿的字段转换

| 当前表单成色 | API condition |
| --- | --- |
| 全新 | NEW |
| 几乎全新 / 99新 | NEAR_NEW |
| 95新 | LIKE_NEW |
| 9成新 | GOOD |
| 有使用痕迹 | USED |

NEAR_NEW 的两种前端文案在后端使用同一枚举，回显以服务端 conditionLabel 为准。当前草稿没有 originalPrice、imageIds、version；正式发布还需要上传组件，编辑还需要获取版本。当前默认照片是生成的展示素材，不能作为用户已经上传的照片 ID。

### 9.2 本机草稿与撤销范围

本机键为 market_draft_<userId或username>_<goodsId或new>，值结构为 `{ "fields": { "category": "", "type": "", "title": "", "description": "", "condition": "", "price": "", "location": "" }, "savedAt": "ISO时间" }`。不完整或尚不合法的字段可以保存草稿；预览/正式发布另行校验。

清除草稿、清除搜索历史、移除筛选、保存反馈的撤销均为本地行为，不增加服务器 DELETE/restore 接口。跨设备草稿同步和草稿发布事务不在本版契约中；以后若增加，需要单独定义草稿 ID、版本和归属，不能把未完成草稿混入公开商品列表。

### 9.3 接口错误与可用性状态

| 情况 | 服务端 / 前端行为 |
| --- | --- |
| 查询成功但无记录 | 200 + 空 records；页面提供减少筛选或浏览全部 |
| 服务不可用 | 503 + 可行动 msg；页面保留当前条件并允许重试 |
| 字段校验失败 | 400 + errors（字段名使用 API 名称）；适配到表单字段旁，保留输入 |
| 版本/订单状态冲突 | 409；提供重新加载详情或返回列表，不静默覆盖 |
| 客户端停止等待 | 仅中止客户端等待，不保证服务端业务撤销；不显示成功或“已取消交易” |
| 真实订单服务失败 | 显示失败/未开放状态；不能伪装为没有订单 |

当前 request.js 将返回体中的 msg 转为 JavaScript Error.message，业务页面直接读取 error.message；原始三字段返回体保留在 error.response.data 中。

## 10. 联调验收与实现顺序

1. 先实现 register、login、users/me、logout，验证当前登录表单可用以及过期 Token 的 401 行为。
2. 实现 categories、home/recommendations、goods 列表和详情，再将首页 Mock 替换为 API 数据并保留空态。
3. 实现图片上传、发布、编辑、上下架；验证只能修改自己的商品，冲突时返回 409。
4. 实现订单创建、买卖记录与状态流转；验证并发下单、幂等重试、取消释放和超时任务。
5. 接入在线反馈；消息、支付、物流另行制定接口。

服务端安全过滤器的 401/403 也必须返回本文 JSON 格式；不要返回 HTML 登录页或 302。开发优先使用 Vite 同源代理，部署后反向代理 `/api/**` 到后端。跨域直连时仅允许配置的前端 Origin 与必要请求头（含 Authorization、Content-Type、Idempotency-Key）。

### 登录与查询示例（PowerShell）

```powershell
$loginBody = @{ username = 'xiaolin'; password = 'example123' } | ConvertTo-Json
$loginResult = Invoke-RestMethod -Method Post -Uri 'http://localhost:8080/api/auth/login' -ContentType 'application/json' -Body $loginBody
$authHeaders = @{ Authorization = "Bearer $($loginResult.data.token)" }
Invoke-RestMethod -Uri 'http://localhost:8080/api/users/me' -Headers $authHeaders
Invoke-RestMethod -Uri 'http://localhost:8080/api/goods?categoryId=digital&typeId=phone&page=1&size=20'
```

示例账号需先注册，且只有后端实现并启动后这些命令才可执行。

## 11. 本地建项目与联调验收

见 [IDE 创建与依赖配置教程](backend-setup.md)。先验证 `/api/health`，再验证注册/登录，随后逐步替换 Mock。草稿、搜索历史和帮助当前无需服务端实现。重构后的界面验收见 [可用性设计规范](usability-design.md)。

