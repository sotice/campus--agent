# Campus Agent API 接口设计文档

版本：V1.2  
适用范围：Flutter 客户端、Agent Orchestrator、Tool Safety Gate、Built-in Mock Service、本地 Mock API Server、后续真实校园 API 对接  
关联文档：[系统架构设计.md](./系统架构设计.md)、[AI_Agent设计文档.md](./AI_Agent设计文档.md)

## 1. 接口设计原则

1. 接口结构优先满足 Agent 闭环：`Observe → Plan → Act → Verify → Respond`。
2. MVP 首选 Built-in Mock Service；本文件中的 HTTP API 可作为本地 Mock API Server 或后续真实接口的契约。
3. Mock API 与真实 API 尽量保持相同请求和响应结构。
4. 所有接口返回统一响应格式，便于前端、Agent 和 Tool Safety Gate 处理错误。
5. 涉及个人数据的接口必须要求演示账号或登录态授权。
6. 敏感操作接口不接受大模型直接调用，只能由工具层在 PendingAction 确认后调用。
7. 所有响应、日志、Trace 必须脱敏，不返回完整学号、完整校园卡号、Token 或密钥。
8. 需要用户确认的 Agent Run 必须先暂停为 `suspended_for_confirmation`，再通过 `resume` 继续执行；不得在同一条单向流中伪造用户确认。
9. 知识库 `score` 仅表示检索相关性，不表示答案真实性概率。

## 2. 通用约定

### 2.1 Base URL

| 环境 | Base URL | 说明 | MVP |
| --- | --- | --- | --- |
| Built-in Mock Service | 内部 Repository 调用 | Chrome Web 主演示路径，无需后端服务 | P0 |
| 本地 Mock API | `http://127.0.0.1:8787/api/v1` | 可选工程展示 | P1 |
| 局域网 Mock API | `http://<host-ip>:8787/api/v1` | Android 真机调试可选 | P1 |
| 生产环境 | 待定 | 后续对接学校真实服务 | P2 |

### 2.2 请求头

```http
Content-Type: application/json
Authorization: Bearer <access_token>
X-Client-Platform: android|web|ios
X-App-Version: 1.0.0
X-Request-Id: <uuid>
X-Demo-Mode: true|false
```

### 2.3 统一响应格式

```json
{
  "success": true,
  "code": "OK",
  "message": "success",
  "data": {},
  "requestId": "req_20260707_001",
  "timestamp": "2026-07-07T10:00:00+08:00"
}
```

错误响应：

```json
{
  "success": false,
  "code": "CARD_ALREADY_LOST",
  "message": "校园卡已处于挂失状态",
  "data": {
    "cardIdMasked": "****0188",
    "status": "lost"
  },
  "requestId": "req_20260707_002",
  "timestamp": "2026-07-07T10:00:00+08:00"
}
```

### 2.4 通用错误码

| 错误码 | HTTP 状态 | 说明 | 前端处理 |
| --- | ---: | --- | --- |
| `OK` | 200 | 成功 | 展示结果。 |
| `BAD_REQUEST` | 400 | 请求参数错误 | 提示参数缺失或格式错误。 |
| `UNAUTHORIZED` | 401 | 未登录或 Token 无效 | 引导演示账号或重新登录。 |
| `FORBIDDEN` | 403 | 无权限访问 | 展示无权限原因。 |
| `NOT_FOUND` | 404 | 资源不存在 | 展示未找到。 |
| `CONFLICT` | 409 | 业务状态冲突 | 展示当前状态和下一步。 |
| `RATE_LIMITED` | 429 | 请求过于频繁 | 稍后重试。 |
| `TOOL_NOT_ALLOWED` | 403 | 工具未注册或当前环境不可用 | Safety Gate 阻断提示。 |
| `CONFIRMATION_REQUIRED` | 409 | 敏感操作缺少确认 | 展示 PendingAction 确认卡。 |
| `PENDING_ACTION_EXPIRED` | 409 | PendingAction 已过期 | 要求重新发起。 |
| `PENDING_ACTION_INVALID` | 409 | PendingAction 无效或参数不一致 | 阻断执行。 |
| `SAFETY_GATE_BLOCKED` | 403 | 安全策略阻断 | 展示安全兜底。 |
| `LOW_RELEVANCE_KNOWLEDGE` | 200 | 知识库低相关，不应生成具体答案 | 展示不确定和人工入口。 |
| `INTERNAL_ERROR` | 500 | 服务内部异常 | 重试或人工路径。 |
| `SERVICE_UNAVAILABLE` | 503 | 校园服务或 Mock 服务暂不可用 | 重试/稍后/人工路径。 |

## 3. 认证与用户接口

### 3.1 演示登录

用于竞赛演示阶段创建测试登录态。MVP 可由 Built-in Mock Service 直接返回同结构数据。

```http
POST /auth/demo-login
```

请求：

```json
{
  "demoUserType": "student",
  "demoUserId": "demo_student_001"
}
```

响应：

```json
{
  "success": true,
  "code": "OK",
  "message": "success",
  "data": {
    "accessToken": "demo_access_token",
    "expiresIn": 7200,
    "user": {
      "userId": "demo_student_001",
      "name": "演示学生",
      "role": "student",
      "studentNoMasked": "2023****018",
      "department": "计算机科学学院",
      "authStatus": "demo_verified"
    }
  }
}
```

### 3.2 获取当前用户

```http
GET /users/me
```

响应字段同演示登录中的 `user`。

## 4. PendingAction 接口/内部协议

MVP 使用内部 Manager 即可；若 Agent 逻辑部署在服务端，可暴露以下接口。

### 4.1 创建 PendingAction

```http
POST /agent/pending-actions
```

请求：

```json
{
  "runId": "run_20260707_001",
  "toolName": "campus_card.report_loss",
  "riskLevel": "high",
  "frozenParamsSummary": {
    "reason": "lost",
    "cardIdMasked": "****0188"
  },
  "frozenParamsCanonicalJson": "{\"reason\":\"lost\",\"target\":\"current_user_card\"}",
  "frozenParamsHash": "sha256:8c7d-demo-hash",
  "warningText": "挂失后校园卡消费、门禁或相关服务可能受限。",
  "expiresInSeconds": 300
}
```

响应：

```json
{
  "success": true,
  "code": "OK",
  "message": "success",
  "data": {
    "pendingActionId": "pa_20260707_001",
    "runId": "run_20260707_001",
    "toolName": "campus_card.report_loss",
    "riskLevel": "high",
    "frozenParamsSummary": {
      "reason": "lost",
      "cardIdMasked": "****0188"
    },
    "frozenParamsHash": "sha256:8c7d-demo-hash",
    "warningText": "挂失后校园卡消费、门禁或相关服务可能受限。",
    "expiresAt": "2026-07-07T10:10:00+08:00",
    "status": "pending_confirmation"
  }
}
```

### 4.2 确认 PendingAction

```http
POST /agent/pending-actions/{pendingActionId}/confirm
```

响应：

```json
{
  "success": true,
  "code": "OK",
  "message": "confirmed",
  "data": {
    "pendingActionId": "pa_20260707_001",
    "confirmationId": "confirm_20260707_001",
    "status": "confirmed"
  }
}
```

规则：

1. `confirmationId` 一次性使用。
2. `confirmationId` 仅对同一 `pendingActionId`、同一 `toolName`、同一 `frozenParamsHash` 有效。
3. 过期、取消、已执行的 PendingAction 不得确认。
4. `frozenParamsSummary` 只用于 UI 展示，Safety Gate 必须使用规范化参数哈希校验。

### 4.3 取消 PendingAction

```http
POST /agent/pending-actions/{pendingActionId}/cancel
```

响应：

```json
{
  "success": true,
  "code": "OK",
  "message": "cancelled",
  "data": {
    "pendingActionId": "pa_20260707_001",
    "status": "cancelled"
  }
}
```

## 5. Agent Run 暂停与恢复协议

本协议既可作为 Flutter 内部 Orchestrator DTO，也可作为服务端 Agent Gateway 接口。P0A 即使不做后端，也必须按该状态机实现内部事件流，避免 UI 假装执行 Agent 阶段。

### 5.1 Run 状态枚举

| status | 说明 |
| --- | --- |
| `created` | 已创建但尚未执行。 |
| `running` | 正在执行 Observe/Plan/Act/Verify/Respond。 |
| `suspended_for_confirmation` | 等待用户确认，敏感工具尚未执行。 |
| `resumed` | 用户确认后继续执行后半段。 |
| `completed` | 正常完成。 |
| `failed` | 执行失败。 |
| `cancelled` | 用户取消。 |
| `expired` | PendingAction 或 Run 超时。 |

### 5.2 创建/发送消息

```http
POST /agent/runs
```

请求字段与 `POST /agent/messages` 保持一致。响应必须返回 `runId`。

```json
{
  "success": true,
  "code": "OK",
  "message": "success",
  "data": {
    "runId": "run_20260707_001",
    "status": "suspended_for_confirmation",
    "currentPhase": "respond",
    "pendingActionId": "pa_20260707_001"
  }
}
```

### 5.3 确认并恢复 Run

```http
POST /agent/runs/{runId}/resume
```

请求：

```json
{
  "pendingActionId": "pa_20260707_001"
}
```

响应：

```json
{
  "success": true,
  "code": "OK",
  "message": "resumed",
  "data": {
    "runId": "run_20260707_001",
    "status": "resumed",
    "confirmationId": "confirm_20260707_001"
  }
}
```

规则：

1. `resume` 只能用于 `suspended_for_confirmation` 状态的 Run。
2. `resume` 必须校验 PendingAction 状态、过期时间、`frozenParamsHash` 和一次性确认凭证。
3. `resume` 后只能执行原计划中被冻结的后半段，不得重新让模型改写敏感工具参数。
4. `resume` 失败时不得执行敏感工具。

## 6. 校园卡接口

### 6.1 查询校园卡状态

工具名：`campus_card.get_status`

```http
GET /campus-card/status
```

响应：

```json
{
  "success": true,
  "code": "OK",
  "message": "success",
  "data": {
    "cardIdMasked": "****0188",
    "status": "normal",
    "balance": 86.50,
    "currency": "CNY",
    "lastUpdatedAt": "2026-07-07T09:40:00+08:00"
  }
}
```

状态枚举：

| status | 说明 |
| --- | --- |
| `normal` | 正常。 |
| `lost` | 已挂失。 |
| `frozen` | 冻结。 |
| `unknown` | 状态未知。 |

### 6.2 挂失校园卡

工具名：`campus_card.report_loss`

```http
POST /campus-card/report-loss
```

请求：

```json
{
  "reason": "lost",
  "pendingActionId": "pa_20260707_001",
  "confirmationId": "confirm_20260707_001",
  "frozenParamsHash": "sha256:8c7d-demo-hash"
}
```

工具层必须重新计算规范化执行参数哈希，并与 `frozenParamsHash` 比对。比对失败时返回 `PENDING_ACTION_INVALID` 或 `SAFETY_GATE_BLOCKED`，不得执行挂失。

响应：

```json
{
  "success": true,
  "code": "OK",
  "message": "校园卡挂失成功",
  "data": {
    "cardIdMasked": "****0188",
    "status": "lost",
    "reportedAt": "2026-07-07T10:05:00+08:00",
    "pendingActionId": "pa_20260707_001",
    "toolCallId": "tool_20260707_001",
    "nextSteps": [
      "请携带有效证件前往校园卡服务中心办理补卡。",
      "如找到原卡，请先确认是否支持解挂。"
    ]
  }
}
```

业务错误：

| 错误码 | 说明 | 前端处理 |
| --- | --- | --- |
| `CARD_ALREADY_LOST` | 校园卡已挂失。 | 展示当前状态和补办指引。 |
| `CARD_NOT_FOUND` | 未找到绑定校园卡。 | 引导绑定身份或联系人工服务。 |
| `CONFIRMATION_REQUIRED` | 未携带确认凭证。 | 展示 PendingAction 确认流程。 |
| `PENDING_ACTION_EXPIRED` | 确认已过期。 | 重新发起挂失流程。 |
| `PENDING_ACTION_INVALID` | 参数与冻结参数不一致。 | 阻断执行，提示重新确认。 |
| `CARD_SERVICE_UNAVAILABLE` | 校园卡服务不可用。 | 提供重试和人工办理路径。 |

## 7. 校园知识库接口

### 7.1 知识库搜索

工具名：`knowledge.search`

```http
POST /knowledge/search
```

请求：

```json
{
  "query": "图书馆今天几点关门",
  "categories": ["library", "procedure", "campus_card"],
  "topK": 5
}
```

响应：

```json
{
  "success": true,
  "code": "OK",
  "message": "success",
  "data": {
    "items": [
      {
        "knowledgeId": "kb_library_hours_001",
        "title": "南湖校区图书馆开放时间",
        "category": "library",
        "content": "南湖校区图书馆开放时间为 08:00-22:00。演示数据以学校最新通知为准。",
        "snippet": "开放时间为 08:00-22:00",
        "source": "demo_knowledge_base",
        "updatedAt": "2026-07-01T00:00:00+08:00",
        "trustLevel": "demo",
        "score": 0.91
      }
    ],
    "confidencePolicy": {
      "directAnswerThreshold": 0.80,
      "caveatThreshold": 0.65
    }
  }
}
```

RAG 处理规则：

`score` 仅表示检索相关性。MVP 可采用关键词命中、标签权重或简化 BM25 计算，不得将其表述为“答案真实概率”。

| 分数 | API/Agent 处理 |
| ---: | --- |
| `score >= 0.80` | 可直接回答，必须展示来源、更新时间、可信等级。 |
| `0.65 <= score < 0.80` | 可回答但必须加不确定提示。 |
| `score < 0.65` 或无命中 | 返回低相关状态，不生成具体结论。 |

低相关响应示例：

```json
{
  "success": true,
  "code": "LOW_RELEVANCE_KNOWLEDGE",
  "message": "未找到可靠知识库来源",
  "data": {
    "items": [],
    "suggestion": "请以学校官网或人工服务窗口信息为准。"
  }
}
```

## 8. 课表接口与本地工具协议

MVP 阶段课表优先存储在本地，因此以下接口作为本地 Repository 的方法协议，也可在后续迁移到服务端。

### 8.1 查询课表

工具名：`schedule.query`

请求：

```json
{
  "date": "2026-07-08",
  "weekday": 3,
  "period": "morning",
  "weekIndex": 1
}
```

响应：

```json
{
  "courses": [
    {
      "courseId": "course_001",
      "name": "高等数学",
      "teacher": "王老师",
      "location": "15号楼 302",
      "weekday": 3,
      "startSection": 1,
      "endSection": 2,
      "weeks": [1, 2, 3, 4, 5, 6, 7, 8],
      "remark": "演示课程"
    }
  ],
  "source": "local_schedule",
  "verified": true
}
```

### 8.2 新增/编辑/删除课程 P1

`schedule.create`、`schedule.update`、`schedule.delete` 为 P1，不作为 MVP P0 阻塞项。删除课程等破坏性本地操作应复用 PendingAction 或提供撤销。

## 9. Agent 会话接口

如果 Agent 逻辑部署在服务端，可使用以下接口。若 Agent 全部在 Flutter 端编排，该协议可作为内部 DTO。

### 9.1 发送消息

```http
POST /agent/messages
```

请求：

```json
{
  "sessionId": "session_001",
  "message": "饭卡丢了，帮我挂失",
  "inputType": "text",
  "clientContext": {
    "timezone": "Asia/Shanghai",
    "currentDate": "2026-07-07",
    "demoMode": true,
    "debugTraceEnabled": true
  }
}
```

非流式响应示例：

```json
{
  "success": true,
  "code": "OK",
  "message": "success",
  "data": {
    "assistantMessage": "我会先检查校园卡状态，并在你确认后执行挂失。",
    "runId": "run_20260707_001",
    "runStatus": "suspended_for_confirmation",
    "phase": "respond",
    "toolCalls": [
      {
        "toolCallId": "tool_001",
        "toolName": "campus_card.get_status",
        "status": "success"
      }
    ],
    "pendingAction": {
      "pendingActionId": "pa_20260707_001",
      "toolName": "campus_card.report_loss",
      "status": "pending_confirmation"
    }
  }
}
```

### 9.2 流式消息事件

可使用 SSE 或 WebSocket。MVP 可优先使用内部事件流；若服务端部署，可使用 SSE。

事件包必须包含 `runId`、递增 `sequence` 和 `terminal` 字段。`pending_action_created` 是暂停点，终止当前前半段流；用户确认后必须通过 `/agent/runs/{runId}/resume` 或内部 `resume(runId, pendingActionId)` 开启后半段事件流。

前半段事件示例：

```text
event: agent_phase
data: {"runId":"run_20260707_001","sequence":1,"phase":"observe","traceId":"trace_001","terminal":false}

event: agent_phase
data: {"runId":"run_20260707_001","sequence":2,"phase":"plan","intent":"campus_card_report_loss","steps":["campus_card.get_status","campus_card.report_loss","knowledge.search"],"terminal":false}

event: safety_gate_decision
data: {"runId":"run_20260707_001","sequence":3,"toolName":"campus_card.get_status","decision":"allow","terminal":false}

event: tool_call_started
data: {"runId":"run_20260707_001","sequence":4,"toolCallId":"tool_001","toolName":"campus_card.get_status","status":"running","terminal":false}

event: tool_call_finished
data: {"runId":"run_20260707_001","sequence":5,"toolCallId":"tool_001","toolName":"campus_card.get_status","status":"success","terminal":false}

event: pending_action_created
data: {"runId":"run_20260707_001","sequence":6,"pendingActionId":"pa_20260707_001","toolName":"campus_card.report_loss","riskLevel":"high","expiresAt":"2026-07-07T10:10:00+08:00","runStatus":"suspended_for_confirmation","terminal":true}
```

后半段 resume 事件示例：

```text
event: run_resumed
data: {"runId":"run_20260707_001","sequence":7,"pendingActionId":"pa_20260707_001","status":"resumed","terminal":false}

event: tool_call_started
data: {"runId":"run_20260707_001","sequence":8,"toolCallId":"tool_002","toolName":"campus_card.report_loss","status":"running","terminal":false}

event: tool_call_finished
data: {"runId":"run_20260707_001","sequence":9,"toolCallId":"tool_002","toolName":"campus_card.report_loss","status":"success","terminal":false}

event: tool_call_verified
data: {"runId":"run_20260707_001","sequence":10,"toolCallId":"tool_002","toolName":"campus_card.report_loss","verificationResult":"status_lost","terminal":false}

event: evidence_selected
data: {"runId":"run_20260707_001","sequence":11,"knowledgeId":"kb_card_replace_001","score":0.91,"source":"demo_knowledge_base","trustLevel":"demo","terminal":false}

event: message_delta
data: {"runId":"run_20260707_001","sequence":12,"delta":"已为演示账号完成校园卡挂失","terminal":false}

event: message_done
data: {"runId":"run_20260707_001","sequence":13,"messageId":"msg_002","runStatus":"completed","terminal":true}
```

### 9.3 Debug Trace 事件

Trace 只展示脱敏阶段级事实。Trace 事件必须来自 Agent Orchestrator 或测试注入的 Orchestrator Mock，UI 不允许生成 Trace。

```json
{
  "traceId": "trace_001",
  "runId": "run_20260707_001",
  "events": [
    {
      "sequence": 2,
      "phase": "plan",
      "intent": "campus_card_report_loss",
      "toolName": "campus_card.report_loss",
      "safetyDecision": "require_confirmation",
      "stateBefore": "running",
      "stateAfter": "suspended_for_confirmation",
      "durationMs": 120
    },
    {
      "sequence": 10,
      "phase": "verify",
      "toolName": "knowledge.search",
      "evidenceIds": ["kb_card_replace_001"],
      "evidenceScore": 0.91,
      "verificationResult": "source_accepted",
      "durationMs": 80
    }
  ]
}
```

禁止在 Trace 中输出系统 Prompt、隐藏推理链、Token、完整学号、完整卡号、完整工具请求体。

## 10. 埋点接口 P1

```http
POST /events
```

请求：

```json
{
  "eventName": "tool_call_success",
  "eventTime": "2026-07-07T10:10:00+08:00",
  "properties": {
    "toolName": "schedule.query",
    "durationMs": 120,
    "demoMode": true
  }
}
```

隐私要求：

1. 埋点不得包含完整学号、手机号、校园卡号。
2. 用户输入内容默认不上传；如需上传应先脱敏并获得授权。
3. API 错误日志只记录错误码、接口名、耗时和请求 ID。

## 11. 接口验收标准

1. 所有接口成功和失败都使用统一响应格式。
2. P0 工具协议覆盖 `schedule.query`、`campus_card.get_status`、`campus_card.report_loss`、`knowledge.search`。
3. 校园卡挂失接口必须校验 `pendingActionId`、`confirmationId` 与 `frozenParamsHash`。
4. Mock 数据能覆盖饭卡挂失、课表查询、图书馆时间、补办流程。
5. 前端能根据错误码展示明确错误提示。
6. RAG 响应必须包含 `knowledgeId`、`source`、`updatedAt`、`trustLevel`、`score`，并说明 `score` 是相关性分数。
7. 流式事件能表达 Agent 阶段、Safety Gate 决策、PendingAction、工具调用、Verify 和最终回复，并包含 `runId`、递增 `sequence`、`terminal`。
8. 需要确认的 Run 必须先暂停，再通过 `resume` 开启后半段执行。
9. Debug Trace 完全脱敏，不包含隐藏推理链或敏感明文，且不得由 UI 自行生成。
