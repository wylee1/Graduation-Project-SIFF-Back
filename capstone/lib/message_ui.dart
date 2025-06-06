import 'package:flutter/material.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({Key? key}) : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  // 샘플 데이터 (API 연동 시 setState로 갱신)
  List<Map<String, dynamic>> messages = [
    {
      'sender': 'Jongno-gu',
      'time': 'now',
      'content':
          'Earthquake disaster training message has been delivered.\nThis is a training message. It is not a real situation.\nThis is an error that occurred during the process of delivering a training message, not a real earthquake situation. We will fix it.',
    },
    {
      'sender': 'Forestry Service',
      'time': '3 hours ago',
      'content':
          "Today at 9 p.m., a landslide crisis warning level 'Caution' has been issued in Seoul and other areas.\nResidents and visitors in landslide-prone areas, etc. are requested to evacuate to a safe place in case of emergency.",
    },
    {
      'sender': 'Seoul Metropolitan Government',
      'time': '7 hours ago',
      'content':
          "Currently, an emergency accident has occurred in front ...", // 예시
    },
  ];

  // 메시지 삭제 함수
  void _removeMessage(int index) {
    setState(() {
      messages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 8),
          // 타이틀
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Emergency disaster message',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // 메시지 리스트
          Expanded(
            child: messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildMessageCard(
                          index: index,
                          sender: msg['sender'],
                          time: msg['time'],
                          content: msg['content'],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard({
    required int index,
    required String sender,
    required String time,
    required String content,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '[$sender]',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _removeMessage(index),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
