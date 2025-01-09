import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminBookingRequestsScreen extends StatelessWidget {
  const AdminBookingRequestsScreen({super.key});

  Future<void> _sendNotification(
    String userId,
    String status,
    String roomName,
    DateTime bookingDate,
    String timeSlot, {
    String reason = '',
  }) async {
    try {
      // Get the user's FCM token from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken == null) {
        print('No FCM token found for user $userId');
        return;
      }

      // Format the notification message
      final String formattedDate =
          DateFormat('MMM dd, yyyy').format(bookingDate);
      final String title = 'Booking ${status.capitalize()}';
      final String body = status == 'rejected'
          ? 'Your booking request for $roomName on $formattedDate at $timeSlot has been $status. Reason: $reason'
          : 'Your booking request for $roomName on $formattedDate at $timeSlot has been $status';

      // Create the notification data
      final notificationData = {
        'to': fcmToken,
        'notification': {
          'title': title,
          'body': body,
        },
        'data': {
          'type': 'booking_update',
          'status': status,
          'roomName': roomName,
          'bookingDate': formattedDate,
          'timeSlot': timeSlot,
        },
      };

      // Save notification to Firestore for in-app notifications
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'status': status,
        'roomName': roomName,
        'bookingDate': bookingDate,
        'timeSlot': timeSlot,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      // Send FCM notification
      var response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'key=YOUR_SERVER_KEY', // Replace with your server key
        },
        body: json.encode(notificationData),
      );

      if (response.statusCode != 200) {
        print(
            'Failed to send FCM notification, status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Future<void> _handleBookingAction(
    BuildContext context,
    String requestId,
    String roomId,
    String action,
  ) async {
    if (action == 'rejected') {
      final TextEditingController reasonController = TextEditingController();
      return showDialog<void>(
        context: context,
        barrierDismissible: false, // User must tap button to close the dialog
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: const Text('Reject Booking'),
            content: TextField(
              controller: reasonController,
              decoration:
                  const InputDecoration(hintText: "Enter reason for rejection"),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close the dialog
                },
              ),
              TextButton(
                child: const Text('Submit'),
                onPressed: () {
                  if (reasonController.text.isNotEmpty) {
                    Navigator.of(dialogContext).pop();
                    _processBookingAction(context, requestId, roomId, action,
                        reasonController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please provide a reason for rejection.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    } else {
      _processBookingAction(context, requestId, roomId, action, '');
    }
  }

  Future<void> _processBookingAction(
    BuildContext context,
    String requestId,
    String roomId,
    String action,
    String reason,
  ) async {
    try {
      final requestDoc = await FirebaseFirestore.instance
          .collection('roomRequests')
          .doc(requestId)
          .get();

      final requestData = requestDoc.data() as Map<String, dynamic>;

      final roomRef =
          FirebaseFirestore.instance.collection('rooms').doc(roomId);
      final roomDoc = await roomRef.get();

      if (!roomDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room does not exist.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      final requestRef =
          FirebaseFirestore.instance.collection('roomRequests').doc(requestId);
      final updateData = {'status': action};
      if (action == 'rejected' && reason.isNotEmpty) {
        updateData['rejectionReason'] = reason;
      }
      batch.update(requestRef, updateData);
      batch.update(roomRef, {
        'is_booked': action == 'approved',
      });

      await batch.commit();

      await _sendNotification(
        requestData['userId'],
        action,
        requestData['roomName'],
        (requestData['bookingDate'] as Timestamp).toDate(),
        requestData['bookingTimeString'],
        reason: reason,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Booking ${action == 'approved' ? 'approved' : 'rejected'} successfully'),
          backgroundColor: action == 'approved' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Requests'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('All Requests'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: 'approved',
                child: Text('Approved'),
              ),
              const PopupMenuItem(
                value: 'rejected',
                child: Text('Rejected'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('roomRequests')
            .orderBy('requestTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No booking requests found'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'] as String;
              final bookingDate = (data['bookingDate'] as Timestamp).toDate();
              final requestTime = (data['requestTime'] as Timestamp).toDate();

              Color statusColor;
              switch (status) {
                case 'pending':
                  statusColor = Colors.orange;
                  break;
                case 'approved':
                  statusColor = Colors.green;
                  break;
                case 'rejected':
                  statusColor = Colors.red;
                  break;
                default:
                  statusColor = Colors.grey;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text(
                    'Room: ${data['roomName']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${DateFormat('MMM dd, yyyy').format(bookingDate)}',
                      ),
                      Text(
                        'Time: ${data['bookingTimeString']}',
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request Details',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text('Floor: ${data['floor']}'),
                          Text('Price: \$${data['price']}'),
                          Text(
                            'Requested: ${DateFormat('MMM dd, yyyy HH:mm').format(requestTime)}',
                          ),
                          const SizedBox(height: 16),
                          if (status == 'pending')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _handleBookingAction(
                                    context,
                                    doc.id,
                                    data['roomId'],
                                    'approved',
                                  ),
                                  icon: const Icon(Icons.check,
                                      color: Colors.white),
                                  label: const Text('Approve'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _handleBookingAction(
                                    context,
                                    doc.id,
                                    data['roomId'],
                                    'rejected',
                                  ),
                                  icon: const Icon(Icons.close,
                                      color: Colors.white),
                                  label: const Text('Reject'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
