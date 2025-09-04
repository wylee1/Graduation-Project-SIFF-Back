import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReportUI extends StatefulWidget {
  const ReportUI({Key? key}) : super(key: key);

  @override
  State<ReportUI> createState() => _ReportUIState();
}

class _ReportUIState extends State<ReportUI> {
  String? _selectedCrimeType;
  final List<String> _crimeTypes = [
    'Arson',
    'Assault',
    'Robbery',
    'Murder',
    'Sexual Violence',
    'Drug',
    'Etc',
  ];

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  File? _pickedImage;
  bool _isSubmitting = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final fileName =
          'reports/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;

      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Image upload error: $e');
      return null;
    }
  }

  Future<void> _submitReport() async {
    if (_selectedCrimeType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a crime type')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(_pickedImage!);
        if (imageUrl == null || imageUrl.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed. Please try again.')),
          );
          setState(() {
            _isSubmitting = false;
          });
          return; // 이미지 업로드 실패시 제출 중단
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email ?? '';
      final writerName = email.contains('@') ? email.split('@')[0] : '';

      await FirebaseFirestore.instance.collection('report_community').add({
        'title': _titleController.text.trim(),
        'incidentType': _selectedCrimeType!,
        'occurDate': _dateController.text.trim(),
        'occurTime': _timeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _addressController.text.trim(),
        'regionName': _regionController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'writerId': user?.uid ?? '',
        'writerName': writerName, // 자동으로 작성자 이메일 아이디 저장
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully.'),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting report: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  // 발생일 달력 선택 위젯
  Widget _buildDatePickerField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _dateController,
        keyboardType: TextInputType.datetime,
        readOnly: true,
        decoration: InputDecoration(
          labelText: "Date of Occurrence",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                final formattedDate =
                    "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                setState(() {
                  _dateController.text = formattedDate;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  // 발생 시간 선택 위젯
  Widget _buildTimePickerField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _timeController,
        keyboardType: TextInputType.datetime,
        readOnly: true,
        decoration: InputDecoration(
          labelText: "Time of Occurrence",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: () async {
              final pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (pickedTime != null) {
                final formattedTime = pickedTime.format(context);
                setState(() {
                  _timeController.text = formattedTime;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create New Report',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white30,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crime Type Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Crime Type",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                value: _selectedCrimeType,
                items: _crimeTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCrimeType = val;
                  });
                },
              ),
            ),

            _buildDatePickerField(),
            _buildTimePickerField(),
            _buildTextField(_titleController, "Title"),
            _buildTextField(_descriptionController, "Brief Description"),
            _buildTextField(_addressController, "Address"),
            _buildTextField(_regionController, "Region"),

            const SizedBox(height: 16),

            // 이미지 업로드 영역
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _pickedImage == null
                      ? const Center(
                          child: Text('Tap to select an image'),
                        )
                      : Image.file(
                          _pickedImage!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit Report'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
