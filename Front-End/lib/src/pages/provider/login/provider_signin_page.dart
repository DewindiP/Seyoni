import 'package:flutter/material.dart';
import 'package:seyoni/src/constants/constants_color.dart';
import 'package:seyoni/src/utils/validators.dart';
import 'package:seyoni/src/widgets/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/url.dart';
import '../components/custom_text_field.dart';
import 'package:seyoni/src/widgets/background_widget.dart';
import 'package:seyoni/src/config/route.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProviderSignInPage extends StatefulWidget {
  const ProviderSignInPage({super.key});

  @override
  ProviderSignInPageState createState() => ProviderSignInPageState();
}

class ProviderSignInPageState extends State<ProviderSignInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!mounted) return;

    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    if (email == 'seyoni@admin.com' && password == 'Seyoni@1234') {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.adminHomePage);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(loginProvidersUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Debug log
      // print('Response status: ${response.statusCode}');
      // print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          final token = responseData['token'];
          final providerId = responseData['providerId'];

          if (token != null && providerId != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', token);
            await prefs.setString('providerId', providerId);

            if (!mounted) return;
            await Navigator.pushReplacementNamed(
                context, AppRoutes.providerHomePage);
          } else {
            _showErrorDialog('Invalid credentials or server response');
          }
        } catch (e) {
          _showErrorDialog(
              'Server response format error: ${response.body.substring(0, 100)}');
        }
      } else if (response.statusCode == 520) {
        _showErrorDialog(
            'Server is currently unavailable. Please try again later.');
      } else {
        try {
          final error = jsonDecode(response.body)['error'];
          _showErrorDialog('Error: $error');
        } catch (e) {
          _showErrorDialog(
              'Server error (${response.statusCode}): Please try again later');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(
          'Connection error: Please check your internet connection');
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    return Stack(
      children: [
        Scaffold(
          backgroundColor: kTransparentColor,
          body: BackgroundWidget(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/images/logo-icon.png',
                    height: height * 0.15,
                    fit: BoxFit.contain,
                  ),
                  Image.asset(
                    'assets/images/logo-name.png',
                    height: height * 0.12,
                    fit: BoxFit.contain,
                  ),
                  Container(
                    margin: const EdgeInsets.all(30),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          CustomTextField(
                            controller: _emailController,
                            labelText: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.validateEmail,
                          ),
                          const SizedBox(height: 10),
                          CustomTextField(
                            controller: _passwordController,
                            labelText: 'Password',
                            obscureText: true,
                            validator: Validators.validatePassword,
                          ),
                          const SizedBox(height: 20),
                          PrimaryFilledButton(
                            text: 'Sign In',
                            onPressed: _signIn,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Don\'t have an account?',
                                style: TextStyle(
                                  color: kParagraphTextColor,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, AppRoutes.providerSignUp);
                                },
                                child: const Text('Sign Up',
                                    style: TextStyle(color: kPrimaryColor)),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Register as a service seeker',
                                style: TextStyle(
                                  color: kParagraphTextColor,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, AppRoutes.signUp);
                                },
                                child: const Text('Register Now',
                                    style: TextStyle(color: kPrimaryColor)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
              ),
            ),
          ),
      ],
    );
  }
}
