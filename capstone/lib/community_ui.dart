import 'package:flutter/material.dart';
import 'report_ui.dart'; // ReportUI 가져오기

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Community',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // 신고서 생성 버튼에 onTap 기능 추가
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReportUI()),
                    );
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.note_alt_outlined),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Create',
                            style: TextStyle(fontSize: 12),
                          ),
                          Text(
                            'New Incidence Report',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                        child: _buildPostCard(
                            'Arson', 'street.jpg', '3 hours ago')),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildPostCard(
                            'Assault', 'alley.jpg', '2 days ago')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildPostCard('Robbery', 'alley.jpg', '')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildPostCard('Arson', 'street.jpg', '')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(String incidentType, String imageName, String timeAgo) {
    Color backgroundColor = Colors.blue;
    IconData icon = Icons.info;

    // 사건 유형에 따른 색상과 아이콘 설정
    if (incidentType == 'Arson') {
      backgroundColor = Colors.orange;
      icon = Icons.local_fire_department;
    } else if (incidentType == 'Assault') {
      backgroundColor = Colors.blue;
      icon = Icons.emergency;
    } else if (incidentType == 'Robbery') {
      backgroundColor = Colors.grey;
      icon = Icons.money_off;
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
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: AspectRatio(
                  aspectRatio: 3 / 2,
                  child: Image.asset(
                    'assets/images/$imageName',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Center(child: Text('Image not available')),
                      );
                    },
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
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Post Title',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(Icons.location_on, size: 12),
                    SizedBox(width: 4),
                    Text('Region Name', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  children: const [
                    Icon(Icons.person, size: 12),
                    SizedBox(width: 4),
                    Text('Username', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          if (timeAgo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  'Posted $timeAgo',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
