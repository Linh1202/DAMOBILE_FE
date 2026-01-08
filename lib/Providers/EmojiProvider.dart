import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Services/EmojiService.dart';

final recentEmojisProvider = StateNotifierProvider<RecentEmojiNotifier, List<String>>((ref) {
  return RecentEmojiNotifier();
});

class RecentEmojiNotifier extends StateNotifier<List<String>> {
  RecentEmojiNotifier() : super([]) {
    loadRecent();
  }

  Future<void> loadRecent() async {
    state = await EmojiService.getRecentEmojis();
  }

  Future<void> addEmoji(String emoji) async {
    await EmojiService.addRecentEmoji(emoji);
    state = await EmojiService.getRecentEmojis();
  }

  Future<void> clearRecent() async {
    await EmojiService.clearRecentEmojis();
    state = [];
  }
}
