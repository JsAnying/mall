# 完整建表与初始数据

> 2026-10-25：本文描述旧市场 15 表结构。当前 Java 17 / Boot 3 / MyBatis-Plus 注册工程改用 `user` 表，请使用 `E:/shiguang-server/market/sql/01-user-schema.sql`；旧账号的可选复制脚本为 `02-copy-legacy-users.sql`。不要为重构注册而重新运行整套旧建表脚本；旧 `users` 表及其外键未自动更名。

适用当前接口契约 v1.1，数据库为 shiguang_market_dev，MySQL 8.4 / 9.x。文件按 01 → 02 → 03 顺序执行。脚本不创建数据库账号、不设置密码、不删除旧表，也不生成默认登录账号或虚构交易。

| 文件 | 内容 |
| --- | --- |
| [01-schema.sql](01-schema.sql) | 全部 15 张表、外键、唯一索引、CHECK、查询索引 |
| [02-seed.sql](02-seed.sql) | 8 个分类、24 个分组、74 个类型、7 热搜、1 Banner、4 频道 |
| [03-verify.sql](03-verify.sql) | 只读查询，检查表数、配置数据与约束 |

## 执行方法

先按 [建项目教程第 4 节](../backend-setup.md)使用现有 root 账号创建或选择开发库。完整脚本用于空库；如果你已建过教程中的 users 演示表，先核对现状，使用新空库并替换三个脚本中的 USE 与 JDBC 库名，不要在已有表上反复运行初始化脚本。

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
| users | 用户账号、密码哈希、昵称、头像引用 |
| uploaded_files | 上传图片的归属、用途、路径、尺寸与大小 |
| categories | 一级分类 |
| category_groups | 分类悬浮面板的分组 |
| category_types | 具体类型，分类与类型联合主键 |
| goods | 商品内容、价格、成色、状态、版本及软删除 |
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

## MyBatis 与接口映射

- 用户、商品、订单、反馈等数据库主键为 BIGINT，Java 用 Long，返回 API 时转成字符串。上传文件 ID 使用应用生成的 UUID/随机字符串；分类和类型使用现有稳定字符串。
- goods.condition_code 对应 API condition；conditionLabel 由枚举生成。price/amount 使用 BigDecimal，不使用 double。
- 封面读取 goods_images.sort_order=1 的文件 URL，商品详情的图片按 sort_order 升序。发布事务保证位置从 1 连续排列且至少一张，SQL 唯一位置约束限制最多 9 张。
- users.avatar_file_id 外键只保证文件存在；Service 另外校验文件属于本人且 purpose=AVATAR。
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

脚本已在独立临时 MySQL 9.6 实例执行；全部表和种子数据创建成功，并验证了用户名大小写唯一、分类/类型组合、价格、图片归属/用途/数量、禁止自购、单商品进行中订单唯一、占用指针归属、订单幂等、取消后释放及快照文件留存约束。未对本机 3306 的用户开发库执行初始化。

使用的是 MySQL 8.4 支持的 SQL 语法，实际执行验证版本为 9.6；未另行在 8.4 服务上执行。
