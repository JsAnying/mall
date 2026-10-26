# 项目协作约定

## 错误修复的持续总结

用户要求以后每次改错，都更新同一份开发建议文档。

- 统一文档：`E:/shiguang-server/market/docs/development-lessons.md`。
- 修复本前端或配套后端的问题前先阅读该文档，修复后追加按北京时间日期记录的症状、根因、解决办法、验证结果与后续建议。
- 同类建议合并维护，保留历史修复记录；不得记录密码、Token 或密钥，不得把未验证的结果写成已通过。
- 最终回复提供文档链接，并说明实际验证范围。用户对本次任务的明确限制优先。

## 配套工程

- 前端：`E:/shop`；后端：`E:/shiguang-server/market`。
- 接口契约：`docs/backend-api.md`；后端教程：`docs/backend-setup.md`。当前后端使用 Java 17、Boot 3、MyBatis-Plus 和 `org.example.aispingboot`，仅实现注册。
- 当前注册使用 `user` 表，建表和旧账号复制脚本位于 `E:/shiguang-server/market/sql/`；`docs/sql/01-schema.sql` 的旧 15 表结构保留为后续业务参考，不代表已完成迁移。
- 修改前先读最新代码，保留用户尚未提交的工作。
