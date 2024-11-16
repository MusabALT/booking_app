import 'package:booking_room/booking_app.dart';
import 'package:booking_room/core/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import Firebase core

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //must put this
  await Firebase.initializeApp();

  runApp(BookingApp(
    appRouter: AppRouter(),
  ));
}
