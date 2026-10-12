# 拾光闲置 · 本地 Spring Boot 建项目步骤

更新：2026-10-11。完整业务契约见 [接口文档](backend-api.md)。本文以 IntelliJ IDEA 为例，提供项目创建与配置示例；尚未实现业务接口。

验证：本文 pom.xml 与两个 Java 示例已在临时 Maven 工程中通过 compile（本机 JDK 25，目标 release 21）；未启动 MySQL 或验证业务接口。

## 1. 技术选择

采用 **Java 21 + Spring Boot 4.1.1 + Maven + MySQL 8.4 + Spring Data JPA + Spring Security JWT**。Boot 版本与 starter 已核对 Spring Initializr 实际生成结果。数据库访问统一用 JPA，无需同时安装 MyBatis；JWT 使用 Spring Security 自带支持，无需额外 jjwt。

建议后端放在 `E:\shiguang-server`，前端继续使用 `E:\shop`。

1. 安装/选择 JDK 21，运行 `java -version` 验证。
2. 安装 MySQL 8.4 并启动服务；默认端口 3306。
3. IDE 的 Project SDK 和 Maven Runner JRE 都选择 21。
4. Maven 使用生成项目内的 Wrapper，无需另装 Maven。自行安装时使用 Maven 3.6.3+。

## 2. 创建与导入

通用流程适用于没有 Spring 项目向导的 IDEA 版本：

1. 打开 [Spring Initializr](https://start.spring.io/)。
2. Project 选 Maven；Language 选 Java；Boot 选 **4.1.1 正式版**。
3. Group：`com.shiguang`；Artifact / Name：`shiguang-server`。
4. Package name：`com.shiguang.market`；Packaging：Jar；Java：21。
5. Add Dependencies 添加 **Spring Web、Spring Data JPA、Validation、MySQL Driver、Spring Security、OAuth2 Resource Server**。
6. Generate 下载，解压到 `E:\shiguang-server`，确认该目录下有 `pom.xml` 和 `mvnw.cmd`。
7. IDEA：File → Open → 选择项目目录或 pom.xml → 导入 Maven，等待依赖下载。
8. Project Structure 中设置 SDK 21；Maven 设置使用 Wrapper，Runner JRE 21。

如果 IDE 有 Spring Initializr 向导，填相同参数即可。VS Code 可安装 Extension Pack for Java 与 Spring Boot Extension Pack；Eclipse 可导入 Existing Maven Project。

## 3. 依赖配置

| 依赖 | 用途 |
| --- | --- |
| spring-boot-starter-webmvc | REST、JSON、内嵌 Web 服务器 |
| spring-boot-starter-data-jpa | 实体、Repository、事务 |
| spring-boot-starter-validation | jakarta.validation 参数校验 |
| mysql-connector-j | MySQL JDBC 驱动 |
| spring-boot-starter-security | 安全过滤链、BCrypt 密码哈希 |
| spring-boot-starter-security-oauth2-resource-server | Bearer JWT 校验，不自动实现账号登录或签发 Token |
| 相应 test starter | MVC、安全与数据库测试 |

下面是完整的精简 `pom.xml`。Initializr 生成的额外项目元信息与测试 starter 可保留。依赖版本交给 Spring Boot parent 管理。**这是 Boot 4 的 starter 名称，不要混用 Boot 3 教程。**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>4.1.1</version>
        <relativePath/>
    </parent>
    <groupId>com.shiguang</groupId>
    <artifactId>shiguang-server</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <properties><java.version>21</java.version></properties>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-webmvc</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
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
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

实体使用 `jakarta.persistence`，参数校验使用 `jakarta.validation`。Boot 4 默认 Jackson 3，旧教程中的 `com.fasterxml.jackson.databind` 配置不能直接照搬。

## 4. 数据库与 application.yml

在 MySQL 执行；替换占位密码：

```sql
CREATE DATABASE shiguang_market
    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE USER 'shiguang_app'@'localhost' IDENTIFIED BY 'REPLACE_WITH_YOUR_PASSWORD';
GRANT ALL PRIVILEGES ON shiguang_market.* TO 'shiguang_app'@'localhost';
```

删除或清空重复的 application.properties，在 `src/main/resources/application.yml` 写入：

```yaml
server:
  port: 8080
spring:
  application:
    name: shiguang-server
  datasource:
    url: jdbc:mysql://localhost:3306/shiguang_market?useUnicode=true&characterEncoding=UTF-8&connectionTimeZone=UTC
    username: ${DB_USERNAME:shiguang_app}
    password: ${DB_PASSWORD}
  jpa:
    open-in-view: false
    hibernate:
      ddl-auto: update
    properties:
      hibernate:
        jdbc:
          time_zone: UTC
  servlet:
    multipart:
      max-file-size: 5MB
      max-request-size: 50MB
app:
  jwt:
    issuer: shiguang-server
    secret-base64: ${JWT_SECRET_BASE64}
    expires-in-seconds: 7200
  upload-dir: ${UPLOAD_DIR:./uploads}
```

不设置 `server.servlet.context-path: /api`：Controller 本身已有 `/api` 前缀，避免形成 `/api/api`。`ddl-auto: update` 只用于本地开发；稳定后生产使用 `validate` 与 Flyway 迁移。业务上传还需验证文件实际类型和大小。

IDE Run Configuration → Environment variables 填写 `DB_PASSWORD` 与 `JWT_SECRET_BASE64`。IDE 不会自动读取普通 .env 文件。

PowerShell 启动时，在同一个终端先执行：

```powershell
$env:DB_PASSWORD = '你创建数据库用户时设置的密码'
$jwtKeyBytes = New-Object byte[] 32
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($jwtKeyBytes)
$rng.Dispose()
$env:JWT_SECRET_BASE64 = [Convert]::ToBase64String($jwtKeyBytes)
```

密钥首次生成后保存并在后续启动复用；更换会使旧 Token 失效。终端变量不会传给已打开的 IDE，IDE 启动需单独填写相同值。

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

每个业务包按 controller、service、repository、entity、dto 拆分。启动类位于根包以扫描全部业务。DTO 返回字符串 ID，不直接序列化 Entity。

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

此表是建模建议，并非完整建表 SQL。JPA 实体可生成本地表；编辑商品用 `@Version`，订单占用商品用事务及条件更新/锁。API page 从 1 开始，JPA 分页从 0 开始，调用 PageRequest 时减 1。

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
        return Map.of("code", 200, "message", "success",
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
                "{\"code\":401,\"message\":\"登录已失效，请重新登录\",\"data\":null}");
        };
        AccessDeniedHandler forbidden = (request, response, exception) -> {
            response.setStatus(403);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(
                "{\"code\":403,\"message\":\"没有操作权限\",\"data\":null}");
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

本例 Decoder 只校验签名、时间与 issuer。实现 logout 契约时还需记录撤销 jti 并增加撤销校验；只清理客户端 Token 不等于服务端撤销。业务异常另外用 @RestControllerAdvice 统一为接口文档的 JSON 格式。

## 7. 启动与联调

启动 MySQL、配置环境变量后，IDE 点击 Initializr 生成的启动类 main 方法旁的 Run；或使用：

```powershell
cd E:\shiguang-server
.\mvnw.cmd -version
.\mvnw.cmd spring-boot:run
```

另一个终端：

```powershell
Invoke-RestMethod 'http://localhost:8080/api/health'
```

期望 code=200、data.status=UP，仅代表项目启动成功。随后启动前端：

```powershell
cd E:\shop
npm.cmd install
npm.cmd run dev
Invoke-RestMethod 'http://localhost:5173/api/health'
```

实际 dev 命令持续运行，验证命令需在另一个终端执行。现有 Vite 已把 /api 保留前缀代理至 http://localhost:8080，不用改 Axios baseURL。

业务实现后测试注册、登录：

```powershell
$credentials = @{ username = 'xiaolin'; password = 'example123' } | ConvertTo-Json
Invoke-RestMethod -Method Post 'http://localhost:8080/api/auth/register' -ContentType 'application/json' -Body $credentials
$result = Invoke-RestMethod -Method Post 'http://localhost:8080/api/auth/login' -ContentType 'application/json' -Body $credentials
$headers = @{ Authorization = "Bearer $($result.data.token)" }
Invoke-RestMethod 'http://localhost:8080/api/users/me' -Headers $headers
```

媒体返回 /api/media/**，利用同一个 Vite 代理；后端后续要添加静态资源映射到 upload-dir。本例尚未实现上传与资源映射。图片公开展示，上传、删除和关联操作需验证权限。

## 8. 实现顺序与排查

1. 统一响应/异常 → 注册/登录 → users/me/logout。
2. 分类/推荐 → 商品列表/详情；前端通过适配层替换 Mock。
3. 上传 → 发布/编辑/上下架。
4. 订单创建/幂等 → 买入卖出 → 确认/完成/取消/超时释放。
5. 反馈；消息、支付、物流另行设计。

| 现象 | 检查 |
| --- | --- |
| unsupported release 21 | Project SDK、Maven JRE、JAVA_HOME 是否一致 |
| starter 无法解析 | Boot 4.1.1 与本文依赖名；Reload Maven |
| 数据库 Access denied | 用户、密码、连接主机；启动进程是否有 DB_PASSWORD |
| 连接数据库失败 | MySQL 服务、3306、库名 |
| 登录 POST 403 | 匿名路径、无状态 Bearer 配置与 CSRF |
| 公开接口带旧 Token 返回 401 | 无效 Bearer 仍会被拒绝；清除旧登录态 |
| 8080 被占用 | 停止旧服务或换端口，并调整前端 VITE_API_TARGET |
| /api/api 返回 404 | 不同时配置 context-path 和 Controller /api 前缀 |
| 首页仍是 Mock | 启动后端不会自动替换前端本地数据 |

## 官方资料

- [Spring Boot 系统要求](https://docs.spring.io/spring-boot/system-requirements.html)
- [Spring Initializr](https://start.spring.io/)
- [Spring MVC](https://docs.spring.io/spring-boot/reference/web/servlet.html)
- [JWT Resource Server](https://docs.spring.io/spring-security/reference/servlet/oauth2/resource-server/jwt.html)
