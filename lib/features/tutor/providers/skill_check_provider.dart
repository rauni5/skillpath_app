import 'package:flutter/foundation.dart';

import '../../audio/sound_effects_service.dart';
import '../../../core/models/skill_check_question.dart';
import '../../../core/models/skill_check_result.dart';
import '../../../core/network/api_exception.dart';
import '../data/tutor_repository.dart';

enum SkillCheckPhase {
  notStarted,
  generating,
  inProgress,
  submitting,
  result,
  error,
}

class SkillCheckProvider extends ChangeNotifier {
  SkillCheckProvider({TutorRepository? repository})
    : _repo = repository ?? TutorRepository();

  final TutorRepository _repo;

  SkillCheckPhase phase = SkillCheckPhase.notStarted;
  String? errorMessage;

  int? attemptId;
  List<SkillCheckQuestion> questions = [];
  int currentIndex = 0;
  final Map<int, int> answers = {}; // question index -> selected option index
  SkillCheckResult? result;

  bool get isLastQuestion => currentIndex == questions.length - 1;
  bool get hasAnsweredCurrent => answers.containsKey(currentIndex);
  int get answeredCount => answers.length;

  /// Resets to a clean slate — call when navigating to a new skill's check.
  void reset() {
    phase = SkillCheckPhase.notStarted;
    errorMessage = null;
    attemptId = null;
    questions = [];
    currentIndex = 0;
    answers.clear();
    result = null;
    notifyListeners();
  }

  Future<void> start(int userId, int skillId) async {
    phase = SkillCheckPhase.generating;
    errorMessage = null;
    notifyListeners();
    try {
      final generated = await _repo.generateSkillCheck(userId, skillId);
      attemptId = generated.attemptId;
      questions = generated.questions;
      currentIndex = 0;
      answers.clear();
      phase = SkillCheckPhase.inProgress;
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not generate a skill check. Please try again.';
      phase = SkillCheckPhase.error;
    }
    notifyListeners();
  }

  void selectAnswer(int optionIndex) {
    answers[currentIndex] = optionIndex;
    SoundEffectsService.instance.play(SoundEffect.buttonTap);
    notifyListeners();
  }

  void goNext() {
    if (currentIndex < questions.length - 1) {
      currentIndex++;
      SoundEffectsService.instance.play(SoundEffect.buttonTap2);
      notifyListeners();
    }
  }

  void goBack() {
    if (currentIndex > 0) {
      currentIndex--;
      SoundEffectsService.instance.play(SoundEffect.buttonTap);
      notifyListeners();
    }
  }

  Future<void> submit(int userId, int skillId) async {
    if (attemptId == null) return;
    phase = SkillCheckPhase.submitting;
    notifyListeners();
    try {
      final orderedAnswers = List.generate(
        questions.length,
        (i) => answers[i] ?? -1,
      );
      result = await _repo.submitSkillCheck(
        userId,
        skillId,
        attemptId: attemptId!,
        answers: orderedAnswers,
      );
      phase = SkillCheckPhase.result;
      SoundEffectsService.instance.play(
        result!.passed ? SoundEffect.quizPass : SoundEffect.quizFail,
      );
    } catch (e) {
      errorMessage = e is ApiException
          ? e.message
          : 'Could not submit this skill check. Please try again.';
      phase = SkillCheckPhase.error;
    }
    notifyListeners();
  }
}
