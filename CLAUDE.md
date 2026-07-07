# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Campus Agent is a Flutter/Dart application — a transactional campus AI Agent for South-Central Minzu University (中南民族大学). It follows an `Observe → Plan → Act → Verify → Respond` orchestration loop. The MVP runs entirely on built-in mock data with no external backend dependency.

**Primary demo platform:** Chrome Web + Built-in Mock Service  
**Secondary:** Android APK  
**Language:** Dart (Flutter), SDK ^3.11.3

## Commands

```bash
flutter pub get                              # Fetch dependencies
flutter run -d chrome --web-port 5173        # Run MVP web demo
flutter run -d <device_id>                   # Run on a connected device
flutter test                                 # Run all tests
flutter test test/path/to/specific_test.dart # Run a single test file
flutter analyze                              # Dart static analysis (linter)
flutter build apk --release                  # Build Android APK
flutter build web --release                  # Build web release
flutter clean                                # Clean build cache
```

## Architecture

The project has extensive design documentation in `docs/` (all in Chinese) that defines the target architecture. Implementation follows these specs.

### Core Agent Loop

Every user request creates an **Agent Run** with a unique `runId`. The run passes through:

1. **Observe** — read user message, session context, current date, demo config
2. **Plan** — intent classification, parameter extraction, structured tool plan
3. **Tool Safety Gate** — mandatory boundary between plan and execution; validates tool whitelist, schema, permissions, risk level, and confirmation credentials
4. **Act** — execute approved tool calls
5. **Verify** — validate tool results against business rules and evidence
6. **Respond** — stream response with sources and next-step suggestions

### Agent Run State Machine

```
created → running → completed
created → running → failed
created → running → cancelled
created → running → suspended_for_confirmation → resumed → completed
created → running → suspended_for_confirmation → expired/cancelled
```

### PendingAction Protocol (Sensitive Operations)

For sensitive tools (e.g., `campus_card.report_loss`), the Safety Gate creates a **PendingAction** that freezes parameters with a SHA-256 hash and suspends the run. Execution only proceeds after user confirmation triggers `resume(runId, pendingActionId)`, which issues a one-time internal `confirmationId` that never reaches the UI or logs.

### Planned Directory Structure (Phase 1 — Vertical Closed Loop)

```
lib/
├── main.dart
├── app/                        # App shell and theme
├── chat/                       # Chat UI: timeline, tool cards, confirm cards, trace panel
├── agent/                      # Orchestrator, safety gate, pending action manager, tool registry, trace
├── tools/                      # P0A tools: schedule_query, campus_card, knowledge_search
└── data/                       # Mock data and local repositories
```

### P0A Tools (MVP)

| Tool | Description | Sensitive |
|------|-------------|-----------|
| `schedule.query` | Local schedule queries | No |
| `campus_card.get_status` | Check campus card status (mock) | No |
| `campus_card.report_loss` | Report campus card lost (mock) | **Yes** — requires PendingAction |
| `knowledge.search` | Campus knowledge base retrieval with relevance scoring | No |

### Key Constraints

- UI only consumes Orchestrator events — never fabricates stage, tool call, or safety decision data.
- Tools must be registered in the Tool Registry before use. The model cannot call unregistered tools or bypass the Safety Gate.
- `systemInjectedContext` (pendingActionId, confirmationId, frozenParamsHash) is injected by the Orchestrator after safety validation — it never appears in prompts, frontend state, or Debug Trace.
- The model must never fabricate campus policies, phone numbers, addresses, or operating hours. Knowledge answers require evidence from `knowledge.search` with a relevance score threshold.
- Sensitive data (full student IDs, card numbers, API keys) must never appear in responses, traces, or logs.

## Key Dependencies

- `flutter_ai_toolkit: ^1.0.0` — AI/chat capabilities
- `flutter_lints: ^6.0.0` — lint rules (configured in `analysis_options.yaml`)

## Documentation (docs/)

All design docs are in Chinese. Key files:
- **PRD.md** — Product requirements and demo scenarios
- **SRS_软件需求规格说明书.md** — Software requirements specification
- **AI_Agent设计文档.md** — Agent workflow, tool registry protocol, Safety Gate rules, intent classification
- **系统架构设计.md** — Layered architecture, state management, data layer design
- **API接口设计文档.md** — API interface contracts
- **测试用例.md** — Test cases
- **部署与运行说明.md** — Environment setup, build, and demo instructions
- **评审整改说明.md** — Review feedback and remediation plan
