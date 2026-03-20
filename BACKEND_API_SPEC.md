# 讯极日历 - 后端 API 接口文档 (v2.5)

## 1. 项目概述
*   **项目名称**：讯极日历 (Synji Calendar)
*   **架构**：本地优先 (Local-First)，云端作为镜像备份与 AI 代理，并提供小组协作共享功能。
*   **认证方式**：基于 JWT (JSON Web Token) 的 `Bearer Token` 认证

---

## 2. 基础规范
*   **Base URL**: `http://localhost:8080/v1` (开发环境) / `http://47.99.102.191:8080/v1` (测试环境)
*   **公共 Header**:
    *   `Content-Type: application/json`
    *   `Authorization: Bearer {token}` (所有受保护接口均需携带)

---

## 3. 数据模型定义 (Data Models)

### 3.1 Schedule (日程对象)
| 字段名 | 类型 | 说明 |
| :--- | :--- | :--- |
| `id` | String | 唯一标识 (建议客户端生成 UUID) |
| `title` | String | 标题 (必填) |
| `description` | String | 详细描述 (可选) |
| `dateTime` | String | 时间 (ISO8601 格式，如: `2024-05-20T14:00:00Z`) |
| `location` | String | 地点 (可选) |
| `groupId` | String | 小组ID (个人日程为 null，小组日程必填) |
| `creatorName` | String | 创建者昵称 |

### 3.2 Group (小组对象)
| 字段名 | 类型 | 说明 |
| :--- | :--- | :--- |
| `id` | String | 唯一标识 |
| `name` | String | 小组名称 |
| `creatorId` | String | 创建者用户 ID |
| `inviteCode` | String | 邀请码 |
| `memberCount` | int | **(新增)** 成员总数。用于列表展示，避免拉取完整 ID 列表。 |
| `adminIds` | List<String> | 管理员 ID 列表 |
| `createdAt` | String | 创建时间 |

---

## 4. 日程管理与同步 (Schedule & Sync)

### 4.1 个人日程镜像同步 (Upsert)
*   **接口地址**：`/schedules/sync`
*   **请求方法**：`POST`
*   **请求体**：`List<Schedule>`
*   **逻辑**：后端接收列表，根据 `id` 更新或插入。仅限 `groupId` 为空的记录。

---

## 5. 小组日程同步 (Group Sync)

### 5.1 获取小组日程列表
*   **接口地址**：`/groups/{groupId}/schedules`
*   **请求方法**：`GET`
*   **返回要求**：必须按照 `dateTime` **从早到晚**升序排列。

### 5.2 发布/更新小组日程
*   **接口地址**：`/groups/{groupId}/schedules`
*   **请求方法**：`POST`
*   **权限**：仅限该小组的**创建者**或**管理员**。

---

## 6. 小组管理 (Group Management)

### 6.1 获取我的小组列表
*   **接口地址**：`/groups`
*   **请求方法**：`GET`
*   **返回数据要求**：必须包含 `memberCount` 字段，且 `creatorId` 需准确，以便前端区分“我创建的”和“我加入的”。

---

## 7. AI 智能解析 (AI Proxy)
*(保持 v2.2 内容不变)*
