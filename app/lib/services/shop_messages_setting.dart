import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether this client wants to see follow-up messages from shops. Messages are a
/// form of direct marketing, so clients can object to all of them at once (GDPR
/// art. 21(2)). When off, the app doesn't even load a shop's messages.
///
/// Kept on the device, like the matching itself: Loyi never learns the choice.
class ShopMessagesSetting extends ValueNotifier<bool> {
  ShopMessagesSetting() : super(true);

  static const _key = 'showShopMessages';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      value = prefs.getBool(_key) ?? true;
    } catch (e) {
      debugPrint('Shop messages setting not loaded: $e');
    }
  }

  Future<void> set(bool show) async {
    value = show;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, show);
    } catch (_) {
      // Not remembered, but applied for this session.
    }
  }
}

final shopMessagesSetting = ShopMessagesSetting();
