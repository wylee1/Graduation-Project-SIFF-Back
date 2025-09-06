import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminApprovalPage extends StatefulWidget {
  const AdminApprovalPage({Key? key}) : super(key: key);

  @override
  _AdminApprovalPageState createState() => _AdminApprovalPageState();
}

class _AdminApprovalPageState extends State<AdminApprovalPage> {
  // pending 상태 신고글 스트림
  Stream<QuerySnapshot> getPendingReportsStream() {
    return FirebaseFirestore.instance
        .collection('report_community')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 상태 변경 함수
  Future<bool> updateReportStatus(String docId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('report_community')
          .doc(docId)
          .update({
        'status': status,
        'approvedAt': status == 'approved' ? FieldValue.serverTimestamp() : null
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 상위 ScaffoldMessengerContext를 미리 저장
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Report Admin Page',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white30,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getPendingReportsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('에러: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('대기 중인 신고글이 없습니다.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final report = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['title'] ?? '제목 없음',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report['description'] ?? '내용 없음',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: const Text('상세보기'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => DetailDialog(report: report),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            child: const Text('거절',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () async {
                              bool success =
                                  await updateReportStatus(docId, 'rejected');
                              if (success) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('신고글 거절 처리 완료'),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            child: const Text('승인',
                                style: TextStyle(color: Colors.green)),
                            onPressed: () async {
                              bool success =
                                  await updateReportStatus(docId, 'approved');
                              if (success) {
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('신고글 승인 처리 완료'),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DetailDialog extends StatelessWidget {
  final Map<String, dynamic> report;
  const DetailDialog({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(report['title'] ?? '제목 없음'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((report['imageUrl'] ?? '').isNotEmpty)
              Image.network(
                report['imageUrl'],
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Text('이미지 로드 실패',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  );
                },
              ),
            const SizedBox(height: 6),
            Text('설명: ${report['description'] ?? ''}'),
            Text('사건 유형: ${report['incidentType'] ?? ''}'),
            Text('지역: ${report['location'] ?? ''}'),
            Text('발생일: ${report['occurDate'] ?? ''}'),
            Text('발생시각: ${report['occurTime'] ?? ''}'),
            Text('행정구역: ${report['regionName'] ?? ''}'),
            Text('작성자: ${report['writerName'] ?? ''}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // 닫기
          },
          child: const Text('닫기'),
        ),
      ],
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 51cf02f248c1b6bbe042457f403d2a4e7ac953b1
