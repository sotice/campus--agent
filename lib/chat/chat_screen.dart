import 'package:flutter/material.dart';
import '../agent/orchestrator.dart';
import '../data/models.dart';
import 'chat_bubble.dart';
import 'tool_card.dart';
import 'confirm_card.dart';
import 'trace_panel.dart';

/// Main chat screen — the primary UI for the Campus Agent demo.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final AgentOrchestrator _orchestrator = AgentOrchestrator();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocus = FocusNode();
  bool _traceExpanded = false;
  bool _showSuggestions = true;

  @override
  void initState() {
    super.initState();
    _orchestrator.addListener(_onOrchestratorUpdate);
  }

  @override
  void dispose() {
    _orchestrator.removeListener(_onOrchestratorUpdate);
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _onOrchestratorUpdate() {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _inputController.clear();
    setState(() => _showSuggestions = false);
    _orchestrator.processMessage(text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: GestureDetector(
              onTap: () => _inputFocus.unfocus(),
              child: _orchestrator.messages.isEmpty
                  ? _buildWelcomeScreen()
                  : _buildMessageList(),
            ),
          ),

          // Trace panel
          TracePanel(
            steps: _orchestrator.currentTrace,
            isExpanded: _traceExpanded,
            onToggle: () => setState(() => _traceExpanded = !_traceExpanded),
          ),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.tertiary,
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.school, color: Colors.white, size: 20),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '中南民族大学',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text(
            '校园AI助手 · MVP Demo',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bug_report_outlined, size: 20),
          tooltip: '切换Trace面板',
          onPressed: () => setState(() => _traceExpanded = !_traceExpanded),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: '清除对话',
          onPressed: () {
            // Re-create orchestrator to reset state
            _orchestrator.removeListener(_onOrchestratorUpdate);
            // We just notify to clear; in a real app we'd reset the orchestrator
            setState(() {
              _showSuggestions = true;
            });
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.school, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              '校园AI助手',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '基于 AI Agent 的智能校园服务\nObserve → Plan → Act → Verify → Respond',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),

            // Suggestion chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _suggestionChip('📅 今天有什么课？'),
                _suggestionChip('💳 查看校园卡余额'),
                _suggestionChip('🔍 图书馆开放时间'),
                _suggestionChip('🆘 我的校园卡丢了'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _orchestrator.messages.length +
          (_orchestrator.isProcessing ? 1 : 0) +
          (_showSuggestions ? 1 : 0),
      itemBuilder: (context, index) {
        // Processing indicator
        if (index == _orchestrator.messages.length + (_showSuggestions ? 1 : 0) &&
            _orchestrator.isProcessing) {
          return _buildTypingIndicator();
        }

        // Quick suggestions after messages
        if (_showSuggestions && index == _orchestrator.messages.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _suggestionChip('📅 查课表'),
                _suggestionChip('💳 校园卡'),
                _suggestionChip('🔍 搜知识库'),
              ],
            ),
          );
        }

        final message = _orchestrator.messages[index];
        return _buildMessageWidget(message);
      },
    );
  }

  Widget _buildMessageWidget(ChatMessage message) {
    switch (message.type) {
      case ChatMessageType.user:
      case ChatMessageType.agent:
        return ChatBubble(message: message);
      case ChatMessageType.toolCard:
        return ToolCard(message: message);
      case ChatMessageType.confirmCard:
        return ConfirmCard(
          message: message,
          onConfirm: () {
            if (message.pendingAction != null) {
              _orchestrator.confirmPendingAction(
                  message.pendingAction!.pendingActionId);
            }
          },
          onCancel: () {
            if (message.pendingAction != null) {
              _orchestrator.cancelPendingAction(
                  message.pendingAction!.pendingActionId);
            }
          },
        );
      case ChatMessageType.system:
        return SystemMessage(text: message.text ?? '');
      case ChatMessageType.error:
        return ErrorMessage(text: message.text ?? '未知错误');
    }
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(top: 8, right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '正在思考...',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _inputController,
                focusNode: _inputFocus,
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  hintText: '输入消息...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 14.5),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.only(bottom: 2),
            child: Material(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _orchestrator.isProcessing
                    ? null
                    : () => _sendMessage(_inputController.text),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _suggestionChip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: () {
        final text = label.replaceAll(RegExp(r'[📅💳🔍🆘]'), '').trim();
        _sendMessage(text);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
    );
  }
}
