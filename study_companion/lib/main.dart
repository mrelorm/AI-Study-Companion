import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/splash/splash_screen.dart';
import 'shared/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Match the status bar to the gradient header
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const StudyCompanionApp());
}

class StudyCompanionApp extends StatelessWidget {
  const StudyCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(create: (_) => ApiClient()),
        ChangeNotifierProxyProvider<ApiClient, AuthProvider>(
          create: (ctx) => AuthProvider(ctx.read<ApiClient>()),
          update: (_, api, prev) => prev ?? AuthProvider(api),
        ),
      ],
      child: MaterialApp(
        title: 'AI Study Companion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const _AppGate(),
      ),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Check for rooted/jailbroken device before doing anything else.
    // On a compromised device, Keystore-backed tokens can be extracted by
    // privileged processes — warn the user so they can make an informed choice.
    await _checkDeviceIntegrity();

    // Run auth check and a minimum splash display time in parallel.
    // The splash stays visible for at least 2 seconds so the animation
    // completes before we transition — even on fast devices.
    await Future.wait([
      context.read<AuthProvider>().tryAutoLogin(),
      Future.delayed(const Duration(milliseconds: 2000)),
    ]);
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _checkDeviceIntegrity() async {
    try {
      final isJailbroken = await FlutterJailbreakDetection.jailbroken;
      if (isJailbroken && mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Security Warning'),
            content: const Text(
              'This device appears to be rooted or jailbroken.\n\n'
              'Your study data and login session may be accessible '
              'to other apps on this device. Proceed with caution.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('I Understand, Continue'),
              ),
            ],
          ),
        );
      }
    } catch (_) {
      // Detection failed — allow the app to continue normally.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const SplashScreen();

    final auth = context.watch<AuthProvider>();
    return auth.isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}
