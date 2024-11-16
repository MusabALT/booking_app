import 'package:booking_room/features/home/widgets/home_top_bar.dart';
import 'package:booking_room/features/home/widgets/room_list_view.dart';
import 'package:flutter/material.dart';

import 'widgets/booking_blue_container.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              const HomeTopBar(),
              const BookingBlueContainer(),
              RoomListView(),
            ],
          ),
        ),
      ),
    );
  }
}
