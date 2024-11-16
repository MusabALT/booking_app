import 'package:booking_room/core/helper/spacing.dart';
import 'package:booking_room/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BookingBlueContainer extends StatelessWidget {
  const BookingBlueContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 195.h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: double.infinity,
            height: 160.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              image: const DecorationImage(
                image: AssetImage('assets/images/home_blue_pattern.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You can\nbook now!',
                    style: TextStyles.font18WhiteMedium,
                    textAlign: TextAlign.start),
                verticalSpace(16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(48.0),
                      ),
                    ),
                    child:
                        Text('Book Now', style: TextStyles.font12BlueRegular),
                  ),
                )
              ],
            ),
          ),
          Positioned(
            right: -10,
            top: 0,
            child: Image.asset('assets/images/home.png', height: 200.h),
          )
        ],
      ),
    );
  }
}
