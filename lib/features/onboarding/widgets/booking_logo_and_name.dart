import 'package:booking_room/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BookingLogoAndName extends StatelessWidget {
  const BookingLogoAndName({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'assets/svgs/logo.svg',
          height: 24.0, // Adjust the height to make the SVG smaller
          width: 24.0, // Adjust the width to match the height
          color: Colors.blue,
        ),
        SizedBox(width: 10.w),
        Text(
          'SpaceBook',
          style: TextStyles.font24BlackBold,
        ),
      ],
    );
  }
}
