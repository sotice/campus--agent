import 'package:flutter/material.dart';
import '../data/models.dart';

/// Debug trace panel showing the agent's Observe→Plan→Act→Verify→Respond steps.
class TracePanel extends StatelessWidget {
  final List<AgentTraceStep> steps;
  final bool isExpanded;
  final VoidCallback onToggle;

  const TracePanel({
    super.key,
    required this.steps,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isExpanded ? 280 : 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (always visible)
          GestureDetector(
            onTap: onToggle,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.bug_report_outlined,
                      size: 16, color: Colors.cyan[300]),
                  const SizedBox(width: 8),
                  Text(
                    'Agent Trace',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.cyan[300],
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (steps.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${steps.length} steps',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.cyan[300],
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.grey[500],
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Trace steps (visible when expanded)
          if (isExpanded)
            Expanded(
              child: steps.isEmpty
                  ? Center(
                      child: Text(
                        '等待请求...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      itemCount: steps.length,
                      itemBuilder: (context, index) => _buildTraceStep(steps[index]),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildTraceStep(AgentTraceStep step) {
    final color = _getStepColor(step.type);
    final icon = _getStepIcon(step.type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step type indicator
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 8, top: 2),
            decoration: BoxDecoration(
              color: step.success
                  ? color.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              step.success ? icon : Icons.close,
              size: 12,
              color: step.success ? color : Colors.red[400],
            ),
          ),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      step.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: step.success ? color : Colors.red[400],
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(step.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  step.detail,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                    fontFamily: 'monospace',
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStepColor(TraceStepType type) {
    switch (type) {
      case TraceStepType.observe:
        return Colors.blue[300]!;
      case TraceStepType.plan:
        return Colors.purple[300]!;
      case TraceStepType.safetyGate:
        return Colors.orange[300]!;
      case TraceStepType.act:
        return Colors.green[300]!;
      case TraceStepType.verify:
        return Colors.teal[300]!;
      case TraceStepType.respond:
        return Colors.cyan[300]!;
      case TraceStepType.error:
        return Colors.red[300]!;
    }
  }

  IconData _getStepIcon(TraceStepType type) {
    switch (type) {
      case TraceStepType.observe:
        return Icons.visibility;
      case TraceStepType.plan:
        return Icons.route;
      case TraceStepType.safetyGate:
        return Icons.shield;
      case TraceStepType.act:
        return Icons.play_arrow;
      case TraceStepType.verify:
        return Icons.check_circle_outline;
      case TraceStepType.respond:
        return Icons.chat_bubble_outline;
      case TraceStepType.error:
        return Icons.error_outline;
    }
  }

  String _formatTimestamp(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}.'
        '${dt.millisecond.toString().padLeft(3, '0')}';
  }
}
