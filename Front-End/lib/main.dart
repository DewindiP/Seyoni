import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/pages/auth/forgot-password/new_password.page.dart';
import 'src/pages/auth/forgot-password/verify_code_page.dart';
import 'src/pages/main/mainpage.dart';
import 'src/pages/sign-pages/signup_page.dart';
import 'src/pages/entry-pages/instruction_page.dart';
import './src/pages/entry-pages/launch_screen.dart';
import './src/pages/sign-pages/signin_page.dart';
import './src/config/route.dart';
import 'src/pages/auth/otp/otp_screen.dart';
import 'src/pages/auth/forgot-password/forgot_password_page.dart';
import 'src/pages/notifications/internal/notification_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('token');
  bool hasSeenLaunchScreen = prefs.getBool('hasSeenLaunchScreen') ?? false;
  runApp(MyApp(token: token, hasSeenLaunchScreen: hasSeenLaunchScreen));
}

class MyApp extends StatelessWidget {
  final String? token;
  final bool hasSeenLaunchScreen;

  const MyApp({super.key, this.token, required this.hasSeenLaunchScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: generateRoute,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => _getInitialPage(),
        AppRoutes.instruction: (context) => const InstructionPage(),
        AppRoutes.signIn: (context) => const SignInPage(),
        AppRoutes.signUp: (context) => SignUpPage(),
        AppRoutes.home: (context) => HomePage(token: token),
        AppRoutes.otppage: (context) => const OtpScreen(),
        AppRoutes.otppagefornewpassword: (context) =>
            const OtpScreenForNewPassword(),
        AppRoutes.forgotpassword: (context) => const ForgotPasswordPage(),
        AppRoutes.resetPassword: (context) => const ResetPasswordPage(),
        AppRoutes.notification: (context) => const NotificationPage(),
      },
    );
  }

  Widget _getInitialPage() {
    if (!hasSeenLaunchScreen) {
      return LaunchScreen(onLaunchScreenComplete: _onLaunchScreenComplete);
    } else if (token != null && !JwtDecoder.isExpired(token!)) {
      return HomePage(token: token);
    } else {
      return const SignInPage();
    }
  }

  void _onLaunchScreenComplete(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenLaunchScreen', true);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.signIn);
  }
}
