enum RoomType { chat, voice, video }

enum CallMode { idle, voice, video }

const String roomShareBaseUrl = 'http://127.0.0.1:8000';

extension RoomTypeX on RoomType {
  String get label {
    switch (this) {
      case RoomType.chat:
        return 'Chat';
      case RoomType.voice:
        return 'Voice';
      case RoomType.video:
        return 'Video';
    }
  }
}

class RoomMessage {
  const RoomMessage({
    required this.sender,
    required this.text,
    required this.isMine,
    required this.createdAt,
    this.isSystem = false,
  });

  final String sender;
  final String text;
  final bool isMine;
  final DateTime createdAt;
  final bool isSystem;

  factory RoomMessage.fromBackend(
    Map<String, dynamic> json, {
    required String clientId,
  }) {
    return RoomMessage(
      sender: (json['nickname'] as String?)?.trim().isNotEmpty == true
          ? (json['nickname'] as String).trim()
          : 'Unknown',
      text: (json['message'] as String?)?.trim() ?? '',
      isMine: (json['sender_id'] as String?) == clientId,
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? '') ?? DateTime.now(),
      isSystem: (json['message_type'] as String?) == 'system',
    );
  }
}

class RoomSession {
  RoomSession({
    required this.roomId,
    required this.roomName,
    required this.roomType,
    required this.maxMembers,
  });

  final String roomId;
  final String roomName;
  final RoomType roomType;
  final int maxMembers;

  String get inviteLink =>
      '$roomShareBaseUrl/room/$roomId?type=${roomType.name}&max=$maxMembers';

  String get qrPayload => inviteLink;
}
