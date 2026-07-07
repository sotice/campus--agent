import '../data/models.dart';

/// Base class for all tools. Each tool defines its schema and execution logic.
abstract class BaseTool {
  ToolDefinition get definition;

  /// Execute the tool with the given parameters.
  /// Returns a ToolCallResult.
  Future<ToolCallResult> execute(ToolCall call);
}
