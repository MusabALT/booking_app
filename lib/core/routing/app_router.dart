import 'package:booking_room/core/admin/add_new_room.dart';
import 'package:booking_room/core/admin/admin.dart';
import 'package:booking_room/core/admin/request_screen.dart';
import 'package:booking_room/core/routing/routes.dart';
import 'package:booking_room/features/home/home_screen.dart';
import 'package:booking_room/features/login/ui/registration_screen.dart';
import 'package:booking_room/features/onboarding/onboarding_screen.dart';
import 'package:booking_room/features/login/ui/login_screen.dart';
import 'package:booking_room/features/onboarding/widgets/room_booking_screen.dart';
import 'package:flutter/material.dart';

class AppRouter {
  Route generateRoute(RouteSettings setting) {
    final arguments = setting.arguments;

    switch (setting.name) {
      case Routes.onBoardingScreen:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );

      case Routes.loginScreen:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );
      case Routes.registrationScreen:
        return MaterialPageRoute(
          builder: (_) => const RegistrationScreen(),
        );

      case Routes.roomBookingScreen:
        return MaterialPageRoute(
          builder: (_) => const RoomBookingScreen(
            roomId: '',
          ),
        );

      case Routes.homeScreen:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );
      case Routes.addNewRoom:
        return MaterialPageRoute(
          builder: (_) => const AddNewRoom(),
        );
      case Routes.adminHomeScreen:
        return MaterialPageRoute(
          builder: (_) => const AdminBookingRequestsScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );
    }
  }
}
