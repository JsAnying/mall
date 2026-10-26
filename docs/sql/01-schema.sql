-- 拾光闲置：接口契约 v1.1 的完整初始结构，2026-10-12
-- MySQL 8.4 / 9.x，InnoDB，UTF-8。仅用于空库初始化，不是升级迁移。
-- 先按 backend-setup.md 第 4 节确认现有 root 账号能访问开发库。
-- 本文件不创建账号、不删除表、不插入用户或订单。
USE shiguang_market_dev;
SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- 1. 用户。注册时 password_hash 必须来自 BCryptPasswordEncoder。
CREATE TABLE users (
    id BIGINT NOT NULL AUTO_INCREMENT,
    username VARCHAR(32) NOT NULL,
    password_hash VARCHAR(100) NOT NULL,
    nickname VARCHAR(32) NOT NULL,
    avatar_file_id VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    CONSTRAINT uk_users_username UNIQUE (username),
    CONSTRAINT ck_users_username CHECK (REGEXP_LIKE(username, '^[A-Za-z0-9_]{3,32}$')),
    CONSTRAINT ck_users_nickname CHECK (CHAR_LENGTH(TRIM(nickname)) BETWEEN 1 AND 32)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户账号与公开资料';

-- 2. 上传文件。file ID 由应用生成 UUID/随机字符串；path 相对 upload-dir。
CREATE TABLE uploaded_files (
    id VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    owner_id BIGINT NOT NULL,
    purpose VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    storage_path VARCHAR(512) COLLATE utf8mb4_0900_as_cs NOT NULL,
    url VARCHAR(512) NOT NULL,
    mime_type VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    size_bytes BIGINT NOT NULL,
    width INT NOT NULL,
    height INT NOT NULL,
    sha256 CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uk_files_path (storage_path),
    UNIQUE KEY uk_files_owner_purpose (id, owner_id, purpose),
    KEY idx_files_owner_created (owner_id, created_at, id),
    KEY idx_files_created (created_at, id),
    CONSTRAINT fk_files_owner FOREIGN KEY (owner_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_files_purpose CHECK (purpose IN ('GOODS', 'AVATAR')),
    CONSTRAINT ck_files_mime CHECK (mime_type IN ('image/jpeg', 'image/png', 'image/webp')),
    CONSTRAINT ck_files_size CHECK (size_bytes BETWEEN 1 AND 5242880),
    CONSTRAINT ck_files_dimensions CHECK (width > 0 AND height > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='已验证的上传图片';

-- 用户和文件有相互引用，先建两个表再补头像外键；归属和 AVATAR 用途由 Service 校验。
ALTER TABLE users ADD CONSTRAINT fk_users_avatar
    FOREIGN KEY (avatar_file_id) REFERENCES uploaded_files (id) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- 3. 一级分类。
CREATE TABLE categories (
    id VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    name VARCHAR(50) NOT NULL,
    icon VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    hint VARCHAR(100) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    enabled TINYINT NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    KEY idx_categories_sort (enabled, sort_order, id),
    CONSTRAINT ck_categories_enabled CHECK (enabled IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='一级分类';

-- 4. 分类浮层分组，例如“手机与电脑”。
CREATE TABLE category_groups (
    id BIGINT NOT NULL AUTO_INCREMENT,
    category_id VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    title VARCHAR(50) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    PRIMARY KEY (id),
    UNIQUE KEY uk_groups_category_title (category_id, title),
    UNIQUE KEY uk_groups_id_category (id, category_id),
    KEY idx_groups_sort (category_id, sort_order, id),
    CONSTRAINT fk_groups_category FOREIGN KEY (category_id) REFERENCES categories (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='分类下的类型分组';

-- 5. 商品类型。同一 type ID 可以在不同一级分类中出现。
CREATE TABLE category_types (
    category_id VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    id VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    group_id BIGINT NOT NULL,
    name VARCHAR(50) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    enabled TINYINT NOT NULL DEFAULT 1,
    PRIMARY KEY (category_id, id),
    KEY idx_types_group_sort (group_id, category_id, sort_order, id),
    CONSTRAINT fk_types_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_types_group FOREIGN KEY (group_id, category_id) REFERENCES category_groups (id, category_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_types_enabled CHECK (enabled IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='具体商品类型';

-- 6. 商品。封面由 goods_images 的 sort_order=1 对应文件给出。
CREATE TABLE goods (
    id BIGINT NOT NULL AUTO_INCREMENT,
    seller_id BIGINT NOT NULL,
    category_id VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    type_id VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    title VARCHAR(80) NOT NULL,
    description VARCHAR(2000) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2) NULL,
    condition_code VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    seller_type VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'PERSONAL',
    location VARCHAR(50) NOT NULL,
    wanted_count INT NOT NULL DEFAULT 0,
    status VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'ON_SALE',
    reserved_order_id BIGINT NULL,
    version INT NOT NULL DEFAULT 1,
    deleted_at DATETIME(3) NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uk_goods_id_seller (id, seller_id),
    KEY idx_goods_fk_seller (seller_id),
    KEY idx_goods_fk_type (category_id, type_id),
    KEY idx_goods_feed (status, deleted_at, created_at, id),
    KEY idx_goods_category_feed (category_id, status, deleted_at, created_at, id),
    KEY idx_goods_type_feed (category_id, type_id, status, deleted_at, created_at, id),
    KEY idx_goods_price (status, deleted_at, price, id),
    KEY idx_goods_category_price (category_id, status, deleted_at, price, id),
    KEY idx_goods_seller (seller_id, deleted_at, created_at, id),
    CONSTRAINT fk_goods_seller FOREIGN KEY (seller_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_goods_type FOREIGN KEY (category_id, type_id) REFERENCES category_types (category_id, id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_goods_title CHECK (CHAR_LENGTH(TRIM(title)) BETWEEN 2 AND 80),
    CONSTRAINT ck_goods_description CHECK (CHAR_LENGTH(TRIM(description)) BETWEEN 10 AND 2000),
    CONSTRAINT ck_goods_price CHECK (price > 0 AND price <= 999999.99),
    CONSTRAINT ck_goods_original CHECK (original_price IS NULL OR original_price >= price),
    CONSTRAINT ck_goods_condition CHECK (condition_code IN ('NEW', 'NEAR_NEW', 'LIKE_NEW', 'GOOD', 'USED')),
    CONSTRAINT ck_goods_seller_type CHECK (seller_type = 'PERSONAL'),
    CONSTRAINT ck_goods_location CHECK (CHAR_LENGTH(TRIM(location)) BETWEEN 1 AND 50),
    CONSTRAINT ck_goods_count CHECK (wanted_count >= 0),
    CONSTRAINT ck_goods_version CHECK (version >= 1),
    CONSTRAINT ck_goods_status CHECK (status IN ('ON_SALE', 'RESERVED', 'SOLD', 'OFF_SHELF')),
    CONSTRAINT ck_goods_reservation CHECK (reserved_order_id IS NULL OR status = 'RESERVED')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='闲置商品及占用状态';

-- 7. 商品图片。1..9 的唯一位置约束保证最多 9 张，至少一张由发布事务校验。
CREATE TABLE goods_images (
    id BIGINT NOT NULL AUTO_INCREMENT,
    goods_id BIGINT NOT NULL,
    seller_id BIGINT NOT NULL,
    file_id VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    purpose VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'GOODS',
    sort_order TINYINT NOT NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    UNIQUE KEY uk_images_position (goods_id, sort_order),
    UNIQUE KEY uk_images_file (goods_id, file_id),
    CONSTRAINT fk_images_goods_owner FOREIGN KEY (goods_id, seller_id) REFERENCES goods (id, seller_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_images_file_owner FOREIGN KEY (file_id, seller_id, purpose) REFERENCES uploaded_files (id, owner_id, purpose) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_images_position CHECK (sort_order BETWEEN 1 AND 9),
    CONSTRAINT ck_images_purpose CHECK (purpose = 'GOODS')
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='商品图片顺序及归属';

-- 8. 订单。单商品、数量固定 1；保留成交时的商品快照。
CREATE TABLE orders (
    id BIGINT NOT NULL AUTO_INCREMENT,
    order_no VARCHAR(40) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    goods_id BIGINT NOT NULL,
    buyer_id BIGINT NOT NULL,
    seller_id BIGINT NOT NULL,
    status VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT 'PENDING',
    amount DECIMAL(10,2) NOT NULL,
    goods_title VARCHAR(80) NOT NULL,
    goods_cover_file_id VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    goods_cover_url VARCHAR(512) NOT NULL,
    goods_condition_code VARCHAR(16) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    goods_condition_label VARCHAR(20) NOT NULL,
    goods_price DECIMAL(10,2) NOT NULL,
    remark VARCHAR(200) NULL,
    expires_at DATETIME(3) NOT NULL,
    confirmed_at DATETIME(3) NULL,
    completed_at DATETIME(3) NULL,
    cancelled_at DATETIME(3) NULL,
    cancel_reason VARCHAR(200) NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
    active_goods_id BIGINT GENERATED ALWAYS AS
        (CASE WHEN status IN ('PENDING', 'CONFIRMED') THEN goods_id ELSE NULL END) STORED,
    PRIMARY KEY (id),
    UNIQUE KEY uk_orders_no (order_no),
    UNIQUE KEY uk_orders_active_goods (active_goods_id),
    UNIQUE KEY uk_orders_id_goods (id, goods_id),
    KEY idx_orders_buy (buyer_id, created_at, id),
    KEY idx_orders_buy_status (buyer_id, status, created_at, id),
    KEY idx_orders_sell (seller_id, created_at, id),
    KEY idx_orders_sell_status (seller_id, status, created_at, id),
    KEY idx_orders_timeout (status, expires_at, id),
    KEY idx_orders_goods (goods_id, seller_id),
    CONSTRAINT fk_orders_goods_owner FOREIGN KEY (goods_id, seller_id) REFERENCES goods (id, seller_id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_orders_buyer FOREIGN KEY (buyer_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_orders_seller FOREIGN KEY (seller_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_orders_cover FOREIGN KEY (goods_cover_file_id) REFERENCES uploaded_files (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_orders_parties CHECK (buyer_id <> seller_id),
    CONSTRAINT ck_orders_status CHECK (status IN ('PENDING', 'CONFIRMED', 'COMPLETED', 'CANCELLED')),
    CONSTRAINT ck_orders_amount CHECK (amount > 0 AND amount <= 999999.99 AND amount = goods_price),
    CONSTRAINT ck_orders_condition CHECK (goods_condition_code IN ('NEW', 'NEAR_NEW', 'LIKE_NEW', 'GOOD', 'USED')),
    CONSTRAINT ck_orders_expiry CHECK (expires_at > created_at),
    CONSTRAINT ck_orders_confirmed CHECK (status NOT IN ('CONFIRMED', 'COMPLETED') OR confirmed_at IS NOT NULL),
    CONSTRAINT ck_orders_completed CHECK (status <> 'COMPLETED' OR completed_at IS NOT NULL),
    CONSTRAINT ck_orders_cancelled CHECK (status <> 'CANCELLED' OR
        (cancelled_at IS NOT NULL AND cancel_reason IS NOT NULL AND CHAR_LENGTH(TRIM(cancel_reason)) > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='线下交付订单与商品快照';

-- 确保占用指针引用的是本商品的订单，而不是别的商品的订单。
ALTER TABLE goods ADD CONSTRAINT fk_goods_reserved_order
    FOREIGN KEY (reserved_order_id, id) REFERENCES orders (id, goods_id) ON DELETE RESTRICT ON UPDATE RESTRICT;

-- 9. 订单幂等记录。先占 Key，再创建订单，最后填 order_id，整个流程在同一事务中。
CREATE TABLE order_idempotency (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    idempotency_key VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    request_hash CHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    order_id BIGINT NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    expires_at DATETIME(3) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_idempotency_user_key (user_id, idempotency_key),
    UNIQUE KEY uk_idempotency_order (order_id),
    KEY idx_idempotency_expiry (expires_at, id),
    CONSTRAINT fk_idempotency_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_idempotency_order FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_idempotency_expiry CHECK (expires_at >= DATE_ADD(created_at, INTERVAL 24 HOUR))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='订单创建请求去重，至少保留24小时';

-- 10. Token 撤销。只存 jti，不存完整 JWT。
CREATE TABLE revoked_tokens (
    token_jti VARCHAR(64) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    user_id BIGINT NOT NULL,
    expires_at DATETIME(3) NOT NULL,
    revoked_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (token_jti),
    KEY idx_revoked_expiry (expires_at),
    KEY idx_revoked_user (user_id),
    CONSTRAINT fk_revoked_user FOREIGN KEY (user_id) REFERENCES users (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='登出后的JWT撤销记录';

-- 11. 在线反馈。本机建议不会自动同步到这个表。
CREATE TABLE feedback (
    id BIGINT NOT NULL AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    content VARCHAR(500) NOT NULL,
    page_path VARCHAR(500) NULL,
    created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    PRIMARY KEY (id),
    KEY idx_feedback_user (user_id, created_at, id),
    KEY idx_feedback_created (created_at, id),
    CONSTRAINT fk_feedback_user FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_feedback_content CHECK (CHAR_LENGTH(TRIM(content)) BETWEEN 1 AND 500),
    CONSTRAINT ck_feedback_path CHECK (page_path IS NULL OR
        (LEFT(page_path, 1) = '/' AND LEFT(page_path, 2) <> '//'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='用户在线反馈';

-- 12. 热搜词。
CREATE TABLE home_hot_searches (
    id BIGINT NOT NULL AUTO_INCREMENT,
    keyword VARCHAR(100) NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    enabled TINYINT NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    UNIQUE KEY uk_hot_keyword (keyword),
    KEY idx_hot_sort (enabled, sort_order, id),
    CONSTRAINT ck_hot_enabled CHECK (enabled IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='首页热门搜索配置';

-- 13. 首屏推荐图文。
CREATE TABLE home_banners (
    id BIGINT NOT NULL AUTO_INCREMENT,
    title VARCHAR(120) NOT NULL,
    subtitle VARCHAR(255) NOT NULL,
    button_text VARCHAR(30) NOT NULL,
    image_url VARCHAR(512) NOT NULL,
    target_category_id VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NULL,
    sort_order INT NOT NULL DEFAULT 0,
    enabled TINYINT NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    KEY idx_banners_sort (enabled, sort_order, id),
    CONSTRAINT fk_banners_category FOREIGN KEY (target_category_id) REFERENCES categories (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_banners_enabled CHECK (enabled IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='首页首屏内容配置';

-- 14. 四个兴趣频道。
CREATE TABLE home_channels (
    id VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    category_id VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    title VARCHAR(50) NOT NULL,
    subtitle VARCHAR(100) NOT NULL,
    decoration_url VARCHAR(512) NOT NULL,
    background_color CHAR(7) CHARACTER SET ascii COLLATE ascii_bin NOT NULL DEFAULT '#F5F5F7',
    sort_order INT NOT NULL DEFAULT 0,
    enabled TINYINT NOT NULL DEFAULT 1,
    PRIMARY KEY (id),
    KEY idx_channels_sort (enabled, sort_order, id),
    CONSTRAINT fk_channels_category FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_channels_enabled CHECK (enabled IN (0, 1)),
    CONSTRAINT ck_channels_color CHECK (REGEXP_LIKE(background_color, '^#[0-9A-Fa-f]{6}$'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='首页兴趣频道配置';

-- 15. 频道推荐商品，可选扩展，每频道最多两个位置。
CREATE TABLE home_channel_goods (
    channel_id VARCHAR(32) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
    goods_id BIGINT NOT NULL,
    sort_order TINYINT NOT NULL,
    PRIMARY KEY (channel_id, goods_id),
    UNIQUE KEY uk_channel_goods_position (channel_id, sort_order),
    CONSTRAINT fk_channel_goods_channel FOREIGN KEY (channel_id) REFERENCES home_channels (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_channel_goods_item FOREIGN KEY (goods_id) REFERENCES goods (id) ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_channel_goods_position CHECK (sort_order BETWEEN 1 AND 2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='频道中的可选推荐商品';
