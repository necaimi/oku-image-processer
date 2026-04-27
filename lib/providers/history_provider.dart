import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryItem {
  final DateTime timestamp;
  final int count;
  final String targetDir;
  final Duration duration;
  final bool success;

  HistoryItem({
    required this.timestamp,
    required this.count,
    required this.targetDir,
    required this.duration,
    this.success = true,
  });
}

class HistoryNotifier extends Notifier<List<HistoryItem>> {
  @override
  List<HistoryItem> build() {
    return [];
  }

  void add(HistoryItem item) {
    state = [item, ...state];
  }

  void clear() {
    state = [];
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, List<HistoryItem>>(HistoryNotifier.new);

// 用于侧边栏切换视图的状态
enum AppView { main, history, settings }

class NavigationNotifier extends Notifier<AppView> {
  @override
  AppView build() => AppView.main;

  void setView(AppView view) => state = view;
}

final navigationProvider = NotifierProvider<NavigationNotifier, AppView>(NavigationNotifier.new);
