import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_ui.dart';
import 'report_admin_ui.dart';
import 'app_language.dart';
import 'translation_service.dart';
import 'localizedtext.dart';

// 관리자 UID 리스트
final List<String> adminUids = [
  '2jMlIFBtRDN6CrHyXM0rmiyLOiY2', // 실제 관리자 UID로 교체
];

// 관리자 권한 여부 확인 함수
bool isAdminUser() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  return adminUids.contains(user.uid);
}

// 승인된 게시글 스트림
Stream<QuerySnapshot> getCommunityReportsStream() {
  return FirebaseFirestore.instance
      .collection('report_community')
      .where('status', isEqualTo: 'approved')
      .orderBy('createdAt', descending: true)
      .snapshots();
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool admin = isAdminUser();

    return Scaffold(
      floatingActionButton: admin
          ? FloatingActionButton(
              heroTag: "admin_approval_button",
              backgroundColor: Colors.red,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminApprovalPage()),
                );
              },
              child: const Icon(Icons.admin_panel_settings),
            )
          : FloatingActionButton(
              heroTag: "community_add_button",
              backgroundColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReportUI()),
                );
              },
              child: const Icon(Icons.add),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: StreamBuilder<QuerySnapshot>(
        stream: getCommunityReportsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: LocalizedText(original: 'data loading error'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: LocalizedText(original: 'There is no post.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              // 안전하게 Timestamp -> DateTime 변환
              DateTime createdAt;
              final raw = data['createdAt'];
              if (raw is Timestamp) {
                createdAt = raw.toDate();
              } else if (raw is DateTime) {
                createdAt = raw;
              } else {
                createdAt = DateTime.now();
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailPage(post: {
                        ...data,
                        'createdAt': createdAt,
                      }),
                    ),
                  );
                },
                child: _PostCard(data: data, docId: docId, createdAt: createdAt),
              );
            },
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.data,
    required this.docId,
    required this.createdAt,
  });

  final Map<String, dynamic> data;
  final String docId;
  final DateTime createdAt;

  // 뱃지/아이콘은 원문 기준으로 결정 (번역값 쓰면 매칭이 깨질 수 있음)
  (Color, IconData) _styleByIncident(String incidentType) {
    switch (incidentType) {
      case 'Arson':
        return (Colors.orange, Icons.local_fire_department);
      case 'Assault':
        return (Colors.blue, Icons.emergency);
      case 'Robbery':
        return (Colors.grey, Icons.money_off);
      case 'Murder':
        return (Colors.red, Icons.dangerous);
      case 'Sexual Violence':
        return (Colors.purple, Icons.warning);
      case 'Drug':
        return (Colors.teal, Icons.medication);
      default:
        return (Colors.blue, Icons.info);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 원문 값들
    final incidentType = (data['incidentType'] ?? '').toString();
    final imageUrl     = (data['imageUrl']     ?? '').toString();
    final title        = (data['title']        ?? '').toString();
    final description  = (data['description']  ?? '').toString();
    final location     = (data['location']     ?? '').toString();
    final regionName   = (data['regionName']   ?? '').toString();
    final writerName   = (data['writerName']   ?? '').toString();
    final occurDate    = (data['occurDate']    ?? '').toString();
    final occurTime    = (data['occurTime']    ?? '').toString();

    final (bgColor, icon) = _styleByIncident(incidentType);

    // 번역: 한 번의 호출로 필요한 텍스트 모두 처리
    return ValueListenableBuilder<MapLanguage>(
      valueListenable: mapLanguageNotifier,
      builder: (_, lang, __) {
        final fut = translateMany(
          texts: [
            incidentType,          // 0
            title,                 // 1
            description,           // 2
            regionName,            // 3
            writerName,            // 4
            'Occur Time: $occurDate $occurTime',  // 5
            'Written: ${createdAt.toLocal().toString().split(' ')[0]}', // 6
          ],
          source: 'auto',
          to: lang,
        );

        return FutureBuilder<List<String>>(
          future: fut,
          builder: (_, snap) {
            final list = snap.data ?? const <String>[];
            String tIncident   = list.length > 0 ? list[0] : incidentType;
            String tTitle      = list.length > 1 ? list[1] : title;
            String tDesc       = list.length > 2 ? list[2] : description;
            String tRegion     = list.length > 3 ? list[3] : regionName;
            String tWriter     = list.length > 4 ? list[4] : writerName;
            String tOccurLabel = list.length > 5 ? list[5] : 'Occur Time: $occurDate $occurTime';
            String tWritten    = list.length > 6 ? list[6] : 'Written: ${createdAt.toLocal().toString().split(' ')[0]}';

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        child: AspectRatio(
                          aspectRatio: 3 / 2,
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey.shade300,
                                    child: const Center(
                                      child: LocalizedText(original: 'Image not available'),
                                    ),
                                  ),
                                )
                              : Container(
                                  height: 100,
                                  color: Colors.grey.shade300,
                                  child: const Center(child: LocalizedText(original: 'No image')),
                                ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                tIncident,
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tDesc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 12),
                            const SizedBox(width: 4),
                            Text(tRegion, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 12),
                            const SizedBox(width: 4),
                            Text(tWriter, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tOccurLabel,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        tWritten,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class PostDetailPage extends StatelessWidget {
  final Map<String, dynamic> post;
  const PostDetailPage({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    DateTime showDate;
    final raw = post['createdAt'];
    if (raw is Timestamp) {
      showDate = raw.toDate();
    } else if (raw is DateTime) {
      showDate = raw;
    } else {
      showDate = DateTime.now();
    }

    final title       = (post['title']        ?? '').toString();
    final description = (post['description']  ?? '').toString();
    final incident    = (post['incidentType'] ?? '').toString();
    final location    = (post['location']     ?? '').toString();
    final region      = (post['regionName']   ?? '').toString();
    final writer      = (post['writerName']   ?? '').toString();
    final occurDate   = (post['occurDate']    ?? '').toString();
    final occurTime   = (post['occurTime']    ?? '').toString();
    final imageUrl    = (post['imageUrl']     ?? '').toString();

    // 번역: 상세 화면에서도 한 번에 처리
    return ValueListenableBuilder<MapLanguage>(
      valueListenable: mapLanguageNotifier,
      builder: (_, lang, __) {
        final fut = translateMany(
          texts: [
            title, description, incident, location, region, writer,
            'Occur Date: $occurDate $occurTime',
            'Written: ${showDate.toLocal().toString().split(' ')[0]}',
          ],
          source: 'auto',
          to: lang,
        );

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          body: FutureBuilder<List<String>>(
            future: fut,
            builder: (_, snap) {
              final list = snap.data ?? const <String>[];
              String tTitle   = list.length > 0 ? list[0] : title;
              String tBody    = list.length > 1 ? list[1] : description;
              String tInc     = list.length > 2 ? list[2] : incident;
              String tLoc     = list.length > 3 ? list[3] : location;
              String tRegion  = list.length > 4 ? list[4] : region;
              String tWriter  = list.length > 5 ? list[5] : writer;
              String tOccur   = list.length > 6 ? list[6] : 'Occur Date: $occurDate $occurTime';
              String tWritten = list.length > 7 ? list[7] : 'Written: ${showDate.toLocal().toString().split(' ')[0]}';

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 200,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: LocalizedText(
                                    original: 'image is not available',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 18),

                        // 제목
                        Text(
                          tTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 설명
                        Text(
                          tBody,
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        const Divider(height: 32, thickness: 1.2),

                        _infoRow(Icons.category, const LocalizedText(original: "Incident Type"), tInc),
                        _infoRow(Icons.place,    const LocalizedText(original: "Location"),      tLoc),
                        _infoRow(Icons.map,      const LocalizedText(original: "Region"),        tRegion),
                        _infoRow(Icons.person,   const LocalizedText(original: "Writer"),        tWriter),
                        _infoRow(Icons.date_range, const LocalizedText(original: "Occur Date"),  tOccur.replaceFirst(RegExp(r'^Occur Date:\s*'), '')),
                        _infoRow(Icons.calendar_today, const LocalizedText(original: "Written"),  tWritten.replaceFirst(RegExp(r'^Written:\s*'), '')),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, Widget label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 18),
          const SizedBox(width: 7),
          DefaultTextStyle.merge(
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            child: label,
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
