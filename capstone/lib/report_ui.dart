import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ▼ 번역/언어 상태
import 'app_language.dart';
import 'translation_service.dart' show translateText, translateMany;
import 'localizedtext.dart';

class ReportUI extends StatefulWidget {
  const ReportUI({Key? key}) : super(key: key);

  @override
  State<ReportUI> createState() => _ReportUIState();
}

class _ReportUIState extends State<ReportUI> {
  // 드롭다운: 영어 원본(저장용) + 화면표시용(번역)
  final List<String> _crimeTypesEn = const [
    'Arson',
    'Assault',
    'Robbery',
    'Murder',
    'Sexual Violence',
    'Drug',
    'Etc',
  ];
  List<String> _crimeTypesDisp = []; // 번역된 표시용
  String? _selectedCrimeTypeEn; // 선택 값은 영어 원본으로 유지 (DB 저장용)

  // 텍스트 컨트롤러
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();

  // 이미지/상태
  File? _pickedImage;
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();

  // ==== 번역된 라벨/힌트/버튼/문구 ====
  String _appBarTitle = 'Create New Report';
  String _labelCrimeType = 'Crime Type';
  String _labelDateOfOccurrence = 'Date of Occurrence';
  String _labelTimeOfOccurrence = 'Time of Occurrence';
  String _labelTitle = 'Title';
  String _labelBriefDescription = 'Brief Description';
  String _labelAddress = 'Address';
  String _labelRegion = 'Region';
  String _tapToSelectImage = 'Tap to select an image';
  String _btnSubmitReport = 'Submit Report';

  String _msgPleaseSelectType = 'Please select a crime type';
  String _msgImageUploadFailed = 'Image upload failed. Please try again.';
  String _msgReportSubmitted = 'Report submitted successfully.';
  String _msgErrorSubmitting = 'Error submitting report';

  @override
  void initState() {
    super.initState();
    // 최초 번역
    _translateAllUI();
    // 언어 변경 시 재번역
    mapLanguageNotifier.addListener(_onLangChanged);
  }

  @override
  void dispose() {
    mapLanguageNotifier.removeListener(_onLangChanged);
    _dateController.dispose();
    _timeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  void _onLangChanged() {
    _translateAllUI();
  }

  Future<void> _translateAllUI() async {
    final lang = mapLanguageNotifier.value;

    // 드롭다운 항목은 한 번에
    final types =
        await translateMany(texts: _crimeTypesEn, source: 'en', to: lang);

    // 라벨/힌트/버튼/문구는 개별 또는 일부 묶음
    final ui1 = await translateMany(
      texts: [
        'Create New Report',
        'Crime Type',
        'Date of Occurrence',
        'Time of Occurrence',
        'Title',
        'Brief Description',
        'Address',
        'Region',
        'Tap to select an image',
        'Submit Report',
      ],
      source: 'en',
      to: lang,
    );

    final ui2 = await translateMany(
      texts: [
        'Please select a crime type',
        'Image upload failed. Please try again.',
        'Report submitted successfully.',
        'Error submitting report',
      ],
      source: 'en',
      to: lang,
    );

    if (!mounted) return;
    setState(() {
      _crimeTypesDisp = types;
      _appBarTitle = ui1.elementAt(0);
      _labelCrimeType = ui1.elementAt(1);
      _labelDateOfOccurrence = ui1.elementAt(2);
      _labelTimeOfOccurrence = ui1.elementAt(3);
      _labelTitle = ui1.elementAt(4);
      _labelBriefDescription = ui1.elementAt(5);
      _labelAddress = ui1.elementAt(6);
      _labelRegion = ui1.elementAt(7);
      _tapToSelectImage = ui1.elementAt(8);
      _btnSubmitReport = ui1.elementAt(9);

      _msgPleaseSelectType = ui2.elementAt(0);
      _msgImageUploadFailed = ui2.elementAt(1);
      _msgReportSubmitted = ui2.elementAt(2);
      _msgErrorSubmitting = ui2.elementAt(3);
    });
  }

  bool _isPickingImage = false;

  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;
    try {
      final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('이미지 선택 에러: $e');
    } finally {
      _isPickingImage = false;
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final fileName =
          'reports/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);

      final snapshot = await ref.putFile(imageFile);
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (_) {
      return null;
    }
  }

  Future<void> _submitReport() async {
    if (_selectedCrimeTypeEn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_msgPleaseSelectType)),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await _uploadImage(_pickedImage!);
        if (imageUrl == null || imageUrl.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_msgImageUploadFailed)),
          );
          setState(() => _isSubmitting = false);
          return;
        }
      }

      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email ?? '';
      final writerName = email.contains('@') ? email.split('@')[0] : '';

      await FirebaseFirestore.instance.collection('report_community').add({
        'title': _titleController.text.trim(),
        'incidentType': _selectedCrimeTypeEn!, // ★ 영어 원본 저장
        'occurDate': _dateController.text.trim(),
        'occurTime': _timeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _addressController.text.trim(),
        'regionName': _regionController.text.trim(),
        'imageUrl': imageUrl ?? '',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'writerId': user?.uid ?? '',
        'writerName': writerName,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_msgReportSubmitted)),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      final msg = '$_msgErrorSubmitting: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          labelText: _labelDateOfOccurrence,
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
                setState(() => _dateController.text = formattedDate);
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
          labelText: _labelTimeOfOccurrence,
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
                setState(() => _timeController.text = formattedTime);
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
  Widget build(BuildContext context) {
    // 표시용 드롭다운 라벨(번역된 리스트) 준비
    final itemsDisp =
        (_crimeTypesDisp.isNotEmpty) ? _crimeTypesDisp : _crimeTypesEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _appBarTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                  labelText: _labelCrimeType,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                value: _selectedCrimeTypeEn,
                items: List.generate(_crimeTypesEn.length, (i) {
                  final en = _crimeTypesEn[i];
                  final disp = itemsDisp[i];
                  return DropdownMenuItem<String>(
                    value: en, // 값은 영어 원본
                    child: Text(disp), // 표시 텍스트는 번역본
                  );
                }),
                onChanged: (val) => setState(() => _selectedCrimeTypeEn = val),
              ),
            ),

            _buildDatePickerField(),
            _buildTimePickerField(),
            _buildTextField(_titleController, _labelTitle),
            _buildTextField(_descriptionController, _labelBriefDescription),
            _buildTextField(_addressController, _labelAddress),
            _buildTextField(_regionController, _labelRegion),

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
                      ? Center(child: Text(_tapToSelectImage))
                      : Image.file(_pickedImage!, fit: BoxFit.cover),
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
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_btnSubmitReport),
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
