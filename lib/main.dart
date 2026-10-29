import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/theme.dart';
import 'core/api.dart';
import 'core/session.dart';
import 'screens/login_screen.dart';
import 'screens/role_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Màn hình chấm công (camera, khuôn mặt) được tính toán cho chiều dọc.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Session.load();

  // Token hết hạn (12 giờ) → về màn đăng nhập.
  onSessionExpired = () {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen(notice: 'Phiên đăng nhập đã hết hạn, hãy đăng nhập lại.')),
      (_) => false,
    );
  };

  runApp(const HhcApp());
}

class HhcApp extends StatelessWidget {
  const HhcApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SmartCheck HHC',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: buildTheme(),
        home: Session.isLoggedIn ? RoleRouter.pageFor(Session.role) : const LoginScreen(),
      );
}
