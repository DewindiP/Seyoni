import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/route.dart';
import '../config/url.dart';
import '../widgets/alertbox/alredy_exist.dart';

Future<Map<String, String>?> validateSeekerData(
  BuildContext context,
  TextEditingController firstNameController,
  TextEditingController lastNameController,
  TextEditingController emailController,
  TextEditingController phoneNumberController,
  TextEditingController passwordController,
) async {
  // Here you can add any additional validation logic if needed
  return {
    'firstName': firstNameController.text,
    'lastName': lastNameController.text,
    'email': emailController.text,
    'phone': phoneNumberController.text,
    'password': passwordController.text,
  };
}

Future<bool> checkSeekerExists(
    String email, String phone, BuildContext context) async {
  try {
    final response = await http.post(
      Uri.parse(checkSeekerExistsUrl), // Use the correct URL constant
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'email': email, 'phone': phone}),
    );

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse['exists'];
    } else {
      if (kDebugMode) {
        print('Failed to check seeker existence');
      }
      return false;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Failed to check seeker existence');
      print(e);
    }
    return false;
  }
}

Future<bool> registerSeekerToBackend(
    Map<String, String> userData, BuildContext context) async {
  try {
    final response = await http.post(
      Uri.parse(registerSeekersUrl), // Use the correct URL constant
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode == 201) {
      var jsonResponse = jsonDecode(response.body);
      // Check if the widget is still mounted before using the context
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', jsonResponse['token']);

      if (!context.mounted) return false;

      Navigator.pushNamed(
        context,
        AppRoutes.home,
        arguments: jsonResponse['token'],
      );
      return true;
    } else if (response.statusCode == 409) {
      if (!context.mounted) return false;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlredyExist(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.signIn);
            },
          );
        },
      );
      return false;
    } else {
      if (kDebugMode) {
        print('Failed');
      }
      return false;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Failed');
      print(e);
    }
    return false;
  }
}

Future<bool> verifyOtpAndRegisterSeeker(
    Map<String, String> userData, String otp, BuildContext context) async {
  try {
    String phone = userData['phone']!;

    if (kDebugMode) {
      print('Verifying OTP - Phone: $phone, OTP: $otp');
    }

    final response = await http.post(
      Uri.parse(verifyOtpUrl),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'phone': phone,
        'otp': otp,
      }),
    );

    if (kDebugMode) {
      print('Verification response: ${response.body}');
    }

    if (response.statusCode == 201) {
      final jsonResponse = jsonDecode(response.body);

      // Save user data to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', jsonResponse['token']);
      await prefs.setString('seekerId', jsonResponse['seeker']['_id']);
      await prefs.setString('firstName', jsonResponse['seeker']['firstName']);
      await prefs.setString('lastName', jsonResponse['seeker']['lastName']);
      await prefs.setString('email', jsonResponse['seeker']['email']);
      await prefs.setString('phone', jsonResponse['seeker']['phone']);

      return true;
    }
    return false;
  } catch (e) {
    if (kDebugMode) {
      print('Verification error: $e');
    }
    return false;
  }
}

Future<bool> resendOtp(String? phone, BuildContext context) async {
  try {
    final response = await http.post(
      Uri.parse(resendOtpUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      if (kDebugMode) {
        print('Failed to resend OTP');
      }
      return false;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Failed to resend OTP');
      print(e);
    }
    return false;
  }
}

Future<void> saveTempUser(String phone, Map<String, String> userData) async {
  try {
    final response = await http.post(
      Uri.parse(saveTempUserUrl),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'phone': phone,
        'userData': userData,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save temporary user data: ${response.body}');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Failed to save temporary user data: $e');
    }
    throw Exception('Failed to save temporary user data');
  }
}

Future<void> generateOtp(String phone) async {
  try {
    final response = await http.post(
      Uri.parse(generateOtpUrl),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'phone': phone}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to generate OTP: ${response.body}');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Failed to generate OTP: $e');
    }
    throw Exception('Failed to generate OTP');
  }
}
