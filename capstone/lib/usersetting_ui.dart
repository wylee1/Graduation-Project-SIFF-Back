import 'package:flutter/material.dart';
import 'login_ui.dart';
import 'home_back.dart'; // Logout() 사용
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_language.dart';
import 'localizedtext.dart';
import 'translation_service.dart' show translateText;

class UserSettingScreen extends StatefulWidget {
  const UserSettingScreen({super.key});

  @override
  _UserSettingScreenState createState() => _UserSettingScreenState();
}

class _UserSettingScreenState extends State<UserSettingScreen> {
  // 현재 선택값(임시) — 적용 버튼 누르면 저장
  MapLanguage _temp = mapLanguageNotifier.value;

  String _label(MapLanguage lang) {
    switch (lang) {
      case MapLanguage.system: return 'System';
      case MapLanguage.ko:     return '한국어';
      case MapLanguage.en:     return 'English';
      case MapLanguage.ja:     return '日本語';
      case MapLanguage.zhCN:   return '简体中文';
    }
  }

  final List<MapLanguage> _options = const [
    MapLanguage.system, MapLanguage.ko, MapLanguage.en, MapLanguage.ja, MapLanguage.zhCN,
  ];

  // 입력 컨트롤러
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isEditingName = false;

  // 번역이 필요한 힌트/문구
  String _hintEnterName = 'Enter your name';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadEmailFromFirebase();
    mapLanguageNotifier.addListener(_onLanguageChanged);
    _translateHints(); // 최초 1회
  }

  @override
  void dispose() {
    mapLanguageNotifier.removeListener(_onLanguageChanged);
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    _translateHints();
    if (mounted) setState(() {});
  }

  Future<void> _translateHints() async {
    _hintEnterName = await translateText(
      'Enter your name',
      source: 'en',
      to: mapLanguageNotifier.value,
    );
    if (mounted) setState(() {});
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _nameController.text = prefs.getString('user_name_${user.uid}') ?? '';
      });
    }
  }

  Future<void> _saveName(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await prefs.setString('user_name_${user.uid}', value);
    }
  }

  void _loadEmailFromFirebase() {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _emailController.text = user?.email ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const LocalizedText(
          original: 'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white30,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              const LocalizedText(
                original: 'Profile Information',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 이름 섹션
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: const Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LocalizedText(
                          original: 'Name',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        _isEditingName
                            ? TextField(
                                controller: _nameController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: _hintEnterName, // 번역된 힌트
                                  isDense: true,
                                ),
                                onSubmitted: (value) {
                                  setState(() => _isEditingName = false);
                                  _saveName(value);
                                },
                                onEditingComplete: () {
                                  setState(() => _isEditingName = false);
                                  _saveName(_nameController.text);
                                },
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: _nameController.text.isNotEmpty
                                        ? Text(
                                            _nameController.text,
                                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                                          )
                                        : const LocalizedText(
                                            original: 'No name entered',
                                            style: TextStyle(fontSize: 16, color: Colors.grey),
                                          ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => setState(() => _isEditingName = true),
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 40),

              // 이메일 섹션
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 50, height: 50,
                    child: const Icon(Icons.alternate_email, size: 30),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LocalizedText(
                          original: 'Email',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _emailController.text.isNotEmpty ? _emailController.text : '',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 40),

              const LocalizedText(
                original: 'Language Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // 언어 선택 칩
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _options.map((opt) {
                    final bool selected = _temp == opt;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(_label(opt)),
                        selected: selected,
                        selectedColor: Colors.blue.shade100,
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(
                          color: selected ? Colors.blue : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _temp = opt),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 8),
              ValueListenableBuilder<MapLanguage>(
                valueListenable: mapLanguageNotifier,
                builder: (context, current, _) {
                  return Row(
                    children: [
                      const LocalizedText(
                        original: 'currently set to ',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      Text(
                        _label(current),
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  await setMapLanguage(_temp);
                  final msg = await translateText(
                    'Map language has been updated',
                    source: 'en',
                    to: mapLanguageNotifier.value,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(msg)),
                    );
                  }
                },
                child: const LocalizedText(original: 'Apply'),
              ),

              const SizedBox(height: 30),

              const LocalizedText(
                original: 'Others',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Row(
                children: const [
                  SizedBox(width: 50, height: 50, child: Icon(Icons.sync, size: 30)),
                  SizedBox(width: 10),
                  LocalizedText(
                    original: 'Data Synchronization',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const Divider(height: 40),

              Row(
                children: const [
                  SizedBox(width: 50, height: 50, child: Icon(Icons.info, size: 30)),
                  SizedBox(width: 10),
                  LocalizedText(
                    original: 'App Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const Divider(height: 40),

              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const LocalizedText(original: 'Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(150, 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () async {
                    await Logout();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
