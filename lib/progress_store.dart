import 'package:shared_preferences/shared_preferences.dart';

String progressKey(DateTime date) =>
    'daybook.done.${date.year}.${date.month}.${date.day}';

abstract interface class ProgressStore {
  Set<String> completedOn(DateTime day);
  Future<bool> save(DateTime day, String activityId, bool completed);
}

class LocalProgressStore implements ProgressStore {
  const LocalProgressStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  Set<String> completedOn(DateTime day) => {
    ...?_preferences.getStringList(progressKey(day)),
  };

  @override
  Future<bool> save(DateTime day, String activityId, bool completed) {
    final activities = completedOn(day);
    if (completed) {
      activities.add(activityId);
    } else {
      activities.remove(activityId);
    }
    return _preferences.setStringList(progressKey(day), activities.toList());
  }
}
