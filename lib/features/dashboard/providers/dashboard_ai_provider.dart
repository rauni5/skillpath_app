import 'package:flutter/foundation.dart';

import '../../../core/models/dashboard_summary.dart';
import '../../../core/network/api_exception.dart';
import '../data/dashboard_ai_repository.dart';

enum SummaryLoadState { initial, loading, loaded, empty, error }

class DashboardAiProvider extends ChangeNotifier {
  DashboardAiProvider({DashboardAiRepository? repository})
    : _repo = repository ?? DashboardAiRepository();

  final DashboardAiRepository _repo;

  SummaryLoadState state = SummaryLoadState.initial;
  DashboardSummary? summary;
  String? errorMessage;

  /// True while a fresh Gemini call is in flight (button-triggered).
  bool isGenerating = false;

  /// Loads whatever summary was last generated, if any. Does not call the AI.
  Future<void> load(int userId) async {
    state = SummaryLoadState.loading;
    notifyListeners();
    try {
      summary = await _repo.getSummary(userId);
      state = summary == null
          ? SummaryLoadState.empty
          : SummaryLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not load your summary.';
      state = SummaryLoadState.error;
    }
    notifyListeners();
  }

  /// Triggered only by the user tapping "Refresh" — calls Gemini.
  Future<void> generate(int userId) async {
    isGenerating = true;
    errorMessage = null;
    notifyListeners();
    try {
      summary = await _repo.generateSummary(userId);
      state = SummaryLoadState.loaded;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not generate a summary right now — please try again.';
    } finally {
      isGenerating = false;
      notifyListeners();
    }
  }
}
