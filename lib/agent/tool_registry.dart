import '../data/models.dart';
import '../tools/base_tool.dart';
import '../tools/schedule_query_tool.dart';
import '../tools/campus_card_tool.dart';
import '../tools/knowledge_search_tool.dart';

/// Central registry for all available tools.
/// Tools must be registered before the model can use them.
class ToolRegistry {
  final Map<String, BaseTool> _tools = {};

  static final ToolRegistry _instance = ToolRegistry._();

  factory ToolRegistry() => _instance;

  ToolRegistry._() {
    _registerDefaults();
  }

  void _registerDefaults() {
    register(ScheduleQueryTool());
    register(CampusCardGetStatusTool());
    register(CampusCardReportLossTool());
    register(KnowledgeSearchTool());
  }

  void register(BaseTool tool) {
    _tools[tool.definition.name] = tool;
  }

  BaseTool? getTool(String name) => _tools[name];

  bool hasTool(String name) => _tools.containsKey(name);

  List<ToolDefinition> getAllDefinitions() =>
      _tools.values.map((t) => t.definition).toList();

  List<ToolDefinition> getNonSensitiveTools() =>
      _tools.values.where((t) => !t.definition.sensitive).map((t) => t.definition).toList();

  List<ToolDefinition> getSensitiveTools() =>
      _tools.values.where((t) => t.definition.sensitive).map((t) => t.definition).toList();
}
