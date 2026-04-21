import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/dio_client.dart';
import '../models/chat_model.dart';

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier()
    : super([
        // Welcome message
        ChatMessage.bot(
          'আসসালামু আলাইকুম! 👋 আমি Brothers Assistant। '
          'আপনাকে furniture ও electronics সম্পর্কে সাহায্য করতে পারি। '
          'কী জানতে চান?',
        ),
      ]);

  bool _isTyping = false;
  bool get isTyping => _isTyping;

  // ── Send message ────────────────────────
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;

    // Add user message
    state = [...state, ChatMessage.user(text)];

    // Show typing indicator
    _isTyping = true;
    state = [...state, ChatMessage.loading()];

    try {
      // Build history (last 10 messages for context)
      final history = state
          .where((m) => !m.isLoading)
          .toList()
          .reversed
          .take(10)
          .toList()
          .reversed
          .map(
            (m) => {
              'role': m.sender == MessageSender.user ? 'user' : 'assistant',
              'content': m.text,
            },
          )
          .toList();

      final response = await DioClient.instance.post(
        '/chat',
        data: {'message': text, 'history': history},
      );

      final botReply =
          response.data['message']?.toString() ??
          'দুঃখিত, আমি এই মুহূর্তে উত্তর দিতে পারছি না।';

      // Remove loading, add bot message
      state = [...state.where((m) => !m.isLoading), ChatMessage.bot(botReply)];
    } catch (e) {
      state = [
        ...state.where((m) => !m.isLoading),
        ChatMessage.bot(
          'দুঃখিত, একটু সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন '
          'অথবা আমাদের hotline এ call করুন: 📞 01913987555',
        ),
      ];
    } finally {
      _isTyping = false;
    }
  }

  void clearChat() {
    state = [
      ChatMessage.bot(
        'আসসালামু আলাইকুম! 👋 নতুন conversation শুরু হয়েছে। কী জানতে চান?',
      ),
    ];
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>(
  (_) => ChatNotifier(),
);
