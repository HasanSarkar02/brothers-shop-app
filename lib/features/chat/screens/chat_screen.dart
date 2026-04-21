import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/constants/app_colors.dart';
import '../models/chat_model.dart';
import '../providers/chat_provider.dart';

// Quick replies provider
final quickRepliesProvider = FutureProvider<List<Map<String, String>>>((
  ref,
) async {
  final response = await DioClient.instance.get('/chat/quick-replies');
  final data = response.data['data'] as List;
  return data
      .map(
        (e) => {
          'text': e['text'].toString(),
          'message': e['message'].toString(),
        },
      )
      .toList();
});

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showQuickReplies = true;

  @override
  void dispose() {
    _controller.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    setState(() => _showQuickReplies = false);
    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final quickReplies = ref.watch(quickRepliesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.ink,
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: AppColors.primary,
              child: Text(
                'B',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Brothers Assistant',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'সাধারণত সাথে সাথে reply করে',
                  style: TextStyle(fontSize: 10.sp, color: AppColors.green),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.inkLight,
            tooltip: 'Clear chat',
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
              setState(() => _showQuickReplies = true);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Divider(height: 1.h, color: AppColors.border),
        ),
      ),

      body: Column(
        children: [
          // ── Chat Messages ──────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: EdgeInsets.all(16.w),
              itemCount: messages.length,
              itemBuilder: (_, i) => _MessageBubble(
                message: messages[i],
                onProductTap: (url) {
                  /* open product */
                },
              ),
            ),
          ),

          // ── Quick Replies ──────────────────
          if (_showQuickReplies)
            quickReplies.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (replies) =>
                  _QuickReplies(replies: replies, onTap: (msg) => _send(msg)),
            ),

          // ── Input Bar ─────────────────────
          _InputBar(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

// ── Message Bubble ─────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(String) onProductTap;

  const _MessageBubble({required this.message, required this.onProductTap});

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          // Bot avatar
          if (!isUser) ...[
            CircleAvatar(
              radius: 14.r,
              backgroundColor: AppColors.primary,
              child: Text(
                'B',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: 8.w),
          ],

          // Message content
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(isUser ? 16.r : 4.r),
                  bottomRight: Radius.circular(isUser ? 4.r : 16.r),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.isLoading
                  ? _TypingIndicator()
                  : Text(
                      message.text,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: isUser ? Colors.white : AppColors.ink,
                        height: 1.5,
                      ),
                    ),
            ),
          ),

          // Timestamp
          if (!message.isLoading)
            Padding(
              padding: EdgeInsets.only(
                left: isUser ? 0 : 6.w,
                right: isUser ? 6.w : 0,
                bottom: 2.h,
              ),
              child: Text(
                _formatTime(message.timestamp),
                style: TextStyle(fontSize: 9.sp, color: AppColors.inkLight),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── Typing Indicator ───────────────────────────────
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _controllers.map((ctrl) {
        return AnimatedBuilder(
          animation: ctrl,
          builder: (_, __) => Container(
            width: 8.w,
            height: 8.h,
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            decoration: BoxDecoration(
              color: AppColors.inkLight.withOpacity(0.3 + ctrl.value * 0.7),
              shape: BoxShape.circle,
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Quick Replies ──────────────────────────────────
class _QuickReplies extends StatelessWidget {
  final List<Map<String, String>> replies;
  final Function(String) onTap;

  const _QuickReplies({required this.replies, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.h,
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: replies.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (_, i) {
          final reply = replies[i];
          return GestureDetector(
            onTap: () => onTap(reply['message']!),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                reply['text']!,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Input Bar ──────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;

  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16.w,
        8.h,
        16.w,
        MediaQuery.of(context).padding.bottom + 8.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: controller,
                maxLines: 3,
                minLines: 1,
                style: TextStyle(fontSize: 14.sp, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'আপনার প্রশ্ন লিখুন...',
                  hintStyle: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.inkLight,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                ),
                onSubmitted: onSend,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: () => onSend(controller.text),
            child: Container(
              width: 46.w,
              height: 46.h,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }
}
