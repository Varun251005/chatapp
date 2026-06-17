import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../models/room_models.dart';

class RoomController extends ChangeNotifier {
  RoomController() {
    _messageController.addListener(notifyListeners);
  }

  final Random _random = Random();
  final TextEditingController _messageController = TextEditingController();
  final List<String> _adjectives = const [
    'blue',
    'amber',
    'silver',
    'quiet',
    'soft',
    'sunny',
    'midnight',
    'coral',
  ];
  final List<String> _animals = const [
    'tiger',
    'falcon',
    'otter',
    'panda',
    'lynx',
    'fox',
    'dove',
    'wolf',
  ];

  RoomType selectedRoomType = RoomType.chat;
  int selectedMaxMembers = 2;
  RoomSession? currentRoom;
  final List<RoomMessage> messages = <RoomMessage>[];
  int memberCount = 1;
  CallMode callMode = CallMode.idle;

  TextEditingController get messageController => _messageController;
  bool get canSend => _messageController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _messageController.removeListener(notifyListeners);
    _messageController.dispose();
    super.dispose();
  }

  void setRoomType(RoomType value) {
    selectedRoomType = value;
    notifyListeners();
  }

  void setMaxMembers(int value) {
    selectedMaxMembers = value;
    notifyListeners();
  }

  RoomSession createRoom() {
    final roomName = _generateRoomName();
    currentRoom = RoomSession(
      roomId: roomName,
      roomName: roomName,
      roomType: selectedRoomType,
      maxMembers: selectedMaxMembers,
    );
    memberCount = 1;
    callMode = CallMode.idle;
    messages
      ..clear()
      ..add(
        RoomMessage(
          sender: 'ChatSnap',
          text: 'Room created. Share the invite link or QR code.',
          isMine: false,
          createdAt: DateTime.now(),
          isSystem: true,
        ),
      );
    notifyListeners();
    return currentRoom!;
  }

  void startRoom() {
    if (currentRoom == null) return;
    messages.add(
      RoomMessage(
        sender: 'ChatSnap',
        text: 'Room started. Waiting for others to join.',
        isMine: false,
        createdAt: DateTime.now(),
        isSystem: true,
      ),
    );
    notifyListeners();
  }

  void joinRoom(String rawInput) {
    final parsed = _parseInvite(rawInput);
    currentRoom = RoomSession(
      roomId: parsed.roomId,
      roomName: parsed.roomName,
      roomType: parsed.roomType,
      maxMembers: parsed.maxMembers,
    );
    memberCount = min(currentRoom!.maxMembers, 2);
    callMode = CallMode.idle;
    messages
      ..clear()
      ..add(
        RoomMessage(
          sender: 'ChatSnap',
          text: 'Joined ${currentRoom!.roomName}.',
          isMine: false,
          createdAt: DateTime.now(),
          isSystem: true,
        ),
      );
    notifyListeners();
  }

  void joinByScan(String rawValue) => joinRoom(rawValue);

  void sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentRoom == null) return;
    messages.add(
      RoomMessage(
        sender: 'You',
        text: text,
        isMine: true,
        createdAt: DateTime.now(),
      ),
    );
    _messageController.clear();
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 650), () {
      if (currentRoom == null) return;
      messages.add(
        RoomMessage(
          sender: 'Room Bot',
          text: 'Received: $text',
          isMine: false,
          createdAt: DateTime.now(),
        ),
      );
      memberCount = min(currentRoom!.maxMembers, memberCount + 1);
      notifyListeners();
    });
  }

  void toggleVoiceCall() {
    callMode = callMode == CallMode.voice ? CallMode.idle : CallMode.voice;
    if (callMode == CallMode.voice) {
      messages.add(
        RoomMessage(
          sender: 'ChatSnap',
          text: 'Voice call started.',
          isMine: false,
          createdAt: DateTime.now(),
          isSystem: true,
        ),
      );
    }
    notifyListeners();
  }

  void toggleVideoCall() {
    callMode = callMode == CallMode.video ? CallMode.idle : CallMode.video;
    if (callMode == CallMode.video) {
      messages.add(
        RoomMessage(
          sender: 'ChatSnap',
          text: 'Video call started.',
          isMine: false,
          createdAt: DateTime.now(),
          isSystem: true,
        ),
      );
    }
    notifyListeners();
  }

  void leaveRoom() {
    currentRoom = null;
    messages.clear();
    memberCount = 1;
    callMode = CallMode.idle;
    _messageController.clear();
    notifyListeners();
  }

  String _generateRoomName() {
    final adjective = _adjectives[_random.nextInt(_adjectives.length)];
    final animal = _animals[_random.nextInt(_animals.length)];
    return '$adjective-$animal';
  }

  _ParsedInvite _parseInvite(String rawInput) {
    final trimmed = rawInput.trim();
    final uri = Uri.tryParse(trimmed);

    RoomType roomType = RoomType.chat;
    int maxMembers = 4;
    String roomId = trimmed;

    if (uri != null) {
      final type = uri.queryParameters['type'];
      if (type != null) {
        roomType = RoomType.values.firstWhere(
          (candidate) => candidate.name == type,
          orElse: () => RoomType.chat,
        );
      }

      final max = uri.queryParameters['max'];
      if (max != null) {
        maxMembers = int.tryParse(max) ?? 4;
      }

      final segments = uri.pathSegments;
      final roomIndex = segments.indexOf('room');
      if (roomIndex >= 0 && roomIndex + 1 < segments.length) {
        roomId = segments[roomIndex + 1];
      } else if (segments.isNotEmpty) {
        roomId = segments.last;
      }
    }

    final roomName = roomId.contains('-') ? roomId : _generateRoomName();
    return _ParsedInvite(
      roomId: roomId,
      roomName: roomName,
      roomType: roomType,
      maxMembers: maxMembers,
    );
  }
}

class _ParsedInvite {
  const _ParsedInvite({
    required this.roomId,
    required this.roomName,
    required this.roomType,
    required this.maxMembers,
  });

  final String roomId;
  final String roomName;
  final RoomType roomType;
  final int maxMembers;
}
