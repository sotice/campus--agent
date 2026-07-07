import 'dart:async';
import '../data/models.dart';

/// Manages PendingActions for sensitive operations.
/// Sensitive tool calls are frozen with a SHA-256 hash and suspended
/// until the user explicitly confirms.
class PendingActionManager {
  final Map<String, PendingAction> _pending = {};

  static final PendingActionManager _instance = PendingActionManager._();
  factory PendingActionManager() => _instance;
  PendingActionManager._();

  /// Create a new pending action for a sensitive tool call.
  PendingAction create({
    required String runId,
    required String toolName,
    required Map<String, dynamic> params,
  }) {
    final id = 'pa_${DateTime.now().millisecondsSinceEpoch}';
    final hash = PendingAction.computeHash(params);

    final action = PendingAction(
      pendingActionId: id,
      runId: runId,
      toolName: toolName,
      frozenParams: Map.from(params),
      frozenParamsHash: hash,
    );

    _pending[id] = action;
    return action;
  }

  /// Confirm a pending action. Returns true if the confirmation is valid.
  bool confirm(String pendingActionId) {
    final action = _pending[pendingActionId];
    if (action == null) return false;
    if (action.isExpired) return false;

    action.confirmed = true;
    action.confirmationId = 'conf_${DateTime.now().microsecondsSinceEpoch}';
    return true;
  }

  /// Get a pending action by ID.
  PendingAction? get(String pendingActionId) => _pending[pendingActionId];

  /// Get all pending actions for a run.
  List<PendingAction> getForRun(String runId) =>
      _pending.values.where((a) => a.runId == runId).toList();

  /// Remove expired pending actions.
  void cleanup() {
    _pending.removeWhere((_, action) => action.isExpired);
  }

  /// Cancel a pending action.
  bool cancel(String pendingActionId) {
    return _pending.remove(pendingActionId) != null;
  }
}
