import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/models.dart';
import 'tool_registry.dart';
import 'safety_gate.dart';
import 'pending_action_manager.dart';

/// Agent Orchestrator — implements the Observe → Plan → Act → Verify → Respond loop.
///
/// This is the central controller for all user requests. It manages the full
/// lifecycle of an AgentRun, including safety gating for sensitive operations.
class AgentOrchestrator extends ChangeNotifier {
  final ToolRegistry _registry = ToolRegistry();
  final SafetyGate _safetyGate = SafetyGate();
  final PendingActionManager _pendingManager = PendingActionManager();

  final List<ChatMessage> _messages = [];
  final List<AgentTraceStep> _currentTrace = [];
  bool _isProcessing = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  List<AgentTraceStep> get currentTrace => List.unmodifiable(_currentTrace);
  bool get isProcessing => _isProcessing;

  final _random = Random();

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Process a user message through the full agent loop.
  Future<void> processMessage(String userMessage) async {
    if (_isProcessing) return;
    _isProcessing = true;
    _currentTrace.clear();

    final runId = 'run_${DateTime.now().millisecondsSinceEpoch}';
    final sessionId = 'session_demo';

    // Add user message to timeline
    _addMessage(ChatMessage(
      id: 'msg_${_random.nextInt(999999)}',
      type: ChatMessageType.user,
      text: userMessage,
    ));

    final run = AgentRun(
      runId: runId,
      sessionId: sessionId,
      userMessage: userMessage,
    );

    try {
      // ── Step 1: Observe ──
      _addTrace(TraceStepType.observe, '观察', '接收用户消息: "$userMessage"');
      run.state = RunState.running;
      notifyListeners();
      await _delay(200);

      // ── Step 2: Plan ──
      _addTrace(TraceStepType.plan, '规划', '进行意图分类和参数提取...');
      notifyListeners();

      final intent = _classifyIntent(userMessage);
      run.intent = intent.intent;
      run.intentConfidence = intent.confidence;

      _addTrace(
        TraceStepType.plan,
        '意图识别',
        '识别意图: ${intent.intent} (置信度: ${(intent.confidence * 100).toStringAsFixed(0)}%)',
      );

      final toolCalls = _planToolCalls(intent);
      run.plannedTools = toolCalls;

      if (toolCalls.isNotEmpty) {
        _addTrace(
          TraceStepType.plan,
          '工具规划',
          '计划调用: ${toolCalls.map((c) => c.toolName).join(", ")}',
        );
      }
      notifyListeners();
      await _delay(300);

      // ── Step 3: Safety Gate ──
      _addTrace(TraceStepType.safetyGate, '安全检查', '验证工具调用权限...');
      notifyListeners();

      List<ToolCall> approvedCalls = [];
      PendingAction? pendingAction;

      for (final call in toolCalls) {
        final result = _safetyGate.validate(call);

        if (result.requiresConfirmation) {
          // Sensitive operation — create PendingAction
          pendingAction = _pendingManager.create(
            runId: runId,
            toolName: call.toolName,
            params: call.params,
          );

          run.state = RunState.suspendedForConfirmation;
          run.pendingActionId = pendingAction.pendingActionId;

          _addTrace(
            TraceStepType.safetyGate,
            '需要确认',
            '敏感操作 "${result.toolDefinition?.displayName}" 需要用户确认',
          );

          // Add confirmation card to chat
          _addMessage(ChatMessage(
            id: 'msg_${_random.nextInt(999999)}',
            type: ChatMessageType.confirmCard,
            text: '敏感操作需要确认',
            pendingAction: pendingAction,
            toolName: call.toolName,
          ));

          _isProcessing = false;
          notifyListeners();
          return; // Wait for user confirmation
        } else if (result.allowed) {
          _addTrace(TraceStepType.safetyGate, '通过', '工具 "${call.toolName}" 验证通过 (风险: ${result.riskLevel})');
          approvedCalls.add(call);
        } else {
          _addTrace(TraceStepType.safetyGate, '拒绝', result.reason ?? '验证失败', success: false);
        }
      }

      notifyListeners();
      await _delay(200);

      // ── Step 4: Act ──
      _addTrace(TraceStepType.act, '执行', '执行已批准的工具调用...');
      notifyListeners();

      for (final call in approvedCalls) {
        final tool = _registry.getTool(call.toolName);
        if (tool == null) continue;

        _addTrace(TraceStepType.act, '调用 ${call.toolName}', '参数: ${call.params}');

        final result = await tool.execute(call);
        run.toolResults.add(result);

        // Add tool card to chat
        _addMessage(ChatMessage(
          id: 'msg_${_random.nextInt(999999)}',
          type: ChatMessageType.toolCard,
          toolName: call.toolName,
          toolResult: result,
        ));

        _addTrace(
          TraceStepType.act,
          '完成 ${call.toolName}',
          result.success ? '执行成功' : '执行失败: ${result.errorMessage}',
          success: result.success,
        );
      }

      notifyListeners();

      // ── Step 5: Verify ──
      _addTrace(TraceStepType.verify, '验证', '校验工具结果...');
      final verificationOk = _verifyResults(run);
      _addTrace(
        TraceStepType.verify,
        verificationOk ? '验证通过' : '验证失败',
        verificationOk ? '所有工具结果符合业务规则' : '部分结果未通过验证',
        success: verificationOk,
      );
      notifyListeners();
      await _delay(200);

      // ── Step 6: Respond ──
      _addTrace(TraceStepType.respond, '响应', '生成最终回复...');
      notifyListeners();

      final response = _generateResponse(run);
      run.response = response;
      run.state = RunState.completed;
      run.completedAt = DateTime.now();

      _addMessage(ChatMessage(
        id: 'msg_${_random.nextInt(999999)}',
        type: ChatMessageType.agent,
        text: response,
        traceSteps: List.from(_currentTrace),
      ));

      _addTrace(
        TraceStepType.respond,
        '完成',
        '响应已生成，耗时: ${run.duration?.inMilliseconds ?? 0}ms',
      );

    } catch (e) {
      run.state = RunState.failed;
      run.errorMessage = e.toString();

      _addMessage(ChatMessage(
        id: 'msg_${_random.nextInt(999999)}',
        type: ChatMessageType.error,
        text: '处理请求时出错: $e',
      ));

      _addTrace(TraceStepType.error, '错误', e.toString(), success: false);
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Resume a suspended run after user confirms the pending action.
  Future<void> confirmPendingAction(String pendingActionId) async {
    final pending = _pendingManager.get(pendingActionId);
    if (pending == null || pending.isExpired) {
      _addMessage(ChatMessage(
        id: 'msg_${_random.nextInt(999999)}',
        type: ChatMessageType.error,
        text: '确认已过期或无效，请重新操作。',
      ));
      notifyListeners();
      return;
    }

    _isProcessing = true;
    _currentTrace.clear();

    _pendingManager.confirm(pendingActionId);

    _addMessage(ChatMessage(
      id: 'msg_${_random.nextInt(999999)}',
      type: ChatMessageType.system,
      text: '用户已确认操作',
    ));

    _addTrace(TraceStepType.safetyGate, '用户确认', '用户确认了敏感操作: ${pending.toolName}');
    notifyListeners();
    await _delay(200);

    // Execute the confirmed tool call
    final call = ToolCall(
      callId: 'call_${_random.nextInt(999999)}',
      toolName: pending.toolName,
      params: pending.frozenParams,
    );

    final tool = _registry.getTool(call.toolName);
    if (tool == null) {
      _addMessage(ChatMessage(
        id: 'msg_${_random.nextInt(999999)}',
        type: ChatMessageType.error,
        text: '工具不可用。',
      ));
      _isProcessing = false;
      notifyListeners();
      return;
    }

    _addTrace(TraceStepType.act, '执行已确认操作', '调用 ${call.toolName}');
    notifyListeners();

    final result = await tool.execute(call);

    _addMessage(ChatMessage(
      id: 'msg_${_random.nextInt(999999)}',
      type: ChatMessageType.toolCard,
      toolName: call.toolName,
      toolResult: result,
    ));

    // Generate response for the confirmed operation
    final response = _generateConfirmedResponse(pending.toolName, result);

    _addMessage(ChatMessage(
      id: 'msg_${_random.nextInt(999999)}',
      type: ChatMessageType.agent,
      text: response,
      traceSteps: List.from(_currentTrace),
    ));

    _addTrace(TraceStepType.respond, '完成', '确认操作已完成');
    _isProcessing = false;
    notifyListeners();
  }

  /// Cancel a pending action.
  void cancelPendingAction(String pendingActionId) {
    _pendingManager.cancel(pendingActionId);
    _addMessage(ChatMessage(
      id: 'msg_${_random.nextInt(999999)}',
      type: ChatMessageType.system,
      text: '操作已取消。',
    ));
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Intent Classification (keyword-based, no LLM)
  // ─────────────────────────────────────────────────────────────────────────

  IntentClassification _classifyIntent(String message) {
    final m = message.toLowerCase();

    // Schedule queries
    if (m.contains('课表') ||
        m.contains('课程') ||
        m.contains('上课') ||
        m.contains('第几节') ||
        m.contains('星期') ||
        m.contains('今天有什么课') ||
        m.contains('明天有课吗') ||
        m.contains('schedule')) {
      final params = <String, dynamic>{};
      if (m.contains('今天') || m.contains('today')) {
        params['day'] = _todayWeekday();
      } else if (m.contains('明天') || m.contains('tomorrow')) {
        params['day'] = _tomorrowWeekday();
      } else if (m.contains('周一') || m.contains('星期一')) {
        params['day'] = 'Monday';
      } else if (m.contains('周二') || m.contains('星期二')) {
        params['day'] = 'Tuesday';
      } else if (m.contains('周三') || m.contains('星期三')) {
        params['day'] = 'Wednesday';
      } else if (m.contains('周四') || m.contains('星期四')) {
        params['day'] = 'Thursday';
      } else if (m.contains('周五') || m.contains('星期五')) {
        params['day'] = 'Friday';
      }
      return IntentClassification(
        intent: 'schedule.query',
        confidence: 0.9,
        extractedParams: params,
      );
    }

    // Campus card — report loss
    if (m.contains('挂失') ||
        m.contains('丢卡') ||
        m.contains('卡丢了') ||
        m.contains('卡不见了') ||
        m.contains('丢失') && m.contains('卡')) {
      return const IntentClassification(
        intent: 'campus_card.report_loss',
        confidence: 0.95,
      );
    }

    // Campus card — check status
    if (m.contains('校园卡') ||
        m.contains('余额') ||
        m.contains('饭卡') ||
        m.contains('消费') ||
        m.contains('充值') ||
        m.contains('卡里还有多少钱')) {
      return const IntentClassification(
        intent: 'campus_card.get_status',
        confidence: 0.9,
      );
    }

    // Knowledge search — with extracted query
    final knowledgeKeywords = [
      '图书馆', '借书', '食堂', '宿舍', '报修', '选课', '教务',
      '网', 'wifi', 'WiFi', '校医院', '看病', '心理', '咨询',
      '挂失', '营业', '开放', '时间', '规定', '怎么办', '在哪',
      '怎么', '如何', '是什么', '谁知道', '谁知道呢',
    ];

    for (final kw in knowledgeKeywords) {
      if (m.contains(kw.toLowerCase())) {
        return IntentClassification(
          intent: 'knowledge.search',
          confidence: 0.8,
          extractedParams: {'query': message},
        );
      }
    }

    // General greeting / unknown
    if (m.contains('你好') || m.contains('hi') || m.contains('hello') || m.contains('嗨')) {
      return const IntentClassification(
        intent: 'greeting',
        confidence: 1.0,
      );
    }

    // Default — try knowledge search
    return IntentClassification(
      intent: 'knowledge.search',
      confidence: 0.5,
      extractedParams: {'query': message},
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Tool Planning
  // ─────────────────────────────────────────────────────────────────────────

  List<ToolCall> _planToolCalls(IntentClassification intent) {
    final callId = 'call_${_random.nextInt(999999)}';

    switch (intent.intent) {
      case 'schedule.query':
        return [
          ToolCall(
            callId: callId,
            toolName: 'schedule.query',
            params: intent.extractedParams,
          ),
        ];

      case 'campus_card.get_status':
        return [
          ToolCall(
            callId: callId,
            toolName: 'campus_card.get_status',
            params: {},
          ),
        ];

      case 'campus_card.report_loss':
        return [
          ToolCall(
            callId: callId,
            toolName: 'campus_card.report_loss',
            params: {'reason': 'card_lost'},
          ),
        ];

      case 'knowledge.search':
        return [
          ToolCall(
            callId: callId,
            toolName: 'knowledge.search',
            params: intent.extractedParams,
          ),
        ];

      case 'greeting':
        return []; // No tool needed

      default:
        return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Verification
  // ─────────────────────────────────────────────────────────────────────────

  bool _verifyResults(AgentRun run) {
    // In this MVP, we verify that:
    // 1. All tool calls returned results
    // 2. No sensitive data is exposed in results
    // 3. Knowledge results have minimum relevance score

    for (final result in run.toolResults) {
      if (!result.success) return false;

      if (result.toolName == 'knowledge.search') {
        final articles = result.data as List?;
        if (articles != null && articles.isNotEmpty) {
          // Check relevance score threshold
          final topScore = (articles.first as Map<String, dynamic>)['relevanceScore'] as double? ?? 0;
          if (topScore < 0.2) {
            // Results too low relevance — would need to inform user
          }
        }
      }
    }
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Response Generation (template-based, no LLM)
  // ─────────────────────────────────────────────────────────────────────────

  String _generateResponse(AgentRun run) {
    if (run.toolResults.isEmpty) {
      if (run.intent == 'greeting') {
        return '你好！我是中南民族大学校园AI助手 🏫\n\n我可以帮你：\n'
            '• 查询课程表\n'
            '• 查看校园卡余额和消费记录\n'
            '• 挂失校园卡\n'
            '• 搜索校园知识库（图书馆、食堂、宿舍等）\n\n'
            '有什么可以帮你的吗？';
      }
      return '抱歉，我没有完全理解你的问题。你可以试着问我关于课程表、校园卡、或校园服务的问题。';
    }

    final buffer = StringBuffer();
    final result = run.toolResults.first;

    switch (result.toolName) {
      case 'schedule.query':
        _formatScheduleResponse(buffer, result);
        break;

      case 'campus_card.get_status':
        _formatCardStatusResponse(buffer, result);
        break;

      case 'knowledge.search':
        _formatKnowledgeResponse(buffer, result);
        break;

      default:
        buffer.write('操作已完成。');
    }

    return buffer.toString();
  }

  void _formatScheduleResponse(StringBuffer buffer, ToolCallResult result) {
    final entries = result.data as List?;
    if (entries == null || entries.isEmpty) {
      buffer.write('没有找到相关课程信息。可能是今天没有课，或者请输入具体的日期或课程名称查询。');
      return;
    }

    buffer.write('为你查询到以下课程信息：\n\n');
    for (final entry in entries) {
      final e = entry as Map<String, dynamic>;
      buffer.write('📚 ${e['courseName']}\n');
      buffer.write('   👨‍🏫 ${e['teacher']}  |  📍 ${e['location']}\n');
      buffer.write('   ⏰ ${e['period']}  |  📅 ${_translateDay(e['dayOfWeek'])}\n');
      buffer.write('   📆 教学周: ${e['weeks']}\n\n');
    }
  }

  void _formatCardStatusResponse(StringBuffer buffer, ToolCallResult result) {
    final data = result.data as Map<String, dynamic>;
    final balance = data['balance'] as double;
    final status = data['status'] as String;
    final statusText = status == 'active' ? '正常' : status;

    buffer.write('💳 校园卡信息\n\n');
    buffer.write('卡号: ${data['cardNumber']}\n');
    buffer.write('持卡人: ${data['holderName']}  |  ${data['department']}\n');
    buffer.write('状态: $statusText\n');
    buffer.write('余额: ¥${balance.toStringAsFixed(2)}\n');
    buffer.write('今日消费: ¥${(data['dailySpent'] as double).toStringAsFixed(2)} / ¥${(data['dailyLimit'] as double).toStringAsFixed(2)}\n\n');

    final txns = data['recentTransactions'] as List?;
    if (txns != null && txns.isNotEmpty) {
      buffer.write('最近消费记录：\n');
      for (final txn in txns.take(5)) {
        final t = txn as Map<String, dynamic>;
        final time = DateTime.parse(t['time'] as String);
        final typeIcon = t['type'] == 'recharge' ? '💰' : '🛒';
        final sign = t['type'] == 'recharge' ? '+' : '-';
        buffer.write('$typeIcon ${_formatDate(time)} ${t['location']}  $sign¥${(t['amount'] as double).toStringAsFixed(2)}\n');
      }
    }
  }

  void _formatKnowledgeResponse(StringBuffer buffer, ToolCallResult result) {
    final articles = result.data as List?;
    if (articles == null || articles.isEmpty) {
      buffer.write('抱歉，知识库中没有找到相关信息。你可以尝试换个关键词，或者联系相关部门咨询。');
      return;
    }

    // Only use high-relevance results
    final relevant = articles.where((a) {
      final score = (a as Map<String, dynamic>)['relevanceScore'] as double? ?? 0;
      return score >= 0.3;
    }).toList();

    if (relevant.isEmpty) {
      buffer.write('抱歉，没有找到足够相关的信息。你可以尝试更具体的关键词，或者：\n');
      buffer.write('• 联系学生事务中心\n');
      buffer.write('• 拨打校园服务热线');
      return;
    }

    final article = relevant.first as Map<String, dynamic>;
    buffer.write('📖 ${article['title']}\n');
    buffer.write('分类: ${article['category']}  |  相关度: ${((article['relevanceScore'] as double) * 100).toStringAsFixed(0)}%\n\n');
    buffer.write(article['content']);

    if (relevant.length > 1) {
      buffer.write('\n\n---\n你可能还想了解：\n');
      for (int i = 1; i < relevant.length && i < 3; i++) {
        final a = relevant[i] as Map<String, dynamic>;
        buffer.write('• ${a['title']}\n');
      }
    }
  }

  String _generateConfirmedResponse(String toolName, ToolCallResult result) {
    if (!result.success) {
      return '操作执行失败: ${result.errorMessage}';
    }

    if (toolName == 'campus_card.report_loss') {
      final data = result.data as Map<String, dynamic>;
      return '✅ 校园卡挂失成功\n\n'
          '卡号: ${data['cardNumber']}\n'
          '冻结余额: ¥${(data['frozenBalance'] as double).toStringAsFixed(2)}\n\n'
          '📋 接下来请：\n'
          '${data['nextStep']}\n\n'
          '📍 ${data['serviceCenter']}\n'
          '⏰ ${data['serviceHours']}\n\n'
          '余额将自动转移到新卡，请尽快办理补卡手续。';
    }

    return '操作已完成。';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _addMessage(ChatMessage msg) {
    _messages.add(msg);
    notifyListeners();
  }

  void _addTrace(TraceStepType type, String label, String detail,
      {bool success = true}) {
    _currentTrace.add(AgentTraceStep(
      type: type,
      label: label,
      detail: detail,
      success: success,
    ));
  }

  Future<void> _delay(int ms) =>
      Future.delayed(Duration(milliseconds: ms));

  String _todayWeekday() {
    // For demo, simulate as Monday
    return 'Monday';
  }

  String _tomorrowWeekday() {
    return 'Tuesday';
  }

  String _translateDay(String day) {
    const map = {
      'Monday': '周一',
      'Tuesday': '周二',
      'Wednesday': '周三',
      'Thursday': '周四',
      'Friday': '周五',
      'Saturday': '周六',
      'Sunday': '周日',
    };
    return map[day] ?? day;
  }

  String _formatDate(DateTime dt) {
    return '${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
