import 'package:booking_room/core/models/room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RoomListView extends StatelessWidget {
  RoomListView({super.key});

  final Map<String, String> categoryDescriptions = {
    'D':
        'For:\n• UTM staff and students who implement community programs\n• Activities without income generation',
    'E':
        'For:\n• UTM Prime Staff and Students who carry out activities involving income generation\n• Distance Learning Center\n• Principal Investigators Using Research Grants',
    'F':
        'For:\n• Government employees\n• Government agencies\n• Statutory bodies\n• NGOs'
  };

  Future<String?> _selectCategory(BuildContext context, Room room) async {
    String? selectedCategory;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Booking Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please select your booking category:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...['D', 'E', 'F'].map((category) => Column(
                    children: [
                      ListTile(
                        title: Text('Category $category'),
                        subtitle: Text(
                            'Price: \$${room.prices[category]?.toStringAsFixed(2)}'),
                        onTap: () {
                          Navigator.of(context).pop(category);
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline),
                          onPressed: () {
                            // Show category description in a temporary dialog
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Category $category Details'),
                                  content: Text(
                                      categoryDescriptions[category] ?? ''),
                                  actions: [
                                    TextButton(
                                      child: const Text('Close'),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const Divider(),
                    ],
                  )),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(null),
            ),
          ],
        );
      },
    ).then((value) => selectedCategory = value as String?);

    return selectedCategory;
  }

  void _requestBooking(BuildContext context, Room room) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to request a booking')),
      );
      return;
    }

    // First, let the user select a category
    final selectedCategory = await _selectCategory(context, room);

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a booking category')),
      );
      return;
    }

    final selectedPrice = room.prices[selectedCategory] ?? 0.0;

    DateTime currentDate = DateTime.now();
    TimeOfDay currentTime = TimeOfDay.now();

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: currentDate,
      lastDate: currentDate.add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) return;

    final DateTime bookingDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (bookingDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot book a time in the past')),
      );
      return;
    }

    String formattedTime =
        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

    // Check for existing bookings
    final QuerySnapshot existingBookings = await FirebaseFirestore.instance
        .collection('roomRequests')
        .where('roomId', isEqualTo: room.id)
        .where('bookingDate', isEqualTo: Timestamp.fromDate(selectedDate))
        .where('status', whereIn: ['pending', 'approved']).get();

    if (existingBookings.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'This room is already booked for the selected date and time')),
      );
      return;
    }

    final bookingRequest = {
      'roomId': room.id,
      'userId': userId,
      'roomName': room.name,
      'requestTime': Timestamp.now(),
      'status': 'pending',
      'bookingDate': Timestamp.fromDate(selectedDate),
      'bookingDateTime': Timestamp.fromDate(bookingDateTime),
      'bookingTimeString': formattedTime,
      'selectedCategory': selectedCategory,
      'price': selectedPrice,
      'floor': room.floor,
    };

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Booking'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Room: ${room.name}'),
              const SizedBox(height: 8),
              Text('Category: $selectedCategory'),
              Text('Price: \$${selectedPrice.toStringAsFixed(2)}'),
              Text('Date: ${DateFormat('MMM dd, yyyy').format(selectedDate)}'),
              Text('Time: $formattedTime'),
              Text('Floor: ${room.floor}'),
              Text('Capacity: ${room.capacity}'),
              const SizedBox(height: 12),
              const Text('Category Eligibility:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(categoryDescriptions[selectedCategory] ?? ''),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('roomRequests')
            .add(bookingRequest);

        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(room.id)
            .update({'is_booked': true});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking request sent for room: ${room.name}'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting booking request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('is_booked', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final rooms =
            snapshot.data!.docs.map((doc) => Room.fromDocument(doc)).toList();

        return ListView.builder(
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return Card(
              margin: const EdgeInsets.all(10.0),
              child: ListTile(
                leading: room.imagePath.isNotEmpty
                    ? Image.network(
                        room.imagePath,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error);
                        },
                      )
                    : const Icon(Icons.hotel),
                title: Text(room.name),
                subtitle:
                    Text('Floor: ${room.floor}, Capacity: ${room.capacity}'),
                trailing: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    _requestBooking(context, room);
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
