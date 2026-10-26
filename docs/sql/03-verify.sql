-- 只读验收：初次初始化应为 15 张表、8 分类、24 分组、74 类型、7 热搜、1 Banner、4 频道。
USE shiguang_market_dev;
SET NAMES utf8mb4;
SELECT DATABASE() AS current_database;
SHOW TABLES;
SELECT COUNT(*) AS table_count FROM information_schema.tables
WHERE table_schema = DATABASE() AND table_type = 'BASE TABLE';
SELECT 'categories' AS item, COUNT(*) AS row_count FROM categories
UNION ALL SELECT 'category_groups', COUNT(*) FROM category_groups
UNION ALL SELECT 'category_types', COUNT(*) FROM category_types
UNION ALL SELECT 'home_hot_searches', COUNT(*) FROM home_hot_searches
UNION ALL SELECT 'home_banners', COUNT(*) FROM home_banners
UNION ALL SELECT 'home_channels', COUNT(*) FROM home_channels;
SELECT constraint_type, COUNT(*) AS constraint_count
FROM information_schema.table_constraints
WHERE constraint_schema = DATABASE()
GROUP BY constraint_type;
-- 新建后以下业务表为空；以后有真实数据时不要求保持 0。
SELECT 'users' AS item, COUNT(*) AS row_count FROM users
UNION ALL SELECT 'goods', COUNT(*) FROM goods
UNION ALL SELECT 'orders', COUNT(*) FROM orders;
