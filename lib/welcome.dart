part of 'main.dart';

const _welcomeSeenKey = 'daybook.welcomeSeen';

class _Welcome extends StatefulWidget {
  const _Welcome({required this.prefs, required this.child});

  final SharedPreferences prefs;
  final Widget child;

  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome> {
  late bool started = widget.prefs.getBool(_welcomeSeenKey) ?? false;

  void start() {
    setState(() => started = true);
    unawaited(_rememberWelcome());
  }

  Future<void> _rememberWelcome() async {
    try {
      await widget.prefs.setBool(_welcomeSeenKey, true);
    } catch (_) {
      // The welcome page can be shown again if storage is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 240),
    child: started
        ? widget.child
        : Scaffold(
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: max(0, constraints.maxHeight - 56),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: AspectRatio(
                                aspectRatio: 180 / 130,
                                child: ColoredBox(
                                  color: butter,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      const ExcludeSemantics(
                                        child: CustomPaint(painter: Sunrise()),
                                      ),
                                      Positioned(
                                        left: 16,
                                        top: 16,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: ink,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.all(10),
                                            child: Icon(
                                              Icons.auto_stories_rounded,
                                              color: paper,
                                              size: 24,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text('Daybook', style: heading(46)),
                            Text('สมุดกิจกรรมประจำวัน', style: heading(23)),
                            const SizedBox(height: 10),
                            const Text(
                              'วางแผนสิ่งที่อยากทำ แล้วติดตามความคืบหน้าในปฏิทิน',
                              style: TextStyle(
                                color: muted,
                                fontSize: 16,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 27),
                            FilledButton.icon(
                              onPressed: start,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_forward_rounded),
                              label: const Text(
                                'เริ่มใช้งาน',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
  );
}
