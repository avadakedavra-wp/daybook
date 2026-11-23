import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'journal_art.dart';
import 'progress_store.dart';
import 'supabase_progress_store.dart';

export 'progress_store.dart' show progressKey;

part 'calendar.dart';
part 'cloud.dart';
part 'custom_activities.dart';
part 'welcome.dart';

const paper = Color(0xfffaf9f3);
const ink = Color(0xff203c33);
const muted = Color(0xff53685d);
const rule = Color(0xffd6dcd0);
const butter = Color(0xfff8e7a4);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  const url = String.fromEnvironment('SUPABASE_URL');
  const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (url.isNotEmpty || publishableKey.isNotEmpty) {
    final endpoint = Uri.tryParse(url);
    final callback = _callback;
    final validCallback =
        callback != null &&
        ((!kReleaseMode && callback.toString() == _developmentCallback) ||
            (callback.scheme == 'https' &&
                callback.host.isNotEmpty &&
                callback.path == '/callback' &&
                !callback.hasQuery &&
                !callback.hasFragment &&
                callback.userInfo.isEmpty));
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        endpoint != null &&
        endpoint.scheme == 'https' &&
        endpoint.host.isNotEmpty &&
        endpoint.userInfo.isEmpty &&
        !endpoint.hasQuery &&
        !endpoint.hasFragment &&
        validCallback &&
        publishableKey.startsWith('sb_publishable_')) {
      try {
        final project = endpoint.host;
        final supabase = await Supabase.initialize(
          url: url,
          publishableKey: publishableKey,
          authOptions: FlutterAuthClientOptions(
            authFlowType: AuthFlowType.pkce,
            localStorage: _SecureSession(project),
            pkceAsyncStorage: _SecurePkce(project),
            detectSessionInUriPredicate: (uri) =>
                uri.scheme == callback.scheme &&
                uri.host == callback.host &&
                uri.path == callback.path,
          ),
        );
        runApp(
          _CloudDaybook(
            prefs: prefs,
            client: supabase.client,
            project: project,
          ),
        );
        return;
      } catch (_) {
        runApp(Daybook(prefs: prefs, screen: const _CloudSetupError()));
        return;
      }
    }
    runApp(Daybook(prefs: prefs, screen: const _CloudSetupError()));
    return;
  }
  runApp(Daybook(prefs: prefs, showWelcome: true));
}

class Activity {
  const Activity(
    this.id,
    this.title,
    this.category,
    this.minutes,
    this.icon,
    this.tint,
    this.description,
    this.steps,
  );
  final String id, title, category, description;
  final int minutes;
  final IconData icon;
  final Color tint;
  final List<String> steps;
}

const activities = [
  Activity(
    'read',
    'อ่านหนังสือ 10 หน้า',
    'การเรียนรู้',
    15,
    Icons.menu_book_rounded,
    Color(0xffdce8f6),
    'เลือกหนังสือที่กำลังอ่าน แล้วให้เวลากับตัวเองสักสิบหน้า',
    [
      'หามุมเงียบ ๆ แล้วเปิดหน้าที่คั่นไว้',
      'อ่านให้ครบ 10 หน้า',
      'จดประโยคที่ชอบไว้สักหนึ่งประโยค',
    ],
  ),
  Activity(
    'walk',
    'ออกไปเดินเล่น',
    'สุขภาพ',
    20,
    Icons.directions_walk_rounded,
    Color(0xfff6ddcb),
    'พักสายตาจากหน้าจอ แล้วออกไปเดินรับลมในจังหวะที่สบาย',
    [
      'เตรียมน้ำดื่มและรองเท้าที่ใส่สบาย',
      'เลือกเส้นทางใกล้บ้านที่ชอบ',
      'เดินเล่นแล้วค่อย ๆ ผ่อนจังหวะก่อนกลับ',
    ],
  ),
  Activity(
    'plants',
    'รดน้ำต้นไม้',
    'บ้านและสวน',
    5,
    Icons.yard_outlined,
    Color(0xffdeead7),
    'แวะดูเพื่อนสีเขียวที่บ้าน และเติมน้ำให้กระถางที่ดินเริ่มแห้ง',
    [
      'แตะหน้าดินเพื่อเช็กความชื้น',
      'รดน้ำเฉพาะกระถางที่ต้องการน้ำ',
      'เทน้ำที่ค้างอยู่ในจานรองออก',
    ],
  ),
];

class Daybook extends StatelessWidget {
  const Daybook({
    super.key,
    required this.prefs,
    this.screen,
    this.showWelcome = false,
  });
  final bool showWelcome;
  final SharedPreferences prefs;
  final Widget? screen;
  @override
  Widget build(BuildContext context) {
    final landing =
        screen ??
        Home(
          progress: LocalProgressStore(prefs),
          customActivities: CustomActivityStore(prefs),
        );
    return MaterialApp(
      title: 'My Mini To-Do',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: ink,
          primary: ink,
          surface: paper,
        ),
        scaffoldBackgroundColor: paper,
        fontFamily: 'JournalThai',
        fontFamilyFallback: const ['JournalLatin'],
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: ink,
          displayColor: ink,
          fontFamily: 'JournalThai',
          fontFamilyFallback: const ['JournalLatin'],
        ),
      ),
      home: showWelcome ? _Welcome(prefs: prefs, child: landing) : landing,
    );
  }
}

TextStyle heading(double size) => TextStyle(
  fontSize: size,
  height: 1.32,
  fontWeight: FontWeight.w700,
  color: ink,
);
const small = TextStyle(fontSize: 14, color: muted);
const sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.all(Radius.circular(18)),
  side: BorderSide(color: rule),
);

String todayLabel(DateTime date) {
  const weekdays = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];
  const months = [
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];
  return 'วัน${weekdays[date.weekday - 1]}ที่ ${date.day} ${months[date.month - 1]}';
}

class Home extends StatefulWidget {
  const Home({
    super.key,
    required this.progress,
    required this.customActivities,
    this.accountActions = const [],
  });
  final ProgressStore progress;
  final CustomActivityStore customActivities;
  final List<Widget> accountActions;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Activity> get allActivities => [
    ...activities,
    ...widget.customActivities.items,
  ];
  DateTime selected = DateUtils.dateOnly(DateTime.now());
  Set<String> completedOn(DateTime day) =>
      widget.progress.completedOn(day)
        ..retainAll(allActivities.map((a) => a.id));
  late Set<String> done = completedOn(selected);
  bool saving = false;

  Future<void> openCalendar() async {
    final day = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(
        builder: (_) => JournalCalendar(
          initial: selected,
          completedOn: completedOn,
          activityCount: allActivities.length,
        ),
      ),
    );
    if (day != null && mounted) {
      setState(() {
        selected = day;
        done = completedOn(day);
      });
    }
  }

  Future<void> change(String id, bool checked) async {
    if (saving) return;
    final day = selected;
    setState(() => saving = true);
    var saved = false;
    try {
      saved = await widget.progress.save(day, id, checked);
    } catch (_) {
      // Keep the last confirmed state when persistence fails.
    }
    if (!mounted) return;
    setState(() {
      saving = false;
      done = completedOn(selected);
    });
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกไม่ได้ กรุณาลองอีกครั้ง')),
      );
    }
  }

  Future<bool> editActivity([Activity? original]) async {
    if (saving) return false;
    final item = await showDialog<Activity>(
      context: context,
      builder: (_) => _ActivityEditor(original),
    );
    if (item == null || !mounted) return false;
    return updateActivities(
      () => widget.customActivities.save(item, creating: original == null),
    );
  }

  Future<bool> deleteActivity(Activity item) async {
    if (saving) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบกิจกรรม'),
        content: Text('ลบ “${item.title}” ออกจากรายการของทุกวันหรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบกิจกรรม'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;
    return updateActivities(() => widget.customActivities.remove(item.id));
  }

  Future<bool> updateActivities(Future<void> Function() update) async {
    setState(() => saving = true);
    try {
      await update();
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกการเปลี่ยนแปลงไม่ได้ กรุณาลองอีกครั้ง'),
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
          done = completedOn(selected);
        });
      }
    }
  }

  Future<void> open(Activity a) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (routeContext) => Details(
          activity: a,
          complete: done.contains(a.id),
          onEdit: a.id.startsWith('custom-')
              ? () async {
                  if (await editActivity(a) &&
                      routeContext.mounted &&
                      ModalRoute.of(routeContext)?.isCurrent == true) {
                    Navigator.pop(routeContext);
                  }
                }
              : null,
          onDelete: a.id.startsWith('custom-')
              ? () async {
                  if (await deleteActivity(a) &&
                      routeContext.mounted &&
                      ModalRoute.of(routeContext)?.isCurrent == true) {
                    Navigator.pop(routeContext);
                  }
                }
              : null,
        ),
      ),
    );
    if (result != null && mounted) await change(a.id, result);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 570),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
            itemCount: allActivities.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_stories_rounded,
                          color: ink,
                          size: 24,
                        ),
                        const SizedBox(width: 9),
                        Text('Daybook', style: heading(22)),
                        const Spacer(),
                        OutlinedButton.icon(
                          key: const ValueKey('open-calendar'),
                          onPressed: openCalendar,
                          icon: const Icon(
                            Icons.calendar_month_outlined,
                            size: 18,
                          ),
                          label: const Text('ปฏิทิน'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ink,
                            side: const BorderSide(color: rule),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: rule),
                    const SizedBox(height: 26),
                    if (widget.accountActions.isNotEmpty)
                      Wrap(spacing: 8, children: widget.accountActions),
                    Text('สมุดกิจกรรมของฉัน', style: heading(31)),
                    const SizedBox(height: 3),
                    Text(todayLabel(selected), style: small),
                    const SizedBox(height: 15),
                    Cover(count: done.length, total: allActivities.length),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text('กิจกรรมของฉัน', style: heading(21)),
                        ),
                        const SizedBox(width: 8),
                        Text('${allActivities.length} รายการ', style: small),
                        IconButton(
                          tooltip: 'เพิ่มกิจกรรม',
                          onPressed: saving ? null : () => editActivity(),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }
              final a = allActivities[index - 1];
              final checked = done.contains(a.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: checked ? const Color(0xfff0f4eb) : Colors.white,
                  shape: sheetShape,
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 9,
                    ),
                    leading: Checkbox(
                      value: checked,
                      semanticLabel: 'ทำเสร็จแล้ว ${a.title}',
                      activeColor: ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      onChanged: saving ? null : (v) => change(a.id, v!),
                    ),
                    horizontalTitleGap: 3,
                    minLeadingWidth: 40,
                    title: Text(
                      a.title,
                      style: heading(18).copyWith(
                        decoration: checked ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Wrap(
                        spacing: 7,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Tag(a),
                          Text('${a.minutes} นาที', style: small),
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'ดูรายละเอียด ${a.title}',
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: () => open(a),
                    ),
                    onTap: () => open(a),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class Tag extends StatelessWidget {
  const Tag(this.a, {super.key});
  final Activity a;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: a.tint,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(a.icon, size: 15, color: ink),
          const SizedBox(width: 4),
          Text(a.category, style: const TextStyle(fontSize: 13, color: ink)),
        ],
      ),
    ),
  );
}

class Cover extends StatelessWidget {
  const Cover({super.key, required this.count, required this.total});
  final int total;
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: butter,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xffdfd19f)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          fit: StackFit.passthrough,
          children: [
            const Positioned(
              right: -2,
              top: 0,
              bottom: 0,
              width: 135,
              child: ExcludeSemantics(child: CustomPaint(painter: Sunrise())),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 122, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ความคืบหน้า', style: heading(16)),
                  const SizedBox(height: 5),
                  Text('$count / $total', style: heading(39)),
                ],
              ),
            ),
          ],
        ),
        Container(
          color: ink,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  count == total
                      ? 'ทำครบทุกกิจกรรมแล้ว'
                      : 'เหลืออีก ${total - count} กิจกรรม',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Row(
                children: List.generate(
                  total.clamp(0, 6),
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 230),
                    width: 20,
                    height: 6,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      color: i < (count * total.clamp(0, 6) / total).round()
                          ? butter
                          : const Color(0xff61786c),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class Details extends StatelessWidget {
  const Details({
    super.key,
    required this.activity,
    required this.complete,
    this.onEdit,
    this.onDelete,
  });
  final VoidCallback? onEdit, onDelete;
  final Activity activity;
  final bool complete;
  @override
  Widget build(BuildContext context) {
    final a = activity;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 570),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'ย้อนกลับ',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text('รายละเอียดกิจกรรม', style: heading(18)),
                    ),
                  ],
                ),
                if (onEdit != null || onDelete != null)
                  Wrap(
                    spacing: 8,
                    children: [
                      if (onEdit != null)
                        TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('แก้ไขกิจกรรม'),
                        ),
                      if (onDelete != null)
                        TextButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('ลบกิจกรรม'),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: a.tint,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(a.icon, size: 40, color: ink),
                          const Spacer(),
                          Icon(
                            complete
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 17,
                            color: ink,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            complete ? 'เสร็จแล้ว' : 'ยังไม่เสร็จ',
                            style: const TextStyle(color: ink),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(a.title, style: heading(29)),
                      const SizedBox(height: 8),
                      Text(
                        '${a.category}   ·   ${a.minutes} นาที',
                        style: const TextStyle(color: ink, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  a.description,
                  style: const TextStyle(fontSize: 17, height: 1.6),
                ),
                const SizedBox(height: 24),
                Text('ขั้นตอนกิจกรรม', style: heading(21)),
                const SizedBox(height: 10),
                for (var i = 0; i < a.steps.length; i++)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: rule)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: a.tint,
                          radius: 14,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Text(
                            a.steps[i],
                            style: const TextStyle(fontSize: 16, height: 1.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ink,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  onPressed: () => Navigator.pop(context, !complete),
                  icon: Icon(
                    complete ? Icons.undo_rounded : Icons.check_rounded,
                  ),
                  label: Text(
                    complete
                        ? 'เปลี่ยนเป็นยังไม่เสร็จ'
                        : 'ทำกิจกรรมนี้เสร็จแล้ว',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
