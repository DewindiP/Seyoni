import 'package:flutter/material.dart';
import '../../constants/constants_color.dart';
import '../../constants/constants_font.dart';
import '../custom_button.dart';
import 'dart:ui';

class SeekerNotFound extends StatelessWidget {
  final VoidCallback onPressed;

  const SeekerNotFound({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        const Opacity(
          opacity: 0.5, // Background opacity
          child: ModalBarrier(
            dismissible: true,
            color: Colors.black,
          ),
        ),
        Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Account Not Found',
                      style: kAlertTitleTextStyle,
                      textAlign: TextAlign.center,
                    ),
                    const Divider(
                      color: kPrimaryColor,
                      thickness: 1,
                      indent: 1,
                      endIndent: 1,
                    ),
                    Image.asset(
                      'assets/icons/AlertBox/User-Not-Found.png',
                      height: 50,
                      width: 50,
                    ),
                    const Text(
                      'The account you are trying to access does not exist. Please sign up to create a new account.',
                      style: kAlertDescriptionTextStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    PrimaryFilledButton(
                      text: 'Sign Up',
                      onPressed: onPressed,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
