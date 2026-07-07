# Campus Agent 软件需求规格说明书 SRS

版本：V1.2  
关联文档：[PRD.md](./PRD.md)  
适用阶段：需求分析、概要设计、测试验收、竞赛答辩  
项目形态：Flutter 应用；Chrome Web + 内置 Mock Service 作为稳定演示路径，Android APK 作为移动端交付证据

## 1. 引言

### 1.1 编写目的

本文档将《产品需求文档 PRD》中的产品目标转化为可设计、可开发、可测试的软件需求。本文档重点约束 Campus Agent 的 MVP 范围、Agent 闭环、工具安全边界、敏感操作确认、RAG 可信问答、失败 UX、数据实体和验收标准。

### 1.2 产品范围

Campus Agent 是面向中南民族大学在校学生与教职工的事务型校园 AI Agent。系统通过文本接收用户指令，结合大模型/规则编排、本地课表、校园知识库和内置 Mock Service，完成校园事务查询、校园卡挂失、课表查询和知识问答等任务。

MVP 阶段采用 P0A/P0B 分级交付。

P0A 必须交付：

- 文本聊天交互：文本输入、阶段状态提示、停止/重试、工具调用状态展示。
- Agent Run 状态机：核心请求遵循 `Observe → Plan → Act → Verify → Respond`，并支持 `suspended_for_confirmation` 与 `resume`。
- Tool Safety Gate：模型只能提出计划，工具调用必须经过白名单、Schema、权限、敏感等级、确认凭证和冻结参数哈希检查。
- PendingAction：校园卡挂失等敏感操作必须先创建待确认动作，确认后通过 `resume` 执行后半段。
- 核心工具：`schedule.query`、`campus_card.get_status`、`campus_card.report_loss`、`knowledge.search`。
- 本地课表查询：使用预置或本地课表数据支持自然语言查课与离线查看。
- 校园知识问答：基于知识库检索结果回答，展示来源、更新时间、可信等级和相关性分数。
- 失败兜底：网络、工具、模型、确认、低相关 RAG 等失败状态均有明确用户路径。
- Judge Mode / Debug Trace：Demo 模式下展示脱敏的阶段级执行轨迹。
- Android APK 闭环证据：至少构建并跑通一次校园卡闭环，留存截图或录屏。

P0B 在 P0A 稳定后交付：大模型流式自然语言摘要、低相关安全失败 Demo、Judge Mode 微交互增强。

以下能力不属于 MVP P0A：语音输入、完整课表新增/编辑/删除、真实校园 API、真实统一认证、通知摘要、TTS、图书馆馆藏检索、iOS、生产级埋点。

### 1.3 术语定义

| 术语 | 定义 |
| --- | --- |
| Agent | 能将用户自然语言目标转化为可观察、可确认、可验证事务流程的编排模块。 |
| Agent 闭环 | `Observe → Plan → Act → Verify → Respond`，用于证明系统不是普通聊天机器人。 |
| Agent Run | 一次用户请求对应的可追踪执行实例，包含 `runId`、状态机、阶段事件、工具调用和最终结果。 |
| Tool | Agent 可调用的受控功能单元，例如查询课表、查询校园卡状态、挂失校园卡、检索知识库。 |
| Tool Safety Gate | 位于 Plan 与 Act 之间的强制安全门，负责工具白名单、参数校验、权限、确认和日志脱敏。 |
| PendingAction | 敏感操作在执行前创建的待确认动作，包含冻结参数摘要、规范化参数哈希、风险说明、过期时间和内部一次性确认凭证。 |
| RAG | 检索增强生成，通过校园知识库检索结果约束大模型回答；MVP 的 `score` 仅表示检索相关性，不表示真实性概率。 |
| Debug Trace | Demo 模式下展示的脱敏阶段级执行轨迹，不包含隐藏推理链、密钥或敏感明文。 |
| Judge Mode | 面向评委的演示模式，以聊天 + Agent 飞行记录仪展示阶段、工具、安全门、证据和耗时。 |
| Built-in Mock Service | 内置在 Flutter 应用中的 Mock Repository，用于竞赛稳定演示。 |

## 2. 总体描述

### 2.1 用户角色

| 角色 | 描述 | 核心需求 |
| --- | --- | --- |
| 学生 | 中南民族大学在校本科生、研究生 | 查课表、问办事流程、挂失校园卡、查询图书馆时间。 |
| 教职工 | 学校教师、行政人员、后勤人员 | 查询校园服务、获取流程指引、处理轻量事务。 |
| 演示评委 | 技术竞赛评审人员 | 看见 Agent 的计划、工具、安全、验证和可信来源。 |
| 系统维护者 | 开发或运维人员 | 维护工具、Mock 数据、知识库、错误追踪和脱敏日志。 |

### 2.2 运行环境

| 项目 | 要求 |
| --- | --- |
| 客户端框架 | Flutter，Dart SDK 约束遵循 `pubspec.yaml`。 |
| 首选演示平台 | Chrome Web。 |
| 备选交付平台 | Android APK。 |
| MVP 数据源 | Built-in Mock Service + 本地知识库 + 本地课表。 |
| 可选展示 | 本地 Mock API Server，用于展示接口分层，不作为 P0A 依赖。 |
| AI 能力 | 可通过 `flutter_ai_toolkit`、规则 Mock Agent 或轻量 Agent Gateway 接入；不得在移动端暴露真实模型密钥。 |

### 2.3 约束与假设

1. MVP 不依赖学校真实统一认证系统，使用演示账号与 Mock 数据。
2. MVP 不依赖真实校园卡、教务或图书馆接口，所有核心链路优先走 Built-in Mock Service。
3. 大模型或规则 Agent 只能输出结构化计划，不得直接执行敏感工具。
4. `campus_card.report_loss` 必须经过 Tool Safety Gate 与 PendingAction 确认。
5. 用户课表数据 MVP 可使用预置数据和本地存储；完整 CRUD 移至 P1。
6. 校园知识库内容必须标注来源、更新时间、可信等级和相关性分数。
7. Debug Trace 只能展示 Orchestrator 产生的阶段级、脱敏信息，不能展示隐藏推理链或密钥；UI 不得自行合成 Trace。

## 3. 功能需求

### 3.1 FR-001 文本聊天首页

| 项目 | 说明 |
| --- | --- |
| 优先级 | P0A |
| 描述 | 用户打开应用后进入以 Agent 聊天为核心的首页，可输入文本、查看今日课表摘要、使用核心 Demo 指令。 |
| 输入 | 用户文本、快捷指令。 |
| 输出 | Agent 阶段状态、流式回复、工具调用卡片、PendingAction 确认卡、错误提示、Debug Trace。 |
| 验收标准 | 首屏 1 秒内可交互；发送消息后 500ms 内出现发送状态或 Agent 阶段状态；支持停止和重试。 |

业务规则：

1. 用户发送空文本时不允许提交。
2. 同一时间只允许一个主事务请求处于执行中，避免工具调用顺序混乱。
3. 用户可中止当前生成；中止不删除已有会话内容和已完成工具结果。
4. 工具成功但 AI 摘要失败时，应展示结构化工具结果，而不是丢失结果。

### 3.2 FR-002 Agent 闭环执行

| 项目 | 说明 |
| --- | --- |
| 优先级 | P0A |
| 描述 | Agent 对核心请求必须以 Agent Run 状态机执行，遵循 `Observe → Plan → Act → Verify → Respond`。 |
| 输入 | `runId`、用户消息、会话摘要、用户状态、工具注册表、本地数据摘要。 |
| 输出 | Run 状态、阶段事件、结构化计划、工具调用结果、验证结果、最终回复。 |
| 验收标准 | 校园卡挂失、课表查询、图书馆时间三条核心 Demo 均可展示由 Orchestrator 产生的闭环阶段。 |

阶段规则：

1. Observe：读取用户目标、上下文、当前日期、Demo 模式和必要本地状态。
2. Plan：识别意图、抽取参数、选择工具、判断是否需要澄清或确认。
3. Act：只在 Tool Safety Gate 允许后执行工具。
4. Verify：校验工具结果、业务状态、RAG 来源、可信等级与相关性分数。
5. Respond：基于已验证结果输出用户可读答复，不得编造工具未返回的信息。

Run 状态规则：

1. 每次用户请求创建唯一 `runId`，所有 Trace、工具调用和消息增量必须关联该 `runId`。
2. 需要用户确认时，Run 进入 `suspended_for_confirmation`，不得继续执行敏感工具。
3. 用户确认后通过 `resume(runId, pendingActionId)` 继续执行后半段；不得在同一条单向 SSE 中假装接收用户确认。
4. UI 只能订阅 Run 事件并渲染，不得自行创建 `plan`、`act`、`verify` 等阶段事件。
5. Run 终态只能是 `completed`、`failed`、`cancelled` 或 `expired`。

### 3.3 FR-003 Agent 意图识别与工具选择

| 项目 | 说明 |
| --- | --- |
| 优先级 | P0A |
| 描述 | Agent 根据用户输入判断意图，并生成受控工具计划。 |
| 输入 | 用户消息、会话上下文、用户状态、可用工具列表。 |
| 输出 | 结构化计划、澄清问题、PendingAction 请求或拒绝执行。 |
| 验收标准 | 对核心指令能稳定选择正确工具；未知或含糊请求先澄清。 |

业务规则：

1. 若用户意图不明确，应先追问，不得盲目调用工具。
2. 若模型输出不存在的工具名，Tool Safety Gate 必须阻断。
3. 若参数缺失或 Schema 校验失败，Agent 应追问或提示修正。
4. 对本地课表问题，应优先调用 `schedule.query`，不将完整课表发送给模型。
5. 对校园知识问题，应优先调用 `knowledge.search`，并在 Verify 阶段执行相关性分数策略。
6. 对敏感操作，Agent 只能创建 PendingAction，不能直接执行工具。

### 3.4 FR-004 工具调用状态与事务时间线

| 项目 | 说明 |
| --- | --- |
| 优先级 | P0A |
| 描述 | 当 Agent 规划或调用工具时，前端以事务时间线和工具卡片展示状态。 |
| 状态 | `observing`、`planning`、`need_confirmation`、`running`、`verifying`、`success`、`failed`、`cancelled`、`expired`、`blocked`。 |
| 验收标准 | 工具调用或阶段切换 500ms 内展示状态；失败时提供原因、下一步和是否已执行。 |

业务规则：

1. 工具卡片不展示系统 Prompt、密钥、完整 Token、完整学号或完整卡号。
2. 失败状态应区分网络失败、权限失败、参数错误、业务失败、安全门阻断、确认过期。
3. 工具执行成功后，应将结构化结果交给 Verify 阶段，验证通过后再生成最终回复。
4. Debug Trace 仅在演示模式展示，且必须脱敏。

### 3.5 FR-005 Tool Safety Gate

| 项目 | 说明 |
| --- | --- |
| 优先级 | P0A |
| 描述 | 所有工具调用在执行前必须通过安全门检查。 |
| 输入 | 工具计划、用户状态、工具注册表、环境配置、PendingAction 状态。 |
| 输出 | `allow`、`require_confirmation`、`clarify`、`deny`、`blocked`、`fail_safe`。 |
| 验收标准 | 模型无法通过伪造工具名、参数或确认凭证绕过安全门。 |

检查项：

1. 工具是否存在于注册表。
2. 当前环境是否允许该工具。
3. 输入参数是否通过 JSON Schema 校验。
4. 是否满足登录、授权或演示账号要求。
5. 是否属于敏感操作。
6. 敏感操作是否存在有效 PendingAction 和内部 `confirmationId`。
7. 参数规范化 JSON 的哈希是否与 PendingAction 冻结参数哈希一致。
8. 是否满足幂等、限流和业务前置条件。
9. 日志与 Trace 是否已脱敏。

### 3.6 FR-006 PendingAction 敏感操作确认

| 项目 | 说明 |
| --- | --- |
| 优先级 | P0A |
| 描述 | 对校园卡挂失等敏感操作，系统先创建 PendingAction，用户确认后才执行。 |
| 输入 | 工具计划、冻结参数摘要、风险说明、用户确认/取消动作。 |
| 输出 | PendingAction 状态、执行结果或取消/过期提示；`confirmationId` 只作为内部执行凭证，不向前端输出。 |
| 验收标准 | 未确认、取消、过期、重复确认均不得造成重复或越权执行。 |

业务规则：

1. PendingAction 创建后状态为 `pending_confirmation`。
2. PendingAction 必须包含 `pendingActionId`、`toolName`、`frozenParamsSummary`、`frozenParamsHash`、`riskLevel`、`warningText`、`expiresAt`、`status`。
3. 用户确认时只提交 `runId` 与 `pendingActionId`，Agent 通过 `resume(runId, pendingActionId)` 校验通过后签发一次性内部 `confirmationId`。
4. 确认后必须使用冻结参数执行，不能重新让模型解释用户确认文本。
5. PendingAction 取消、过期、已执行后不得再次使用。
6. 所有结果必须可追溯到对应 `pendingActionId` 和 `toolCallId`，但不得在 UI、日志或 Debug Trace 中暴露 `confirmationId`。
7. `frozenParamsSummary` 仅用于 UI 展示，不作为安全校验依据；安全校验必须使用规范化参数和 `frozenParamsHash`。

### 3.7 FR-007 校园卡挂失

| 项目 | 说明 |
| --- | --- |
| 优先级 | P0A |
| 描述 | 用户通过自然语言发起校园卡挂失请求，系统查状态、确认、执行、验证并给出补办指引。 |
| 输入 | 用户指令、演示账号、校园卡状态、PendingAction 确认结果。 |
| 输出 | 挂失成功/失败结果、验证状态、补办流程来源。 |
| 验收标准 | 未确认不得调用 `campus_card.report_loss`；成功后展示挂失时间、卡号尾号、补办建议和知识库来源。 |

业务规则：

1. 挂失前必须先调用 `campus_card.get_status`。
2. 校园卡已挂失时，不重复调用挂失接口，直接反馈当前状态和补办指引。
3. 挂失前确认卡应说明影响：挂失后校园卡消费、门禁或相关服务可能受限。
4. 挂失执行后必须 Verify：再次查询状态或校验 Mock 状态为 `lost`。
5. 补办指引必须来自 `knowledge.search`，并展示来源与更新时间。

### 3.8 FR-008 本地课表查询

| 项目 | 说明 |
| --- | --- |
| 优先级 | P0A |
| 描述 | 用户通过自然语言询问课程安排，系统调用本地课表工具返回结果。 |
| 示例 | “我明天上午有课吗”“周三下午在哪上课”“今天第一节课是什么” |
| 验收标准 | 能解析日期、星期、上午/下午、节次；无课程时明确说明无课。 |

业务规则：

1. MVP 使用预置或本地课表数据。
2. 查询结果应包含课程名、时间、地点和教师。
3. 本地课表可离线查看。
4. 课程新增、编辑、删除、冲突检测为 P1，不作为 P0A 验收阻塞项。

### 3.9 FR-009 校园知识库问答

| 项目 | 说明 |
| --- | --- |
| 优先级 | P0A |
| 描述 | 回答校园地点、办事流程、图书馆时间、校园卡补办等问题。 |
| 输入 | 用户问题、知识库检索条件。 |
| 输出 | 答案、来源、更新时间、可信等级、相关性分数、补充建议。 |
| 验收标准 | 回答应包含明确结论和来源；无法确认时说明不确定性并给出人工查询入口。 |

RAG 规则：

1. `score >= 0.80`：允许直接回答，并展示来源。
2. `0.65 <= score < 0.80`：可回答但必须加“不确定/以官方为准”提示。
3. `score < 0.65` 或无命中：不得给出具体时间、地点、电话、政策结论。
4. 冲突信息优先级为 `official > verified > demo`，同等级采用更新时间更新的来源。
5. Demo 数据必须标注 `trustLevel=demo`。

### 3.10 FR-010 评委 Debug Trace

| 项目 | 说明 |
| --- | --- |
| 优先级 | P0A |
| 描述 | Demo 模式下展示 Agent 的阶段级执行轨迹，用于证明系统具备事务闭环。 |
| 输入 | Agent 阶段事件、工具事件、RAG 证据、错误码、耗时。 |
| 输出 | 脱敏 Trace 面板或卡片。 |
| 验收标准 | Trace 能展示 intent、tool、safety decision、pendingActionId、evidence score、verification result、duration；不泄露隐藏推理链或敏感明文。 |

## 4. 非功能性需求

### 4.1 性能需求

| 指标 | 要求 |
| --- | --- |
| Chrome Web 首屏可交互 | 1 秒内可输入或点击快捷指令。 |
| 页面刷新/冷启动 | 3 秒内进入首页。 |
| 工具状态反馈 | 工具或阶段启动后 500ms 内展示状态。 |
| AI 首字或状态 | 普通问答 1.5 秒内出现流式内容或等待状态。 |
| 本地课表查询 | 300ms 内完成筛选并返回。 |
| 页面动画 | 常规页面切换保持 60fps。 |

### 4.2 安全需求

1. 用户身份、Token、校园卡相关数据不得明文写入日志或 Trace。
2. 敏感操作必须经过 PendingAction。
3. 大模型请求只发送完成任务所需的最小数据。
4. 工具调用必须经过白名单注册，禁止模型动态拼接任意接口地址。
5. Tool Safety Gate 阻断时，用户可见原因应简洁，不能泄露内部配置。
6. 本地数据应支持清除；生产版本后续支持加密存储。

### 4.3 可用性与失败 UX 要求

| 失败类别 | 用户提示 | 操作 |
| --- | --- | --- |
| 意图不明确 | “你想查询余额还是挂失校园卡？” | 追问/快捷选项 |
| 参数缺失 | “还需要课程时间才能继续。” | 补充参数 |
| 需要登录 | “该操作需要演示账号。” | 使用演示账号 |
| 需要确认 | “这是高风险操作，请确认。” | 确认/取消 |
| 用户取消 | “已取消，未执行。” | 返回聊天 |
| PendingAction 过期 | “确认已过期，请重新发起。” | 重新创建 |
| 安全门阻断 | “该操作当前不允许执行。” | 查看原因/人工路径 |
| Mock 服务异常 | “演示数据暂不可用。” | 重试/切换本地预置 |
| 业务冲突 | “校园卡已处于挂失状态。” | 查看补办流程 |
| 模型超时 | “AI 摘要超时，已保留工具结果。” | 重试摘要 |
| RAG 低相关 | “未找到可靠来源，不能保证准确。” | 官方查询入口 |
| 课表为空 | “当前没有课表数据。” | 使用演示课表/添加课程 |
| 本地数据损坏 | “本地数据异常，已尝试恢复。” | 重置/重新导入 |

等待阶梯要求：

| 时间 | 系统行为 |
| --- | --- |
| 0-500ms | 插入用户消息并展示 Observe 或已收到状态。 |
| 500ms-2s | 展示 Plan 或工具准备状态。 |
| 2-8s | 展示具体工具 running 卡片、耗时和取消入口。 |
| 8-15s | 提供继续等待、取消、重试可重试步骤。 |
| 超过 15s | 进入超时兜底，保留已完成工具结果，不无限 loading。 |

### 4.4 兼容性需求

1. Chrome Web 为竞赛稳定演示平台。
2. Android APK 为移动端交付证据，至少需要完整跑通一次校园卡挂失闭环并保留截图或录屏。
3. Windows Desktop 和 iOS 不作为 MVP 强制验收项。
4. 适配常见屏幕宽度，避免输入框、按钮、时间线、确认卡内容溢出。

## 5. 数据需求

### 5.1 核心数据实体

| 实体 | 关键字段 |
| --- | --- |
| UserProfile | userId、name、role、studentNoMasked、department、authStatus。 |
| AgentRun | runId、sessionId、status、currentPhase、createdAt、suspendedAt、resumedAt、completedAt、terminalReason。 |
| Course | courseId、name、teacher、location、weekday、startSection、endSection、weeks、remark。 |
| ChatMessage | messageId、role、content、createdAt、relatedToolCallId。 |
| ToolCall | toolCallId、toolName、status、inputSummary、resultSummary、createdAt、durationMs、errorCode、pendingActionId。 |
| PendingAction | pendingActionId、toolName、frozenParamsSummary、frozenParamsHash、riskLevel、warningText、expiresAt、status、internalConfirmationId、createdAt、executedAt；`internalConfirmationId` 不外显。 |
| CampusKnowledge | knowledgeId、title、category、content、source、updatedAt、trustLevel、score、snippet。 |
| CampusCard | cardIdMasked、status、balance、lastUpdatedAt。 |
| DebugTraceEvent | traceId、runId、sequence、phase、intent、toolName、safetyDecision、stateBefore、stateAfter、evidenceIds、durationMs、redactedErrorCode、createdAt。 |

### 5.2 数据保留策略

1. 本地课表默认长期保存，用户可手动删除。
2. 会话历史 MVP 可仅保存当前会话；持久化历史为 P1。
3. 工具调用日志只保存摘要，不保存完整敏感参数。
4. PendingAction 过期或完成后只保留脱敏摘要。
5. Mock 数据必须与真实用户数据隔离。

## 6. 验收标准

### 6.1 MVP 验收场景

| 编号 | 场景 | 通过标准 |
| --- | --- | --- |
| AC-001 | 用户输入“校园卡丢了，帮我挂失” | 系统创建 Agent Run，展示计划，查询卡状态，创建 PendingAction；Run 进入 `suspended_for_confirmation`，未确认前不执行挂失。 |
| AC-002 | 用户确认挂失 | 系统通过 `resume` 继续原 Run，调用 `campus_card.report_loss`，随后 Verify 卡状态为 `lost`。 |
| AC-003 | 用户取消或确认过期 | 系统明确说明未执行，Mock 卡状态不变。 |
| AC-004 | 用户输入“那怎么补办？” | 系统继承校园卡上下文，调用 `knowledge.search` 返回补办流程和来源。 |
| AC-005 | 用户输入“我明天上午有课吗” | 系统调用 `schedule.query`，返回课程列表或无课说明。 |
| AC-006 | 用户输入“图书馆今天几点关门” | 系统调用 `knowledge.search`，按 RAG 阈值返回答案或拒答。 |
| AC-007 | RAG 低相关或无命中 | 系统不编造，给出官方/人工查询建议。 |
| AC-008 | 工具调用失败 | 展示失败原因、重试或人工路径，应用不崩溃。 |
| AC-009 | Debug Trace 开启 | 可见阶段级 Trace，且无完整学号、卡号、Token、隐藏推理链。 |
| AC-010 | UI Trace 真实性 | Trace 事件均包含 `runId` 和递增 `sequence`，由 Orchestrator 产生，UI 不能自行伪造。 |

### 6.2 竞赛演示验收

1. 准备可复现演示数据：测试用户、测试校园卡、测试课表、校园知识库。
2. 核心演示采用 Chrome Web + Built-in Mock Service，不依赖外部网络或后端。
3. 三条核心指令必须稳定通过：校园卡挂失、查询明天课表、查询图书馆时间。
4. 校园卡挂失必须展示“查状态 → 确认 → 执行 → 验证 → 补办来源”。
5. 每次工具调用都能看到状态变化，而不是只有最终文本答案。
6. 评委能清楚看到应用具备 Agent 的“观察、计划、安全门、执行、验证、反馈”闭环。
7. Android APK 至少完成一次核心闭环验证，并将截图或录屏作为答辩材料。

### 6.3 通过标准

1. 所有 P0A 用例通过。
2. P0B 用例在 P0A 稳定后尽量完成，P1 用例不阻塞 MVP 验收。
3. 核心演示连续执行 3 次均成功。
4. 敏感操作未确认前不发生真实或模拟执行。
5. 应用在核心流程中无崩溃、无明显卡死、无敏感信息明文日志。
