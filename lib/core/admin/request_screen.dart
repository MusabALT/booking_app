import 'package:booking_room/core/models/room.dart';
import 'package:booking_room/core/payment/payment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminBookingRequestsScreen extends StatelessWidget {
  const AdminBookingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Requests'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              // Add filter logic here
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
                          Text('User ID: ${data['userId']}'),
                          const SizedBox(height: 16),
                          if (status == 'pending')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _handleBookingRequest(
                                    context,
                                    doc.id,
                                    data['roomId'],
                                    'approved',
                                    data['price'],
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
                                  onPressed: () => _handleBookingRequest(
                                    context,
                                    doc.id,
                                    data['roomId'],
                                    'rejected',
                                    data['price'],
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

  Future<void> _handleBookingRequest(
    BuildContext context,
    String requestId,
    String roomId,
    String action,
    double price,
  ) async {
    try {
      if (action == 'approved') {
        // Perform booking approval
        await _performBookingAction(context, requestId, roomId, 'approved');

        // If price is free (0), just show success message
        if (price == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking approved successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // If there's a price, navigate to payment screen
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
        }
      } else if (action == 'rejected') {
        // Show rejection reason dialog
        final rejectionReason = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            final reasonController = TextEditingController();
            return AlertDialog(
              title: const Text('Reject Booking'),
              content: TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Enter reason for rejection',
                ),
                maxLines: 3,
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: const Text('Reject'),
                  onPressed: () {
                    Navigator.of(context).pop(reasonController.text.trim());
                  },
                ),
              ],
            );
          },
        );

        // If no reason provided, cancel the rejection
        if (rejectionReason == null || rejectionReason.isEmpty) {
          return;
        }

        // Perform rejection
        await _performBookingAction(
            context, requestId, roomId, 'rejected', rejectionReason);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _performBookingAction(
      BuildContext context, String requestId, String roomId, String action,
      [String? rejectionReason]) async {
    try {
      // Batch write for atomic operations
      final batch = FirebaseFirestore.instance.batch();

      // Prepare the update for the booking request
      final requestUpdateData = {
        'status': action,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      };

      // Reference to the request document
      final requestRef =
          FirebaseFirestore.instance.collection('roomRequests').doc(requestId);

      // Reference to the room document
      final roomRef =
          FirebaseFirestore.instance.collection('rooms').doc(roomId);

      // Update request status
      batch.update(requestRef, requestUpdateData);

      // Update room availability based on action
      batch.update(roomRef, {
        'is_booked': action == 'approved',
        'booking_date':
            action == 'approved' ? FieldValue.serverTimestamp() : null,
      });

      // Commit the batch
      await batch.commit();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking ${action.toLowerCase()} successfully'),
          backgroundColor: action == 'approved' ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      // Handle any errors during the process
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
