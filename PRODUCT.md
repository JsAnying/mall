# 拾光闲置

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

面向想浏览、比较个人闲置商品的中文用户，同时支持桌面和手机浏览器。

## Product Purpose

用户本轮明确选择“更快找到商品：商品、搜索和分类优先”。首页先服务发现、筛选和进入详情；发布草稿、订单和账号流程保留。

## Capabilities and Constraints

- 沿用 Vue 3、Vite、Vue Router、Pinia、Element Plus 和现有本地 CSS，不迁移框架。
- 注册已完成真实后端验收；前端通过 /api/auth/register 请求，三字段响应为 code、msg、data。登录接口尚未实现，不将注册成功当作登录成功。
- 商品和价格来自 src/data/market.js 的 15 条本地示例；不编造真实交易、评价或平台规模。
- 搜索、分类、具体类型和价格排序写入 URL。保留搜索历史、清除/撤销筛选、详情返回和滚动行为。
- 发布和订单保留既有登录守卫；发布仅保存当前浏览器草稿，订单明确说明服务尚未开放。
- 帮助、反馈、消息和手机端说明保留；反馈仅保存在本机。

## Brand Commitments

保留“拾光闲置”名称、既有 SVG 标志、中文语气及 public/images 中的现有商品素材。视觉重构不能让示例商品被误认为真实在售。

## Evidence on Hand

本轮前置测试为 4 个文件、18 项通过。重构前 1440/768/390 像素浏览器截图和检测结果在 .taste-skill/before/。开发库与后端的既有验收记录不等于浏览器新页面已验证。
