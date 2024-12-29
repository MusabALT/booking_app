import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestStatusScreen extends StatefulWidget {
  const RequestStatusScreen({Key? key}) : super(key: key);

  @override
  State<RequestStatusScreen> createState() => _RequestStatusScreenState();
}

class _RequestStatusScreenState extends State<RequestStatusScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Request Status'),
        ),
        body: const Center(
          child: Text('Please log in to view your booking requests.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Booking Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('roomRequests')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('requestTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No booking requests found.'),
            );
          }

          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final doc = requests[index];
              final data = doc.data() as Map<String, dynamic>;

              final roomName = data['roomName'] ?? 'Unknown Room';
              final bookingDate =
                  (data['bookingDate'] as Timestamp?)?.toDate() ??
                      DateTime.now();
              final bookingTime = data['bookingTimeString'] ?? 'N/A';
              final status = data['status'] ?? 'Pending';
              final price = (data['price'] as num?)?.toDouble() ?? 0.0;
              final selectedCategory = data['selectedCategory'] ?? 'Unknown';
              final floor = data['floor'] ?? 'N/A';
              final rejectionReason =
                  data['rejectionReason'] ?? 'No reason provided';

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Room: $roomName'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category: $selectedCategory'),
                      Text('Floor: $floor'),
                      Text('Price: \$${price.toStringAsFixed(2)}'),
                      Text('Booking Date: ${bookingDate.toLocal()}'),
                      Text('Booking Time: $bookingTime'),
                      Text('Status: $status'),
                      if (status == 'rejected')
                        Text(
                          'Reason: $rejectionReason',
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                  trailing: Icon(
                    status == 'approved'
                        ? Icons.check_circle
                        : status == 'rejected'
                            ? Icons.cancel
                            : Icons.hourglass_empty,
                    color: status == 'approved'
                        ? Colors.green
                        : status == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
