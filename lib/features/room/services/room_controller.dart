import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/room_models.dart';
import 'room_api_service.dart';

class RoomController extends ChangeNotifier {
  RoomController() {
    clientId = _generateId();
    nickname = 'Guest-${_random.nextInt(9000) + 1000}';
    _messageController.addListener(_onMessageDraftChanged);
  }

  final RoomApiService _api = RoomApiService();
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

  late final String clientId;
  late final String nickname;
  RoomType selectedRoomType = RoomType.chat;
  int selectedMaxMembers = 2;
  RoomSession? currentRoom;
  final List<RoomMessage> messages = <RoomMessage>[];
  int memberCount = 1;
  CallMode callMode = CallMode.idle;
  bool isBusy = false;
  String? errorMessage;

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;

  TextEditingController get messageController => _messageController;
  bool get canSend => _messageController.text.trim().isNotEmpty && currentRoom != null && _channel != null;

  @override
  void dispose() {
    _messageController.removeListener(_onMessageDraftChanged);
    _messageController.dispose();
    _closeSocket();
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

  Future<RoomSession> createRoom({String? roomName}) async {
    return _runRoomAction(() async {
      final roomId = roomName?.trim().isNotEmpty == true ? roomName!.trim() : _generateRoomName();
      final roomData = await _api.createRoom(
        roomId: roomId,
        nickname: nickname,
        roomType: selectedRoomType,
        maxMembers: selectedMaxMembers,
      );
      _applyRoomResponse(roomData, roomIdFallback: roomId);
      await _connectAndJoin();
      return currentRoom!;
    });
  }

  Future<RoomSession> joinRoom(String rawInput) async {
    return _runRoomAction(() async {
      final parsed = _parseInvite(rawInput);
      final roomData = await _api.joinRoom(roomId: parsed.roomId, nickname: nickname);
      _applyRoomResponse(
        roomData,
        roomIdFallback: parsed.roomId,
        overrideRoomType: parsed.roomType,
        overrideMaxMembers: parsed.maxMembers,
      );
      await _connectAndJoin();
      return currentRoom!;
    });
  }

  Future<RoomSession> joinByScan(String rawValue) => joinRoom(rawValue);

  Future<void> startRoom() async {
    if (currentRoom == null) {
      return;
    }

    _appendSystemMessage('Room started. Waiting for others to join.');
    notifyListeners();
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentRoom == null || _channel == null) {
      return;
    }

    _channel!.sink.add(
      jsonEncode({
        'type': 'chat_message',
        'sender_id': clientId,
        'nickname': nickname,
        'message': text,
      }),
    );
    _messageController.clear();
    notifyListeners();
  }

  Future<void> toggleVoiceCall() async {
    await _sendCallState(callMode == CallMode.voice ? CallMode.idle : CallMode.voice);
  }

  Future<void> toggleVideoCall() async {
    await _sendCallState(callMode == CallMode.video ? CallMode.idle : CallMode.video);
  }

  Future<void> leaveRoom() async {
    final channel = _channel;
    if (channel != null && currentRoom != null) {
      channel.sink.add(
        jsonEncode({
          'type': 'participant_leave',
          'sender_id': clientId,
        }),
      );
    }

    await _closeSocket();
    currentRoom = null;
    messages.clear();
    memberCount = 1;
    callMode = CallMode.idle;
    _messageController.clear();
    notifyListeners();
  }

  void setError(String? value) {
    errorMessage = value;
    notifyListeners();
  }

  Future<RoomSession> _runRoomAction(Future<RoomSession> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await action();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _connectAndJoin() async {
    await _closeSocket();
    if (currentRoom == null) {
      return;
    }

    _channel = _api.connectRoomSocket(currentRoom!.roomId);
    _channelSubscription = _channel!.stream.listen(
      _handleSocketEvent,
      onError: (error) {
        errorMessage = error.toString();
        notifyListeners();
      },
      onDone: () {
        if (currentRoom != null) {
          callMode = CallMode.idle;
          notifyListeners();
        }
      },
    );

    _channel!.sink.add(
      jsonEncode({
        'type': 'participant_join',
        'sender_id': clientId,
        'nickname': nickname,
      }),
    );
  }

  void _handleSocketEvent(dynamic rawData) {
    if (rawData is! String) {
      return;
    }

    final decoded = jsonDecode(rawData);
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    final type = decoded['type'] as String? ?? '';

    switch (type) {
      case 'room_state':
        _applyRoomState(decoded);
        break;
      case 'room_participants':
        memberCount = (decoded['member_count'] as num?)?.toInt() ?? memberCount;
        break;
      case 'participant_join':
        final senderId = decoded['sender_id'] as String?;
        final senderNickname = decoded['nickname'] as String?;
        if (senderId != null && senderId != clientId && senderNickname != null) {
          _appendSystemMessage('$senderNickname joined the room.');
        }
        break;
      case 'participant_leave':
        final senderNickname = decoded['nickname'] as String?;
        if (senderNickname != null) {
          _appendSystemMessage('$senderNickname left the room.');
        }
        break;
      case 'chat_message':
        messages.add(RoomMessage.fromBackend(decoded, clientId: clientId));
        break;
      case 'webrtc_ready':
        final mode = (decoded['mode'] as String?)?.toLowerCase();
        callMode = mode == 'video' ? CallMode.video : CallMode.voice;
        final senderNickname = decoded['nickname'] as String?;
        if (senderNickname != null && decoded['sender_id'] != clientId) {
          _appendSystemMessage('$senderNickname started a ${callMode == CallMode.video ? 'video' : 'voice'} call.');
        }
        break;
      case 'webrtc_leave':
        callMode = CallMode.idle;
        final senderNickname = decoded['nickname'] as String?;
        if (senderNickname != null && decoded['sender_id'] != clientId) {
          _appendSystemMessage('$senderNickname ended the call.');
        }
        break;
      case 'webrtc_offer':
      case 'webrtc_answer':
      case 'webrtc_ice':
        break;
      default:
        break;
    }

    notifyListeners();
  }

  void _applyRoomResponse(
    Map<String, dynamic> roomData, {
    required String roomIdFallback,
    RoomType? overrideRoomType,
    int? overrideMaxMembers,
  }) {
    final roomId = (roomData['room_id'] as String?) ?? roomIdFallback;
    final roomType = overrideRoomType ?? _roomTypeFromValue(roomData['room_type'] as String? ?? selectedRoomType.name);
    final maxMembers = overrideMaxMembers ?? _intFromValue(roomData['max_members']) ?? selectedMaxMembers;

    currentRoom = RoomSession(
      roomId: roomId,
      roomName: roomId,
      roomType: roomType,
      maxMembers: maxMembers,
    );
    selectedRoomType = roomType;
    selectedMaxMembers = maxMembers;
    memberCount = ((roomData['users'] as List?)?.length ?? 1).clamp(1, maxMembers);

    messages
      ..clear()
      ..add(
        RoomMessage(
          sender: 'ChatSnap',
          text: 'Room ready. Share the invite link or QR code.',
          isMine: false,
          createdAt: DateTime.now(),
          isSystem: true,
        ),
      );
    callMode = CallMode.idle;
    notifyListeners();
  }

  void _applyRoomState(Map<String, dynamic> decoded) {
    final participants = (decoded['participants'] as List?) ?? const [];
    memberCount = (decoded['member_count'] as num?)?.toInt() ?? participants.length;

    final roomType = _roomTypeFromValue(decoded['room_type'] as String? ?? currentRoom?.roomType.name ?? selectedRoomType.name);
    final maxMembers = _intFromValue(decoded['max_members']) ?? currentRoom?.maxMembers ?? selectedMaxMembers;
    final roomId = decoded['room_id'] as String? ?? currentRoom?.roomId;

    if (roomId != null && currentRoom != null) {
      currentRoom = RoomSession(
        roomId: roomId,
        roomName: roomId,
        roomType: roomType,
        maxMembers: maxMembers,
      );
    }

    final backendMessages = (decoded['messages'] as List?) ?? const [];
    if (backendMessages.isNotEmpty) {
      messages
        ..clear()
        ..addAll(
          backendMessages
              .whereType<Map<String, dynamic>>()
              .map((item) => RoomMessage.fromBackend(item, clientId: clientId)),
        );
    }
  }

  Future<void> _sendCallState(CallMode nextMode) async {
    if (_channel == null || currentRoom == null) {
      return;
    }

    callMode = nextMode;
    final payload = <String, dynamic>{
      'sender_id': clientId,
      'nickname': nickname,
    };

    if (nextMode == CallMode.idle) {
      payload['type'] = 'webrtc_leave';
    } else {
      payload['type'] = 'webrtc_ready';
      payload['mode'] = nextMode == CallMode.video ? 'video' : 'voice';
    }

    _channel!.sink.add(jsonEncode(payload));
    notifyListeners();
  }

  void _appendSystemMessage(String text) {
    messages.add(
      RoomMessage(
        sender: 'ChatSnap',
        text: text,
        isMine: false,
        createdAt: DateTime.now(),
        isSystem: true,
      ),
    );
  }

  Future<void> _closeSocket() async {
    await _channelSubscription?.cancel();
    _channelSubscription = null;
    _channel?.sink.close();
    _channel = null;
  }

  void _onMessageDraftChanged() {
    notifyListeners();
  }

  String _generateRoomName() {
    final adjective = _adjectives[_random.nextInt(_adjectives.length)];
    final animal = _animals[_random.nextInt(_animals.length)];
    return '$adjective-$animal';
  }

  String _generateId() {
    return '${DateTime.now().millisecondsSinceEpoch}-${_random.nextInt(999999)}';
  }

  RoomType _roomTypeFromValue(String value) {
    return RoomType.values.firstWhere(
      (candidate) => candidate.name == value,
      orElse: () => RoomType.chat,
    );
  }

  int? _intFromValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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
        roomType = _roomTypeFromValue(type);
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
