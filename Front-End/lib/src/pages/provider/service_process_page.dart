import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:seyoni/src/config/url.dart';
import 'package:http/http.dart' as http;
import 'package:seyoni/src/constants/constants_color.dart';
import 'package:seyoni/src/constants/constants_font.dart';
import 'package:seyoni/src/pages/provider/home/provider_home_page.dart';
import 'package:seyoni/src/pages/seeker/sign-pages/otp/components/input_field.dart';
import 'package:seyoni/src/pages/seeker/sign-pages/otp/components/verify_button.dart';
import 'package:seyoni/src/widgets/background_widget.dart';
import 'package:seyoni/src/pages/provider/notification/notification_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServiceProcessPage extends StatefulWidget {
  final String seekerName;
  final String otp;
  final String reservationId;

  const ServiceProcessPage({
    required this.seekerName,
    required this.otp,
    required this.reservationId,
    super.key,
  });

  @override
  ServiceProcessPageState createState() => ServiceProcessPageState();
}

class ServiceProcessPageState extends State<ServiceProcessPage> {
  final TextEditingController _otpController1 = TextEditingController();
  final TextEditingController _otpController2 = TextEditingController();
  final TextEditingController _otpController3 = TextEditingController();
  final TextEditingController _otpController4 = TextEditingController();
  final TextEditingController _otpController5 = TextEditingController();
  final TextEditingController _otpController6 = TextEditingController();
  final TextEditingController _paymentController = TextEditingController();

  final FocusNode _focusNode1 = FocusNode();
  final FocusNode _focusNode2 = FocusNode();
  final FocusNode _focusNode3 = FocusNode();
  final FocusNode _focusNode4 = FocusNode();
  final FocusNode _focusNode5 = FocusNode();
  final FocusNode _focusNode6 = FocusNode();

  Timer? _timer;
  int _currentSection = 0;
  int _remainingTime = 0;
  int _elapsedTime = 0;
  bool _isVerifyButtonActive = false;
  bool _isErrorVisible = false;
  String _errorMessage = '';
  bool _disposed = false;
  late final NotificationProvider _notificationProvider;

  @override
  void initState() {
    super.initState();
    _otpController1.addListener(_checkInputFields);
    _otpController2.addListener(_checkInputFields);
    _otpController3.addListener(_checkInputFields);
    _otpController4.addListener(_checkInputFields);
    _otpController5.addListener(_checkInputFields);
    _otpController6.addListener(_checkInputFields);

    // Refresh the page every 10 seconds
    Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _otpController1.dispose();
    _otpController2.dispose();
    _otpController3.dispose();
    _otpController4.dispose();
    _otpController5.dispose();
    _otpController6.dispose();
    _paymentController.dispose();
    _focusNode1.dispose();
    _focusNode2.dispose();
    _focusNode3.dispose();
    _focusNode4.dispose();
    _focusNode5.dispose();
    _focusNode6.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!_disposed && mounted) {
      setState(fn);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _safeSetState(() {
        _remainingTime++;
      });
      // Update provider with new timer value
      if (!_disposed) {
        Provider.of<NotificationProvider>(context, listen: false)
          ..updateTimer(_remainingTime)
          ..setSection(1); // Ensure section is updated
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    if (!_disposed) {
      _safeSetState(() {
        _elapsedTime = _remainingTime;
        _currentSection = 2;
      });
      _notificationProvider.setSection(2);
    }
  }

  void _checkInputFields() {
    _safeSetState(() {
      _isVerifyButtonActive = _otpController1.text.isNotEmpty &&
          _otpController2.text.isNotEmpty &&
          _otpController3.text.isNotEmpty &&
          _otpController4.text.isNotEmpty &&
          _otpController5.text.isNotEmpty &&
          _otpController6.text.isNotEmpty;
    });
  }

  void _nextField(String value, FocusNode currentFocus, FocusNode nextFocus) {
    if (value.isNotEmpty) {
      currentFocus.unfocus();
      FocusScope.of(context).requestFocus(nextFocus);
    }
  }

  void _verifyOtp() {
    final enteredOtp = _otpController1.text +
        _otpController2.text +
        _otpController3.text +
        _otpController4.text +
        _otpController5.text +
        _otpController6.text;

    if (enteredOtp == widget.otp) {
      _safeSetState(() {
        _currentSection = 1;
      });

      final provider =
          Provider.of<NotificationProvider>(context, listen: false);

      // Update local state first
      provider.setSection(1);
      provider.setIsTimerActive(true);
      provider.updateTimer(0);

      // Then send WebSocket message with reservationId
      provider.sendMessage({
        'type': 'section_update',
        'section': 1,
        'reservationId': widget.reservationId
      });

      _startTimer();
    } else {
      _safeSetState(() {
        _errorMessage = 'The code you entered is incorrect. Please try again.';
        _isErrorVisible = true;
      });
    }
  }

  void _finishService() async {
    _timer?.cancel(); // Stop the timer
    _safeSetState(() {
      _elapsedTime = _remainingTime;
      _currentSection = 2;
    });
    // Update provider
    Provider.of<NotificationProvider>(context, listen: false)
      ..setSection(2)
      ..setIsTimerActive(false)
      ..updateTimer(_elapsedTime);
  }

  // In service_process_page.dart
  void handlePaymentSubmission() async {
    final amount = double.tryParse(_paymentController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final providerId = prefs.getString('providerId');

      if (providerId == null) {
        throw Exception('Provider ID not found');
      }

      // 1. Update NotificationProvider for real-time sync
      if (!_disposed) {
        Provider.of<NotificationProvider>(context, listen: false)
          ..setSection(2)
          ..setAmount(amount)
          ..updatePayment(
            method: 'pending',
            status: 'pending',
            amount: amount,
          );
      }

      // 2. Update reservation status
      final response = await http.patch(
        Uri.parse('$url/api/reservations/${widget.reservationId}/finish'),
        headers: {
          'Content-Type': 'application/json',
          'provider-id': providerId,
        },
        body: json.encode({
          'serviceTime': _elapsedTime,
          'amount': amount,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const ProviderHomePage(),
          ),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorResponse = json.decode(response.body);
        throw Exception(
            errorResponse['error'] ?? 'Failed to finish reservation');
      }
    } catch (e) {
      debugPrint('Error completing service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        title: Text('Service for ${widget.seekerName}',
            style: kAppBarTitleTextStyle),
      ),
      body: BackgroundWidget(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _currentSection == 0
                ? _buildOtpSection()
                : _currentSection == 1
                    ? _buildTimeLapseSection()
                    : _buildPaymentSection(),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Enter OTP sent to ${widget.seekerName}',
          style: kBodyTextStyle,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InputBox(
              controller: _otpController1,
              focusNode: _focusNode1,
              onChanged: (value) => _nextField(value, _focusNode1, _focusNode2),
            ),
            const SizedBox(width: 6),
            InputBox(
              controller: _otpController2,
              focusNode: _focusNode2,
              onChanged: (value) => _nextField(value, _focusNode2, _focusNode3),
            ),
            const SizedBox(width: 6),
            InputBox(
              controller: _otpController3,
              focusNode: _focusNode3,
              onChanged: (value) => _nextField(value, _focusNode3, _focusNode4),
            ),
            const SizedBox(width: 6),
            InputBox(
              controller: _otpController4,
              focusNode: _focusNode4,
              onChanged: (value) => _nextField(value, _focusNode4, _focusNode5),
            ),
            const SizedBox(width: 6),
            InputBox(
              controller: _otpController5,
              focusNode: _focusNode5,
              onChanged: (value) => _nextField(value, _focusNode5, _focusNode6),
            ),
            const SizedBox(width: 6),
            InputBox(
              controller: _otpController6,
              focusNode: _focusNode6,
              onChanged: (value) => _nextField(value, _focusNode6, FocusNode()),
            ),
          ],
        ),
        if (_isErrorVisible)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _errorMessage,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
        const SizedBox(height: 20),
        _isVerifyButtonActive
            ? VerifyButton(
                onPressed: _verifyOtp,
              )
            : VerifyButtonInactive(
                onPressed: () {
                  // Do nothing or show a message
                },
              ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildTimeLapseSection() {
    String formatTime(int seconds) {
      final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
      final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
      final secs = (seconds % 60).toString().padLeft(2, '0');
      return '$hours:$minutes:$secs';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: kPrimaryColor, width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            formatTime(_remainingTime),
            style: kBodyTextStyle.copyWith(
              fontSize: 58,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200, // Set a fixed width for the buttons
                child: ElevatedButton(
                  onPressed: _finishService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Success color
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Finish',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 200, // Set the same fixed width for the buttons
                child: ElevatedButton(
                  onPressed: () {
                    // Handle emergency
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Emergency color
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Emergency',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildPaymentSection() {
    String formatTime(int seconds) {
      final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
      final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
      final secs = (seconds % 60).toString().padLeft(2, '0');
      return '$hours:$minutes:$secs';
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Service Time: ${formatTime(_elapsedTime)}',
          style: kBodyTextStyle.copyWith(
              fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 20),
        Container(
          width: 300,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: kPrimaryColor, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const SizedBox(width: 5),
              Text(
                'Rs',
                style: TextStyle(
                  fontSize: 38, // Adjust font size
                  fontWeight: FontWeight.bold, // Make text bold
                  color: Colors.white, // Set text color
                ),
              ),
              Expanded(
                child: TextField(
                  cursorColor: Colors.white, // Set cursor color
                  controller: _paymentController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '00.00',
                    hintStyle: TextStyle(
                      color: Colors.white38,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 44, // Adjust font size
                    fontWeight: FontWeight.bold, // Make text bold
                    color: Colors.white, // Set text color
                  ),
                  textAlign: TextAlign.center, // Center the text
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            handlePaymentSubmission();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: const Text('Submit', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
