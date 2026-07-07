import '../data/models.dart';
import '../data/mock_campus_card_data.dart';
import 'base_tool.dart';

/// campus_card.get_status — Check card status (non-sensitive)
class CampusCardGetStatusTool extends BaseTool {
  @override
  ToolDefinition get definition => const ToolDefinition(
        name: 'campus_card.get_status',
        displayName: '查询校园卡',
        description: '查询校园卡余额、状态和最近交易记录',
        params: [],
        sensitive: false,
        riskLevel: 'low',
      );

  @override
  Future<ToolCallResult> execute(ToolCall call) async {
    await Future.delayed(const Duration(milliseconds: 400));

    final card = MockCampusCardData.getCardStatus();
    final transactions = MockCampusCardData.getRecentTransactions(limit: 5);

    return ToolCallResult(
      callId: call.callId,
      toolName: call.toolName,
      success: true,
      data: {
        'cardNumber': card.cardNumber,
        'holderName': card.holderName,
        'department': card.department,
        'balance': card.balance,
        'status': card.status,
        'dailySpent': card.dailySpent,
        'dailyLimit': card.dailyLimit,
        'recentTransactions': transactions
            .map((t) => {
                  'time': t.time.toIso8601String(),
                  'location': t.location,
                  'amount': t.amount,
                  'type': t.type,
                  'balanceAfter': t.balanceAfter,
                })
            .toList(),
      },
    );
  }
}

/// campus_card.report_loss — Report card lost (SENSITIVE — requires PendingAction)
class CampusCardReportLossTool extends BaseTool {
  @override
  ToolDefinition get definition => const ToolDefinition(
        name: 'campus_card.report_loss',
        displayName: '校园卡挂失',
        description: '挂失校园卡，冻结账户防止盗刷。此操作需要用户确认。',
        params: [
          ToolParamDef(
            name: 'reason',
            type: 'string',
            description: '挂失原因',
            defaultValue: 'card_lost',
          ),
        ],
        sensitive: true,
        riskLevel: 'high',
      );

  @override
  Future<ToolCallResult> execute(ToolCall call) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // In a real system, this would call the backend API
    return ToolCallResult(
      callId: call.callId,
      toolName: call.toolName,
      success: true,
      data: {
        'status': 'reported_lost',
        'message': '校园卡已成功挂失，账户已冻结。',
        'cardNumber': MockCampusCardData.activeCard.cardNumber,
        'frozenBalance': MockCampusCardData.activeCard.balance,
        'nextStep': '请携带学生证和身份证到学生事务中心1楼补办新卡。',
        'serviceCenter': '校园卡服务中心（学生事务中心1楼）',
        'serviceHours': '工作日 8:30-17:00',
      },
    );
  }
}
