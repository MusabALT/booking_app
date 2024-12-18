import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String name;
  final String imagePath;
  final int floor;
  final Map<String, double> prices; 
  final bool isBooked;
  final DateTime? bookingDate;
  final String? bookingTime;
  final int capacity;

  Room({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.floor,
    required this.prices,
    required this.isBooked,
    this.bookingDate,
    this.bookingTime,
    required this.capacity, required double price,
  });

  // Factory method to create a Room object from Firestore data
  factory Room.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Convert price data to Map<String, double>
    Map<String, double> prices = {
      'D': double.tryParse(data['prices']['D'].toString()) ?? 0.0,
      'E': double.tryParse(data['prices']['E'].toString()) ?? 0.0,
      'F': double.tryParse(data['prices']['F'].toString()) ?? 0.0,
    };

    return Room(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      imagePath: data['image_path'] ?? 'room_images/placeholder.png',
      floor: int.tryParse(data['floor'].toString()) ?? 0,
      prices: prices,
      isBooked: data['is_booked'] ?? false,
      bookingDate: data['booking_date'] != null
          ? (data['booking_date'] as Timestamp).toDate()
          : null,
      bookingTime: data['booking_time'] as String?,
      capacity: int.tryParse(data['capacity'].toString()) ?? 0, price: prices['D'] ?? 0.0,
    );
  }

  // Method to convert a Room object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'image_path': imagePath,
      'floor': floor,
      'prices': {
        'D': prices['D'],
        'E': prices['E'],
        'F': prices['F'],
      },
      'is_booked': isBooked,
      'booking_date':
          bookingDate != null ? Timestamp.fromDate(bookingDate!) : null,
      'booking_time': bookingTime,
      'capacity': capacity,
    };
  }
}
