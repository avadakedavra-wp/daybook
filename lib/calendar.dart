part of 'main.dart';

const _monthNames = [
  'มกราคม',
  'กุมภาพันธ์',
  'มีนาคม',
  'เมษายน',
  'พฤษภาคม',
  'มิถุนายน',
  'กรกฎาคม',
  'สิงหาคม',
  'กันยายน',
  'ตุลาคม',
  'พฤศจิกายน',
  'ธันวาคม',
];

class JournalCalendar extends StatefulWidget {
  const JournalCalendar({
    super.key,
    required this.initial,
    required this.completedOn,
  });
  final DateTime initial;
  final Set<String> Function(DateTime) completedOn;
  @override
  State<JournalCalendar> createState() => _JournalCalendarState();
}

class _JournalCalendarState extends State<JournalCalendar> {
  late DateTime day = widget.initial;
  late DateTime month = DateTime(day.year, day.month);

  void moveMonth(int delta) {
    final next = DateTime(month.year, month.month + delta);
    final last = DateUtils.getDaysInMonth(next.year, next.month);
    setState(() {
      month = next;
      day = DateTime(next.year, next.month, day.day.clamp(1, last));
    });
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final done = widget.completedOn(day);
    final offset = month.weekday - 1;
    final length = DateUtils.getDaysInMonth(month.year, month.month);
    final cells = ((offset + length + 6) ~/ 7) * 7;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 570),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'ย้อนกลับ',
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: Text('ปฏิทินกิจกรรม', style: heading(22))),
                    TextButton(
                      onPressed: () => setState(() {
                        day = today;
                        month = DateTime(today.year, today.month);
                      }),
                      child: const Text('วันนี้'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Material(
                  color: Colors.white,
                  shape: sheetShape,
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      Container(
                        color: ink,
                        padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (var i = 0; i < 8; i++)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: const BoxDecoration(
                                      color: paper,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'พ.ศ. ${month.year + 543}',
                              style: const TextStyle(
                                color: butter,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _monthNames[month.month - 1],
                                    style: heading(
                                      29,
                                    ).copyWith(color: Colors.white),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'เดือนก่อนหน้า',
                                  onPressed: () => moveMonth(-1),
                                  icon: const Icon(
                                    Icons.chevron_left_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'เดือนถัดไป',
                                  onPressed: () => moveMonth(1),
                                  icon: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(7, 15, 7, 12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                for (final name in [
                                  'จ',
                                  'อ',
                                  'พ',
                                  'พฤ',
                                  'ศ',
                                  'ส',
                                  'อา',
                                ])
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        name,
                                        style: small.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            for (var row = 0; row < cells; row += 7)
                              Row(
                                children: [
                                  for (var i = row; i < row + 7; i++)
                                    Expanded(
                                      child:
                                          (i < offset || i >= offset + length)
                                          ? const SizedBox(height: 48)
                                          : dayCell(
                                              DateTime(
                                                month.year,
                                                month.month,
                                                i - offset + 1,
                                              ),
                                              today,
                                            ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _CalendarLegend(
                      color: Color(0xffcf944a),
                      label: 'ทำบางส่วน',
                    ),
                    _CalendarLegend(
                      color: Color(0xff36835f),
                      label: 'ทำครบแล้ว',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xffeaf0df),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(todayLabel(day), style: heading(20)),
                      const SizedBox(height: 6),
                      Text(
                        'ทำแล้ว ${done.length} จาก ${activities.length} กิจกรรม',
                        style: const TextStyle(color: muted, fontSize: 15),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const ValueKey('confirm-date'),
                  onPressed: () => Navigator.pop(context, day),
                  style: FilledButton.styleFrom(
                    backgroundColor: ink,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.checklist_rounded),
                  label: const Text(
                    'เปิดกิจกรรมวันที่เลือก',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget dayCell(DateTime date, DateTime today) {
    final selected = DateUtils.isSameDay(date, day);
    final isToday = DateUtils.isSameDay(date, today);
    final count = widget.completedOn(date).length;
    final dot = count == activities.length
        ? const Color(0xff36835f)
        : const Color(0xffcf944a);
    return Semantics(
      button: true,
      selected: selected,
      label:
          '${todayLabel(date)} ทำแล้ว $count จาก ${activities.length} กิจกรรม',
      child: InkWell(
        key: ValueKey(progressKey(date)),
        borderRadius: BorderRadius.circular(13),
        onTap: () => setState(() => day = date),
        child: Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.all(2),
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: selected ? ink : null,
            border: isToday
                ? Border.all(color: selected ? ink : const Color(0xff7d947e))
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: TextStyle(
                  color: selected ? Colors.white : ink,
                  fontWeight: selected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: count == 0
                      ? Colors.transparent
                      : selected
                      ? (count == activities.length
                            ? const Color(0xffa7e3b5)
                            : butter)
                      : dot,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, size: 8, color: color),
      const SizedBox(width: 5),
      Text(label, style: small),
    ],
  );
}
