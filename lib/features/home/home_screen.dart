import 'package:booking_room/core/payment/payment.dart';
import 'package:booking_room/features/home/widgets/booking_blue_container.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:booking_room/features/home/widgets/home_top_bar.dart';
import 'package:booking_room/features/home/widgets/room_list_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBookingStatus();
    });
  }

  Future<void> _checkBookingStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Query for the most recent booking request by the user
      final querySnapshot = await FirebaseFirestore.instance
          .collection('roomRequests')
          .where('userId', isEqualTo: user.uid)
          .orderBy('requestTime', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final bookingRequest = querySnapshot.docs.first;
      final data = bookingRequest.data();
      final status = data['status'] as String;
      final requestId = bookingRequest.id;
      final roomId = data['roomId'] as String;

      switch (status) {
        case 'pending':
          // Do nothing for pending requests
          break;
        case 'approved':
          // Check if payment is required
          final roomDoc = await FirebaseFirestore.instance
              .collection('rooms')
              .doc(roomId)
              .get();

          final price =
              (roomDoc.data()?['prices']?['D'] as num?)?.toDouble() ?? 0.0;

          if (price > 0) {
            // Show payment alert
            await _showPaymentAlert(
                requestId: requestId, roomId: roomId, price: price);
          } else {
            // Show free booking accepted alert
            await _showBookingAcceptedAlert();
          }
          break;
        case 'rejected':
          // Show rejection alert with reason
          await _showRejectionAlert(
              data['rejectionReason'] ?? 'No reason provided');
          break;
      }
    } catch (e) {
      print('Error checking booking status: $e');
    }
  }

  Future<void> _showPaymentAlert({
    required String requestId,
    required String roomId,
    required double price,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Required'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Your booking has been approved.'),
                Text(
                    'Please complete the payment of \$${price.toStringAsFixed(2)}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Proceed to Payment'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      requestId: requestId,
                      roomId: roomId,
                      price: price,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showBookingAcceptedAlert() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Booking Confirmed'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Congratulations!'),
                Text('Your booking has been approved and is free of charge.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRejectionAlert(String reason) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Booking Rejected'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Unfortunately, your booking has been rejected.'),
                const SizedBox(height: 10),
                const Text('Reason:'),
                Text(
                  reason,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

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
