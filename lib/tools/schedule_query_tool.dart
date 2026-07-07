import '../data/models.dart';
import '../data/mock_schedule_data.dart';
import 'base_tool.dart';

/// schedule.query — Query course schedule (non-sensitive)
class ScheduleQueryTool extends BaseTool {
  @override
  ToolDefinition get definition => const ToolDefinition(
        name: 'schedule.query',
        displayName: '课程查询',
        description: '查询课程表信息，支持按星期、课程名称、教师等条件查询',
        params: [
          ToolParamDef(
            name: 'day',
            type: 'string',
            description: '星期几（Monday-Sunday）',
          ),
          ToolParamDef(
            name: 'keyword',
            type: 'string',
            description: '搜索关键词（课程名/教师/教室）',
          ),
        ],
        sensitive: false,
        riskLevel: 'low',
      );

  @override
  Future<ToolCallResult> execute(ToolCall call) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate latency

    final day = call.params['day'] as String?;
    final keyword = call.params['keyword'] as String?;

    List<ScheduleEntry> results;

    if (keyword != null && keyword.isNotEmpty) {
      results = MockScheduleData.search(keyword);
    } else if (day != null && day.isNotEmpty) {
      results = MockScheduleData.getScheduleForDay(day);
    } else {
      results = MockScheduleData.entries;
    }

    return ToolCallResult(
      callId: call.callId,
      toolName: call.toolName,
      success: true,
      data: results
          .map((e) => {
                'courseName': e.courseName,
                'teacher': e.teacher,
                'location': e.location,
                'period': e.periodRange,
                'dayOfWeek': e.dayOfWeek,
                'weeks': e.weeks,
              })
          .toList(),
    );
  }
}
