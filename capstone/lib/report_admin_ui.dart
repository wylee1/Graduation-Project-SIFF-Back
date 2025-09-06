import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ▼ 번역/언어 상태
import 'app_language.dart';
import 'translation_service.dart' show translateText, translateMany;
import 'localizedtext.dart';

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
    final messenger = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const LocalizedText(
          original: 'Report Admin Page',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white30,
        scrolledUnderElevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getPendingReportsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: LocalizedText(original: 'data loading error'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: LocalizedText(original: 'No pending reports.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final report = docs[index].data() as Map<String, dynamic>;
              final docId  = docs[index].id;

              final title = (report['title'] ?? '').toString();
              final desc  = (report['description'] ?? '').toString();

              // 카드 안 텍스트를 현재 언어로 번역 (제목/본문)
              return ValueListenableBuilder<MapLanguage>(
                valueListenable: mapLanguageNotifier,
                builder: (_, lang, __) {
                  final fut = translateMany(
                    texts: [title, desc],
                    source: 'auto',
                    to: lang,
                  );

                  return FutureBuilder<List<String>>(
                    future: fut,
                    builder: (_, snap) {
                      final tTitle = (snap.data?.isNotEmpty ?? false) ? snap.data![0] : title;
                      final tDesc  = (snap.data?.length ?? 0) > 1 ? snap.data![1] : desc;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tTitle,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tDesc,
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    child: const LocalizedText(original: 'View details'),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => DetailDialog(report: report),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 16),
                                  TextButton(
                                    child: const LocalizedText(
                                      original: 'Reject',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () async {
                                      final ok = await updateReportStatus(docId, 'rejected');
                                      if (ok) {
                                        final msg = await translateText(
                                          'Report has been rejected',
                                          source: 'en',
                                          to: mapLanguageNotifier.value,
                                        );
                                        messenger.showSnackBar(SnackBar(content: Text(msg)));
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    child: const LocalizedText(
                                      original: 'Approve',
                                      style: TextStyle(color: Colors.green),
                                    ),
                                    onPressed: () async {
                                      final ok = await updateReportStatus(docId, 'approved');
                                      if (ok) {
                                        final msg = await translateText(
                                          'Report has been approved',
                                          source: 'en',
                                          to: mapLanguageNotifier.value,
                                        );
                                        messenger.showSnackBar(SnackBar(content: Text(msg)));
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
    final title       = (report['title']        ?? '').toString();
    final description = (report['description']  ?? '').toString();
    final incident    = (report['incidentType'] ?? '').toString();
    final location    = (report['location']     ?? '').toString();
    final occurDate   = (report['occurDate']    ?? '').toString();
    final occurTime   = (report['occurTime']    ?? '').toString();
    final region      = (report['regionName']   ?? '').toString();
    final writer      = (report['writerName']   ?? '').toString();
    final imageUrl    = (report['imageUrl']     ?? '').toString();

    // 값(제목/본문/필드값)을 한 번에 번역
    return ValueListenableBuilder<MapLanguage>(
      valueListenable: mapLanguageNotifier,
      builder: (_, lang, __) {
        final fut = translateMany(
          texts: [
            title, description, incident, location,
            occurDate, occurTime, region, writer
          ],
          source: 'auto',
          to: lang,
        );

        return FutureBuilder<List<String>>(
          future: fut,
          builder: (_, snap) {
            final list = snap.data ?? const <String>[];
            String tTitle = list.length > 0 ? list[0] : title;
            String tDesc  = list.length > 1 ? list[1] : description;
            String tInc   = list.length > 2 ? list[2] : incident;
            String tLoc   = list.length > 3 ? list[3] : location;
            String tDate  = list.length > 4 ? list[4] : occurDate;
            String tTime  = list.length > 5 ? list[5] : occurTime;
            String tReg   = list.length > 6 ? list[6] : region;
            String tWriter= list.length > 7 ? list[7] : writer;

            return AlertDialog(
              title: Text(tTitle),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 120,
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: LocalizedText(
                                original: 'Image load failed',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 6),
                    _infoRow(const LocalizedText(original: 'Description'), tDesc),
                    _infoRow(const LocalizedText(original: 'Incident Type'), tInc),
                    _infoRow(const LocalizedText(original: 'Location'), tLoc),
                    _infoRow(const LocalizedText(original: 'Occur Date'), '$tDate $tTime'),
                    _infoRow(const LocalizedText(original: 'Region'), tReg),
                    _infoRow(const LocalizedText(original: 'Writer'), tWriter),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const LocalizedText(original: 'Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _infoRow(Widget label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DefaultTextStyle.merge(
            style: const TextStyle(fontWeight: FontWeight.bold),
            child: label,
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
