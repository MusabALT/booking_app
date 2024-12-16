import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingStatusScreen extends StatelessWidget {
  final String userId; // This is obtained from the user's login session

  const BookingStatusScreen({Key? key, required this.userId}) : super(key: key);

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
            .orderBy('bookingDate', descending: true) // Make sure to index this query in Firestore if needed
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error.toString()}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No booking requests found'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text('Room: ${data['roomName']}'),
                  subtitle: Text('Date: ${DateFormat('MMM dd, yyyy').format((data['bookingDate'] as Timestamp).toDate())}'),
                  trailing: _buildStatusChip(data['status'], context),
                  onTap: () => _showRequestDetails(context, data),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showRequestDetails(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Request Details'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Status: ${data['status']}'),
              if (data['status'] == 'rejected')
                Text('Reason: ${data['rejectionReason'] ?? "No reason provided"}'),
              Text('Room: ${data['roomName']}'),
              Text('Date: ${DateFormat('MMM dd, yyyy').format((data['bookingDate'] as Timestamp).toDate())}'),
              Text('Time: ${data['bookingTimeString']}'),
              Text('Floor: ${data['floor']}'),
              Text('Price: \$${data['price']}'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, BuildContext context) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'pending':
      default:
        color = Colors.orange;
        break;
    }
    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }
}
