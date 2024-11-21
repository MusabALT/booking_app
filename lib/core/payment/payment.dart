import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentScreen extends StatefulWidget {
  final String requestId;
  final String roomId;
  final double price;

  const PaymentScreen({
    super.key, 
    required this.requestId, 
    required this.roomId, 
    required this.price
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.cash;

  @override
  Widget build(BuildContext context) {
    // If price is 0, automatically complete the booking
    if (widget.price == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _completeBooking(context);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Amount: \$${widget.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (widget.price > 0) ...[
              PaymentMethodTile(
                method: PaymentMethod.cash,
                title: 'Pay by Cash',
                subtitle: 'Pay at the reception',
                icon: Icons.money,
                isSelected: _selectedMethod == PaymentMethod.cash,
                onTap: () {
                  setState(() {
                    _selectedMethod = PaymentMethod.cash;
                  });
                },
              ),
              const SizedBox(height: 10),
              PaymentMethodTile(
                method: PaymentMethod.card,
                title: 'Pay by Card',
                subtitle: 'Credit or Debit Card',
                icon: Icons.credit_card,
                isSelected: _selectedMethod == PaymentMethod.card,
                onTap: () {
                  setState(() {
                    _selectedMethod = PaymentMethod.card;
                  });
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => _completeBooking(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 50, 
                      vertical: 15
                    ),
                  ),
                  child: const Text(
                    'Confirm Payment',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Center(
                child: Text(
                  'This booking is free of charge.',
                  style: TextStyle(
                    fontSize: 16, 
                    color: Colors.green, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _completeBooking(BuildContext context) async {
    try {
      // Start a batch write
      final batch = FirebaseFirestore.instance.batch();

      // Update the request status
      final requestRef =
          FirebaseFirestore.instance.collection('roomRequests').doc(widget.requestId);
      batch.update(requestRef, {
        'status': 'approved',
        'paymentMethod': widget.price > 0 ? _selectedMethod.toString().split('.').last : 'free'
      });

      // Update room status 
      final roomRef =
          FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
      batch.update(roomRef, {
        'is_booked': true,
      });

      // Commit the batch
      await batch.commit();

      // Show success message and navigate back to home
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Booking ${widget.price > 0 ? 'paid and ' : ''}confirmed successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate back to home or previous screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Custom widget for payment method selection
class PaymentMethodTile extends StatelessWidget {
  final PaymentMethod method;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentMethodTile({
    super.key,
    required this.method,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, size: 40, color: isSelected ? Colors.blue : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.blue : Colors.black,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: isSelected 
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : null,
        onTap: onTap,
      ),
    );
  }
}

// Enum for payment methods
enum PaymentMethod {
  cash,
  card
}