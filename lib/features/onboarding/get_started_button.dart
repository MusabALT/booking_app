import 'package:flutter/material.dart';
import 'package:booking_room/core/helper/extenstions.dart';
import 'package:booking_room/core/routing/routes.dart';
import 'package:booking_room/core/theming/colors.dart';
import 'package:booking_room/core/theming/styles.dart';

class GetStartedButton extends StatelessWidget {
  const GetStartedButton({super.key});

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
            context.pushNamed(Routes.loginScreen);
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(ColorsManager.mainBlue),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // Rounded corners
              ),
            ),
          ),
          child: Text(
            'Get Started',
            style: TextStyles.font16WhiteSemiBold,
          ),
        ),
      ),
    );
  }
}
