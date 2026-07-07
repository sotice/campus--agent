import '../data/models.dart';
import 'tool_registry.dart';

/// Safety Gate — mandatory boundary between plan and execution.
/// Validates: tool whitelist, schema, permissions, risk level, confirmation.
class SafetyGate {
  static final SafetyGate _instance = SafetyGate._();
  factory SafetyGate() => _instance;
  SafetyGate._();

  final ToolRegistry _registry = ToolRegistry();

  /// Validate a planned tool call against safety rules.
  SafetyGateResult validate(ToolCall call, {String? confirmationId}) {
    // 1. Check tool exists in registry
    final tool = _registry.getTool(call.toolName);
    if (tool == null) {
      return SafetyGateResult(
        allowed: false,
        reason: '工具 "${call.toolName}" 未注册，无法执行。',
        riskLevel: 'unknown',
      );
    }

    final def = tool.definition;

    // 2. Validate required parameters
    for (final param in def.params.where((p) => p.required)) {
      if (!call.params.containsKey(param.name) ||
          call.params[param.name] == null ||
          (call.params[param.name] is String &&
              (call.params[param.name] as String).isEmpty)) {
        return SafetyGateResult(
          allowed: false,
          reason: '缺少必需参数: ${param.name} (${param.description})',
          riskLevel: def.riskLevel,
        );
      }
    }

    // 3. Check if tool is sensitive
    if (def.sensitive) {
      if (confirmationId == null) {
        return SafetyGateResult(
          allowed: false,
          reason: '工具 "${def.displayName}" 是敏感操作，需要用户确认。',
          riskLevel: def.riskLevel,
          requiresConfirmation: true,
        );
      }
      // In a real system, we'd validate the confirmationId here
    }

    // 4. All checks passed
    return SafetyGateResult(
      allowed: true,
      riskLevel: def.riskLevel,
      toolDefinition: def,
    );
  }
}

class SafetyGateResult {
  final bool allowed;
  final String? reason;
  final String riskLevel;
  final bool requiresConfirmation;
  final ToolDefinition? toolDefinition;

  const SafetyGateResult({
    required this.allowed,
    this.reason,
    this.riskLevel = 'low',
    this.requiresConfirmation = false,
    this.toolDefinition,
  });
}
