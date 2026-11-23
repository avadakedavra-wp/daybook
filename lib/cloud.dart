part of 'main.dart';

const _developmentCallback = 'com.daybook.minitodo://auth/callback';
final _callback = Uri.tryParse(
  const String.fromEnvironment(
    'DAYBOOK_AUTH_REDIRECT',
    defaultValue: _developmentCallback,
  ),
);
const _secureStorage = FlutterSecureStorage();

class _SecureSession extends LocalStorage {
  _SecureSession(String project) : key = 'daybook.session.$project';
  final String key;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() => _secureStorage.containsKey(key: key);

  @override
  Future<String?> accessToken() => _secureStorage.read(key: key);

  @override
  Future<void> removePersistedSession() => _secureStorage.delete(key: key);

  @override
  Future<void> persistSession(String session) =>
      _secureStorage.write(key: key, value: session);
}

class _SecurePkce extends GotrueAsyncStorage {
  _SecurePkce(this.project);
  final String project;

  String _key(String key) => 'daybook.pkce.$project.$key';

  @override
  Future<String?> getItem({required String key}) =>
      _secureStorage.read(key: _key(key));

  @override
  Future<void> setItem({required String key, required String value}) =>
      _secureStorage.write(key: _key(key), value: value);

  @override
  Future<void> removeItem({required String key}) =>
      _secureStorage.delete(key: _key(key));
}

class _CloudDaybook extends StatelessWidget {
  const _CloudDaybook({
    required this.prefs,
    required this.client,
    required this.project,
  });

  final SharedPreferences prefs;
  final SupabaseClient client;
  final String project;

  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: client.auth.onAuthStateChange,
    builder: (context, snapshot) {
      final user = client.auth.currentUser;
      return Daybook(
        key: ValueKey(user?.id),
        prefs: prefs,
        screen: user == null
            ? _SignIn(client: client, callbackFailed: snapshot.hasError)
            : _CloudHome(
                client: client,
                prefs: prefs,
                userId: user.id,
                project: project,
              ),
      );
    },
  );
}

class _SignIn extends StatefulWidget {
  const _SignIn({required this.client, required this.callbackFailed});

  final SupabaseClient client;
  final bool callbackFailed;

  @override
  State<_SignIn> createState() => _SignInState();
}

class _SignInState extends State<_SignIn> {
  bool opening = false;
  bool failed = false;

  Future<void> signIn() async {
    setState(() {
      opening = true;
      failed = false;
    });
    var launched = false;
    try {
      launched = await widget.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _callback!.toString(),
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // Show a generic error without including tokens or callback parameters.
    }
    if (!mounted) return;
    setState(() {
      opening = false;
      failed = !launched;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Daybook', style: heading(31)),
          FilledButton(
            onPressed: opening ? null : signIn,
            child: const Text('เข้าสู่ระบบด้วย Google'),
          ),
          if (failed || widget.callbackFailed)
            const Text('เข้าสู่ระบบไม่สำเร็จ กรุณาลองอีกครั้ง'),
        ],
      ),
    ),
  );
}

class _CloudHome extends StatefulWidget {
  const _CloudHome({
    required this.client,
    required this.prefs,
    required this.userId,
    required this.project,
  });

  final SupabaseClient client;
  final SharedPreferences prefs;
  final String userId;
  final String project;

  @override
  State<_CloudHome> createState() => _CloudHomeState();
}

class _CloudHomeState extends State<_CloudHome> {
  late final progress = SupabaseProgressStore(
    widget.client,
    widget.prefs,
    widget.userId,
    widget.project,
  );
  late final customActivities = CustomActivityStore.cloud(
    widget.prefs,
    widget.client,
    widget.project,
    widget.userId,
  );
  Future<void> refresh() async {
    await Future.wait([progress.refresh(), customActivities.refresh()]);
  }

  late Future<void> loading = refresh();
  bool signingOut = false;

  Future<void> signOut() async {
    setState(() => signingOut = true);
    try {
      await widget.client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      if (!mounted) return;
      setState(() => signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ออกจากระบบไม่สำเร็จ กรุณาลองอีกครั้ง')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return Home(
        progress: progress,
        customActivities: customActivities,
        accountActions: [
          if (snapshot.hasError) const Text('กำลังแสดงข้อมูลจากแคช'),
          TextButton(
            onPressed: () => setState(() => loading = refresh()),
            child: const Text('โหลดข้อมูลล่าสุด'),
          ),
          TextButton(
            onPressed: signingOut ? null : signOut,
            child: const Text('ออกจากระบบ'),
          ),
        ],
      );
    },
  );
}

class _CloudSetupError extends StatelessWidget {
  const _CloudSetupError();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Text(
        'เปิดการเชื่อมต่อไม่ได้ กรุณาตรวจการตั้งค่า Android และ Supabase',
      ),
    ),
  );
}
