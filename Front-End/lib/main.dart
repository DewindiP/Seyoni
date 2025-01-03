// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seyoni/src/services/websocket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'src/pages/admin/admin_home_page.dart';
import 'src/pages/admin/list_of_providers.dart';
import 'src/pages/admin/list_of_reg_requests.dart';
import 'src/pages/admin/list_of_seekers.dart';
import 'src/pages/provider/notification/notification_provider.dart';
import 'src/pages/provider/provider_entry_page.dart';
import 'src/pages/seeker/forgot-password/new_password.page.dart';
import 'src/pages/seeker/forgot-password/verify_code_page.dart';
import 'src/pages/seeker/main/mainpage.dart';
import 'src/pages/provider/home/provider_home_page.dart';
import 'src/pages/provider/login/provider_signin_page.dart';
import 'src/pages/provider/registration/provider_registration_page.dart';
import 'src/pages/seeker/order-history/order_history_page.dart';
import 'src/pages/seeker/sign-pages/signup_page.dart';
import 'src/pages/entry-pages/instruction_page.dart';
import './src/pages/entry-pages/launch_screen.dart';
import 'src/pages/seeker/sign-pages/signin_page.dart';
import './src/config/route.dart';
import 'src/pages/seeker/sign-pages/otp/otp_screen.dart';
import 'src/pages/seeker/forgot-password/forgot_password_page.dart';
import 'src/pages/seeker/notifications/internal/notification_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await _requestPermissions();

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
  String? token = prefs.getString('token');
  String? providerId = prefs.getString('providerId');
  String? seekerId = prefs.getString('seekerId');

  // Initialize WebSocket
  final webSocketService = WebSocketService();
  await webSocketService.connect();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: MyApp(
        isFirstLaunch: isFirstLaunch,
        token: token,
        providerId: providerId,
        seekerId: seekerId,
      ),
    ),
  );
}

Future<void> _requestPermissions() async {
  final permissions = [
    Permission.camera,
    Permission.location,
  ];

  if (!kIsWeb) {
    permissions.add(Permission.photos);
    permissions.add(Permission.storage);
  }

  await permissions.request();
}

class MyApp extends StatelessWidget {
  final bool isFirstLaunch;
  final String? token;
  final String? providerId;
  final String? seekerId;

  const MyApp({
    super.key,
    required this.isFirstLaunch,
    this.token,
    this.providerId,
    this.seekerId,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _getInitialPage(),
      routes: {
        AppRoutes.instruction: (context) => const InstructionPage(),
        AppRoutes.signIn: (context) => const SignInPage(),
        AppRoutes.signUp: (context) => SignUpPage(),
        AppRoutes.home: (context) => const HomePage(),
        AppRoutes.otppage: (context) => const OtpScreen(),
        AppRoutes.otppagefornewpassword: (context) =>
            const OtpScreenForNewPassword(),
        AppRoutes.forgotpassword: (context) => const ForgotPasswordPage(),
        AppRoutes.resetPassword: (context) => const ResetPasswordPage(),
        AppRoutes.notification: (context) => const NotificationPage(),
        AppRoutes.providerSignIn: (context) => const ProviderSignInPage(),
        AppRoutes.providerSignUp: (context) => const ProviderRegistrationPage(),
        AppRoutes.providerHomePage: (context) => const ProviderHomePage(),
        AppRoutes.orderHistoryPage: (context) => const OrderHistoryPage(),
        AppRoutes.providerEntryPage: (context) => const ProviderEntryPage(),
        AppRoutes.adminHomePage: (context) => const AdminHomePage(),
        AppRoutes.listOfRegistrationRequests: (context) =>
            const ListOfRegistrationRequests(),
        AppRoutes.listOfSeekers: (context) => const ListOfSeekers(),
        AppRoutes.listOfProviders: (context) => const ListOfProviders(),
      },
    );
  }

  Widget _getInitialPage() {
    if (isFirstLaunch) {
      return LaunchScreen(onLaunchScreenComplete: _onLaunchScreenComplete);
    }

    // Check if token exists and is valid
    if (token != null && !JwtDecoder.isExpired(token!)) {
      // Check user type and return appropriate home page
      if (providerId != null) {
        return const ProviderHomePage();
      } else if (seekerId != null) {
        return const HomePage();
      }
    }

    // Default to sign in page if no valid credentials
    return const SignInPage();
  }

  Future<void> _onLaunchScreenComplete(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstLaunch', false);
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.signIn);
  }
}
