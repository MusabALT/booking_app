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

  // Color palette
  final Color primaryColor = const Color(0xFF3B5998); // Deep blue
  final Color accentColor = const Color(0xFF8C9EFF); // Soft blue
  final Color backgroundColor = const Color(0xFFF5F5F5); // Light gray
  final Color cardColor = Colors.white;

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

  Future<void> deleteAllRooms() async {
    try {
      setState(() {
        isLoading = true;
      });

      final batch = FirebaseFirestore.instance.batch();
      final roomDocs =
          await FirebaseFirestore.instance.collection('rooms').get();

      for (var room in rooms) {
        if (room.imagePath.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(room.imagePath).delete();
          } catch (e) {
            print('Error deleting image for room ${room.id}: $e');
          }
        }
        batch.delete(
            FirebaseFirestore.instance.collection('rooms').doc(room.id));
      }

      await batch.commit();
      await fetchRooms();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All rooms deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting rooms: $e')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteRoom(String roomId, String imagePath) async {
    try {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).delete();

      if (imagePath.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(imagePath).delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }

      await fetchRooms();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting room: $e')),
        );
      }
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
                      if (imageFile != null) {
                        final storageRef = FirebaseStorage.instance
                            .ref()
                            .child('room_images')
                            .child(
                                '${DateTime.now().millisecondsSinceEpoch}.jpg');

                        await storageRef.putFile(imageFile!);
                        newImagePath = await storageRef.getDownloadURL();
                      }

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

  Future<bool?> _showDeleteAllConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete All Rooms'),
          content: const Text(
            'Are you sure you want to delete all rooms? This action cannot be undone.',
            style: TextStyle(color: Colors.red),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Manage Rooms',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          if (rooms.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_forever, color: Colors.white),
              onPressed: () async {
                final confirmed = await _showDeleteAllConfirmation();
                if (confirmed == true) {
                  await deleteAllRooms();
                }
              },
              tooltip: 'Delete All Rooms',
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: primaryColor,
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchRooms,
              color: primaryColor,
              child: rooms.isEmpty
                  ? Center(
                      child: Text(
                        'No rooms available',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: rooms.length,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              )
                            ],
                          ),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            color: cardColor,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (room.imagePath.isNotEmpty)
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(15),
                                    ),
                                    child: Image.network(
                                      room.imagePath,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                        height: 200,
                                        color: backgroundColor,
                                        child: Icon(
                                          Icons.error,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        room.name,
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Floor: ${room.floor} | Capacity: ${room.capacity}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Prices: D: ${room.prices['D']} | E: ${room.prices['E']} | F: ${room.prices['F']}',
                                        style: TextStyle(
                                          color: accentColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: primaryColor,
                                        ),
                                        onPressed: () => _editRoom(room),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          final confirm = await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text(
                                                    'Confirm Delete'),
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
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
