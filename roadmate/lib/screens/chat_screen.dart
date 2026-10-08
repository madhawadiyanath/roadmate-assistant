import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/service_request.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../theme/app_colors.dart';

/// One-to-one chat for a request: driver ↔ assigned mechanic.
class ChatScreen extends StatefulWidget {
  final ServiceRequest request;
  final String senderUid;
  final String senderName;
  final String senderRole;
  final String peerName;
  final ChatService? chatService;

  const ChatScreen({
    super.key,
    required this.request,
    required this.senderUid,
    required this.senderName,
    required this.senderRole,
    required this.peerName,
    this.chatService,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();

  /// State-owned edit controller: never disposed while the edit dialog's
  /// pop transition may still rebuild its TextField.
  final _editController = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  ChatService get _chat => widget.chatService ?? ChatService();

  @override
  void dispose() {
    _input.dispose();
    _editController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _chat.send(
        requestId: widget.request.id,
        senderUid: widget.senderUid,
        senderName: widget.senderName,
        senderRole: widget.senderRole,
        text: text,
      );
      _input.clear();
    } catch (e) {
      _snack(AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Long-press menu on own bubbles: edit or delete the message.
  Future<void> _bubbleMenu(ChatMessage m) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  color: AppColors.navy),
              title: const Text('Edit message'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: Colors.red),
              title: const Text('Delete message',
                  style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      await _editDialog(m);
    } else if (action == 'delete') {
      await _confirmDelete(m);
    }
  }

  Future<void> _editDialog(ChatMessage m) async {
    _editController.text = m.text;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(
          controller: _editController,
          autofocus: true,
          maxLines: 3,
          maxLength: 1000,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    try {
      await _chat.edit(
        requestId: widget.request.id,
        messageId: m.id,
        newText: _editController.text,
      );
    } catch (e) {
      _snack(AuthService.friendlyMessage(e));
    }
  }

  Future<void> _confirmDelete(ChatMessage m) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This removes it for both sides.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    try {
      await _chat.remove(
        requestId: widget.request.id,
        messageId: m.id,
      );
    } catch (e) {
      _snack(AuthService.friendlyMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final peer = widget.peerName.trim().isEmpty ? 'Chat' : widget.peerName.trim();
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.navy.withValues(alpha: 0.1),
              child: Text(
                peer[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    peer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyDark,
                    ),
                  ),
                  Text(
                    widget.request.refCode,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.greyText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _snack('Calling $peer…'),
            icon: const Icon(Icons.phone_outlined, color: AppColors.navy),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chat.watch(widget.request.id),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load chat.\n${snap.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.greyText, fontSize: 13),
                      ),
                    ),
                  );
                }
                final msgs = snap.data ?? [];
                if (msgs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Say hello — coordinate pickup and ETA here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.greyText, fontSize: 13),
                    ),
                  );
                }
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());
                return ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final m = msgs[i];
                    final mine = m.senderUid == widget.senderUid;
                    return _Bubble(
                      message: m,
                      mine: mine,
                      onLongPress:
                          mine ? () => _bubbleMenu(m) : null,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(color: Color(0xFFEDF1F7), width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: const TextStyle(
                          fontSize: 14.5, color: AppColors.navyDark),
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        hintStyle: const TextStyle(
                            color: AppColors.fieldHint, fontSize: 14),
                        filled: true,
                        fillColor: AppColors.fieldFill,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppColors.navy,
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(13),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;
  final VoidCallback? onLongPress;
  const _Bubble({
    required this.message,
    required this.mine,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: mine
              ? null
              : Border.all(color: const Color(0xFFEDF1F7), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  message.senderName,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orange,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                color: mine ? Colors.white : AppColors.navyDark,
              ),
            ),
            if (message.edited)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'edited',
                  style: TextStyle(
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    color: mine
                        ? Colors.white70
                        : AppColors.greyText,
                  ),
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}
