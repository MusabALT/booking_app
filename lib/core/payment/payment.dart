import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatelessWidget {
  final String requestId;
  final double price;
  final String roomName;
  final DateTime bookingDate;
  final String bookingTime;
  final String selectedCategory;
  final int floor;
  final String roomId;

  const PaymentScreen({
    super.key,
    required this.requestId,
    required this.price,
    required this.roomName,
    required this.bookingDate,
    required this.bookingTime,
    required this.selectedCategory,
    required this.floor,
    required this.roomId,
  });

  Future<void> _processPayment(
      BuildContext context, String paymentMethod) async {
    try {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirm $paymentMethod Payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Room: $roomName (Floor $floor)'),
                Text('Category: $selectedCategory'),
                Text('Amount: \$${price.toStringAsFixed(2)}'),
                Text('Date: ${DateFormat('MMM dd, yyyy').format(bookingDate)}'),
                Text('Time: $bookingTime'),
                const SizedBox(height: 16),
                if (paymentMethod == 'Cash')
                  const Text(
                    'Please proceed to the counter to make your cash payment.',
                    style: TextStyle(color: Colors.blue),
                  )
                else
                  const Text(
                    'You will be redirected to the secure payment gateway.',
                    style: TextStyle(color: Colors.blue),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );

      if (confirmed == true) {
        await FirebaseFirestore.instance
            .collection('roomRequests')
            .doc(requestId)
            .update({
          'paymentStatus': 'pending',
          'paymentMethod': paymentMethod,
          'paymentTimestamp': Timestamp.now(),
          'roomId': roomId,
          'status': 'pending_payment',
        });

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentMethod == 'Cash'
                ? 'Please proceed to the counter for payment'
                : 'Redirecting to payment gateway...'),
            backgroundColor: Colors.green,
          ),
        );

        if (paymentMethod == 'Card') {
          await Future.delayed(const Duration(seconds: 2));
          if (!context.mounted) return;
          _showCardPaymentDialog(context);
        } else {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCardPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Payment Gateway'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  hintText: '**** **** **** ****',
                ),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Expiry Date',
                        hintText: 'MM/YY',
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'CVV',
                        hintText: '***',
                      ),
                      obscureText: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Pay Now'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text('Room: $roomName (Floor $floor)'),
                    Text('Category: $selectedCategory'),
                    Text(
                        'Date: ${DateFormat('MMM dd, yyyy').format(bookingDate)}'),
                    Text('Time: $bookingTime'),
                    const SizedBox(height: 8),
                    Text(
                      'Amount: \$${price.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Select Payment Method',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _processPayment(context, 'Cash'),
                    icon: const Icon(Icons.money),
                    label: const Text('Pay with Cash'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _processPayment(context, 'Card'),
                    icon: const Icon(Icons.credit_card),
                    label: const Text('Pay with Card'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Cash payments must be made at the counter'),
                    Text('• Card payments are processed securely'),
                    Text('• Payment must be completed within 24 hours'),
                    Text(
                        '• Booking will be cancelled if payment is not received'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
