import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserBookingStatusScreen extends StatelessWidget {
  final String userId; // Pass the logged-in user's ID

  const UserBookingStatusScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Booking Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('roomRequests')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final roomName = request['roomName'];
              final status = request['status'];

              return ListTile(
                title: Text('Room: $roomName'),
                subtitle: Text('Status: $status'),
              );
            },
          );
        },
      ),
    );
  }
}
