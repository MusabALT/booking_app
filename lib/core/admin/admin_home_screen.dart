import 'package:booking_room/core/admin/admin_view_calender_screen.dart';
import 'package:booking_room/core/admin/blue_for_admin.dart';
import 'package:booking_room/core/admin/request_screen.dart';
import 'package:booking_room/core/helper/spacing.dart';
import 'package:booking_room/core/widgets/app_text_button.dart';
import 'package:flutter/material.dart';

class HomeScreenAdmin extends StatelessWidget {
  const HomeScreenAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const adminBookingBlueContainer(),
              verticalSpace(20),
              AppTextButton(
                buttonText: 'View Calendar',
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminCalendarScreen()),
                  );
                },
              ),
              verticalSpace(20),
              AppTextButton(
                buttonText: 'View Requests',
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const AdminBookingRequestsScreen()),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
