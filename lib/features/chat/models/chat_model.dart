enum MessageSender { user, bot }

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isLoading = false,
  });

  factory ChatMessage.user(String text) => ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    text: text,
    sender: MessageSender.user,
    timestamp: DateTime.now(),
  );

  factory ChatMessage.bot(String text, {bool isLoading = false}) => ChatMessage(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    text: text,
    sender: MessageSender.bot,
    timestamp: DateTime.now(),
    isLoading: isLoading,
  );

  factory ChatMessage.loading() => ChatMessage.bot('...', isLoading: true);
}
