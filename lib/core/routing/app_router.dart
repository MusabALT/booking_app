import 'package:booking_room/core/admin/add_new_room.dart';
import 'package:booking_room/core/admin/admin_home_screen.dart';
import 'package:booking_room/core/admin/manage_room.dart';
import 'package:booking_room/core/admin/super_admin_home_screen.dart';
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
          builder: (_) => const HomeScreenAdmin(),
        );
      case Routes.superAdminHomeScreen:
        return MaterialPageRoute(
          builder: (_) => const SuperHomeScreenAdmin(),
        );
      case Routes.manageRoom:
        return MaterialPageRoute(
          builder: (_) => const ManageRoom(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );
    }
  }
}
