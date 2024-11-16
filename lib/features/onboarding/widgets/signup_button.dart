import 'package:flutter/material.dart';
import 'package:booking_room/core/helper/extenstions.dart';
import 'package:booking_room/core/routing/routes.dart';
import 'package:booking_room/core/theming/styles.dart';

class SignUpButton extends StatelessWidget {
  const SignUpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 20.0), // Added padding for centering
      child: SizedBox(
        width: double.infinity, // Full width
        height: 52, // Height of the button
        child: TextButton(
          onPressed: () {
            context.pushNamed(Routes.registrationScreen);
          },
          style: ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Rounded corners
              ),
            ),
          ),
          child: Text('Sign up', style: TextStyles.font13BlueSemiBold),
        ),
      ),
    );
  }
}
