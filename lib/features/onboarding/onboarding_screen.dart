import 'package:booking_room/features/onboarding/widgets/app_image_and_text.dart';
import 'package:booking_room/features/onboarding/widgets/booking_logo_and_name.dart';
import 'package:booking_room/features/onboarding/get_started_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: Colors.deepPurple,
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: 10.h, bottom: 30.h),
          child: Column(
            children: [
              const BookingLogoAndName(),
              SizedBox(
                height: 30.h,
              ),
              const AppImageAndText(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                child: Column(
                  children: [
                    const Text('Book a room rith now ! ..'),
                    SizedBox(
                      height: 30.h,
                    ),
                    const GetStartedButton()
                  ],
                ),
              )
            ],
          ),
        ),
      )),
    );
  }
}
