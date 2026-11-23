import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'progress_store.dart';

class SupabaseProgressStore implements ProgressStore {
  SupabaseProgressStore(this.client, this.prefs, this.userId, String project)
    : prefix = 'daybook.cache.$project.$userId.';

  final SupabaseClient client;
  final SharedPreferences prefs;
  final String userId;
  final String prefix;
  final Map<String, Set<String>> _confirmed = {};

  String _date(DateTime day) =>
      DateTime(day.year, day.month, day.day).toIso8601String().split('T').first;

  @override
  Set<String> completedOn(DateTime day) {
    final date = _date(day);
    return {...?_confirmed[date] ?? prefs.getStringList('$prefix$date')};
  }

  Future<void> refresh() async {
    final fetched = <String, Set<String>>{};
    const pageSize = 300;
    var offset = 0;
    while (true) {
      final rows = await client
          .from('activity_progress')
          .select('activity_date,activity_id')
          .eq('user_id', userId)
          .eq('completed', true)
          .order('activity_date')
          .order('activity_id')
          .range(offset, offset + pageSize - 1)
          .timeout(const Duration(seconds: 8));
      for (final row in rows) {
        final day = row['activity_date'] as String;
        (fetched[day] ??= {}).add(row['activity_id'] as String);
      }
      if (rows.length < pageSize) break;
      offset += rows.length;
    }
    final cachedDates = prefs
        .getKeys()
        .where((key) => key.startsWith(prefix))
        .map((key) => key.substring(prefix.length));
    final dates = {...cachedDates, ..._confirmed.keys, ...fetched.keys};
    for (final date in dates) {
      _confirmed[date] = fetched[date] ?? {};
      await _cache(date);
    }
  }

  Future<void> _cache(String date) async {
    try {
      final completed = _confirmed[date]!;
      if (completed.isEmpty) {
        await prefs.remove('$prefix$date');
      } else {
        await prefs.setStringList('$prefix$date', completed.toList());
      }
    } catch (_) {
      // The database remains authoritative if a cache write fails.
    }
  }

  @override
  Future<bool> save(DateTime day, String activityId, bool completed) async {
    final date = _date(day);
    await client
        .from('activity_progress')
        .upsert({
          'user_id': userId,
          'activity_date': date,
          'activity_id': activityId,
          'completed': completed,
        })
        .timeout(const Duration(seconds: 8));
    final updated = completedOn(day);
    if (completed) {
      updated.add(activityId);
    } else {
      updated.remove(activityId);
    }
    _confirmed[date] = updated;
    await _cache(date);
    return true;
  }
}
