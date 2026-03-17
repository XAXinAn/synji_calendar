# 讯极日历 (Synji Calendar) 后端 API 接口文档 (v2.0)

本规范定义了前后端交互的标准格式，采用“本地优先 (Local-First)” 架构。云端作为日程的镜像备份与同步中转站，并提供 AI 代理服务。

## 1. 基础规范
- **Base URL**: `http://47.99.102.191:8080/v1` (本地调试: `http://localhost:8080/v1`)
- **数据格式**: `application/json; charset=utf-8`
- **认证方式**: `Bearer Token`。所有受保护接口需在 Header 携带 `Authorization: Bearer {token}`。
- **公共响应结构**:
  ```json
  {
    "code": 200,      // 200 成功，401 鉴权失败，400 参数错误，500 服务器错误
    "message": "提示信息",
    "data": {}        // 业务数据，根据接口不同为对象或数组
  }
  ```

---

## 2. 用户认证 (Auth)

### 2.1 注册与登录
- **路径**: `/auth/register` (POST) / `/auth/login` (POST)
- **请求体**: `{"username": "...", "password": "..."}`
- **成功响应 (`data`)**:
  ```json
  {
    "id": "1",
    "username": "admin",
    "nickname": "admin",
    "accessToken": "eyJhbGciOiJIUzI1...",
    "accessTokenExpiresIn": 1800
  }
  ```
- **Refresh Token**: 后端应通过 `HttpOnly Cookie` (建议名 `refreshToken`) 返回刷新令牌。

### 2.2 Token 刷新
- **路径**: `/auth/refresh` (POST)
- **说明**: 依赖 Cookie 中的 `refreshToken`。
- **成功响应 (`data`)**: 返回新的 `{"accessToken": "...", "accessTokenExpiresIn": 1800}`。

---

## 3. 用户资料 (Profile)

### 3.1 获取/修改个人资料
- **路径**: `/auth/me`
- **GET (获取)**: 返回 `{"id": "String", "username": "String", "nickname": "String"}`。
- **PATCH (修改)**: 请求体 `{"nickname": "String"}`，仅支持更新昵称。

---

## 4. 日程同步与管理 (Schedule Sync)

### 4.1 镜像同步 (Mirror Sync - 上传)
- **路径**: `/schedules/sync` (POST)
- **说明**: 前端发送本地全量日程数组。
- **后端逻辑**: 
  1. 执行 **Upsert**: 对传入列表中的记录进行更新或插入。
  2. 执行 **物理删除**: 删除数据库中该用户下、但不在当前请求列表中的所有日程记录。
  3. **目标**: 确保云端数据与前端上报的“快照”完全一致。

### 4.2 获取日程列表 (Pull - 下载)
- **路径**: `/schedules` (GET)
- **说明**: 返回当前用户在云端存储的所有日程数组。

### 4.3 独立管理接口 (不影响本地)
- **单个删除**: `DELETE /schedules/{id}`
- **全部清空**: `DELETE /schedules/clear`
- **注意**: 这两个操作仅清除云端备份，不应通过同步机制反向删除手机本地数据。

---

## 5. AI 智能解析 (AI Proxy)

### 5.1 文本解析接口
- **路径**: `/ai/parse-schedule` (POST)
- **请求体**: 
  ```json
  {
    "text": "原始待解析文本",
    "context": {
      "currentTime": "2024-05-20 10:00:00",
      "currentYear": "2024"
    }
  }
  ```
- **后端 Prompt 指引**:
  > 任务：将文本转为 JSON。当前时间：{currentTime}。
  > 规则：年份缺失补 {currentYear}。返回 JSON 数组。
  > 字段：title, time (YYYY-MM-DD HH:mm:ss), location, description。
- **成功响应数据 (`data`)**: 
  ```json
  [
    {
      "title": "会议",
      "time": "2024-05-20 15:30:00",
      "location": "302室",
      "description": "无"
    }
  ]
  ```

---

## 6. 开发协议
1. **字段兼容**: 前端已兼容解析 `token` 和 `accessToken` 两个 Key。
2. **安全隔离**: 所有数据操作必须基于 Token 解析出的 `userId`。
3. **HTTP 401**: 任何涉及 Token 失效的情况必须返回 401 状态码。
4. **CORS**: 必须配置 `Allow-Credentials: true` 且 Origin 不可为 `*`。
