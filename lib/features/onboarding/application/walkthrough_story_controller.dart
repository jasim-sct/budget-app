import 'package:flutter/material.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/financial_calculation_engine.dart';
import '../../../core/services/financial_sync_service.dart';

enum StoryChapter {
  welcome,
  createAccount,
  createCategory,
  createTransaction,
  viewBankReaction,
  analyticsShowcase,
  storyEnd,
}

class WalkthroughStoryController extends ChangeNotifier {
  static final WalkthroughStoryController instance = WalkthroughStoryController._();
  WalkthroughStoryController._();

  bool _isStoryActive = false;
  StoryChapter _currentChapter = StoryChapter.welcome;

  bool get isStoryActive => _isStoryActive;
  StoryChapter get currentChapter => _currentChapter;

  int get chapterIndex => _currentChapter.index + 1;
  int get totalChapters => StoryChapter.values.length;

  void startStory() {
    _isStoryActive = true;
    _currentChapter = StoryChapter.welcome;
    notifyListeners();
  }

  void nextChapter() {
    if (_currentChapter.index < StoryChapter.values.length - 1) {
      _currentChapter = StoryChapter.values[_currentChapter.index + 1];
      notifyListeners();
    }
  }

  void goToChapter(StoryChapter chapter) {
    _currentChapter = chapter;
    _isStoryActive = true;
    notifyListeners();
  }

  void skipStory() {
    _isStoryActive = false;
    notifyListeners();
  }

  /// Automatically wipes all test data stored during the walkthrough story
  Future<void> endStoryAndClearData() async {
    await DatabaseHelper.instance.clearAllData();
    await FinancialSyncService.instance.persistAndNotify();
    await FinancialCalculationEngine.instance.recalculate();
    _isStoryActive = false;
    _currentChapter = StoryChapter.welcome;
    notifyListeners();
  }
}
