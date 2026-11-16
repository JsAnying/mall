# 完整建表与初始数据

> 2026-11-08：市场 15 表初始化模板已统一使用 `user`。开发库 `shiguang_market_dev` 已将 7 条外键迁到 `user` 并删除空的旧 `users` 表。当前后端运行需要的表见 [后端启动说明](../backend-setup.md)。

适用当前接口契约 v1.1，数据库为 shiguang_market_dev，MySQL 8.4 / 9.x。文件按 01 → 02 → 03 顺序执行。脚本不创建数据库账号、不设置密码、不删除旧表，也不生成默认登录账号或虚构交易。

| 文件 | 内容 |
| --- | --- |
| [01-schema.sql](01-schema.sql) | 全部 15 张表、外键、唯一索引、CHECK、查询索引 |
| [02-seed.sql](02-seed.sql) | 8 个分类、24 个分组、74 个类型、7 热搜、1 Banner、4 频道 |
| [03-verify.sql](03-verify.sql) | 只读查询，检查表数、配置数据与约束 |

## 执行方法

先按 [建项目教程第 4 节](../backend-setup.md)使用现有 root 账号创建或选择开发库。完整脚本用于空库。如果使用另一个空库，需同步替换三个脚本中的 USE 与 JDBC 库名。已有业务库升级使用独立迁移脚本。

本机 MySQL 9.6 客户端需要启用本地命令，才能使用 SOURCE。在 PowerShell：

```powershell
mysql --commands=ON --default-character-set=utf8mb4 -h localhost -P 3306 -u root -p
```

输入你现有的 root 密码。看到 mysql> 后，先确认当前开发库没有业务表：

```sql
USE shiguang_market_dev;
SHOW TABLES;
```

空库中按顺序执行，每个文件成功后再执行下一个：

```sql
SOURCE E:/shop/docs/sql/01-schema.sql;
SOURCE E:/shop/docs/sql/02-seed.sql;
SOURCE E:/shop/docs/sql/03-verify.sql;
```

如有 SQL 错误，停止后续步骤并检查错误；不要用 --force 忽略错误。DDL 会隐式提交，初始化失败不代表前面已经建好的表自动回滚。重新初始化请用新空库，已有业务数据升级应写单独迁移。

也可在 IDEA Database、MySQL Workbench 或其他数据库客户端中连接开发库，逐个打开 SQL 文件并执行整个文件。默认数据库与账号要选对。第一次成功后，01 和 02 不应重复执行；03 可重复运行。

## 所有表

| 表 | 用途 |
| --- | --- |
| `user` | 用户账号、密码哈希、昵称、头像引用 |
| uploaded_files | 上传图片的归属、用途、路径、尺寸与大小 |
| categories | 一级分类 |
| category_groups | 分类悬浮面板的分组 |
| category_types | 具体类型，分类与类型联合主键 |
| goods | 商品内容、售价、成色、浏览量、状态、版本及软删除 |
| goods_images | 图片顺序，最多 9 张；同时约束文件归属与 GOODS 用途 |
| orders | 买卖记录、商品快照、状态及超时时间 |
| order_idempotency | 同一用户与幂等 Key 去重 |
| revoked_tokens | 退出后撤销 JWT jti |
| feedback | 登录用户的在线反馈 |
| home_hot_searches | 热门搜索配置 |
| home_banners | 首屏文案与图片配置 |
| home_channels | 四个兴趣频道配置 |
| home_channel_goods | 可选的频道商品推荐，每频道最多两个位置 |

当前不需要草稿、搜索历史表：它们保存在浏览器。聊天、支付、物流、退款等没有定义接口，本脚本不提前创建这些业务表。

## 个人中心与商品操作增量

接口契约 v1.6 的以下五张表由 [08-market-profile-and-actions.sql](../../../shiguang-server/market/sql/08-market-profile-and-actions.sql) 创建。先确保已有 `user`、`goods`、`orders`，再执行该增量脚本。脚本选择本机开发配置使用的 `shiguang_market_dev`，可重复执行。

| 表 | 对应功能 | 约束和查询 |
| --- | --- | --- |
| `user_public_profiles` | 个人名片与卖家摘要 | 每个账号最多一行，存放允许公开的地区和最近活跃时间 |
| `user_follows` | 粉丝数和关注数 | 按关注者与被关注者分别查询。每对用户只有一条同向关系，禁止关注自己 |
| `order_reviews` | 信用及评价 | 同一订单的每位评价人最多提交一次。按被评价方、可见状态、创建时间和 ID 查询 |
| `goods_favorites` | 收藏、取消收藏和收藏列表 | 每个账号对同一商品最多一条，按收藏时间与商品 ID 倒序查询 |
| `cart_items` | 加入购物车 | 每个账号对同一商品最多一条，数量固定为一件 |

昵称、头像和加入时间继续读取 `user`。宝贝及发布记录查询 `goods`，买入与卖出记录查询 `orders`。成交数取已完成订单，好评率可由可展示评价计算。信用徽章由后端按信用规则生成。当前 `goods` 暂无包邮字段，详情契约允许 `freeShipping` 返回 `null`。

评价写入时由 Service 核对订单已完成、双方确为该订单参与者。加购时由 Service 检查在售状态与卖家身份。数据库约束负责引用完整性和去重。

2026-11-08 已在 MySQL 9.6.0 的 `shiguang_market_dev` 执行。现有 17 张表的定义和行数核对一致，新增五张空表。隔离库复跑两次迁移，验证了关注与评价查询、收藏排序、联合主键、外键和 `CHECK` 约束。

## 商品浏览量迁移

已有库缺少 `goods.view_count` 时，执行一次 [10-goods-view-count.sql](../../../shiguang-server/market/sql/10-goods-view-count.sql)。该列为非空整数，默认 0，约束禁止负数。旧 `original_price`、`wanted_count` 作为历史数据保留，商品列表只读取当前售价及浏览量。

新版 `01-schema.sql` 已包含 `view_count`，空库初始化后无需执行第 10 号迁移。第 9 号注释脚本面向迁移前的旧结构。

## MyBatis 与接口映射

- 用户、商品、订单、反馈等数据库主键为 BIGINT，Java 用 Long，返回 API 时转成字符串。上传文件 ID 使用应用生成的 UUID/随机字符串；分类和类型使用现有稳定字符串。
- goods.condition_code 对应 API condition；conditionLabel 由枚举生成。price/amount 使用 BigDecimal，不使用 double。
- 封面读取 goods_images.sort_order=1 的文件 URL，商品详情的图片按 sort_order 升序。发布事务保证位置从 1 连续排列且至少一张，SQL 唯一位置约束限制最多 9 张。
- 当前头像服务通过 `user.avatar_file_id` 引用 `user_avatar.id`，头像归属由 Service 校验。`user_avatar` 由后端的 `04-user-avatar.sql` 创建。
- category_groups 按 sort_order 返回，category_types 按组与 sort_order 返回；不用依赖自增 ID 的自然顺序。
- orders 的 goods_title、goods_cover_url、goods_condition_label、goods_price 是下单快照。JSON goods.id 来自 goods_id，amount 不能由客户端指定。快照图片由商品封面推导，Service 不能接受任意文件 ID。
- seed 中首页图片引用前端已有 public/images 素材，用于本地联调；不是用户上传图片或真实在售商品。正式内容可换成 /api/media 地址。
- home_channel_goods 初始为空，当前频道模板只需要主图与文案；若返回迷你商品，查询时过滤已删除/非 ON_SALE 的商品。

## 时间与事务要求

时间字段使用 DATETIME(3)，统一按 UTC 存取。脚本 SET time_zone 只影响执行脚本的连接；Spring 的 JDBC URL 使用 `connectionTimeZone=UTC&forceConnectionTimeZoneToSession=true`，让 CURRENT_TIMESTAMP 默认值和更新时间也按 UTC 生成。Java LocalDateTime 转 API ISO 时间时显式关联 UTC。[Connector/J 官方时间配置](https://dev.mysql.com/doc/connector-j/en/connector-j-connp-props-datetime-types-processing.html)。

下单流程在同一个 @Transactional 事务中：

1. 插入 order_idempotency，绑定当前用户与规范化请求的 SHA-256 摘要，暂时 order_id=NULL。
2. 条件更新商品 ON_SALE → RESERVED，核对 price/version，受影响行数必须为 1。
3. 从数据库读取价格、卖家、封面，插入 PENDING 订单并获得 ID。
4. 回写 goods.reserved_order_id，并绑定幂等记录 order_id，然后提交。

任意步骤失败全部回滚，不能提交 order_id=NULL 的幂等占位。相同 Key 的并发请求由唯一键处理；查询原记录并比对摘要，不能生成第二笔订单。保留结果至少 24 小时，不把取消订单的幂等记录立即删除。

orders.active_goods_id 为内部生成列，PENDING/CONFIRMED 时等于 goods_id，终态为 NULL。唯一索引保证一个商品最多一个进行中订单，MyBatis insert/update 不填写这个生成列。取消/完成订单时更新状态及时间，再以 reserved_order_id=本订单ID 为条件释放/售出商品并清空占用指针，同一事务提交。

数据库可以检查允许的状态值与部分时间字段，但合法状态迁移、卖家/买家权限、超时任务和价格变化仍必须由 Service 校验。检查 version 条件更新的行数，冲突返回 409。软删除商品不物理删除用户、订单和已被快照引用的图片。

## 验证范围

2026-11-08 在独立 MySQL 9.6 空库重放更新后的三个脚本，确认初始化生成 15 张表和 7 条指向 `user.id` 的账号外键。

脚本已在独立临时 MySQL 9.6 实例执行；全部表和种子数据创建成功，并验证了用户名大小写唯一、分类/类型组合、价格、图片归属/用途/数量、禁止自购、单商品进行中订单唯一、占用指针归属、订单幂等、取消后释放及快照文件留存约束。未对本机 3306 的用户开发库执行初始化。

使用的是 MySQL 8.4 支持的 SQL 语法，实际执行验证版本为 9.6；未另行在 8.4 服务上执行。
