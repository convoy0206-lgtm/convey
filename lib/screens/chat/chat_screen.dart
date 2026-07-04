import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/trip_model.dart';
import '../../models/message_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final TripModel trip;

  const ChatScreen({
    super.key,
    required this.trip,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    try {
      final user = ref.read(authServiceProvider).currentUser;
      if (user == null) return;

      final message = MessageModel(
        id: '',
        senderId: user.uid,
        senderName: user.displayName,
        text: text,
        timestamp: DateTime.now(),
        type: 'text',
      );

      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.sendMessage(widget.trip.id, message);
      
      // Scroll to bottom
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final currentUser = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Squad Chat'),
            Text(
              widget.trip.name,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages stream list view
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: firestoreService.streamMessages(widget.trip.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        const Text('No messages yet. Start coordinates sync convo!'),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUser?.uid;

                    return _buildMessageBubble(theme, msg, isMe);
                  },
                );
              },
            ),
          ),

          // Message Composer Card Input
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send_outlined),
                  color: theme.colorScheme.primary,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ThemeData theme, MessageModel msg, bool isMe) {
    final isSystemAlert = msg.type == 'location_alert' || msg.type == 'speed_alert';
    
    if (isSystemAlert) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.error.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.senderName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    msg.text,
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe 
              ? theme.colorScheme.primary.withOpacity(0.85) 
              : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMe) ...[
              Text(
                msg.senderName,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              msg.text,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white54, fontSize: 9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
