import 'package:flutter/material.dart';
import '../data/models.dart';

/// Card displaying tool execution results in the chat timeline.
class ToolCard extends StatelessWidget {
  final ChatMessage message;

  const ToolCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final result = message.toolResult;
    if (result == null) return const SizedBox.shrink();

    final toolName = result.toolName;
    final icon = _getToolIcon(toolName);
    final displayName = _getToolDisplayName(toolName);
    final color = _getToolColor(toolName);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
          color: color.withOpacity(0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: color),
                    const SizedBox(width: 8),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: result.success
                            ? Colors.green.withOpacity(0.15)
                            : Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        result.success ? '成功' : '失败',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: result.success ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(14),
                child: _buildToolContent(context, result),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolContent(BuildContext context, ToolCallResult result) {
    if (!result.success) {
      return Text(
        '错误: ${result.errorMessage}',
        style: TextStyle(fontSize: 13, color: Colors.red[700]),
      );
    }

    switch (result.toolName) {
      case 'schedule.query':
        return _buildScheduleContent(result);
      case 'campus_card.get_status':
        return _buildCardStatusContent(result);
      case 'campus_card.report_loss':
        return _buildReportLossContent(result);
      case 'knowledge.search':
        return _buildKnowledgeContent(result);
      default:
        return Text(
          result.data.toString(),
          style: const TextStyle(fontSize: 13),
        );
    }
  }

  Widget _buildScheduleContent(ToolCallResult result) {
    final entries = result.data as List?;
    if (entries == null || entries.isEmpty) {
      return const Text('没有找到课程信息', style: TextStyle(fontSize: 13));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: entries.map((entry) {
        final e = entry as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 36,
                margin: const EdgeInsets.only(right: 10, top: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e['courseName']}  ${e['period']}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${e['teacher']}  •  ${e['location']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCardStatusContent(ToolCallResult result) {
    final data = result.data as Map<String, dynamic>;
    final balance = data['balance'] as double;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.credit_card, size: 32, color: Colors.indigo),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data['holderName']}  ${data['cardNumber']}',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${data['department']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _infoChip('余额', '¥${balance.toStringAsFixed(2)}', Colors.green),
            const SizedBox(width: 8),
            _infoChip(
              '今日消费',
              '¥${(data['dailySpent'] as double).toStringAsFixed(2)}',
              Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportLossContent(ToolCallResult result) {
    final data = result.data as Map<String, dynamic>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Text(
              '校园卡挂失成功',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('卡号: ${data['cardNumber']}'),
        Text('冻结余额: ¥${(data['frozenBalance'] as double).toStringAsFixed(2)}'),
      ],
    );
  }

  Widget _buildKnowledgeContent(ToolCallResult result) {
    final articles = result.data as List?;
    if (articles == null || articles.isEmpty) {
      return const Text('未找到相关知识', style: TextStyle(fontSize: 13));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: articles.take(3).map((article) {
        final a = article as Map<String, dynamic>;
        final score = ((a['relevanceScore'] as double) * 100).toStringAsFixed(0);
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(Icons.article_outlined, size: 16, color: Colors.teal[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${a['title']}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$score%',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.teal[700],
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  IconData _getToolIcon(String toolName) {
    switch (toolName) {
      case 'schedule.query':
        return Icons.calendar_today;
      case 'campus_card.get_status':
        return Icons.credit_card;
      case 'campus_card.report_loss':
        return Icons.warning_amber_rounded;
      case 'knowledge.search':
        return Icons.search;
      default:
        return Icons.build;
    }
  }

  String _getToolDisplayName(String toolName) {
    switch (toolName) {
      case 'schedule.query':
        return '课程查询';
      case 'campus_card.get_status':
        return '校园卡查询';
      case 'campus_card.report_loss':
        return '校园卡挂失';
      case 'knowledge.search':
        return '知识库检索';
      default:
        return toolName;
    }
  }

  Color _getToolColor(String toolName) {
    switch (toolName) {
      case 'schedule.query':
        return Colors.blue;
      case 'campus_card.get_status':
        return Colors.indigo;
      case 'campus_card.report_loss':
        return Colors.orange;
      case 'knowledge.search':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
