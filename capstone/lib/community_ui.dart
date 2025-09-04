import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'report_ui.dart';
import 'report_admin_ui.dart';

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
            return const Center(child: Text('data loading error'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('There is no post.'));
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
                child: _buildPostCard(data, docId, createdAt),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildPostCard(
      Map<String, dynamic> data, String docId, DateTime createdAt) {
    String incidentType = data['incidentType'] ?? '';
    String imageUrl = data['imageUrl'] ?? '';
    String title = data['title'] ?? '';
    String description = data['description'] ?? '';
    String location = data['location'] ?? '';
    String regionName = data['regionName'] ?? '';
    String writerName = data['writerName'] ?? '';
    String occurDate = data['occurDate'] ?? '';
    String occurTime = data['occurTime'] ?? '';

    Color backgroundColor = Colors.blue;
    IconData icon = Icons.info;

    switch (incidentType) {
      case 'Arson':
        backgroundColor = Colors.orange;
        icon = Icons.local_fire_department;
        break;
      case 'Assault':
        backgroundColor = Colors.blue;
        icon = Icons.emergency;
        break;
      case 'Robbery':
        backgroundColor = Colors.grey;
        icon = Icons.money_off;
        break;
      case 'Murder':
        backgroundColor = Colors.red;
        icon = Icons.dangerous;
        break;
      case 'Sexual Violence':
        backgroundColor = Colors.purple;
        icon = Icons.warning;
        break;
      case 'Drug':
        backgroundColor = Colors.teal;
        icon = Icons.medication;
        break;
    }

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
                    topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Text('Image not available'),
                            ),
                          ),
                        )
                      : Container(
                          height: 100,
                          color: Colors.grey.shade300,
                          child: const Center(child: Text('No image')),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        incidentType,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
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
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12),
                    const SizedBox(width: 4),
                    Text(regionName, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.person, size: 12),
                    const SizedBox(width: 4),
                    Text(writerName, style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Occur Time: $occurDate $occurTime',
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
                'Written: ${createdAt.toLocal().toString().split(' ')[0]}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
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

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        foregroundColor: Colors.white, // 화살표 및 아이콘 색
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 영역
                if ((post['imageUrl'] ?? '').isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      post['imageUrl'],
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Text('image is not available',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                // 제목
                Text(post['title'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    )),
                const SizedBox(height: 10),
                // 설명
                Text(post['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    )),
                const Divider(height: 32, thickness: 1.2),
                // 세부 정보
                _infoRow(Icons.category, "Incident Type", post['incidentType']),
                _infoRow(Icons.place, "Location", post['location']),
                _infoRow(Icons.map, "Region", post['regionName']),
                _infoRow(Icons.person, "Writer", post['writerName']),
                _infoRow(Icons.date_range, "Occur Date",
                    "${post['occurDate'] ?? ''} ${post['occurTime'] ?? ''}"),
                _infoRow(Icons.calendar_today, "Written",
                    showDate.toLocal().toString().split(' ')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 18),
          const SizedBox(width: 7),
          Text("$label: ",
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(
            child: Text(value?.toString() ?? '',
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
