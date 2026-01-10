import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EmojiService {
  static const String _kRecentEmojis = 'recent_emojis';
  static const int _maxRecentCount = 30;
  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static Future<List<String>> getRecentEmojis() async {
    try {
      final jsonStr = await _storage.read(key: _kRecentEmojis);
      if (jsonStr == null) return [];
      
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> addRecentEmoji(String emoji) async {
    try {
      List<String> recent = await getRecentEmojis();
      
      recent.remove(emoji);
      
      recent.insert(0, emoji);
      
      if (recent.length > _maxRecentCount) {
        recent = recent.sublist(0, _maxRecentCount);
      }
      
      await _storage.write(key: _kRecentEmojis, value: jsonEncode(recent));
    } catch (e) {
      //
    }
  }


  static Future<void> removeRecentEmoji(String emoji) async {
    try {
      List<String> recent = await getRecentEmojis();
      if (recent.remove(emoji)) {
        await _storage.write(key: _kRecentEmojis, value: jsonEncode(recent));
      }
    } catch (e) {
      //
    }
  }

  static Future<void> clearRecentEmojis() async {
    try {
      await _storage.delete(key: _kRecentEmojis);
    } catch (e) {
      //
    }
  }

  static bool isOnlyEmojis(String text) {
    if (text.isEmpty) return false;
    
    final RegExp emojiRegex = RegExp(
      r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])+$'
    );
    
    return emojiRegex.hasMatch(text.replaceAll(' ', ''));
  }

  static List<String> getDefaultReactions() {
    return ['❤️', '👍', '😂', '😮', '😢', '🔥'];
  }
}
