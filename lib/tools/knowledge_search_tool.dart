import '../data/models.dart';
import '../data/mock_knowledge_base.dart';
import 'base_tool.dart';

/// knowledge.search — Campus knowledge base retrieval (non-sensitive)
class KnowledgeSearchTool extends BaseTool {
  @override
  ToolDefinition get definition => const ToolDefinition(
        name: 'knowledge.search',
        displayName: '知识库检索',
        description: '搜索校园知识库，返回相关的校园政策、规定和服务信息',
        params: [
          ToolParamDef(
            name: 'query',
            type: 'string',
            description: '搜索关键词',
            required: true,
          ),
        ],
        sensitive: false,
        riskLevel: 'low',
      );

  @override
  Future<ToolCallResult> execute(ToolCall call) async {
    await Future.delayed(const Duration(milliseconds: 350));

    final query = call.params['query'] as String? ?? '';

    if (query.isEmpty) {
      return ToolCallResult(
        callId: call.callId,
        toolName: call.toolName,
        success: false,
        errorMessage: '请提供搜索关键词。',
      );
    }

    final results = MockKnowledgeBase.search(query, threshold: 0.2);

    return ToolCallResult(
      callId: call.callId,
      toolName: call.toolName,
      success: true,
      data: results
          .map((a) => {
                'id': a.id,
                'title': a.title,
                'category': a.category,
                'content': a.content,
                'tags': a.tags,
                'relevanceScore': a.relevanceScore,
                'lastUpdated': a.lastUpdated.toIso8601String(),
              })
          .toList(),
    );
  }
}
