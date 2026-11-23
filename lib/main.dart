import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'journal_art.dart';

part 'calendar.dart';

const paper = Color(0xfffaf9f3);
const ink = Color(0xff203c33);
const muted = Color(0xff53685d);
const rule = Color(0xffd6dcd0);
const butter = Color(0xfff8e7a4);
String progressKey(DateTime date) =>
    'daybook.done.${date.year}.${date.month}.${date.day}';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(Daybook(prefs: prefs));
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
  const Daybook({super.key, required this.prefs});
  final SharedPreferences prefs;
  @override
  Widget build(BuildContext context) => MaterialApp(
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
    home: Home(prefs: prefs),
  );
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
  const Home({super.key, required this.prefs});
  final SharedPreferences prefs;
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  DateTime selected = DateUtils.dateOnly(DateTime.now());
  Set<String> completedOn(DateTime day) =>
      {...?widget.prefs.getStringList(progressKey(day))}
        ..retainAll(activities.map((a) => a.id));
  late Set<String> done = completedOn(selected);

  Future<void> openCalendar() async {
    final day = await Navigator.push<DateTime>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            JournalCalendar(initial: selected, completedOn: completedOn),
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
    setState(() {
      if (checked) {
        done.add(id);
      } else {
        done.remove(id);
      }
    });
    if (!await widget.prefs.setStringList(
          progressKey(selected),
          done.toList(),
        ) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกในเครื่องไม่ได้ กรุณาลองอีกครั้ง')),
      );
    }
  }

  Future<void> open(Activity a) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => Details(activity: a, complete: done.contains(a.id)),
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
            itemCount: activities.length + 1,
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
                    Text('สมุดกิจกรรมของฉัน', style: heading(31)),
                    const SizedBox(height: 3),
                    Text(todayLabel(selected), style: small),
                    const SizedBox(height: 15),
                    Cover(count: done.length),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text('กิจกรรมของฉัน', style: heading(21)),
                        const Spacer(),
                        Text('${activities.length} รายการ', style: small),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }
              final a = activities[index - 1];
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
                      onChanged: (v) => change(a.id, v!),
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
  const Cover({super.key, required this.count});
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
                  Text('$count / ${activities.length}', style: heading(39)),
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
                  count == activities.length
                      ? 'ทำครบทุกกิจกรรมแล้ว'
                      : 'เหลืออีก ${activities.length - count} กิจกรรม',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Row(
                children: List.generate(
                  activities.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 230),
                    width: 20,
                    height: 6,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      color: i < count ? butter : const Color(0xff61786c),
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
  const Details({super.key, required this.activity, required this.complete});
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
                    Text('รายละเอียดกิจกรรม', style: heading(18)),
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
