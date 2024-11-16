import 'package:booking_room/booking_app.dart';
import 'package:booking_room/core/routing/app_router.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await Firebase.initializeApp();

  runApp(BookingApp(
    appRouter: AppRouter(),
  ));
}
