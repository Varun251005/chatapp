enum RoomType { chat, voice, video }

enum CallMode { idle, voice, video }

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
      'https://chatsnap.app/room/$roomId?type=${roomType.name}&max=$maxMembers';

  String get qrPayload => inviteLink;
}
