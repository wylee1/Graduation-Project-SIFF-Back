import 'package:flutter/material.dart';
import 'message_api.dart';
import 'translation_service.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({Key? key}) : super(key: key);

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}
class MessageList extends StatelessWidget {
  const MessageList({super.key, required this.messages});
  final List<Map<String, dynamic>> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: messages.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = messages[i];
        final sender  = (m['sender']  ?? '') as String;
        final content = (m['content'] ?? '') as String; // 원문(ko) 가정

        return ListTile(
          title: Text(sender),
          subtitle: TranslatedText(
            content,
            source: 'ko', // 원문 언어(필요 시 변경/감지)
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          dense: true,
        );
      },
    );
  }
}
class _MessageScreenState extends State<MessageScreen> {
  // 샘플 데이터 (API 연동 시 setState로 갱신)
  List<Map<String, dynamic>> messages = [];

  @override
  void initState() {
    super.initState();
    _loadDisasterMessages();
  }

  Future<void> _loadDisasterMessages() async {
    final fetchedMessages = await fetchDisasterMessages();
    setState(() {
      messages = fetchedMessages;
    });
  }

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
            TranslatedText(
              content,
              source: 'ko', // 재난문자 원문이 한국어라고 가정
              // 필요하면 줄 수 제한/ellipsis 추가 가능:
              // maxLines: 6,
              // overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
