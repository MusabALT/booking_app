import 'package:booking_room/core/payment/payment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ShowPaymentScreen extends StatelessWidget {
  const ShowPaymentScreen({super.key});

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    const String currentUserId =
        "example-user-id"; // Replace with actual user ID retrieval

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Bookings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('roomRequests')
              .where('userId', isEqualTo: currentUserId)
              .where('status', isEqualTo: 'approved')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('No approved bookings found'),
              );
            }

            final requests = snapshot.data!.docs;
            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final doc = requests[index];
                final data = doc.data() as Map<String, dynamic>;

                // Get document ID for the request
                final requestId = doc.id;
                final roomId = data['roomId'] as String? ?? '';
                final roomName = data['roomName'] as String? ?? 'Unknown Room';
                final price = (data['price'] as num?)?.toDouble() ?? 0.0;
                final bookingTimeString =
                    data['bookingTimeString'] as String? ?? '';
                final bookingDateTime =
                    (data['bookingDateTime'] as Timestamp?)?.toDate();
                final floor = (data['floor'] as num?)?.toInt() ?? 0;
                final selectedCategory =
                    data['selectedCategory'] as String? ?? '';
                final requestTime =
                    (data['requestTime'] as Timestamp?)?.toDate();

                if (bookingDateTime == null) {
                  return const SizedBox.shrink();
                }

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Approved Booking: $roomName',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Text('Room ID: $roomId'),
                        Text('Floor: $floor'),
                        Text('Category: $selectedCategory'),
                        const SizedBox(height: 8),
                        Text('Booking Date: ${_formatDate(bookingDateTime)}'),
                        Text('Booking Time: $bookingTimeString'),
                        Text(
                            'Request Time: ${requestTime != null ? _formatDate(requestTime) : 'N/A'}'),
                        Text('Price: \$${price.toStringAsFixed(2)}'),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaymentScreen(
                                    requestId:
                                        requestId, 
                                    roomId: roomId,
                                    price: price,
                                    roomName: roomName,
                                    bookingDate: bookingDateTime,
                                    bookingTime: bookingTimeString,
                                    selectedCategory: selectedCategory,
                                    floor: floor,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Proceed to Payment'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
