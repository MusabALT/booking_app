import 'package:flutter/material.dart';
import 'package:booking_room/core/theming/styles.dart';

class AppImageAndText extends StatelessWidget {
  const AppImageAndText({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        foregroundDecoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.white.withOpacity(0.0),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: const [0.14, 0.4],
          ),
        ),
        child: Image.asset(
          'assets/images/FC.png',
          fit: BoxFit.contain,
        ),
      ),
      Positioned(
        bottom: 30,
        left: 0,
        right: 0,
        child: Text('Your One-Stop \n Booking Solution!..',
            textAlign: TextAlign.center,
            style: TextStyles.font32BlueBold.copyWith(height: 1.4)),
      )
    ]);
  }
}
