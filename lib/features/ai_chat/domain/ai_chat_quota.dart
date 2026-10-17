import 'package:shared_preferences/shared_preferences.dart';

/// Preguntas gratis por día al asistente para quien no tiene Pro, para que
/// pruebe la IA antes de contratar el plan.
class AiChatQuota {
  AiChatQuota(this._prefs, {DateTime Function()? now, this.dailyLimit = 3})
    : _now = now ?? DateTime.now;

  static const String _dayKey = 'ai_chat_free_day';
  static const String _countKey = 'ai_chat_free_count';

  final SharedPreferences _prefs;
  final DateTime Function() _now;
  final int dailyLimit;

  String get _today {
    final d = _now();
    return '${d.year}-${d.month}-${d.day}';
  }

  int get usedToday =>
      _prefs.getString(_dayKey) == _today ? _prefs.getInt(_countKey) ?? 0 : 0;

  int get remainingToday =>
      (dailyLimit - usedToday).clamp(0, dailyLimit).toInt();

  bool get hasRemaining => remainingToday > 0;

  Future<void> consume() async {
    final used = usedToday + 1;
    await _prefs.setString(_dayKey, _today);
    await _prefs.setInt(_countKey, used);
  }
}
