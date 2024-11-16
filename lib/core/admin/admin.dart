import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:booking_room/core/models/room.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  String? _imageUrl; 
  final ImagePicker _picker = ImagePicker();
  final List<Room> _rooms = [];
  List<Map<String, dynamic>> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
    _fetchBookingRequests(); 
  }

  Future<void> _fetchRooms() async {
    final snapshot = await FirebaseFirestore.instance.collection('rooms').get();
    setState(() {
      _rooms.clear();
      _rooms
          .addAll(snapshot.docs.map((doc) => Room.fromDocument(doc)).toList());
    });
  }

  Future<void> _fetchBookingRequests() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('booking_requests').get();
    setState(() {
      _pendingRequests = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    });
  }

  Future<void> _addRoom() async {
    final newRoom = Room(
      id: '',
      name: _nameController.text,
      imagePath: _imageUrl ?? 'room_images/placeholder.png',
      floor: int.parse(_floorController.text),
      price: double.parse(_priceController.text),
      isBooked: false, 
      capacity: int.parse(_capacityController.text), prices: {},
    );

    await FirebaseFirestore.instance.collection('rooms').add(newRoom.toMap());
    _fetchRooms();
    _clearInputs();
  }

  Future<void> _deleteRoom(String roomId) async {
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).delete();
    _fetchRooms(); 
  }

  Future<void> _uploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('room_images/${pickedFile.name}');
      await ref.putFile(File(pickedFile.path));
      
      final url = await ref.getDownloadURL();
      setState(() {
        _imageUrl = url; 
      });
    }
  }

  Future<void> _acceptBookingRequest(String requestId, String roomId) async {
    // Update the room status to 'booked'
    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
      'is_booked': true,
    });

    // Remove the request from pending requests
    await FirebaseFirestore.instance
        .collection('booking_requests')
        .doc(requestId)
        .delete();

    _fetchRooms();
    _fetchBookingRequests(); // Refresh the requests list
  }

  Future<void> _rejectBookingRequest(String requestId) async {
    // Simply remove the request from pending requests
    await FirebaseFirestore.instance
        .collection('booking_requests')
        .doc(requestId)
        .delete();

    _fetchBookingRequests(); // Refresh the requests list
  }

  void _clearInputs() {
    _nameController.clear();
    _floorController.clear();
    _priceController.clear();
    _imageUrl = null; // Clear image URL
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Text('Admin Room Management')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Add New Room', style: TextStyle(fontSize: 20)),
              _buildTextField(_nameController, 'Room Name'),
              _buildImageUploadButton(),
              _buildTextField(_floorController, 'Floor', isNumber: true),
              _buildTextField(_priceController, 'Price', isNumber: true),
              ElevatedButton(
                onPressed: _addRoom,
                child: const Text('Add Room'),
              ),
              const SizedBox(height: 20),
              Text('Existing Rooms', style: TextStyle(fontSize: 20)),
              Expanded(
                child: ListView.builder(
                  itemCount: _rooms.length,
                  itemBuilder: (context, index) {
                    final room = _rooms[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(room.name),
                        subtitle: Text(
                            'Price: \$${room.prices} | Floor: ${room.floor}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!room.isBooked)
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => _acceptBookingRequest(
                                    _pendingRequests[index]['id'], room.id),
                              ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteRoom(room.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text('Pending Booking Requests', style: TextStyle(fontSize: 20)),
              Expanded(
                child: ListView.builder(
                  itemCount: _pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = _pendingRequests[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text('Request for Room ID: ${request['roomId']}'),
                        subtitle: Text(
                            'Requested by: ${request['userId']} \nDate: ${request['booking_date']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check,
                                  color: Colors.green),
                              onPressed: () => _acceptBookingRequest(
                                  request['id'], request['roomId']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear, color: Colors.red),
                              onPressed: () => _rejectBookingRequest(request['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadButton() {
    return ElevatedButton(
      onPressed: _uploadImage,
      child: const Text('Upload Image'),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      ),
    );
  }
}
