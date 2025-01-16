import 'package:flutter/material.dart';
import 'package:booking_room/core/helper/extenstions.dart';
import 'package:booking_room/core/routing/routes.dart';
import 'package:booking_room/core/theming/styles.dart';

class SignUpButton extends StatelessWidget {
  const SignUpButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: TextButton(
          onPressed: () {
            context.pushNamed(Routes.registrationScreen);
          },
          style: ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: Text('Sign up', style: TextStyles.font13BlueSemiBold),
        ),
      ),
    );
  }
}
