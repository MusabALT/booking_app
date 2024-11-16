import 'dart:io';

import 'package:booking_room/core/admin/admin_view_calender_screen.dart';
import 'package:booking_room/core/admin/request_screen.dart';
import 'package:booking_room/core/helper/spacing.dart';
import 'package:booking_room/core/routing/routes.dart';
import 'package:booking_room/core/widgets/app_text_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddNewRoom extends StatefulWidget {
  const AddNewRoom({super.key});

  @override
  _AddNewRoomState createState() => _AddNewRoomState();
}

class _AddNewRoomState extends State<AddNewRoom> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  late String name, floor, capacity;
  late String priceD = '', priceE = '', priceF = '';
  XFile? _roomImage;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _roomImage = image;
      });
    }
  }

  Future<String> _uploadImage(XFile image) async {
    Reference storageReference =
        _storage.ref().child('room_images/${image.path}');
    UploadTask uploadTask = storageReference.putFile(File(image.path));
    await uploadTask;
    return await storageReference.getDownloadURL();
  }

  Future<void> _addRoom() async {
    if (_roomImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image'),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      try {
        String imageUrl = await _uploadImage(_roomImage!);

        await _firestore.collection('rooms').add({
          'name': name,
          'image_path': imageUrl,
          'floor': int.tryParse(floor) ?? 0,
          'prices': {
            'D': double.tryParse(priceD) ?? 0.0,
            'E': double.tryParse(priceE) ?? 0.0,
            'F': double.tryParse(priceF) ?? 0.0,
          },
          'is_booked': false,
          'capacity': 0,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room added successfully'),
          ),
        );

        setState(() {
          _roomImage = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add room: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Room'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                onChanged: (value) => name = value,
                decoration: const InputDecoration(
                  labelText: 'Room Name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              verticalSpace(20),
              TextFormField(
                onChanged: (value) => floor = value,
                decoration: const InputDecoration(
                  labelText: 'floor',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a floor';
                  }
                  return null;
                },
              ),
              verticalSpace(20),
              TextFormField(
                onChanged: (value) => capacity = value,
                decoration: const InputDecoration(
                  labelText: 'capacity',
                  icon: Icon(Icons.people),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a capacity';
                  }
                  return null;
                },
              ),
              const Text(
                'Price Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              verticalSpace(10),
              TextFormField(
                onChanged: (value) => priceD = value,
                decoration: const InputDecoration(
                  labelText: 'Category D Price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Category D price';
                  }
                  return null;
                },
              ),
              verticalSpace(10),
              TextFormField(
                onChanged: (value) => priceE = value,
                decoration: const InputDecoration(
                  labelText: 'Category E Price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Category E price';
                  }
                  return null;
                },
              ),
              verticalSpace(10),
              TextFormField(
                onChanged: (value) => priceF = value,
                decoration: const InputDecoration(
                  labelText: 'Category F Price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter Category F price';
                  }
                  return null;
                },
              ),
              verticalSpace(20),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Select Room Image'),
              ),
              const SizedBox(height: 10),
              _roomImage == null
                  ? const Text('No image selected')
                  : Image.file(File(_roomImage!.path)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addRoom,
                child: const Text('Add Room'),
              ),
              verticalSpace(20),
              AppTextButton(
                buttonText: 'view requests',
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const AdminBookingRequestsScreen()),
                  );
                },
              ),
              verticalSpace(20),
              AppTextButton(
                buttonText: 'View Calendar',
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const AdminCalendarScreen()),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
