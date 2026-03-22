# 讯极日历 - 后端 API 接口文档 (v3.4)

## 1. 项目概述
*   **同步核心**：采用增量同步机制。
*   **个人日程**：允许离线操作，通过 `delta-sync` 后台合并。
*   **小组日程**：要求强一致性，操作需即时同步云端。

---

## 2. 核心数据模型 (Schedule)

| 字段名 | 类型 | 说明 |
| :--- | :--- | :--- |
| `id` | String | 唯一标识 |
| `updatedAt` | DateTime | ISO8601 UTC 时间戳。用于 LWW (Last Write Wins) 冲突比对。 |
| `isDeleted` | Integer | **1 为已删除，0 为活跃**。后端必须严格映射此字段。 |
| `groupId` | String | 小组 ID。为空表示个人日程。 |

---

## 3. 增量同步接口

### 3.1 增量推送 (Upsert) - `POST /schedules/delta-sync`
*   **功能**：同步本地变动。删除日程时，发送 `isDeleted: 1`。
*   **权限校验 (重要)**：
    1. **小组日程删除**：如果请求中 `isDeleted: 1` 且 `groupId` 不为空，后端**必须**校验当前用户是否为该小组的 **创建者 (Creator)** 或 **管理员 (Admin)**。
    2. **非法操作反馈**：若普通成员尝试删除小组日程，后端**严禁静默忽略**，必须返回 **403 Forbidden**。

### 3.2 增量拉取 (Fetch) - `GET /schedules/delta-fetch`
*   **功能**：获取自 `since` 以来的变动。
*   **返回要求 (关键)**：
    1. **必须包含已删除记录**：返回的数据集中，必须包含 `is_deleted = 1` 的记录。
    2. **否则后果**：如果后端不返回已删除记录，其他成员的手机端将永远无法获知该日程已被删除，导致数据在多端“复活”。

---

## 4. 小组专属接口 (Direct Access)

### 4.1 获取小组日程 - `GET /groups/{groupId}/schedules`
*   **返回要求**：返回该小组下所有 `is_deleted = 0` 的记录。

---

## 5. 【必读】后端 Hibernate/JPA 实现避坑指南

### 5.1 JSON 字段映射 (Naming Strategy)
*   前端发送键名：`isDeleted` (驼峰)。
*   后端数据库名：`is_deleted` (下划线)。
*   **技术要求**：请确保 Jackson 能够正确识别映射。建议在 DTO 字段上显式标注：
    `@JsonProperty("isDeleted") private Integer isDeleted;`
*   **排查**：如果后端收到的 `isDeleted` 为 `null`，逻辑将不会执行更新，请检查此处。

### 5.2 LWW 冲突比对
*   **逻辑**：`if (request.updatedAt >= database.updatedAt) { update(); }`
*   **时区**：强制统一使用 **UTC** 时间进行字符串或长整型比对。

### 5.3 物理删除禁令
*   后端数据库**严禁直接物理删除 (DELETE)** 记录。
*   必须使用逻辑删除 (`is_deleted = 1`)，否则 `delta-fetch` 接口将无法为其他客户端下发删除指令。

### 5.4 事务性保证
*   同步接口涉及多条记录，请务必开启 `@Transactional`。若权限校验失败，应触发回滚并返回错误响应。
