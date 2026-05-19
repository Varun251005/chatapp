import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'theme/app_theme.dart';
import 'theme/colors.dart';
import 'theme/spacing.dart';

void main() {
  runApp(const ChatApp());
}

const Color _bgTop = Color(0xFF0F1226);
const Color _bgBottom = Color(0xFF090B15);
const Color _panelColor = Color(0xFF141A2F);
const Color _panelBorder = Color(0xFF2D355F);
const Color _primaryPurple = Color(0xFF6C5CF6);
const Color _textPrimary = Color(0xFFEAF0FF);
const Color _textMuted = Color(0xFF98A2C7);
const Color _boardBgColor = Color(0xFFFFFEFD);

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room Chat App',
      theme: AppTheme.lightTheme(),
      home: const NicknameScreen(),
    );
  }
}

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key});

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _nicknameController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _continueToLobby() {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a nickname')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LobbyScreen(nickname: nickname)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 56,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text('Room'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.lg),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'DEBUG',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 350),
                builder: (context, value, child) {
                  return Opacity(opacity: value, child: child);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline,
                          color: AppColors.accent,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Enter your nickname',
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'This is how others will see you in the room.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      controller: _nicknameController,
                      hintText: 'Type your nickname',
                      prefixIcon: Icons.person_outline,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: 'Continue',
                      onPressed: _continueToLobby,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key, required this.nickname});

  final String nickname;

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final roomData = await ApiService.createRoom(widget.nickname);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomScreen(
            nickname: widget.nickname,
            roomId: roomData['room_id'] as String,
            roomLink: roomData['room_link'] as String,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _joinRoom() async {
    final input = _linkController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a room link or room ID')),
      );
      return;
    }

    final roomId = _extractRoomId(input);
    if (roomId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid room link')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.joinRoom(roomId, widget.nickname);
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomScreen(
            nickname: widget.nickname,
            roomId: roomId,
            roomLink: '/room/$roomId',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _extractRoomId(String value) {
    if (value.contains('/room/')) {
      final parts = value.split('/room/');
      return parts.last.trim();
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Room'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: AppSpacing.lg),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'DEBUG',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 350),
                builder: (context, value, child) {
                  return Opacity(opacity: value, child: child);
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          shape: BoxShape.circle,
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: const Icon(
                          Icons.groups_outlined,
                          color: AppColors.accent,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      "Let's connect!",
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Create a new room or join an existing one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    ActionCard(
                      icon: Icons.add,
                      title: 'Create a Room',
                      description: 'Start a new room and invite others.',
                      onTap: _isLoading ? null : _createRoom,
                      trailing: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_ios, size: 16),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ActionCard(
                      icon: Icons.meeting_room_outlined,
                      title: 'Join a Room',
                      description: 'Enter a room link or ID to join.',
                      child: Column(
                        children: [
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _linkController,
                            hintText: 'Enter room link or ID',
                            prefixIcon: Icons.link,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PrimaryButton(
                            label: 'Join Room',
                            onPressed: _isLoading ? null : _joinRoom,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoomScreen extends StatefulWidget {
  const RoomScreen({
    super.key,
    required this.nickname,
    required this.roomId,
    required this.roomLink,
  });

  final String nickname;
  final String roomId;
  final String roomLink;

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _PeerState {
  _PeerState({required this.connection, required this.renderer});

  final RTCPeerConnection connection;
  final RTCVideoRenderer renderer;
}

enum _BoardTool { pen, pencil, marker, eraser, rect, circle, text }

String _toolKey(_BoardTool tool) {
  switch (tool) {
    case _BoardTool.pen:
      return 'pen';
    case _BoardTool.pencil:
      return 'pencil';
    case _BoardTool.marker:
      return 'marker';
    case _BoardTool.eraser:
      return 'eraser';
    case _BoardTool.rect:
      return 'rect';
    case _BoardTool.circle:
      return 'circle';
    case _BoardTool.text:
      return 'text';
  }
}

_BoardTool _toolFromKey(String? value) {
  switch (value) {
    case 'pencil':
      return _BoardTool.pencil;
    case 'marker':
      return _BoardTool.marker;
    case 'eraser':
      return _BoardTool.eraser;
    case 'rect':
      return _BoardTool.rect;
    case 'circle':
      return _BoardTool.circle;
    case 'text':
      return _BoardTool.text;
    case 'pen':
    default:
      return _BoardTool.pen;
  }
}

class _BoardPoint {
  const _BoardPoint(this.x, this.y);

  final double x;
  final double y;

  Offset toOffset(Size size) {
    return Offset(x * size.width, y * size.height);
  }
}

abstract class _BoardItem {
  const _BoardItem();
}

class _BoardStroke extends _BoardItem {
  _BoardStroke({
    required this.tool,
    required this.points,
    required this.color,
    required this.width,
    required this.opacity,
  });

  final _BoardTool tool;
  final List<_BoardPoint> points;
  final Color color;
  final double width;
  final double opacity;
}

class _BoardShape extends _BoardItem {
  _BoardShape({
    required this.tool,
    required this.start,
    required this.end,
    required this.color,
    required this.width,
    required this.opacity,
  });

  final _BoardTool tool;
  _BoardPoint start;
  _BoardPoint end;
  final Color color;
  final double width;
  final double opacity;
}

class _BoardText extends _BoardItem {
  _BoardText({
    required this.position,
    required this.text,
    required this.color,
    required this.size,
  });

  final _BoardPoint position;
  final String text;
  final Color color;
  final double size;
}

class _RoomScreenState extends State<RoomScreen> {
  late final WebSocketChannel _channel;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];

  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  MediaStream? _screenStream;
  final Map<String, _PeerState> _peers = {};
  late final String _clientId;
  bool _isInCall = false;
  bool _isMuted = false;
  bool _isMutedByHost = false;
  bool _isCameraOn = true;
  bool _isVideoMode = true;
  bool _isScreenSharing = false;
  bool _lowBandwidthMode = false;
  final List<_BoardItem> _boardItems = [];
  final Map<String, _BoardStroke> _remoteStrokes = {};
  final Map<String, _BoardShape> _remoteShapes = {};
  _BoardStroke? _activeStroke;
  _BoardShape? _activeShape;
  _BoardTool _selectedTool = _BoardTool.pen;
  Color _selectedColor = Colors.white;
  static const double _textToolSize = 16;
  List<Map<String, dynamic>> _participants = [];
  String? _hostNickname;
  bool _presentationMode = false;
  int _mobileTabIndex = 0;
  bool _showChatPanel = true;

  static const int _maxUsersInCall = 6;

  @override
  void initState() {
    super.initState();
    _clientId = '${widget.nickname}-${DateTime.now().millisecondsSinceEpoch}';
    _initRenderers();
    _channel = WebSocketChannel.connect(
      Uri.parse('${ApiService.wsBaseUrl}${widget.roomId}/'),
    );

    _channel.stream.listen((data) {
      final payload = jsonDecode(data as String) as Map<String, dynamic>;
      _handleSocketPayload(payload);
    });

    _registerInRoom();
  }

  @override
  void dispose() {
    _disposeVoiceResources();
    _localRenderer.dispose();
    _messageController.dispose();
    _channel.sink.close();
    super.dispose();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
  }

  void _disposeVoiceResources() {
    for (final peer in _peers.values) {
      peer.connection.close();
      peer.renderer.dispose();
    }
    _peers.clear();

    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    for (final track in _screenStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    _localStream?.dispose();
    _screenStream?.dispose();
    _localStream = null;
    _screenStream = null;
    _localRenderer.srcObject = null;

    _isInCall = false;
    _isMuted = false;
    _isCameraOn = _isVideoMode;
    _isScreenSharing = false;
  }

  void _handleSocketPayload(Map<String, dynamic> payload) {
    final payloadType = payload['type']?.toString();

    if (payloadType != null && payloadType.startsWith('room_')) {
      _handleRoomControlPayload(payload);
      return;
    }

    if (payloadType != null && payloadType.startsWith('webrtc_')) {
      _handleSignalingMessage(payload);
      return;
    }

    if (payloadType != null && payloadType.startsWith('whiteboard_')) {
      _handleWhiteboardPayload(payload);
      return;
    }

    final nickname = payload['nickname']?.toString() ?? 'Unknown';
    final message = payload['message']?.toString() ?? '';
    if (!mounted) return;
    setState(() {
      _messages.add({'nickname': nickname, 'message': message});
    });
  }

  void _registerInRoom() {
    _channel.sink.add(
      jsonEncode({
        'type': 'room_register',
        'sender_id': _clientId,
        'nickname': widget.nickname,
      }),
    );
  }

  bool get _isHost => _hostNickname == widget.nickname;

  void _handleRoomControlPayload(Map<String, dynamic> payload) {
    final payloadType = payload['type']?.toString() ?? '';

    if (payloadType == 'room_state') {
      final targetId = payload['target_id']?.toString();
      if (targetId != null && targetId != _clientId) {
        return;
      }

      final host = payload['host']?.toString();
      final presentationMode = payload['presentation_mode'] == true;
      final mutedUsers = ((payload['muted_users'] as List?) ?? [])
          .map((item) => item.toString())
          .toList();

      if (!mounted) return;
      setState(() {
        _hostNickname = host;
        _presentationMode = presentationMode;
      });

      final forcedMuted =
          mutedUsers.contains(widget.nickname) ||
          (_presentationMode && !_isHost);
      _applyHostMute(forcedMuted);
      return;
    }

    if (payloadType == 'room_participants') {
      final participants = (payload['participants'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _participants = participants
            .whereType<Map>()
            .map(
              (item) =>
                  item.map((key, value) => MapEntry(key.toString(), value)),
            )
            .toList();
      });
      return;
    }

    if (payloadType == 'room_user_muted') {
      final targetId = payload['target_id']?.toString();
      if (targetId != _clientId) return;
      final muted = payload['muted'] == true;
      _applyHostMute(muted);
      return;
    }

    if (payloadType == 'room_kicked') {
      final targetId = payload['target_id']?.toString();
      if (targetId != _clientId) return;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You were removed by host')));
      Navigator.of(context).pop();
    }
  }

  void _applyHostMute(bool muted) {
    final stream = _localStream;
    if (stream == null) {
      if (mounted) {
        setState(() {
          _isMutedByHost = muted;
          if (muted) _isMuted = true;
        });
      }
      return;
    }

    for (final track in stream.getAudioTracks()) {
      track.enabled = !muted;
    }

    if (!mounted) return;
    setState(() {
      _isMutedByHost = muted;
      _isMuted = muted ? true : _isMuted;
    });
  }

  void _sendHostAction(Map<String, dynamic> payload) {
    _channel.sink.add(
      jsonEncode({
        ...payload,
        'sender_id': _clientId,
        'nickname': widget.nickname,
      }),
    );
  }

  void _setPresentationMode(bool enabled) {
    if (!_isHost) return;
    _sendHostAction({'type': 'host_set_presentation_mode', 'enabled': enabled});
  }

  void _muteUser(String targetId, bool muted) {
    if (!_isHost) return;
    _sendHostAction({
      'type': 'host_mute_user',
      'target_id': targetId,
      'muted': muted,
    });
  }

  void _kickUser(String targetId) {
    if (!_isHost) return;
    _sendHostAction({'type': 'host_kick_user', 'target_id': targetId});
  }

  void _handleWhiteboardPayload(Map<String, dynamic> payload) {
    final senderId = payload['sender_id']?.toString() ?? '';
    if (senderId == _clientId) return;

    final payloadType = payload['type']?.toString() ?? '';

    if (payloadType == 'whiteboard_clear') {
      if (!mounted) return;
      setState(() {
        _boardItems.clear();
        _remoteStrokes.clear();
        _remoteShapes.clear();
      });
      return;
    }

    if (payloadType != 'whiteboard_draw') return;

    final action = payload['action']?.toString() ?? 'move';
    final tool = _toolFromKey(payload['tool']?.toString());

    if (tool == _BoardTool.text && action == 'commit') {
      final x = (payload['x'] as num?)?.toDouble();
      final y = (payload['y'] as num?)?.toDouble();
      final text = payload['text']?.toString().trim() ?? '';
      if (x == null || y == null || text.isEmpty) return;
      final colorValue = (payload['color'] as int?) ?? Colors.white.value;
      final size = (payload['size'] as num?)?.toDouble() ?? _textToolSize;

      if (!mounted) return;
      setState(() {
        _boardItems.add(
          _BoardText(
            position: _BoardPoint(x, y),
            text: text,
            color: Color(colorValue),
            size: size,
          ),
        );
      });
      return;
    }

    final x = (payload['x'] as num?)?.toDouble();
    final y = (payload['y'] as num?)?.toDouble();
    if (x == null || y == null) return;

    final colorValue = (payload['color'] as int?) ?? Colors.white.value;
    final width = (payload['width'] as num?)?.toDouble() ?? 2;
    final opacity = (payload['opacity'] as num?)?.toDouble() ?? 1;
    final color = Color(colorValue);

    if (tool == _BoardTool.rect || tool == _BoardTool.circle) {
      if (action == 'start') {
        final shape = _BoardShape(
          tool: tool,
          start: _BoardPoint(x, y),
          end: _BoardPoint(x, y),
          color: color,
          width: width,
          opacity: opacity,
        );
        _remoteShapes[senderId] = shape;
        if (!mounted) return;
        setState(() {
          _boardItems.add(shape);
        });
        return;
      }

      final shape = _remoteShapes[senderId];
      if (shape == null) return;
      if (!mounted) return;
      setState(() {
        shape.end = _BoardPoint(x, y);
        if (action == 'end') {
          _remoteShapes.remove(senderId);
        }
      });
      return;
    }

    if (action == 'start') {
      final stroke = _BoardStroke(
        tool: tool,
        points: [_BoardPoint(x, y)],
        color: color,
        width: width,
        opacity: opacity,
      );
      _remoteStrokes[senderId] = stroke;
      if (!mounted) return;
      setState(() {
        _boardItems.add(stroke);
      });
      return;
    }

    final stroke = _remoteStrokes[senderId];
    if (stroke == null) return;
    if (!mounted) return;
    setState(() {
      stroke.points.add(_BoardPoint(x, y));
      if (action == 'end') {
        _remoteStrokes.remove(senderId);
      }
    });
  }

  void _onBoardPanStart(DragStartDetails details, Size size) {
    if (_selectedTool == _BoardTool.text) return;

    final point = _normalizeBoardPoint(details.localPosition, size);
    if (point == null) return;

    if (_selectedTool == _BoardTool.rect || _selectedTool == _BoardTool.circle) {
      final shape = _BoardShape(
        tool: _selectedTool,
        start: point,
        end: point,
        color: _toolColor(_selectedTool),
        width: _toolWidth(_selectedTool),
        opacity: _toolOpacity(_selectedTool),
      );
      _activeShape = shape;
      setState(() {
        _boardItems.add(shape);
      });
      _sendWhiteboardDraw(
        action: 'start',
        point: point,
        tool: _selectedTool,
        color: shape.color,
        width: shape.width,
        opacity: shape.opacity,
      );
      return;
    }

    final stroke = _BoardStroke(
      tool: _selectedTool,
      points: [point],
      color: _toolColor(_selectedTool),
      width: _toolWidth(_selectedTool),
      opacity: _toolOpacity(_selectedTool),
    );
    _activeStroke = stroke;
    setState(() {
      _boardItems.add(stroke);
    });
    _sendWhiteboardDraw(
      action: 'start',
      point: point,
      tool: stroke.tool,
      color: stroke.color,
      width: stroke.width,
      opacity: stroke.opacity,
    );
  }

  void _onBoardPanUpdate(DragUpdateDetails details, Size size) {
    if (_selectedTool == _BoardTool.text) return;

    final point = _normalizeBoardPoint(details.localPosition, size);
    if (point == null) return;

    if (_activeShape != null) {
      setState(() {
        _activeShape!.end = point;
      });
      _sendWhiteboardDraw(
        action: 'move',
        point: point,
        tool: _activeShape!.tool,
      );
      return;
    }

    if (_activeStroke == null) return;
    setState(() {
      _activeStroke!.points.add(point);
    });
    _sendWhiteboardDraw(
      action: 'move',
      point: point,
      tool: _activeStroke!.tool,
    );
  }

  void _onBoardPanEnd() {
    if (_activeShape != null) {
      final shape = _activeShape!;
      _sendWhiteboardDraw(action: 'end', point: shape.end, tool: shape.tool);
      _activeShape = null;
      return;
    }

    if (_activeStroke != null) {
      final stroke = _activeStroke!;
      final lastPoint = stroke.points.isNotEmpty ? stroke.points.last : null;
      if (lastPoint != null) {
        _sendWhiteboardDraw(
          action: 'end',
          point: lastPoint,
          tool: stroke.tool,
        );
      }
      _activeStroke = null;
    }
  }

  _BoardPoint? _normalizeBoardPoint(Offset offset, Size size) {
    if (size.width <= 0 || size.height <= 0) return null;
    final x = (offset.dx / size.width).clamp(0.0, 1.0);
    final y = (offset.dy / size.height).clamp(0.0, 1.0);
    return _BoardPoint(x, y);
  }

  void _sendWhiteboardDraw({
    required String action,
    required _BoardPoint point,
    required _BoardTool tool,
    Color? color,
    double? width,
    double? opacity,
  }) {
    final payload = <String, dynamic>{
      'type': 'whiteboard_draw',
      'action': action,
      'tool': _toolKey(tool),
      'x': point.x,
      'y': point.y,
      'sender_id': _clientId,
      'nickname': widget.nickname,
    };

    if (color != null) payload['color'] = color.value;
    if (width != null) payload['width'] = width;
    if (opacity != null) payload['opacity'] = opacity;

    _channel.sink.add(jsonEncode(payload));
  }

  Future<void> _addTextAt(Offset localOffset, Size size) async {
    final point = _normalizeBoardPoint(localOffset, size);
    if (point == null) return;

    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121A33),
          title: const Text('Add text'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Type text'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    final value = text?.trim() ?? '';
    if (value.isEmpty) return;

    setState(() {
      _boardItems.add(
        _BoardText(
          position: point,
          text: value,
          color: _selectedColor,
          size: _textToolSize,
        ),
      );
    });

    _channel.sink.add(
      jsonEncode({
        'type': 'whiteboard_draw',
        'action': 'commit',
        'tool': _toolKey(_BoardTool.text),
        'x': point.x,
        'y': point.y,
        'text': value,
        'color': _selectedColor.value,
        'size': _textToolSize,
        'sender_id': _clientId,
        'nickname': widget.nickname,
      }),
    );
  }

  void _clearBoard() {
    setState(() {
      _boardItems.clear();
      _remoteStrokes.clear();
      _remoteShapes.clear();
      _activeStroke = null;
      _activeShape = null;
    });

    _channel.sink.add(
      jsonEncode({
        'type': 'whiteboard_clear',
        'sender_id': _clientId,
        'nickname': widget.nickname,
      }),
    );
  }

  double _toolWidth(_BoardTool tool) {
    switch (tool) {
      case _BoardTool.pencil:
        return 2;
      case _BoardTool.marker:
        return 8;
      case _BoardTool.eraser:
        return 16;
      case _BoardTool.rect:
      case _BoardTool.circle:
        return 3;
      case _BoardTool.text:
        return 0;
      case _BoardTool.pen:
      default:
        return 3;
    }
  }

  double _toolOpacity(_BoardTool tool) {
    switch (tool) {
      case _BoardTool.pencil:
        return 0.6;
      case _BoardTool.marker:
        return 0.35;
      default:
        return 1.0;
    }
  }

  Color _toolColor(_BoardTool tool) {
    if (tool == _BoardTool.eraser) return _boardBgColor;
    return _selectedColor;
  }

  Future<void> _handleSignalingMessage(Map<String, dynamic> payload) async {
    final senderId = payload['sender_id']?.toString() ?? '';
    if (senderId.isEmpty || senderId == _clientId) return;
    if (!_isInCall) return;

    final targetId = payload['target_id']?.toString();
    if (targetId != null && targetId != _clientId) {
      return;
    }

    final messageType = payload['type']?.toString() ?? '';

    if (messageType == 'webrtc_ready') {
      if (_peers.containsKey(senderId)) return;
      if (_peers.length >= _maxUsersInCall - 1) return;

      await _createPeerConnection(senderId, createOffer: true);
      return;
    }

    if (messageType == 'webrtc_leave') {
      await _removePeer(senderId);
      return;
    }

    if (messageType == 'webrtc_offer') {
      final peer = await _createPeerConnection(senderId);
      if (peer == null) return;

      final sdp = payload['sdp']?.toString() ?? '';
      if (sdp.isEmpty) return;

      await peer.connection.setRemoteDescription(
        RTCSessionDescription(sdp, 'offer'),
      );

      final answer = await peer.connection.createAnswer({
        'offerToReceiveAudio': 1,
        'offerToReceiveVideo': 1,
      });
      await peer.connection.setLocalDescription(answer);

      _sendSignalMessage({
        'type': 'webrtc_answer',
        'target_id': senderId,
        'sdp': answer.sdp,
      });
      return;
    }

    if (messageType == 'webrtc_answer') {
      final peer = _peers[senderId];
      final sdp = payload['sdp']?.toString() ?? '';
      if (peer != null && sdp.isNotEmpty) {
        await peer.connection.setRemoteDescription(
          RTCSessionDescription(sdp, 'answer'),
        );
      }
      return;
    }

    if (messageType == 'webrtc_ice') {
      final candidateMap = payload['candidate'];
      final peer = _peers[senderId];
      if (candidateMap is Map<String, dynamic> && peer != null) {
        final candidate = candidateMap['candidate']?.toString();
        final sdpMid = candidateMap['sdpMid']?.toString();
        final sdpMLineIndex = candidateMap['sdpMLineIndex'] as int?;

        if (candidate != null && sdpMLineIndex != null) {
          await peer.connection.addCandidate(
            RTCIceCandidate(candidate, sdpMid, sdpMLineIndex),
          );
        }
      }
    }
  }

  Future<void> _joinVoiceCall() async {
    if (_isInCall) return;

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': _isVideoMode,
      });

      _localRenderer.srcObject = _localStream;
      _isCameraOn = _isVideoMode && _localStream!.getVideoTracks().isNotEmpty;

      if (!_isCameraOn) {
        for (final track in _localStream!.getVideoTracks()) {
          track.enabled = false;
        }
      }

      await _applyVideoQualityConstraints();

      if (!mounted) return;
      setState(() {
        _isInCall = true;
        _isMuted = false;
      });

      _sendSignalMessage({'type': 'webrtc_ready'});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start voice call: $error')),
      );
    }
  }

  Future<void> _leaveVoiceCall({bool notifyOthers = true}) async {
    if (notifyOthers && _isInCall) {
      _sendSignalMessage({'type': 'webrtc_leave'});
    }

    for (final peer in _peers.values) {
      await peer.connection.close();
      await peer.renderer.dispose();
    }
    _peers.clear();

    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    for (final track in _screenStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    await _localStream?.dispose();
    await _screenStream?.dispose();
    _localStream = null;
    _screenStream = null;
    _localRenderer.srcObject = null;

    if (!mounted) return;
    setState(() {
      _isInCall = false;
      _isMuted = false;
      _isCameraOn = _isVideoMode;
      _isScreenSharing = false;
    });
  }

  void _toggleMute() {
    if (_isMutedByHost || (_presentationMode && !_isHost)) {
      return;
    }

    final stream = _localStream;
    if (stream == null) return;

    final audioTracks = stream.getAudioTracks();
    if (audioTracks.isEmpty) return;

    final nextMuted = !_isMuted;
    for (final track in audioTracks) {
      track.enabled = !nextMuted;
    }

    setState(() {
      _isMuted = nextMuted;
    });
  }

  void _openHostControlsSheet() {
    if (!_isHost) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF11172B),
      builder: (context) {
        final others = _participants
            .where((user) => user['client_id']?.toString() != _clientId)
            .toList();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Host Controls',
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'Presentation',
                          style: TextStyle(color: _textMuted),
                        ),
                        Switch(
                          value: _presentationMode,
                          onChanged: _setPresentationMode,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (others.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No other users in room',
                      style: TextStyle(color: _textMuted),
                    ),
                  )
                else
                  ...others.map((user) {
                    final nickname = user['nickname']?.toString() ?? 'User';
                    final targetId = user['client_id']?.toString() ?? '';
                    final isMuted = user['is_muted'] == true;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        nickname,
                        style: const TextStyle(color: _textPrimary),
                      ),
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          OutlinedButton(
                            onPressed: targetId.isEmpty
                                ? null
                                : () => _muteUser(targetId, !isMuted),
                            child: Text(isMuted ? 'Unmute' : 'Mute'),
                          ),
                          OutlinedButton(
                            onPressed: targetId.isEmpty
                                ? null
                                : () => _kickUser(targetId),
                            child: const Text('Kick'),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _toggleCamera() {
    if (!_isInCall || !_isVideoMode || _isScreenSharing) return;

    final videoTracks = _localStream?.getVideoTracks() ?? [];
    if (videoTracks.isEmpty) return;

    final nextCameraOn = !_isCameraOn;
    for (final track in videoTracks) {
      track.enabled = nextCameraOn;
    }

    setState(() {
      _isCameraOn = nextCameraOn;
    });
  }

  Future<void> _toggleLowBandwidthMode() async {
    final next = !_lowBandwidthMode;

    if (!mounted) return;
    setState(() {
      _lowBandwidthMode = next;
    });

    await _applyVideoQualityConstraints();
    await _applyBitrateToAllPeers();
  }

  Future<void> _applyVideoQualityConstraints() async {
    if (!_isInCall || !_isVideoMode || _isScreenSharing) return;

    final tracks = _localStream?.getVideoTracks() ?? [];
    if (tracks.isEmpty) return;

    final width = _lowBandwidthMode ? 320 : 960;
    final height = _lowBandwidthMode ? 180 : 540;
    final frameRate = _lowBandwidthMode ? 10 : 24;

    try {
      await tracks.first.applyConstraints({
        'width': width,
        'height': height,
        'frameRate': frameRate,
      });
    } catch (_) {}
  }

  int get _targetVideoBitrate => _lowBandwidthMode ? 150000 : 1200000;

  Future<void> _applyBitrateToAllPeers() async {
    for (final peer in _peers.values) {
      await _applyBitrateToConnection(peer.connection);
    }
  }

  Future<void> _applyBitrateToConnection(RTCPeerConnection connection) async {
    final senders = await connection.getSenders();
    for (final sender in senders) {
      if (sender.track?.kind != 'video') continue;

      try {
        final dynamic senderDynamic = sender;
        final dynamic parameters = await senderDynamic.getParameters();

        final List<dynamic> encodings =
            (parameters.encodings as List?) ?? <dynamic>[];

        if (encodings.isEmpty) {
          parameters.encodings = [
            {'maxBitrate': _targetVideoBitrate},
          ];
        } else {
          for (final dynamic encoding in encodings) {
            encoding.maxBitrate = _targetVideoBitrate;
          }
          parameters.encodings = encodings;
        }

        await senderDynamic.setParameters(parameters);
      } catch (_) {}
    }
  }

  Future<void> _startScreenShare() async {
    if (!_isInCall || !_isVideoMode || _isScreenSharing) return;

    try {
      final displayStream = await navigator.mediaDevices.getDisplayMedia({
        'video': true,
        'audio': false,
      });

      final videoTracks = displayStream.getVideoTracks();
      if (videoTracks.isEmpty) {
        await displayStream.dispose();
        return;
      }

      _screenStream = displayStream;
      _isScreenSharing = true;
      _localRenderer.srcObject = _screenStream;

      videoTracks.first.onEnded = () {
        _stopScreenShare();
      };

      await _replaceOutgoingVideoTrack(videoTracks.first, displayStream);

      if (!mounted) return;
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Screen share failed: $error')));
    }
  }

  Future<void> _stopScreenShare() async {
    if (!_isScreenSharing) return;

    final cameraTrack = _localStream?.getVideoTracks().isNotEmpty == true
        ? _localStream!.getVideoTracks().first
        : null;

    await _replaceOutgoingVideoTrack(cameraTrack, _localStream);

    for (final track in _screenStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    await _screenStream?.dispose();
    _screenStream = null;

    _localRenderer.srcObject = _localStream;

    if (!mounted) return;
    setState(() {
      _isScreenSharing = false;
    });
  }

  Future<void> _replaceOutgoingVideoTrack(
    MediaStreamTrack? nextTrack,
    MediaStream? sourceStream,
  ) async {
    for (final peer in _peers.values) {
      final senders = await peer.connection.getSenders();
      RTCRtpSender? videoSender;

      for (final sender in senders) {
        if (sender.track?.kind == 'video') {
          videoSender = sender;
          break;
        }
      }

      if (videoSender != null) {
        await videoSender.replaceTrack(nextTrack);
      } else if (nextTrack != null && sourceStream != null) {
        await peer.connection.addTrack(nextTrack, sourceStream);
      }
    }
  }

  Future<void> _switchAudioVideoMode() async {
    final nextMode = !_isVideoMode;

    if (!_isInCall) {
      setState(() {
        _isVideoMode = nextMode;
        _isCameraOn = nextMode;
      });
      return;
    }

    await _leaveVoiceCall(notifyOthers: true);

    if (!mounted) return;
    setState(() {
      _isVideoMode = nextMode;
      _isCameraOn = nextMode;
    });

    await _joinVoiceCall();
  }

  Future<_PeerState?> _createPeerConnection(
    String remoteId, {
    bool createOffer = false,
  }) async {
    final existing = _peers[remoteId];
    if (existing != null) {
      if (createOffer) {
        await _createAndSendOffer(remoteId, existing.connection);
      }
      return existing;
    }

    if (_peers.length >= _maxUsersInCall - 1) return null;

    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    final peerConnection = await createPeerConnection(configuration);
    final renderer = RTCVideoRenderer();
    await renderer.initialize();

    for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await peerConnection.addTrack(track, _localStream!);
    }

    peerConnection.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        renderer.srcObject = event.streams.first;
        if (mounted) setState(() {});
      }
    };

    peerConnection.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        _removePeer(remoteId);
      }
    };

    peerConnection.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) {
        return;
      }

      _sendSignalMessage({
        'type': 'webrtc_ice',
        'target_id': remoteId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };

    final peer = _PeerState(connection: peerConnection, renderer: renderer);
    _peers[remoteId] = peer;
    await _applyBitrateToConnection(peerConnection);
    if (mounted) setState(() {});

    if (createOffer) {
      await _createAndSendOffer(remoteId, peerConnection);
    }

    return peer;
  }

  Future<void> _createAndSendOffer(
    String remoteId,
    RTCPeerConnection peerConnection,
  ) async {
    if (!_isInCall) return;

    final offer = await peerConnection.createOffer({
      'offerToReceiveAudio': 1,
      'offerToReceiveVideo': 1,
    });
    await peerConnection.setLocalDescription(offer);

    _sendSignalMessage({
      'type': 'webrtc_offer',
      'target_id': remoteId,
      'sdp': offer.sdp,
    });
  }

  Future<void> _removePeer(String remoteId) async {
    final peer = _peers.remove(remoteId);
    if (peer == null) return;

    await peer.connection.close();
    await peer.renderer.dispose();
    if (mounted) setState(() {});
  }

  void _sendSignalMessage(Map<String, dynamic> payload) {
    final message = {
      ...payload,
      'sender_id': _clientId,
      'nickname': widget.nickname,
    };
    _channel.sink.add(jsonEncode(message));
  }

  Widget _buildVideoTile({required Widget child, required String label}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F152A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _panelBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoGrid() {
    final tiles = <Widget>[];

    if (_isVideoMode) {
      tiles.add(
        _buildVideoTile(
          label: 'You',
          child: _localRenderer.srcObject == null
              ? const Center(
                  child: Icon(
                    PhosphorIconsLight.videoCameraSlash,
                    color: _textMuted,
                  ),
                )
              : RTCVideoView(
                  _localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
        ),
      );
    }

    for (final entry in _peers.entries.take(_maxUsersInCall - 1)) {
      final renderer = entry.value.renderer;
      tiles.add(
        _buildVideoTile(
          label: entry.key,
          child: renderer.srcObject == null
              ? const Center(
                  child: Icon(
                    PhosphorIconsLight.user,
                    color: _textMuted,
                  ),
                )
              : RTCVideoView(
                  renderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
        ),
      );
    }

    if (tiles.isEmpty) {
      return const SizedBox.shrink();
    }

    final count = tiles.length;
    final crossAxisCount = count <= 2 ? 2 : (count <= 4 ? 2 : 3);

    return SizedBox(
      height: 220,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tiles.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.1,
        ),
        itemBuilder: (context, index) => tiles[index],
      ),
    );
  }

  String _displayNameFromPeerId(String peerId) {
    final separatorIndex = peerId.lastIndexOf('-');
    if (separatorIndex > 0) {
      return peerId.substring(0, separatorIndex);
    }
    return peerId;
  }

  List<String> _callParticipantNames() {
    final names = _peers.keys
        .take(_maxUsersInCall - 1)
        .map(_displayNameFromPeerId)
        .toList();
    names.add('You');
    return names;
  }

  Widget _buildVoiceCallScreen() {
    final participants = _callParticipantNames();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              _ModeChip(
                label: _lowBandwidthMode ? 'Low Bandwidth ON' : 'Low Bandwidth',
                onTap: _toggleLowBandwidthMode,
                highlighted: _lowBandwidthMode,
                icon: PhosphorIconsLight.wifiLow,
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: _isVideoMode ? 'Audio Only' : 'Video Mode',
                onTap: _switchAudioVideoMode,
                highlighted: !_isVideoMode,
                icon: _isVideoMode
                    ? PhosphorIconsLight.waveform
                    : PhosphorIconsLight.videoCamera,
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: participants.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final name = participants[index];
              final firstLetter = name.isEmpty
                  ? '?'
                  : name.characters.first.toUpperCase();

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B5CF6), Color(0xFF3A4A85)],
                      ),
                      border: Border.all(
                        color: const Color(0xFF6B5CF6),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name,
                    style: const TextStyle(color: _textPrimary, fontSize: 14),
                  ),
                ],
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CallCircleButton(
                icon: _isMuted
                    ? PhosphorIconsLight.microphoneSlash
                    : PhosphorIconsLight.microphone,
                onTap: _toggleMute,
              ),
              _CallCircleButton(
                icon: _isVideoMode
                    ? PhosphorIconsLight.waveform
                    : PhosphorIconsLight.videoCamera,
                onTap: _switchAudioVideoMode,
                isPrimary: true,
              ),
              _CallCircleButton(
                icon: PhosphorIconsLight.phoneDisconnect,
                onTap: () => _leaveVoiceCall(notifyOthers: true),
                isDanger: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCallScreen() {
    final tiles = <Map<String, dynamic>>[];

    tiles.add({'name': 'You', 'renderer': _localRenderer, 'local': true});

    for (final entry in _peers.entries.take(_maxUsersInCall - 1)) {
      tiles.add({
        'name': _displayNameFromPeerId(entry.key),
        'renderer': entry.value.renderer,
        'local': false,
      });
    }

    return Column(
      children: [
        if (_isScreenSharing)
          Container(
            margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF11172B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _panelBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  PhosphorIconsLight.screencast,
                  color: _textPrimary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'You are sharing screen',
                    style: TextStyle(color: _textPrimary),
                  ),
                ),
                InkWell(
                  onTap: _stopScreenShare,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE4574D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Stop',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
            children: [
              _ModeChip(
                label: _lowBandwidthMode ? 'Low Bandwidth ON' : 'Low Bandwidth',
                onTap: _toggleLowBandwidthMode,
                highlighted: _lowBandwidthMode,
                icon: PhosphorIconsLight.wifiLow,
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: _isVideoMode ? 'Audio Only' : 'Video Mode',
                onTap: _switchAudioVideoMode,
                highlighted: !_isVideoMode,
                icon: _isVideoMode
                    ? PhosphorIconsLight.waveform
                    : PhosphorIconsLight.videoCamera,
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tiles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 0.98,
            ),
            itemBuilder: (context, index) {
              final tile = tiles[index];
              final renderer = tile['renderer'] as RTCVideoRenderer;
              final isLocal = tile['local'] as bool;
              final name = tile['name'] as String;

              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: renderer.srcObject == null
                          ? Container(
                              color: const Color(0xFF0F152A),
                              alignment: Alignment.center,
                              child: const Icon(
                                PhosphorIconsLight.videoCameraSlash,
                                color: _textMuted,
                              ),
                            )
                          : RTCVideoView(
                              renderer,
                              mirror: isLocal,
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitCover,
                            ),
                    ),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: Colors.black45,
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Icon(
                        _isMuted && isLocal
                            ? PhosphorIconsLight.microphoneSlash
                            : PhosphorIconsLight.microphone,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CallCircleButton(
                icon: _isCameraOn
                    ? PhosphorIconsLight.videoCamera
                    : PhosphorIconsLight.videoCameraSlash,
                onTap: _toggleCamera,
              ),
              _CallCircleButton(
                icon: _isMuted
                    ? PhosphorIconsLight.microphoneSlash
                    : PhosphorIconsLight.microphone,
                onTap: _toggleMute,
              ),
              _CallCircleButton(
                icon: PhosphorIconsLight.phoneDisconnect,
                onTap: () => _leaveVoiceCall(notifyOthers: true),
                isDanger: true,
              ),
              _CallCircleButton(
                icon: _isScreenSharing
                    ? PhosphorIconsLight.screencast
                    : PhosphorIconsLight.monitorArrowUp,
                onTap: _isScreenSharing ? _stopScreenShare : _startScreenShare,
              ),
              _CallCircleButton(
                icon: _isVideoMode
                    ? PhosphorIconsLight.waveform
                    : PhosphorIconsLight.videoCamera,
                onTap: _switchAudioVideoMode,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _channel.sink.add(
      jsonEncode({'nickname': widget.nickname, 'message': text}),
    );

    _messageController.clear();
  }

  PreferredSizeWidget _buildRoomHeader(
    BuildContext context, {
    bool showChatToggle = false,
    bool chatVisible = false,
    VoidCallback? onToggleChat,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final displayParticipants = _participants.take(4).toList();

    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 80,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  PhosphorIconsLight.square,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Room ${widget.roomId}',
                      style: textTheme.displaySmall?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.roomLink,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (showChatToggle)
                    IconButton(
                      onPressed: onToggleChat,
                      icon: Icon(
                        chatVisible
                            ? PhosphorIconsLight.chatDots
                            : PhosphorIconsLight.chatDots,
                        color: chatVisible
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                    ),
                  ...displayParticipants.map((participant) {
                    final nickname = participant['nickname']?.toString() ?? '';
                    final initials = nickname.isNotEmpty
                        ? nickname.characters.first.toUpperCase()
                        : '?';
                    return Container(
                      margin: const EdgeInsets.only(left: 6),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.accentSoft,
                        child: Text(
                          initials,
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: AppSpacing.md),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(PhosphorIconsLight.userPlus, size: 16),
                    label: const Text('Invite'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(PhosphorIconsLight.dotsThree),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Chat', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Live',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'J',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.softShadow,
                ),
                child: TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(
                    PhosphorIconsLight.userPlus,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    'Invite',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: () {},
                icon: const Icon(PhosphorIconsLight.dotsThree),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _messages.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        PhosphorIconsLight.chatsCircle,
                        color: AppColors.accent,
                        size: 56,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Start the conversation!',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final item = _messages[index];
                      final isMine = item['nickname'] == widget.nickname;

                      if (isMine) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            constraints: const BoxConstraints(maxWidth: 240),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              item['message'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.accentSoft,
                              child: Text(
                                (item['nickname'] ?? '?')
                                    .characters
                                    .first
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Flexible(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 240),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.chatIncoming,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['nickname'] ?? 'Unknown',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['message'] ?? '',
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(PhosphorIconsLight.plusCircle),
                  color: AppColors.textSecondary,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: _sendMessage,
                    icon: const Icon(PhosphorIconsLight.paperPlaneRight, size: 18),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_presentationMode)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    _isHost
                        ? 'Presentation mode is ON (only host speaks)'
                        : 'Presentation mode is ON (host only speaks)',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              if (_isMutedByHost)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    'You are muted by host',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
              const Text(
                'Share room link',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              SelectableText(
                widget.roomLink,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _PillActionButton(
                    label: 'Join Call',
                    icon: PhosphorIconsLight.phoneCall,
                    onPressed: _isInCall ? null : _joinVoiceCall,
                    isPrimary: !_isInCall,
                  ),
                  _PillActionButton(
                    label: 'Leave',
                    icon: PhosphorIconsLight.phoneX,
                    onPressed:
                        _isInCall ? () => _leaveVoiceCall(notifyOthers: true) : null,
                  ),
                  _PillActionButton(
                    label: _isMuted ? 'Unmute' : 'Mute',
                    icon: _isMuted ? PhosphorIconsLight.microphoneSlash : PhosphorIconsLight.microphone,
                    onPressed: _isInCall ? _toggleMute : null,
                  ),
                  _PillActionButton(
                    label: _isCameraOn ? 'Camera On' : 'Camera Off',
                    icon: _isCameraOn ? PhosphorIconsLight.videoCamera : PhosphorIconsLight.videoCameraSlash,
                    onPressed: _isInCall ? _toggleCamera : null,
                  ),
                  _PillActionButton(
                    label: _isVideoMode ? 'Switch to Audio' : 'Switch to Video',
                    icon: _isVideoMode ? PhosphorIconsLight.waveform : PhosphorIconsLight.videoCamera,
                    onPressed: _switchAudioVideoMode,
                  ),
                  _PillActionButton(
                    label: _isScreenSharing ? 'Stop Share' : 'Start Share',
                    icon: _isScreenSharing
                        ? PhosphorIconsLight.monitorX
                        : PhosphorIconsLight.monitorArrowUp,
                    onPressed: _isInCall && _isVideoMode
                        ? (_isScreenSharing ? _stopScreenShare : _startScreenShare)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (_isInCall && _isVideoMode) ...[
          _buildVideoGrid(),
          const SizedBox(height: AppSpacing.md),
        ],
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Shared Whiteboard',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _clearBoard,
                    icon: const Icon(PhosphorIconsLight.broom),
                    label: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _BoardToolIconButton(
                        icon: PhosphorIconsLight.pencilSimple,
                        selected: _selectedTool == _BoardTool.pen,
                        onTap: () => setState(() {
                          _selectedTool = _BoardTool.pen;
                        }),
                      ),
                      _BoardToolIconButton(
                        icon: PhosphorIconsLight.pencil,
                        selected: _selectedTool == _BoardTool.pencil,
                        onTap: () => setState(() {
                          _selectedTool = _BoardTool.pencil;
                        }),
                      ),
                      _BoardToolIconButton(
                        icon: PhosphorIconsLight.highlighter,
                        selected: _selectedTool == _BoardTool.marker,
                        onTap: () => setState(() {
                          _selectedTool = _BoardTool.marker;
                        }),
                      ),
                      _BoardToolIconButton(
                        icon: PhosphorIconsLight.eraser,
                        selected: _selectedTool == _BoardTool.eraser,
                        onTap: () => setState(() {
                          _selectedTool = _BoardTool.eraser;
                        }),
                      ),
                      _BoardToolIconButton(
                        icon: PhosphorIconsLight.square,
                        selected: _selectedTool == _BoardTool.rect,
                        onTap: () => setState(() {
                          _selectedTool = _BoardTool.rect;
                        }),
                      ),
                      _BoardToolIconButton(
                        icon: PhosphorIconsLight.circle,
                        selected: _selectedTool == _BoardTool.circle,
                        onTap: () => setState(() {
                          _selectedTool = _BoardTool.circle;
                        }),
                      ),
                      _BoardToolIconButton(
                        icon: PhosphorIconsLight.textT,
                        selected: _selectedTool == _BoardTool.text,
                        onTap: () => setState(() {
                          _selectedTool = _BoardTool.text;
                        }),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      _ColorDot(
                        color: Colors.white,
                        selected: _selectedColor == Colors.white,
                        onTap: () => setState(() {
                          _selectedColor = Colors.white;
                        }),
                      ),
                      _ColorDot(
                        color: Colors.green.shade500,
                        selected: _selectedColor == Colors.green.shade500,
                        onTap: () => setState(() {
                          _selectedColor = Colors.green.shade500;
                        }),
                      ),
                      _ColorDot(
                        color: Colors.blue.shade400,
                        selected: _selectedColor == Colors.blue.shade400,
                        onTap: () => setState(() {
                          _selectedColor = Colors.blue.shade400;
                        }),
                      ),
                      _ColorDot(
                        color: Colors.purple.shade400,
                        selected: _selectedColor == Colors.purple.shade400,
                        onTap: () => setState(() {
                          _selectedColor = Colors.purple.shade400;
                        }),
                      ),
                      _ColorDot(
                        color: Colors.orange.shade400,
                        selected: _selectedColor == Colors.orange.shade400,
                        onTap: () => setState(() {
                          _selectedColor = Colors.orange.shade400;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                height: 420,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final canvasSize = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );

                    return GestureDetector(
                      onTapDown: (details) {
                        if (_selectedTool == _BoardTool.text) {
                          _addTextAt(
                            details.localPosition,
                            canvasSize,
                          );
                        }
                      },
                      onPanStart: (details) =>
                          _onBoardPanStart(details, canvasSize),
                      onPanUpdate: (details) =>
                          _onBoardPanUpdate(details, canvasSize),
                      onPanEnd: (_) => _onBoardPanEnd(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _boardBgColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.canvasBorder),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _WhiteboardGridPainter(),
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _WhiteboardPainter(
                                  items: _boardItems,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final participants = _participants;

    return Container(
      width: 240,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Workspace', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _SidebarNavItem(
            icon: PhosphorIconsLight.squaresFour,
            label: 'Overview',
            active: false,
          ),
          _SidebarNavItem(
            icon: PhosphorIconsLight.penNib,
            label: 'Whiteboard',
            active: true,
          ),
          _SidebarNavItem(
            icon: PhosphorIconsLight.chatDots,
            label: 'Chat',
            active: false,
          ),
          _SidebarNavItem(
            icon: PhosphorIconsLight.users,
            label: 'Participants',
            active: false,
          ),
          _SidebarNavItem(
            icon: PhosphorIconsLight.gear,
            label: 'Settings',
            active: false,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Participants', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView.separated(
              itemCount: participants.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final participant = participants[index];
                final nickname = participant['nickname']?.toString() ?? 'Guest';
                final isHost = participant['is_host'] == true;
                final initials = nickname.isNotEmpty
                    ? nickname.characters.first.toUpperCase()
                    : '?';

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.accentSoft,
                      child: Text(
                        initials,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        nickname,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isHost)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Host',
                          style: textTheme.labelMedium?.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInCall) {
      final textTheme = Theme.of(context).textTheme;
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isVideoMode ? 'Study Group Video' : 'Study Group Voice',
                style: textTheme.titleMedium,
              ),
              Text(
                '${_peers.length + 1} members${_presentationMode ? ' • Presentation' : ''}',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            if (_isHost)
              IconButton(
                onPressed: _openHostControlsSheet,
                icon: const Icon(PhosphorIconsLight.crown),
              ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: _GradientBackground(
          child: _isVideoMode
              ? _buildVideoCallScreen()
              : _buildVoiceCallScreen(),
        ),
      );
    }

    final isCompact = MediaQuery.of(context).size.width < 1100;
    return Scaffold(
      appBar: _buildRoomHeader(
        context,
        showChatToggle: isCompact,
        chatVisible: _showChatPanel,
        onToggleChat: isCompact
            ? () {
                setState(() {
                  _showChatPanel = !_showChatPanel;
                });
              }
            : null,
      ),
      body: _GradientBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            if (width < 720) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Expanded(
                      child: IndexedStack(
                        index: _mobileTabIndex,
                        children: [
                          SingleChildScrollView(child: _buildCenterContent()),
                          _buildChatPanel(context),
                          _buildSidebar(context),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    NavigationBar(
                      selectedIndex: _mobileTabIndex,
                      onDestinationSelected: (index) {
                        setState(() {
                          _mobileTabIndex = index;
                        });
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(PhosphorIconsLight.penNib),
                          label: 'Board',
                        ),
                        NavigationDestination(
                          icon: Icon(PhosphorIconsLight.chatDots),
                          label: 'Chat',
                        ),
                        NavigationDestination(
                          icon: Icon(PhosphorIconsLight.users),
                          label: 'People',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            if (width < 1100) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 220, child: _buildSidebar(context)),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildCenterContent(),
                      ),
                    ),
                    if (_showChatPanel) ...[
                      const SizedBox(width: AppSpacing.lg),
                      SizedBox(width: 320, child: _buildChatPanel(context)),
                    ],
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebar(context),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: _buildCenterContent()),
                  const SizedBox(width: AppSpacing.lg),
                  SizedBox(width: 320, child: _buildChatPanel(context)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: active ? AppColors.accentSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillActionButton extends StatelessWidget {
  const _PillActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final bgColor = isPrimary ? AppColors.accent : Colors.white;
    final borderColor = isPrimary ? AppColors.accent : AppColors.border;
    final textColor = isPrimary ? Colors.white : AppColors.textPrimary;

    return SizedBox(
      height: 44,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: isEnabled ? textColor : AppColors.textSecondary),
        label: Text(
          label,
          style: TextStyle(
            color: isEnabled ? textColor : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: isEnabled ? bgColor : AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: borderColor),
          ),
        ),
      ),
    );
  }
}

class _CallCircleButton extends StatelessWidget {
  const _CallCircleButton({
    required this.icon,
    required this.onTap,
    this.isDanger = false,
    this.isPrimary = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isDanger;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.card;
    Color iconColor = AppColors.textPrimary;

    if (isPrimary) {
      bgColor = AppColors.accentSoft;
      iconColor = AppColors.accent;
    }
    if (isDanger) {
      bgColor = AppColors.danger;
      iconColor = Colors.white;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: AppTheme.softShadow,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.onTap,
    required this.highlighted,
    required this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool highlighted;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.accentSoft : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlighted ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _BoardToolButton extends StatelessWidget {
  const _BoardToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}

class _BoardToolIconButton extends StatelessWidget {
  const _BoardToolIconButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: selected ? AppColors.accent : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: child,
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    );
  }
}

class _WhiteboardPainter extends CustomPainter {
  const _WhiteboardPainter({required this.items});

  final List<_BoardItem> items;

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in items) {
      if (item is _BoardStroke) {
        if (item.points.length < 2) continue;
        final paint = Paint()
          ..color = item.color.withOpacity(item.opacity)
          ..strokeWidth = item.width
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        final path = Path();
        final first = item.points.first.toOffset(size);
        path.moveTo(first.dx, first.dy);
        for (final point in item.points.skip(1)) {
          final offset = point.toOffset(size);
          path.lineTo(offset.dx, offset.dy);
        }
        canvas.drawPath(path, paint);
      } else if (item is _BoardShape) {
        final paint = Paint()
          ..color = item.color.withOpacity(item.opacity)
          ..strokeWidth = item.width
          ..style = PaintingStyle.stroke;

        final start = item.start.toOffset(size);
        final end = item.end.toOffset(size);
        final rect = Rect.fromPoints(start, end);

        if (item.tool == _BoardTool.circle) {
          canvas.drawOval(rect, paint);
        } else {
          canvas.drawRect(rect, paint);
        }
      } else if (item is _BoardText) {
        final offset = item.position.toOffset(size);
        final painter = TextPainter(
          text: TextSpan(
            text: item.text,
            style: TextStyle(color: item.color, fontSize: item.size),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(canvas, offset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) {
    return oldDelegate.items != items;
  }
}

class _WhiteboardGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double spacing = 18;
    final paint = Paint()
      ..color = AppColors.border.withOpacity(0.6)
      ..strokeWidth = 1;

    for (double y = 0; y <= size.height; y += spacing) {
      for (double x = 0; x <= size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardGridPainter oldDelegate) {
    return false;
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class AppTextField extends StatefulWidget {
  const AppTextField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    super.key,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = _focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused ? AppColors.accent : AppColors.border,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          Icon(widget.prefixIcon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                isDense: true,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: enabled
          ? (_) => setState(() {
                _pressed = true;
              })
          : null,
      onTapUp: enabled
          ? (_) => setState(() {
                _pressed = false;
              })
          : null,
      onTapCancel: () => setState(() {
        _pressed = false;
      }),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? AppColors.accent : AppColors.border,
            borderRadius: BorderRadius.circular(16),
            boxShadow: enabled ? AppTheme.softShadow : null,
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  const ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.trailing,
    this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';
  static const String wsBaseUrl = 'ws://127.0.0.1:8000/ws/chat/';

  static Future<Map<String, dynamic>> createRoom(String nickname) async {
    final uri = Uri.parse('$baseUrl/api/rooms/create/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nickname': nickname}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return data;
    }

    throw Exception(data['error'] ?? 'Failed to create room');
  }

  static Future<void> joinRoom(String roomId, String nickname) async {
    final uri = Uri.parse('$baseUrl/api/rooms/join/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'room_id': roomId, 'nickname': nickname}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to join room');
    }
  }
}
