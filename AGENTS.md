# 项目协作约定

## 配套工程

- 前端：`E:/shop`；后端：`E:/shiguang-server/market`。
- 接口契约：`docs/backend-api.md`；后端教程：`docs/backend-setup.md`。当前后端使用 Java 17、Boot 3、MyBatis-Plus 和 `org.example.aispingboot`，仅实现注册。
- 当前注册使用 `user` 表，建表和旧账号复制脚本位于 `E:/shiguang-server/market/sql/`；`docs/sql/01-schema.sql` 的旧 15 表结构保留为后续业务参考，不代表已完成迁移。
- 修改前先读最新代码，保留用户尚未提交的工作。
