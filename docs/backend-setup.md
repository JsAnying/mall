# 拾光闲置 · 本地 Spring Boot 建项目步骤

> 2026-10-25：当前工程已按新要求迁移为 Java 17 + Spring Boot 3.5.16 + MyBatis-Plus 3.5.17，启动类为 `org.example.aispingboot.AiSpingbootApplication`，本轮仅注册接口。请优先阅读[当前运行说明](../../shiguang-server/market/README.md)和[每个文件的完整代码](../../shiguang-server/market/docs/refactor-complete-source.md)。当前注册使用独立 `user` 表，旧数据不会自动迁移。下方 Boot 4、JDK 21/25、原生 MyBatis/XML 和安全配置内容保留为历史参考，不要直接覆盖新工程配置。

更新：2026-10-16，配套接口契约 v1.1。第 4 节按你已有的 root 账号调整，密码通过本机输入或环境变量填写。完整业务契约见 [接口文档](backend-api.md)。本文以 IntelliJ IDEA 为例，提供项目创建与配置示例；最新实现进展见下一段。

2026-10-24 实现进展：注册接口已实现，统一返回体改为 `code`、`msg`、`data`；当前暂不启用 Spring Security 鉴权，仅保留独立 BCrypt 密码哈希工具。下文安全配置为后续开发参考，不表示当前工程已启用。

验证：MyBatis + Lombok pom.xml 与 7 个 Java 示例已在临时 Maven 工程中编译通过（本机 JDK 25，目标 release 21）；YAML 解析、数据源/MyBatis 配置、Mapper XML 语句绑定、Lombok getter/setter 与构造注入检查通过。没有使用数据库凭据连接 MySQL 或验证业务接口。

## 0. 这次重构对后端工程的影响

| 功能 | 需要后端做什么 |
| --- | --- |
| 表单错误、停止等待 | 返回中文 JSON 错误；取消客户端等待不等于回滚注册 |
| 搜索、分类、价格排序 | 实现 goods 查询；默认推荐映射 latest，升降序支持 priceAsc/priceDesc |
| 本机草稿、预览、清除撤销 | 当前不需要草稿表或接口；保存不调用发布接口 |
| 正式发布/编辑 | 上传真实照片后 POST/PUT goods；编辑检查 version；成色和金额转换见接口文档 |
| 订单买入/卖出 | role=buy/sell 分页；未开放/失败不返回虚构记录 |
| 搜索历史、帮助、快捷键 | 当前仅前端实现，不需要新依赖或接口 |

先完成本教程的最小启动，再逐阶段接入业务。已有项目无需重新生成：按当前 Boot 版本替换持久化依赖、添加 Mapper 与 SQL、启用 Lombok 注解处理即可。草稿当前仍保存在浏览器。

## 1. 技术选择

采用 **Java 21 + Spring Boot 4.0.8 + Maven + MySQL 8.4 + MyBatis Framework + Lombok + Spring Security JWT**。本文使用原生 MyBatis，通过 Mapper/XML 编写 SQL；JWT 使用 Spring Security 自带支持。

2026-10-12 已实际验证 Spring Initializr：MyBatis Framework 在生成器中的版本范围暂为 `[4.0.0, 4.1.0-M1)`，4.1.1 选择该依赖会被拒绝。因此本教程使用可生成的 **Boot 4.0.8 + MyBatis starter 4.0.1**，不推断手工配置 Boot 4.1 的运行兼容性。

| 已有项目版本 | MyBatis starter 系列 | 使用方式 |
| --- | --- | --- |
| Boot 4.0.x | 4.0.x；本文 4.0.1 | 可参考本文完整 pom.xml |
| Boot 3.2–3.5 | 3.0.x | 保留原 Boot 3 parent、Spring Web 与测试依赖，只添加匹配版本的 MyBatis 和 Lombok |

如果你的项目已经选择其他 Boot 版本，先核对 [MyBatis 官方兼容表](https://mybatis.org/spring-boot-starter/mybatis-spring-boot-autoconfigure/)，不要直接覆盖整个 pom.xml。Lombok 由 Boot 管理版本；本教程显式配置注解处理，兼顾 JDK 21 与本机 JDK 25 编译。

建议后端放在 `E:\shiguang-server`，前端继续使用 `E:\shop`。

1. 安装/选择 JDK 21，运行 `java -version` 验证。
2. 安装 MySQL 8.4 并启动服务；默认端口 3306。
3. IDE 的 Project SDK 和 Maven Runner JRE 都选择 21。
4. Maven 使用生成项目内的 Wrapper，无需另装 Maven。自行安装时使用 Maven 3.6.3+。

## 2. 创建与导入

通用流程适用于没有 Spring 项目向导的 IDEA 版本：

1. 打开 [Spring Initializr](https://start.spring.io/)。
2. Project 选 Maven；Language 选 Java；Boot 选 **4.0.8 正式版**。
3. Group：`com.shiguang`；Artifact / Name：`shiguang-server`。
4. Package name：`com.shiguang.market`；Packaging：Jar；Java：21。
5. Add Dependencies 添加 **Spring Web、MyBatis Framework、Lombok、Validation、MySQL Driver、Spring Security、OAuth2 Resource Server**。
6. Generate 下载，解压到 `E:\shiguang-server`，确认该目录下有 `pom.xml` 和 `mvnw.cmd`。
7. IDEA：File → Open → 选择项目目录或 pom.xml → 导入 Maven，等待依赖下载。
8. Project Structure 中设置 SDK 21；Maven 设置使用 Wrapper，Runner JRE 21。
9. Settings → Build, Execution, Deployment → Compiler → Annotation Processors，启用 **Enable annotation processing**；若编辑器无法识别 getter/构造方法，检查 Lombok 插件支持并 Reload Maven。

如果 IDE 有 Spring Initializr 向导，填相同参数即可。VS Code 可安装 Extension Pack for Java 与 Spring Boot Extension Pack；Eclipse 可导入 Existing Maven Project。

## 3. 依赖配置

| 依赖 | 用途 |
| --- | --- |
| spring-boot-starter-webmvc | REST、JSON、内嵌 Web 服务器 |
| mybatis-spring-boot-starter 4.0.1 | Mapper、SQL 映射、Spring JDBC 事务集成 |
| lombok | 自动生成 getter/setter、无参构造、构造注入；编译期依赖 |
| spring-boot-starter-validation | jakarta.validation 参数校验 |
| mysql-connector-j | MySQL JDBC 驱动 |
| spring-boot-starter-security | 安全过滤链、BCrypt 密码哈希 |
| spring-boot-starter-security-oauth2-resource-server | Bearer JWT 校验，不自动实现账号登录或签发 Token |
| mybatis-spring-boot-starter-test 4.0.1 | Mapper 测试支持，仍需配置测试数据源 |
| 相应 Spring test starter | MVC、安全测试 |

下面是 Boot 4.0.8 的精简完整 `pom.xml`，已对照 MyBatis Framework + Lombok 的 Initializr 生成结果。Spring 和 Lombok 依赖由 Boot parent 管理；MyBatis 是第三方 starter，显式指定版本。已有项目应移除旧持久化 starter 后合并配置，不要残留自动 ORM 建表配置。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>4.0.8</version>
        <relativePath/>
    </parent>
    <groupId>com.shiguang</groupId>
    <artifactId>shiguang-server</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <properties>
        <java.version>21</java.version>
        <mybatis.version>4.0.1</mybatis.version>
    </properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webmvc</artifactId>
        </dependency>
        <dependency>
            <groupId>org.mybatis.spring.boot</groupId>
            <artifactId>mybatis-spring-boot-starter</artifactId>
            <version>${mybatis.version}</version>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security-oauth2-resource-server</artifactId>
        </dependency>
        <dependency>
            <groupId>com.mysql</groupId>
            <artifactId>mysql-connector-j</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webmvc-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.mybatis.spring.boot</groupId>
            <artifactId>mybatis-spring-boot-starter-test</artifactId>
            <version>${mybatis.version}</version>
            <scope>test</scope>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
                <configuration>
                    <excludes>
                        <exclude>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                        </exclude>
                    </excludes>
                </configuration>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-compiler-plugin</artifactId>
                <configuration>
                    <annotationProcessorPaths>
                        <path>
                            <groupId>org.projectlombok</groupId>
                            <artifactId>lombok</artifactId>
                            <version>${lombok.version}</version>
                        </path>
                    </annotationProcessorPaths>
                </configuration>
            </plugin>
        </plugins>
    </build>
</project>
```

数据对象是普通 Java POJO，通过 MyBatis 映射；字段验证使用 `jakarta.validation`。Lombok 建议按需使用 `@Getter/@Setter/@NoArgsConstructor/@RequiredArgsConstructor`，含密码哈希的对象不自动生成 toString，也不直接作为接口响应。Boot 4 默认 Jackson 3，旧 Jackson 2 配置不能直接照搬。

显式 annotationProcessorPaths 用于编译生成 Lombok 方法，尤其 JDK 23+ 不能只依赖“把 Lombok 放入 dependencies”。[Lombok Maven 官方说明](https://projectlombok.org/setup/maven)。

## 4. 数据库与 application.yml：从零重新配置

这一节按你当前电脑的实际环境编写，按 4.1 → 4.8 顺序操作。2026-10-12 检查结果：MySQL 服务名为 `MySQL`，已运行并监听 3306；mysql 命令可用；后端实际目录是 `E:\shiguang-server\market`，已有 `src/main/resources/application.yaml`。项目 pom.xml 使用 Boot 4.0.8、Java 25、MyBatis 4.0.1 和 Lombok。

本次本地开发直接使用你已有的 `root` 账号和现有密码，只需确认开发库 `shiguang_market_dev`。这里给出操作步骤，不创建新账号、不重设密码；数据库命令和后端配置由你在本机执行。

### 4.1 确认 MySQL 与登录管理员

在 PowerShell 中执行（不是 Java 文件或 YAML 文件）：

```powershell
Get-Service MySQL
mysql --version
Test-NetConnection localhost -Port 3306
mysql --commands=ON --default-character-set=utf8mb4 -h localhost -P 3306 -u root -p
```

依次看到服务 Running、版本信息、TcpTestSucceeded=True。最后一条会提示 Enter password，输入你现有的 root 密码；输入时不会显示字符，回车即可。--commands=ON 用于本机 MySQL 9.6 客户端，方便后面执行 SOURCE。

看到 `mysql>` 后，再输入下一节的 SQL。MySQL 客户端与 Spring Boot 都使用 root 和同一个数据库密码；它们与网站用户登录接口的账号密码是两套不同概念。

若 mysql 命令找不到，本机客户端路径是：

```powershell
& 'E:\Development\mysql-9.6.0-winx64\bin\mysql.exe' --commands=ON --default-character-set=utf8mb4 -h localhost -P 3306 -u root -p
```

本机已安装 MySQL，无需为这一节重新安装。若服务停止，可在管理员 PowerShell 中执行 `Start-Service MySQL`。

### 4.2 创建或选择开发库

在 `mysql>` 内先查看开发库是否已存在：

```sql
SHOW DATABASES LIKE 'shiguang_market_dev';
```

执行以下 SQL。库不存在时创建，已存在时保留现状并切换到它：

```sql
CREATE DATABASE IF NOT EXISTS shiguang_market_dev
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

USE shiguang_market_dev;
SELECT DATABASE();
SHOW TABLES;
```

SELECT DATABASE() 应显示 shiguang_market_dev。SHOW TABLES 为空时可以在 4.7 执行完整初始化；如果已有表，不重复执行 01/02，而是先用 03-verify.sql 查看现状。这里不需要 CREATE USER、GRANT 或 ALTER USER。

### 4.3 验证 root 能访问开发库

先在 MySQL 控制台输入：

```sql
exit;
```

回到 PowerShell，用现有 root 账号直接连接开发库：

```powershell
mysql --commands=ON --default-character-set=utf8mb4 -h localhost -P 3306 -u root -p -D shiguang_market_dev
```

输入同一个 root 密码。登录后验证：

```sql
SELECT DATABASE(), CURRENT_USER(), 1 AS connection_ok;
exit;
```

预期显示 shiguang_market_dev、root 对应的 MySQL 账号和 1。成功后继续配置 Java；如果失败，先核对库名、root 密码及连接地址。

### 4.4 配置现有 application.yaml

在 IDEA 打开：

```text
E:\shiguang-server\market\src\main\resources\application.yaml
```

`.yaml` 和 `.yml` 都可用，你的项目已有 `.yaml`，本次继续编辑它。把以下配置合并到这个文件：已有 spring.application.name: market 保留，其他同名节点合并，避免写两个 spring: 或 datasource:。如另有 application.properties/application.yml，检查并移除重复配置，别让多个文件同时设置不同密码或库名。

```yaml
server:
  port: 8080
spring:
  application:
    name: market
  datasource:
    url: jdbc:mysql://localhost:3306/shiguang_market_dev?useUnicode=true&characterEncoding=UTF-8&connectionTimeZone=UTC&forceConnectionTimeZoneToSession=true
    username: ${DB_USERNAME:root}
    password: ${DB_PASSWORD}
  servlet:
    multipart:
      max-file-size: 5MB
      max-request-size: 50MB
mybatis:
  mapper-locations: classpath*:/mapper/**/*.xml
  configuration:
    map-underscore-to-camel-case: true
    default-statement-timeout: 30
app:
  jwt:
    issuer: shiguang-server
    secret-base64: ${JWT_SECRET_BASE64}
    expires-in-seconds: 7200
  upload-dir: ${UPLOAD_DIR:./uploads}
```

`${DB_PASSWORD}` 是读取环境变量的表达式，不是让你把密码填进这对大括号。YAML 使用空格缩进，不使用 Tab；mybatis 和 app 是顶层节点，与 spring 同级。

不设置 server.servlet.context-path: /api，Controller 本身已有前缀。JWT issuer 继续用 shiguang-server，与 application.name=market 不要求相同，但必须与签发 Token 的 issuer 一致。MyBatis 不会自动建表，完整建表文件见 4.7。

### 4.5 配置密码和 JWT 环境变量

先在 PowerShell 执行，输入现有 root 密码：

```powershell
$env:DB_USERNAME = 'root'
$dbSecret = Read-Host '请输入 root 的数据库密码' -AsSecureString
$env:DB_PASSWORD = [System.Net.NetworkCredential]::new('', $dbSecret).Password
```

如果已配置 JWT_SECRET_BASE64，继续使用已有值。首次配置时才在本地生成一次 JWT 密钥：

```powershell
$jwtKeyBytes = New-Object byte[] 32
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($jwtKeyBytes)
$rng.Dispose()
$env:JWT_SECRET_BASE64 = [Convert]::ToBase64String($jwtKeyBytes)
Set-Clipboard -Value $env:JWT_SECRET_BASE64
```

JWT 密钥已复制到本机剪贴板。接下来选择一种启动方式：

**方式 A：IDE 启动（推荐）**

1. IDEA：Run → Edit Configurations → 选择启动类的运行配置；如果没有，先找到项目 main 方法创建运行配置。
2. 找到 Environment variables；如果未显示，在 Modify options 中启用它。
3. 逐行添加 DB_USERNAME=root、DB_PASSWORD=你现有的 root 密码、JWT_SECRET_BASE64=已有值或剪贴板中的新值。若之前配置过 DB_USERNAME=shiguang_dev，改成 root。
4. 设置运行 JRE 为 25，与当前 pom.xml 的 java.version 一致，保存后运行。

**方式 B：刚才的 PowerShell 启动**

```powershell
cd E:\shiguang-server\market
mvn.cmd -version
mvn.cmd spring-boot:run
```

本机工程没有 mvnw.cmd，当前使用已安装的 mvn.cmd。mvn -version 输出的 Java 应为 25；若不一致，检查 JAVA_HOME 或 IDE Maven Runner JRE。

环境变量只对相应进程生效：在终端设置变量不会自动传给已打开的 IDEA。普通 .env 文件也不会被 Spring Boot 自动读取。JWT 密钥保存到本机 IDE 配置后后续复用；重新生成会使旧 Token 失效。密钥和数据库密码不写入可提交的 YAML。

### 4.6 验证 Spring Boot 真正连上数据库

应用启动成功并不一定表示 MyBatis 已建立数据库连接，健康检查返回 UP 也不能单独证明数据库可用。为第一次联调临时增加一个只执行 SELECT 1 的启动检查。

本机启动类为 com.shiguang.market.MarketApplication，保存到 `E:\shiguang-server\market\src\main\java\com\shiguang\market\config\DbConnectionCheck.java` 即可被扫描。其他项目请将 package 替换成实际根包 + .config：

```java
package com.shiguang.market.config;

import javax.sql.DataSource;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DbConnectionCheck implements ApplicationRunner {
    private final DataSource dataSource;

    @Override
    public void run(ApplicationArguments args) throws Exception {
        try (var connection = dataSource.getConnection();
             var statement = connection.createStatement();
             var result = statement.executeQuery("SELECT 1")) {
            if (!result.next() || result.getInt(1) != 1) {
                throw new IllegalStateException("数据库连接验证未通过");
            }
            System.out.println("数据库连接验证通过：SELECT 1 = 1");
        }
    }
}
```

重新运行应用，看到“数据库连接验证通过：SELECT 1 = 1”才证明 Java 数据源认证和连接正常。这段代码不建表、不插入数据；验证完可移除，避免临时检查长期绑在启动流程上。

如果你已经按第 6 节创建 HealthController，再另开终端测试 `Invoke-RestMethod 'http://localhost:8080/api/health'`；尚未创建该 Controller 时，404 不能用来判断数据库失败。

### 4.7 开始建业务表

完成连接验证后，执行 [完整建表脚本](sql/01-schema.sql)，再执行 [分类与首页初始数据](sql/02-seed.sql)。具体步骤见 [SQL 执行说明](sql/README.md)。先确认 shiguang_market_dev 是空库，再初始化一次。

可以先创建完整表结构，业务接口仍按 users → 注册/登录 → 分类/商品 → 上传/订单逐步实现。Lombok POJO 和 Mapper 不会自动生成数据表。

### 4.8 常见问题按顺序排查

| 现象 | 下一步 |
| --- | --- |
| root 登录失败 | 核对安装时的管理员密码；此时还未涉及 Spring 配置 |
| 数据库已存在 | 选择已有库并检查表，不重复初始化已有结构 |
| Spring 报 Access denied | 检查实际启动配置中 DB_USERNAME=root、DB_PASSWORD 为现有密码；用 4.3 先验证 |
| Unknown database | JDBC URL 与实际创建的库名一致 |
| Could not resolve placeholder DB_PASSWORD/JWT_SECRET_BASE64 | 在实际启动进程的环境变量中配置；不能只在另一个终端设置 |
| 无法找到启动目录中的 pom.xml | 本机路径是 E:\shiguang-server\market，不是外层目录 |
| mvnw.cmd 找不到 | 本机工程没有 Wrapper，使用 mvn.cmd |
| invalid target release 25 | 当前工程要求 Java 25，核对 Maven/IDE JRE |
| SELECT 1 检查没有日志 | 类是否在启动类扫描的根包内，是否完成编译并重新启动 |
| 业务表不存在 | 完成连接后按 SQL 执行说明初始化完整结构 |

## 5. 目录与数据表建议

```text
src/main/java/com/shiguang/market/
├── ShiguangServerApplication.java  # 生成的启动类，保留实际类名
├── common/                        # 响应、分页、异常
├── config/                        # 安全、媒体路径
├── auth/                          # 注册、登录、Token 撤销
├── user/
├── category/
├── home/
├── goods/
├── upload/
├── order/
└── feedback/
```

每个业务包按 controller、service、mapper、entity、dto 拆分。XML 放 `src/main/resources/mapper/<业务>/`，例如 mapper/user/UserMapper.xml。启动类位于根包；本文使用接口上的 `@Mapper` 自动扫描，也可在启动类用 `@MapperScan` 统一扫描约定的 mapper 包。DTO 返回字符串 ID，不直接序列化数据库对象。

| 表 | 核心要求 |
| --- | --- |
| users | username 唯一、password_hash、nickname、avatar_file_id |
| categories / category_types | 分类与类型联合唯一 |
| goods | seller_id、price DECIMAL(10,2)、status、version、deleted_at |
| uploaded_files / goods_images | 上传归属、用途、路径、排序 |
| orders | 买卖双方、金额、状态、过期时间、商品快照 |
| order_idempotency | user_id + idempotency_key 唯一、请求摘要、order_id |
| revoked_tokens | token_jti 唯一、expires_at |
| feedback | 用户、内容、站内页面路径 |

上表列出核心业务表，包含首页与分类分组在内的全部 15 张表见 [完整建表说明](sql/README.md)。MyBatis 使用 Mapper/XML 执行 SQL；Service 通过 `@Transactional(rollbackFor = Exception.class)` 管理多步写入。同一事务中的 Mapper 应使用同一数据源，不在异步线程中拆分商品占用和订单创建。

分页手动计算 `offset = (page - 1) * size`，Mapper 使用 LIMIT/OFFSET 和独立 COUNT，返回接口文档的分页对象。先校验 page/size，offset 用 long 计算。排序使用服务端白名单和 XML choose，参数绑定用 `#{...}`，不直接拼接客户端字段名或排序片段。

版本控制通过条件更新实现，而非框架自动乐观锁：

```sql
UPDATE goods
SET title = ?, version = version + 1, updated_at = UTC_TIMESTAMP()
WHERE id = ? AND seller_id = ? AND version = ?
  AND status IN ('ON_SALE', 'OFF_SHELF') AND deleted_at IS NULL;
```

检查受影响行数；为 0 时再按资源是否存在、归属、状态/版本区分 404/403/409。订单创建时条件更新 ON_SALE → RESERVED，并在同一个事务插入订单；后续步骤失败必须回滚。原生 MyBatis 没有 MyBatis-Plus 的 BaseMapper、自动分页或自动版本插件。

### 5.1 MyBatis + Lombok 最小数据访问示例

以下示例只演示 Mapper/XML 与 Lombok 构造注入，未实现登录接口。users 已包含在 01-schema.sql 中，执行完整脚本后不要再次创建同名表。

保存为 `user/entity/UserEntity.java`：

```java
package com.shiguang.market.user.entity;

import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;

@Getter
@Setter
@NoArgsConstructor
public class UserEntity {
    private Long id;
    private String username;
    private String passwordHash;
    private String nickname;
    private String avatarFileId;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
```

保存为 `user/mapper/UserMapper.java`：

```java
package com.shiguang.market.user.mapper;

import com.shiguang.market.user.entity.UserEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface UserMapper {
    UserEntity findById(@Param("id") Long id);
    UserEntity findByUsername(@Param("username") String username);
    int insert(UserEntity user);
}
```

保存为 `src/main/resources/mapper/user/UserMapper.xml`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
        "https://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.shiguang.market.user.mapper.UserMapper">
    <select id="findById" resultType="com.shiguang.market.user.entity.UserEntity">
        SELECT id, username, password_hash, nickname, avatar_file_id, created_at, updated_at
        FROM users WHERE id = #{id}
    </select>
    <select id="findByUsername" resultType="com.shiguang.market.user.entity.UserEntity">
        SELECT id, username, password_hash, nickname, avatar_file_id, created_at, updated_at
        FROM users WHERE username = #{username}
    </select>
    <insert id="insert" parameterType="com.shiguang.market.user.entity.UserEntity"
            useGeneratedKeys="true" keyProperty="id">
        INSERT INTO users (username, password_hash, nickname, avatar_file_id, created_at, updated_at)
        VALUES (#{username}, #{passwordHash}, #{nickname}, #{avatarFileId}, UTC_TIMESTAMP(), UTC_TIMESTAMP())
    </insert>
</mapper>
```

XML namespace 必须为 Mapper 接口完整类名，id 对应方法名。使用 map-underscore-to-camel-case 映射下划线字段；这个配置不会自动把 Java 对象变成建表语句，也不会执行 insert。insert 返回影响行数，生成的 id 回填到传入对象；时间字段若需要返回，应再查数据库。

保存为 `user/service/UserService.java`，演示 Lombok 构造注入与安全 DTO：

```java
package com.shiguang.market.user.service;

import com.shiguang.market.user.mapper.UserMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserService {
    private final UserMapper userMapper;

    public UserProfile findProfile(Long id) {
        var user = userMapper.findById(id);
        if (user == null) return null;
        return new UserProfile(user.getId().toString(), user.getUsername(), user.getNickname());
    }

    public record UserProfile(String id, String username, String nickname) {}
}
```

这是演示 DTO，正式 users/me 还需按契约补齐 avatarUrl/createdAt。Controller 从验证后的 Token 获取 id，再调用 Service；不要直接接受任意用户 ID 返回资料。注册 Service 调用 PasswordEncoder.encode 后再 insert，不能存明文密码。

## 6. 最小启动验证代码

以下示例只验证配置与过滤链，**不实现注册、登录、商品或订单**。

`common/HealthController.java`：

```java
package com.shiguang.market.common;

import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {
    @GetMapping("/api/health")
    public Map<String, Object> health() {
        return Map.of("code", 200, "msg", "操作成功",
                "data", Map.of("status", "UP"));
    }
}
```

`config/SecurityConfig.java`：

```java
package com.shiguang.market.config;

import java.util.Base64;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtValidators;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;

@Configuration
public class SecurityConfig {
    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    JwtDecoder jwtDecoder(@Value("${app.jwt.secret-base64}") String secret,
                          @Value("${app.jwt.issuer}") String issuer) {
        byte[] bytes = Base64.getDecoder().decode(secret);
        if (bytes.length < 32) {
            throw new IllegalArgumentException("JWT key must contain at least 32 bytes");
        }
        var key = new SecretKeySpec(bytes, "HmacSHA256");
        var decoder = NimbusJwtDecoder.withSecretKey(key)
                .macAlgorithm(MacAlgorithm.HS256).build();
        decoder.setJwtValidator(JwtValidators.createDefaultWithIssuer(issuer));
        return decoder;
    }

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        AuthenticationEntryPoint unauthorized = (request, response, exception) -> {
            response.setStatus(401);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(
                "{\"code\":401,\"msg\":\"登录已失效，请重新登录\",\"data\":null}");
        };
        AccessDeniedHandler forbidden = (request, response, exception) -> {
            response.setStatus(403);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(
                "{\"code\":403,\"msg\":\"没有操作权限\",\"data\":null}");
        };
        http.csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers(HttpMethod.POST,
                    "/api/auth/login", "/api/auth/register").permitAll()
                .requestMatchers(HttpMethod.GET,
                    "/api/health", "/api/categories", "/api/home/recommendations",
                    "/api/goods", "/api/goods/*", "/api/media/**").permitAll()
                .anyRequest().authenticated())
            .exceptionHandling(errors -> errors
                .authenticationEntryPoint(unauthorized)
                .accessDeniedHandler(forbidden))
            .oauth2ResourceServer(resource -> resource
                .jwt(jwt -> {})
                .authenticationEntryPoint(unauthorized)
                .accessDeniedHandler(forbidden));
        return http.build();
    }
}
```

这是 Authorization 请求头 Bearer Token 的无状态 API 配置；若改为 Cookie 登录，需要重新设计 CSRF/会话策略。当前通过 Vite 同源代理，无需另配 CORS。

后续登录应使用 PasswordEncoder.matches 校验密码，然后用同一密钥签发 HS256 JWT，包含 iss=shiguang-server、sub=用户字符串 ID、iat、exp、随机 jti。返回 data.token 与 data.userInfo。Resource Server 只负责校验，不自动签发 Token。

注册 DTO 使用 @NotBlank、用户名 @Pattern、密码 @Size(min=6,max=64)，并用 `password.getBytes(StandardCharsets.UTF_8).length <= 72` 独立检查字节数。不要 trim 密码，不把确认密码作为必填 API 字段；BCrypt 不能静默截断。用户名按约定标准化并设置数据库唯一索引，处理并发重复注册为 409。后续用户身份从经过验证的 JWT sub 获取，不能相信请求中的 userId。

本例 Decoder 只校验签名、时间与 issuer。实现 logout 契约时还需记录撤销 jti 并增加撤销校验；只清理客户端 Token 不等于服务端撤销。业务异常另外用 @RestControllerAdvice 统一为接口文档的 JSON 格式。

### 媒体资源地址配置

保存为 `config/MediaConfig.java`，与上述类处于同一根包：

```java
package com.shiguang.market.config;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class MediaConfig implements WebMvcConfigurer {
    private final String location;

    public MediaConfig(@Value("${app.upload-dir}") String directory) throws IOException {
        Path root = Path.of(directory).toAbsolutePath().normalize();
        Files.createDirectories(root);
        String uri = root.toUri().toString();
        location = uri.endsWith("/") ? uri : uri + "/";
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/api/media/**")
                .addResourceLocations(location);
    }
}
```

上传器生成不可预测的文件名，例如保存至 uploads/goods/<随机ID>.webp，返回 /api/media/goods/<随机ID>.webp。此配置仅映射资源，不实现上传或校验；upload-dir 只存允许公开的商品图/头像，不放日志、配置或私密文件。前端现有 Vite /api 代理可访问这些图片，Spring Security 示例已放行 GET /api/media/**。

## 7. 启动与联调

启动 MySQL、配置环境变量后，IDE 点击本机 MarketApplication 的 main 方法旁的 Run；本机工程没有 Wrapper，使用：

```powershell
cd E:\shiguang-server\market
mvn.cmd -version
mvn.cmd spring-boot:run
```

另一个终端：

如果是其他通过 Initializr 新建、带 mvnw.cmd 的工程，可以使用 .\mvnw.cmd 替代 mvn.cmd；实际工作目录必须包含 pom.xml。

```powershell
Invoke-RestMethod 'http://localhost:8080/api/health'
```

期望 code=200、data.status=UP，仅代表项目启动成功。随后启动前端：

```powershell
cd E:\shop
npm.cmd install
npm.cmd run dev
```

dev 命令持续运行，在另一个终端验证前端代理：

```powershell
Invoke-RestMethod 'http://localhost:5173/api/health'
```

现有 Vite 已把 /api 保留前缀代理至 http://localhost:8080，不用改 Axios baseURL。若 Vite 实际运行在其他端口，用终端显示的地址验证。

业务实现后测试注册、登录：

```powershell
$credentials = @{ username = 'xiaolin'; password = 'example123' } | ConvertTo-Json
Invoke-RestMethod -Method Post 'http://localhost:8080/api/auth/register' -ContentType 'application/json' -Body $credentials
$result = Invoke-RestMethod -Method Post 'http://localhost:8080/api/auth/login' -ContentType 'application/json' -Body $credentials
$headers = @{ Authorization = "Bearer $($result.data.token)" }
Invoke-RestMethod 'http://localhost:8080/api/users/me' -Headers $headers
```

媒体返回 /api/media/**，利用同一个 Vite 代理；上面的 MediaConfig 已提供资源映射示例，上传、格式校验、归属和商品关联仍需实现。图片公开展示，上传、删除和关联操作需验证权限。

完成商品列表接口后验证排序：

```powershell
Invoke-RestMethod 'http://localhost:8080/api/goods?categoryId=digital&sort=priceAsc&page=1&size=20'
Invoke-RestMethod 'http://localhost:8080/api/goods?categoryId=digital&sort=priceDesc&page=1&size=20'
Invoke-RestMethod 'http://localhost:8080/api/goods?keyword=camera&page=1&size=20'
```

当前前端搜索/分类/排序仍使用本地数据。仅启动后端不会自动产生网络请求，需新增 api/goods.js 等模块并按接口文档第 9 节适配字段。测试中文请求/响应时让客户端使用 UTF-8。

## 8. 实现顺序与排查

1. 统一响应/异常 → 注册/登录 → users/me/logout。
2. 分类/推荐 → 商品列表/详情；前端通过适配层替换 Mock。
3. 上传 → 发布/编辑/上下架；草稿保持本机保存，明确区分“已保存草稿”和“发布成功”。
4. 订单创建/幂等 → 买入卖出 → 确认/完成/取消/超时释放。
5. 反馈；消息、支付、物流另行设计。

| 现象 | 检查 |
| --- | --- |
| unsupported release 21 | Project SDK、Maven JRE、JAVA_HOME 是否一致 |
| Initializr 无法选 MyBatis | 当前生成器对该依赖限制 Boot 4.0.x；本教程使用 4.0.8 |
| starter 无法解析 | 核对 Boot / MyBatis 版本组合；Reload Maven |
| getter/setter/构造注入报错 | Lombok 依赖、annotationProcessorPaths、IDE 注解处理开关 |
| Mapper Bean 找不到 | 接口加 @Mapper，或正确配置 @MapperScan；启动类根包覆盖业务 |
| Invalid bound statement | XML 路径、namespace 与 Mapper 方法 id；检查 mapper-locations |
| Table users doesn't exist | 按 sql/README.md 执行完整初始化；MyBatis 不会自动建表 |
| 数据库 Access denied | 用户、密码、连接主机；启动进程是否有 DB_PASSWORD |
| 连接数据库失败 | MySQL 服务、3306、库名 |
| 登录 POST 403 | 匿名路径、无状态 Bearer 配置与 CSRF |
| 公开接口带旧 Token 返回 401 | 无效 Bearer 仍会被拒绝；清除旧登录态 |
| 8080 被占用 | 停止旧服务或换端口，并调整前端 VITE_API_TARGET |
| /api/api 返回 404 | 不同时配置 context-path 和 Controller /api 前缀 |
| 首页仍是 Mock | 启动后端不会自动替换前端本地数据 |
| 保存草稿没有网络请求 | 正常：当前只存本机，不能以此判断发布接口已成功 |
| 图片 404 | 核对 MediaConfig、upload-dir 与返回的 /api/media 路径 |
| 停止等待后注册提示重复 | 服务端可能已处理；检查账号并尝试登录，不宣称请求已回滚 |

## 9. 按新版界面逐阶段验收

| 阶段 | 后端完成条件 | 前端验收 |
| --- | --- | --- |
| 启动 | health 返回统一 JSON，数据源可连 | 经 5173 代理也可访问 health |
| 账号 | 注册/登录/用户资料；JSON 401/409/503；密码哈希 | 失败保留输入、可重试；停止等待无迟到页面跳转；登录返回原任务 |
| 浏览 | 分类、列表、详情、排序、分页、图片 | 条件可移除/撤销；新条件 page=1；失败与空结果分开；详情返回保持位置 |
| 发布 | 上传、关联校验、商品创建/编辑、version | 草稿不创建商品；预览不上传；收到成功后才提示发布成功；409 保留表单 |
| 订单 | 买入/卖出、权限、幂等、状态事务 | role 与 Tab 对齐；失败可重试；不能把失败显示成无订单 |
| 反馈 | 在线保存接口 | 接入前只保存本机；在线保存后的撤销需新契约，不复用本机撤销伪装删除 |

API 返回错误时提供可行动中文说明和 errors 字段；表单字段映射如 category→categoryId、type→typeId、condition 中文→枚举，详见接口文档。以上验收为接入计划，不代表本项目已经运行这些接口。

## 官方资料

- [Spring Boot 系统要求](https://docs.spring.io/spring-boot/system-requirements.html)
- [Spring Initializr](https://start.spring.io/)
- [Spring MVC](https://docs.spring.io/spring-boot/reference/web/servlet.html)
- [JWT Resource Server](https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/jwt.html)
- [MyBatis starter 版本兼容与配置](https://mybatis.org/spring-boot-starter/mybatis-spring-boot-autoconfigure/)
- [Lombok Maven 注解处理配置](https://projectlombok.org/setup/maven)
