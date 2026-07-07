import 'dart:convert';
import 'package:crypto/crypto.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Agent Run State Machine
// ─────────────────────────────────────────────────────────────────────────────

enum RunState {
  created,
  running,
  completed,
  failed,
  cancelled,
  suspendedForConfirmation,
  resumed,
  expired,
}

// ─────────────────────────────────────────────────────────────────────────────
// Agent Run
// ─────────────────────────────────────────────────────────────────────────────

class AgentRun {
  final String runId;
  final String sessionId;
  final String userMessage;
  RunState state;
  DateTime createdAt;
  DateTime? completedAt;
  String? intent;
  double? intentConfidence;
  List<ToolCall> plannedTools;
  List<ToolCallResult> toolResults;
  String? response;
  String? errorMessage;
  String? pendingActionId;

  AgentRun({
    required this.runId,
    required this.sessionId,
    required this.userMessage,
    this.state = RunState.created,
    DateTime? createdAt,
    this.completedAt,
    this.intent,
    this.intentConfidence,
    List<ToolCall>? plannedTools,
    List<ToolCallResult>? toolResults,
    this.response,
    this.errorMessage,
    this.pendingActionId,
  })  : createdAt = createdAt ?? DateTime.now(),
        plannedTools = plannedTools ?? [],
        toolResults = toolResults ?? [];

  Duration? get duration =>
      completedAt != null ? completedAt!.difference(createdAt) : null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Intent
// ─────────────────────────────────────────────────────────────────────────────

class IntentClassification {
  final String intent;
  final double confidence;
  final Map<String, dynamic> extractedParams;

  const IntentClassification({
    required this.intent,
    required this.confidence,
    this.extractedParams = const {},
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Tool System
// ─────────────────────────────────────────────────────────────────────────────

class ToolParamDef {
  final String name;
  final String type;
  final String description;
  final bool required;
  final dynamic defaultValue;

  const ToolParamDef({
    required this.name,
    required this.type,
    required this.description,
    this.required = false,
    this.defaultValue,
  });
}

class ToolDefinition {
  final String name;
  final String displayName;
  final String description;
  final List<ToolParamDef> params;
  final bool sensitive;
  final String riskLevel; // 'low', 'medium', 'high'

  const ToolDefinition({
    required this.name,
    required this.displayName,
    required this.description,
    this.params = const [],
    this.sensitive = false,
    this.riskLevel = 'low',
  });
}

class ToolCall {
  final String callId;
  final String toolName;
  final Map<String, dynamic> params;
  final DateTime timestamp;

  ToolCall({
    required this.callId,
    required this.toolName,
    this.params = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ToolCallResult {
  final String callId;
  final String toolName;
  final bool success;
  final dynamic data;
  final String? errorMessage;
  final DateTime timestamp;

  ToolCallResult({
    required this.callId,
    required this.toolName,
    required this.success,
    this.data,
    this.errorMessage,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ─────────────────────────────────────────────────────────────────────────────
// PendingAction (Sensitive Operation Protocol)
// ─────────────────────────────────────────────────────────────────────────────

class PendingAction {
  final String pendingActionId;
  final String runId;
  final String toolName;
  final Map<String, dynamic> frozenParams;
  final String frozenParamsHash;
  final DateTime createdAt;
  final DateTime expiresAt;
  bool confirmed;
  String? confirmationId;

  PendingAction({
    required this.pendingActionId,
    required this.runId,
    required this.toolName,
    required this.frozenParams,
    required this.frozenParamsHash,
    DateTime? createdAt,
    DateTime? expiresAt,
    this.confirmed = false,
    this.confirmationId,
  })  : createdAt = createdAt ?? DateTime.now(),
        expiresAt = expiresAt ??
            DateTime.now().add(const Duration(minutes: 5));

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  static String computeHash(Map<String, dynamic> params) {
    final jsonStr = jsonEncode(params);
    return sha256.convert(utf8.encode(jsonStr)).toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Messages
// ─────────────────────────────────────────────────────────────────────────────

enum ChatMessageType { user, agent, toolCard, confirmCard, system, error }

class ChatMessage {
  final String id;
  final ChatMessageType type;
  final String? text;
  final DateTime timestamp;
  final String? toolName;
  final ToolCallResult? toolResult;
  final PendingAction? pendingAction;
  final List<AgentTraceStep>? traceSteps;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.type,
    this.text,
    DateTime? timestamp,
    this.toolName,
    this.toolResult,
    this.pendingAction,
    this.traceSteps,
    this.isStreaming = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ─────────────────────────────────────────────────────────────────────────────
// Agent Trace
// ─────────────────────────────────────────────────────────────────────────────

enum TraceStepType {
  observe,
  plan,
  safetyGate,
  act,
  verify,
  respond,
  error,
}

class AgentTraceStep {
  final TraceStepType type;
  final String label;
  final String detail;
  final DateTime timestamp;
  final bool success;

  AgentTraceStep({
    required this.type,
    required this.label,
    required this.detail,
    DateTime? timestamp,
    this.success = true,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock Data Models
// ─────────────────────────────────────────────────────────────────────────────

class ScheduleEntry {
  final String courseName;
  final String teacher;
  final String classroom;
  final String building;
  final int startPeriod;
  final int endPeriod;
  final String dayOfWeek; // 'Monday' .. 'Friday'
  final String weeks; // e.g. '1-16'

  const ScheduleEntry({
    required this.courseName,
    required this.teacher,
    required this.classroom,
    required this.building,
    required this.startPeriod,
    required this.endPeriod,
    required this.dayOfWeek,
    required this.weeks,
  });

  String get periodRange => '第$startPeriod-$endPeriod节';
  String get location => '$building $classroom';
}

class CampusCardInfo {
  final String cardNumber; // masked: ****1234
  final String holderName;
  final String department;
  final double balance;
  final String status; // 'active', 'frozen', 'lost', 'reported_lost'
  final DateTime lastTransaction;
  final double dailySpent;
  final double dailyLimit;

  const CampusCardInfo({
    required this.cardNumber,
    required this.holderName,
    required this.department,
    required this.balance,
    required this.status,
    required this.lastTransaction,
    required this.dailySpent,
    required this.dailyLimit,
  });

  bool get canTransact => status == 'active';
  double get remainingDaily => dailyLimit - dailySpent;
}

class CardTransaction {
  final String id;
  final DateTime time;
  final String location;
  final double amount;
  final String type; // 'consume', 'recharge', 'refund'
  final double balanceAfter;

  const CardTransaction({
    required this.id,
    required this.time,
    required this.location,
    required this.amount,
    required this.type,
    required this.balanceAfter,
  });
}

class KnowledgeArticle {
  final String id;
  final String title;
  final String category;
  final String content;
  final List<String> tags;
  final DateTime lastUpdated;
  final double relevanceScore;

  const KnowledgeArticle({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    this.tags = const [],
    required this.lastUpdated,
    this.relevanceScore = 0.0,
  });
}
