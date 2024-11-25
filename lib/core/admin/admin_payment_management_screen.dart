import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminPaymentScreen extends StatelessWidget {
  const AdminPaymentScreen({super.key});

  Future<void> _markPaymentComplete(
      BuildContext context, String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('roomRequests')
          .doc(requestId)
          .update({
        'paymentStatus': 'completed',
        'paymentCompletedAt': Timestamp.now(),
        'status': 'confirmed', // Update the overall status to confirmed
      });

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment marked as completed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating payment status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment Management'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Pending'),
              Tab(text: 'Cash Payments'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPaymentList(
              context,
              paymentStatus: 'pending',
              title: 'Pending Payments',
            ),
            _buildPaymentList(
              context,
              paymentStatus: 'pending',
              paymentMethod: 'Cash',
              title: 'Cash Payments',
            ),
            _buildPaymentList(
              context,
              paymentStatus: 'completed',
              title: 'Completed Payments',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentList(
    BuildContext context, {
    String? paymentStatus,
    String? paymentMethod,
    required String title,
  }) {
    Query query = FirebaseFirestore.instance
        .collection('roomRequests')
        .orderBy('bookingDateTime', descending: true);

    if (paymentStatus != null) {
      query = query.where('paymentStatus', isEqualTo: paymentStatus);
    }

    if (paymentMethod != null) {
      query = query.where('paymentMethod', isEqualTo: paymentMethod);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payment, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No $title found'),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;

            final bookingDateTime =
                (data['bookingDateTime'] as Timestamp).toDate();
            final requestTime = (data['requestTime'] as Timestamp?)?.toDate();
            final paymentTimestamp = data['paymentTimestamp'] as Timestamp?;
            final paymentCompletedAt = data['paymentCompletedAt'] as Timestamp?;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ExpansionTile(
                title: Row(
                  children: [
                    Icon(
                      data['paymentMethod'] == 'Cash'
                          ? Icons.money
                          : Icons.credit_card,
                      color: data['paymentStatus'] == 'completed'
                          ? Colors.green
                          : data['paymentMethod'] == 'Cash'
                              ? Colors.orange
                              : Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Room: ${data['roomName']} (Floor ${data['floor']})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Amount: \$${(data['price'] as num).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking: ${DateFormat('dd/MM/yyyy').format(bookingDateTime)}',
                    ),
                    Text('Time: ${data['bookingTimeString']}'),
                    if (data['paymentMethod'] != null)
                      Text(
                        'Payment Method: ${data['paymentMethod']}',
                        style: TextStyle(
                          color: data['paymentMethod'] == 'Cash'
                              ? Colors.orange
                              : Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking Details',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('Room ID: ${data['roomId']}'),
                        Text('Category: ${data['selectedCategory']}'),
                        Text('User ID: ${data['userId']}'),
                        if (requestTime != null)
                          Text(
                            'Request Time: ${DateFormat('dd/MM/yyyy HH:mm').format(requestTime)}',
                          ),
                        const SizedBox(height: 12),
                        Text(
                          'Payment Details',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (paymentTimestamp != null)
                          Text(
                            'Payment Initiated: ${DateFormat('dd/MM/yyyy HH:mm').format(paymentTimestamp.toDate())}',
                          ),
                        if (paymentCompletedAt != null)
                          Text(
                            'Payment Completed: ${DateFormat('dd/MM/yyyy HH:mm').format(paymentCompletedAt.toDate())}',
                          ),
                        const SizedBox(height: 16),
                        if (data['paymentMethod'] == 'Cash' &&
                            data['paymentStatus'] == 'pending')
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _markPaymentComplete(context, doc.id),
                              icon: const Icon(Icons.check),
                              label: const Text('Mark as Paid'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
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
    );
  }
}
