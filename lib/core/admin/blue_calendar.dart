import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class calendarBookingBlueContainer extends StatelessWidget {
  const calendarBookingBlueContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 195.h,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            right: -10,
            top: 10,
            bottom: 10,
            child: Image.asset('assets/images/calendar.png',
                height: 400.h, width: 400.w),
          )
        ],
      ),
    );
  }
}
