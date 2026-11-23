part of 'main.dart';

class CustomActivityStore {
  CustomActivityStore(this.prefs)
    : cacheKey = 'daybook.customActivities',
      client = null,
      userId = null;

  CustomActivityStore.cloud(
    this.prefs,
    this.client,
    String project,
    String user,
  ) : cacheKey = 'daybook.customActivities.$project.$user',
      userId = user;

  final SharedPreferences prefs;
  final String cacheKey;
  final SupabaseClient? client;
  final String? userId;
  late List<Activity> _items = [
    for (final item in prefs.getStringList(cacheKey) ?? const <String>[])
      _decodeActivity(jsonDecode(item) as Map<String, dynamic>),
  ];

  List<Activity> get items => List.unmodifiable(_items);

  Future<void> refresh() async {
    final backend = client;
    if (backend == null) return;
    final fetched = <Activity>[];
    const pageSize = 200;
    while (true) {
      final rows = await backend
          .from('custom_activities')
          .select('id,title,category,minutes,description')
          .eq('user_id', userId!)
          .order('id')
          .range(fetched.length, fetched.length + pageSize - 1)
          .timeout(const Duration(seconds: 8));
      fetched.addAll(rows.map(_decodeActivity));
      if (rows.length < pageSize) break;
    }
    await _store(fetched);
  }

  Future<void> save(Activity item, {required bool creating}) async {
    final backend = client;
    if (backend != null) {
      if (creating) {
        await backend
            .from('custom_activities')
            .insert({..._encodeActivity(item), 'user_id': userId})
            .timeout(const Duration(seconds: 8));
      } else {
        final fields = _encodeActivity(item)..remove('id');
        await backend
            .from('custom_activities')
            .update(fields)
            .eq('user_id', userId!)
            .eq('id', item.id)
            .select('id')
            .single()
            .timeout(const Duration(seconds: 8));
      }
    }
    await _store([
      for (final current in _items)
        if (current.id == item.id) item else current,
      if (creating) item,
    ]);
  }

  Future<void> remove(String id) async {
    final backend = client;
    if (backend != null) {
      await backend
          .from('custom_activities')
          .delete()
          .eq('user_id', userId!)
          .eq('id', id)
          .timeout(const Duration(seconds: 8));
    }
    await _store([
      for (final item in _items)
        if (item.id != id) item,
    ]);
  }

  Future<void> _store(List<Activity> next) async {
    next.sort((a, b) => a.title.compareTo(b.title));
    if (client != null) _items = next;
    try {
      final saved = await prefs.setStringList(
        cacheKey,
        next.map((item) => jsonEncode(_encodeActivity(item))).toList(),
      );
      if (!saved && client == null) {
        throw StateError('Activity storage write failed');
      }
    } catch (_) {
      if (client == null) rethrow;
    }
    _items = next;
  }
}

Activity _customActivity(
  String id,
  String title,
  String category,
  int minutes,
  String description,
) => Activity(
  id,
  title,
  category,
  minutes,
  Icons.event_note_outlined,
  const Color(0xffe1ede7),
  description,
  const [],
);

Activity _decodeActivity(Map<String, dynamic> row) => _customActivity(
  row['id'] as String,
  row['title'] as String,
  row['category'] as String,
  row['minutes'] as int,
  row['description'] as String,
);

Map<String, dynamic> _encodeActivity(Activity activity) => {
  'id': activity.id,
  'title': activity.title,
  'category': activity.category,
  'minutes': activity.minutes,
  'description': activity.description,
};

class _ActivityEditor extends StatefulWidget {
  const _ActivityEditor(this.activity);
  final Activity? activity;

  @override
  State<_ActivityEditor> createState() => _ActivityEditorState();
}

class _ActivityEditorState extends State<_ActivityEditor> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(text: widget.activity?.title);
  late final category = TextEditingController(text: widget.activity?.category);
  late final description = TextEditingController(
    text: widget.activity?.description,
  );
  late final minutes = TextEditingController(
    text: widget.activity?.minutes.toString() ?? '15',
  );

  @override
  void dispose() {
    title.dispose();
    category.dispose();
    description.dispose();
    minutes.dispose();
    super.dispose();
  }

  void submit() {
    if (!form.currentState!.validate()) return;
    final random = Random.secure();
    final id =
        widget.activity?.id ??
        'custom-${List.generate(16, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
    Navigator.pop(
      context,
      _customActivity(
        id,
        title.text.trim(),
        category.text.trim(),
        int.parse(minutes.text.trim()),
        description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.activity == null ? 'เพิ่มกิจกรรม' : 'แก้ไขกิจกรรม'),
    scrollable: true,
    content: Form(
      key: form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: title,
            decoration: const InputDecoration(labelText: 'ชื่อกิจกรรม'),
            maxLength: 80,
            validator: (value) =>
                value!.trim().isEmpty ? 'กรอกชื่อกิจกรรม' : null,
          ),
          TextFormField(
            controller: category,
            decoration: const InputDecoration(labelText: 'หมวดหมู่'),
            maxLength: 40,
          ),
          TextFormField(
            controller: minutes,
            decoration: const InputDecoration(labelText: 'ระยะเวลา (นาที)'),
            keyboardType: TextInputType.number,
            validator: (value) {
              final amount = int.tryParse(value!.trim());
              return amount == null || amount < 1 || amount > 1440
                  ? 'กรอกจำนวนระหว่าง 1–1440 นาที'
                  : null;
            },
          ),
          TextFormField(
            controller: description,
            decoration: const InputDecoration(labelText: 'รายละเอียด'),
            maxLength: 500,
            maxLines: 3,
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ยกเลิก'),
      ),
      FilledButton(onPressed: submit, child: const Text('บันทึก')),
    ],
  );
}
