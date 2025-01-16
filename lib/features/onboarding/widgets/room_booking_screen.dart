import 'package:booking_room/core/models/room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RoomBookingScreen extends StatelessWidget {
  const RoomBookingScreen({super.key, required String roomId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Rooms')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading rooms'));
          }

          final rooms = snapshot.data!.docs.map((doc) {
            return Room.fromDocument(doc);
          }).toList();

          if (rooms.isEmpty) {
            return const Center(child: Text('No rooms available'));
          }

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                margin: const EdgeInsets.all(10.0),
                child: ListTile(
                  title: Text(room.name),
                  subtitle:
                      Text('Price: \$${room.prices}, Floor: ${room.floor}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      // Functionality to request booking
                      _requestBooking(context, room);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _requestBooking(BuildContext context, Room room) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Request Booking'),
          content: Text(
              'Do you want to request booking for ${room.name} on floor ${room.floor}?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(room.id)
                    .update({
                  'isPending': true, 
                  'requesterId':
                      'userId',                 });

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Booking request sent')),
                );
              },
              child: const Text('Request'),
            ),
          ],
        );
      },
    );
  }
}
