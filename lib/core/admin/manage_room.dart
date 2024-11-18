import 'dart:io';
import 'package:booking_room/core/models/room.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ManageRoom extends StatefulWidget {
  const ManageRoom({super.key});

  @override
  State<ManageRoom> createState() => _ManageRoomState();
}

class _ManageRoomState extends State<ManageRoom> {
  List<Room> rooms = [];
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    fetchRooms();
  }

  Future<void> fetchRooms() async {
    try {
      final QuerySnapshot roomSnapshot =
          await FirebaseFirestore.instance.collection('rooms').get();

      setState(() {
        rooms = roomSnapshot.docs.map((doc) => Room.fromDocument(doc)).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching rooms: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteRoom(String roomId, String imagePath) async {
    try {
      // Delete from Firestore
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).delete();

      // Delete image from Storage if it exists
      if (imagePath.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(imagePath).delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }

      // Refresh the room list
      await fetchRooms();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting room: $e')),
      );
    }
  }

  Future<void> _editRoom(Room room) async {
    final nameController = TextEditingController(text: room.name);
    final floorController = TextEditingController(text: room.floor.toString());
    final capacityController =
        TextEditingController(text: room.capacity.toString());
    final priceControllerD =
        TextEditingController(text: room.prices['D'].toString());
    final priceControllerE =
        TextEditingController(text: room.prices['E'].toString());
    final priceControllerF =
        TextEditingController(text: room.prices['F'].toString());
    String? newImagePath = room.imagePath;
    File? imageFile;

    Future<void> updateImage() async {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          imageFile = File(image.path);
        });
      }
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Room'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await updateImage();
                        setState(() {});
                      },
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                        ),
                        child: imageFile != null
                            ? Image.file(imageFile!, fit: BoxFit.cover)
                            : (newImagePath != null && newImagePath!.isNotEmpty
                                ? Image.network(newImagePath!,
                                    fit: BoxFit.cover)
                                : const Icon(Icons.add_photo_alternate,
                                    size: 50)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Room Name'),
                    ),
                    TextField(
                      controller: floorController,
                      decoration: const InputDecoration(labelText: 'Floor'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: capacityController,
                      decoration: const InputDecoration(labelText: 'Capacity'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: priceControllerD,
                      decoration: const InputDecoration(labelText: 'Price (D)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: priceControllerE,
                      decoration: const InputDecoration(labelText: 'Price (E)'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: priceControllerF,
                      decoration: const InputDecoration(labelText: 'Price (F)'),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      // Upload new image if selected
                      if (imageFile != null) {
                        final storageRef = FirebaseStorage.instance
                            .ref()
                            .child('room_images')
                            .child(
                                '${DateTime.now().millisecondsSinceEpoch}.jpg');

                        await storageRef.putFile(imageFile!);
                        newImagePath = await storageRef.getDownloadURL();
                      }

                      // Update room data
                      final updatedRoom = {
                        'name': nameController.text,
                        'floor': int.parse(floorController.text),
                        'capacity': int.parse(capacityController.text),
                        'image_path': newImagePath,
                        'prices': {
                          'D': double.parse(priceControllerD.text),
                          'E': double.parse(priceControllerE.text),
                          'F': double.parse(priceControllerF.text),
                        },
                        'is_booked': room.isBooked,
                        'booking_date': room.bookingDate != null
                            ? Timestamp.fromDate(room.bookingDate!)
                            : null,
                        'booking_time': room.bookingTime,
                      };

                      await FirebaseFirestore.instance
                          .collection('rooms')
                          .doc(room.id)
                          .update(updatedRoom);

                      await fetchRooms();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Room updated successfully')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating room: $e')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Rooms'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchRooms,
              child: rooms.isEmpty
                  ? const Center(child: Text('No rooms available'))
                  : ListView.builder(
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          child: Column(
                            children: [
                              if (room.imagePath.isNotEmpty)
                                Image.network(
                                  room.imagePath,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error),
                                ),
                              ListTile(
                                title: Text(room.name),
                                subtitle: Text(
                                    'Floor: ${room.floor}\nCapacity: ${room.capacity}\nPrice (D): ${room.prices['D']}\nPrice (E): ${room.prices['E']}\nPrice (F): ${room.prices['F']}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () => _editRoom(room),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete),
                                      onPressed: () async {
                                        final confirm = await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title:
                                                  const Text('Confirm Delete'),
                                              content: const Text(
                                                  'Are you sure you want to delete this room?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, false),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                          context, true),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (confirm == true) {
                                          await deleteRoom(
                                              room.id, room.imagePath);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
