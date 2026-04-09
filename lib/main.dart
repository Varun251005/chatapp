import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

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

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room Chat App',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bgBottom,
        colorScheme: const ColorScheme.dark(
          primary: _primaryPurple,
          secondary: _primaryPurple,
          surface: _panelColor,
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: const TextStyle(color: _textMuted),
          labelStyle: const TextStyle(color: _textMuted),
          filled: true,
          fillColor: const Color(0xFF11172B),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _panelBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _panelBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _primaryPurple),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryPurple,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
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
    return Scaffold(
      body: _GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                const Icon(
                  Icons.chat_bubble_rounded,
                  size: 64,
                  color: _primaryPurple,
                ),
                const SizedBox(height: 10),
                const Text(
                  'EchoRoom',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _primaryPurple,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Join a room. Connect instantly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textMuted),
                ),
                const SizedBox(height: 24),
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Enter your nickname',
                        style: TextStyle(
                          color: _textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          hintText: 'Type your nickname',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _continueToLobby,
                        child: const Text('Continue'),
                      ),
                    ],
                  ),
                ),
              ],
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: const Text('Room'),
      ),
      body: _GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create a Room',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hello ${widget.nickname}. Room ID will appear after you tap Create Room.',
                      style: const TextStyle(color: _textMuted),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createRoom,
                      child: const Text('Create Room'),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 12),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Join a Room',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _linkController,
                      decoration: const InputDecoration(
                        hintText: 'Enter room link or ID',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _joinRoom,
                      child: const Text('Join Room'),
                    ),
                  ],
                ),
              ),
            ],
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

class _BoardPoint {
  const _BoardPoint({required this.x, required this.y, required this.isBreak});

  final double x;
  final double y;
  final bool isBreak;
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
  final List<_BoardPoint> _boardPoints = [];
  List<Map<String, dynamic>> _participants = [];
  String? _hostNickname;
  bool _presentationMode = false;

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
        _boardPoints.clear();
      });
      return;
    }

    if (payloadType != 'whiteboard_draw') return;

    final action = payload['action']?.toString() ?? 'move';
    if (action == 'end') {
      if (!mounted) return;
      setState(() {
        _boardPoints.add(const _BoardPoint(x: 0, y: 0, isBreak: true));
      });
      return;
    }

    final x = (payload['x'] as num?)?.toDouble();
    final y = (payload['y'] as num?)?.toDouble();
    if (x == null || y == null) return;

    if (!mounted) return;
    setState(() {
      if (action == 'start' &&
          _boardPoints.isNotEmpty &&
          !_boardPoints.last.isBreak) {
        _boardPoints.add(const _BoardPoint(x: 0, y: 0, isBreak: true));
      }
      _boardPoints.add(_BoardPoint(x: x, y: y, isBreak: false));
    });
  }

  void _onBoardPanStart(DragStartDetails details, Size size) {
    _addLocalBoardPoint(details.localPosition, size, action: 'start');
  }

  void _onBoardPanUpdate(DragUpdateDetails details, Size size) {
    _addLocalBoardPoint(details.localPosition, size, action: 'move');
  }

  void _onBoardPanEnd() {
    setState(() {
      _boardPoints.add(const _BoardPoint(x: 0, y: 0, isBreak: true));
    });

    _channel.sink.add(
      jsonEncode({
        'type': 'whiteboard_draw',
        'action': 'end',
        'sender_id': _clientId,
        'nickname': widget.nickname,
      }),
    );
  }

  void _addLocalBoardPoint(
    Offset localOffset,
    Size size, {
    required String action,
  }) {
    if (size.width <= 0 || size.height <= 0) return;

    final x = (localOffset.dx / size.width).clamp(0.0, 1.0);
    final y = (localOffset.dy / size.height).clamp(0.0, 1.0);

    setState(() {
      if (action == 'start' &&
          _boardPoints.isNotEmpty &&
          !_boardPoints.last.isBreak) {
        _boardPoints.add(const _BoardPoint(x: 0, y: 0, isBreak: true));
      }
      _boardPoints.add(_BoardPoint(x: x, y: y, isBreak: false));
    });

    _channel.sink.add(
      jsonEncode({
        'type': 'whiteboard_draw',
        'action': action,
        'x': x,
        'y': y,
        'sender_id': _clientId,
        'nickname': widget.nickname,
      }),
    );
  }

  void _clearBoard() {
    setState(() {
      _boardPoints.clear();
    });

    _channel.sink.add(
      jsonEncode({
        'type': 'whiteboard_clear',
        'sender_id': _clientId,
        'nickname': widget.nickname,
      }),
    );
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
              ? const Center(child: Icon(Icons.videocam_off, color: _textMuted))
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
              ? const Center(child: Icon(Icons.person, color: _textMuted))
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
                icon: Icons.network_check,
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: _isVideoMode ? 'Audio Only' : 'Video Mode',
                onTap: _switchAudioVideoMode,
                highlighted: !_isVideoMode,
                icon: _isVideoMode ? Icons.voicemail : Icons.video_call,
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
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF121A33),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _panelBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CallCircleButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic,
                onTap: _toggleMute,
              ),
              _CallCircleButton(
                icon: _isVideoMode ? Icons.voicemail : Icons.video_call,
                onTap: _switchAudioVideoMode,
                isPrimary: true,
              ),
              _CallCircleButton(
                icon: Icons.call_end,
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
                const Icon(Icons.cast_connected, color: _textPrimary, size: 16),
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
                icon: Icons.network_check,
              ),
              const SizedBox(width: 8),
              _ModeChip(
                label: _isVideoMode ? 'Audio Only' : 'Video Mode',
                onTap: _switchAudioVideoMode,
                highlighted: !_isVideoMode,
                icon: _isVideoMode ? Icons.voicemail : Icons.video_call,
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
                                Icons.videocam_off,
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
                        _isMuted && isLocal ? Icons.mic_off : Icons.mic_none,
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
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF121A33),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _panelBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CallCircleButton(
                icon: _isCameraOn ? Icons.videocam : Icons.videocam_off,
                onTap: _toggleCamera,
              ),
              _CallCircleButton(
                icon: _isMuted ? Icons.mic_off : Icons.mic,
                onTap: _toggleMute,
              ),
              _CallCircleButton(
                icon: Icons.call_end,
                onTap: () => _leaveVoiceCall(notifyOthers: true),
                isDanger: true,
              ),
              _CallCircleButton(
                icon: _isScreenSharing
                    ? Icons.stop_screen_share
                    : Icons.screen_share,
                onTap: _isScreenSharing ? _stopScreenShare : _startScreenShare,
              ),
              _CallCircleButton(
                icon: _isVideoMode ? Icons.voicemail : Icons.video_call,
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

  @override
  Widget build(BuildContext context) {
    if (_isInCall) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: _textPrimary,
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isVideoMode ? 'Study Group Video' : 'Study Group Voice',
                style: const TextStyle(fontSize: 16, color: _textPrimary),
              ),
              Text(
                '${_peers.length + 1} members${_presentationMode ? ' • Presentation' : ''}',
                style: const TextStyle(fontSize: 12, color: _textMuted),
              ),
            ],
          ),
          actions: [
            if (_isHost)
              IconButton(
                onPressed: _openHostControlsSheet,
                icon: const Icon(Icons.admin_panel_settings_outlined),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: _GradientBackground(
          child: _isVideoMode
              ? _buildVideoCallScreen()
              : _buildVoiceCallScreen(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _textPrimary,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Room ${widget.roomId}',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.nickname,
              style: const TextStyle(color: _textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          if (_isHost)
            IconButton(
              onPressed: _openHostControlsSheet,
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          IconButton(
            onPressed: _isInCall ? _toggleMute : null,
            icon: Icon(_isMuted ? Icons.mic_off : Icons.mic_none),
          ),
          IconButton(
            onPressed: _isInCall ? _toggleCamera : null,
            icon: Icon(_isCameraOn ? Icons.videocam : Icons.videocam_off),
          ),
          IconButton(
            onPressed: _isInCall && _isVideoMode
                ? (_isScreenSharing ? _stopScreenShare : _startScreenShare)
                : null,
            icon: Icon(
              _isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
            ),
          ),
          IconButton(
            onPressed: _switchAudioVideoMode,
            icon: Icon(_isVideoMode ? Icons.voicemail : Icons.video_call),
          ),
          IconButton(
            onPressed: _isInCall
                ? () => _leaveVoiceCall(notifyOthers: true)
                : _joinVoiceCall,
            icon: Icon(_isInCall ? Icons.call_end : Icons.call),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _GradientBackground(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_presentationMode)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _isHost
                              ? 'Presentation mode is ON (only host speaks)'
                              : 'Presentation mode is ON (host only speaks)',
                          style: const TextStyle(color: _textMuted),
                        ),
                      ),
                    if (_isMutedByHost)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'You are muted by host',
                          style: TextStyle(color: Colors.orangeAccent),
                        ),
                      ),
                    const Text(
                      'Share room link',
                      style: TextStyle(color: _textMuted),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      widget.roomLink,
                      style: const TextStyle(color: _textMuted),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isInCall ? null : _joinVoiceCall,
                          icon: const Icon(Icons.call),
                          label: const Text('Join Call'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isInCall
                              ? () => _leaveVoiceCall(notifyOthers: true)
                              : null,
                          icon: const Icon(Icons.call_end),
                          label: const Text('Leave'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isInCall ? _toggleMute : null,
                          icon: Icon(_isMuted ? Icons.mic_off : Icons.mic),
                          label: Text(_isMuted ? 'Unmute' : 'Mute'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isInCall ? _toggleCamera : null,
                          icon: Icon(
                            _isCameraOn ? Icons.videocam : Icons.videocam_off,
                          ),
                          label: Text(_isCameraOn ? 'Camera On' : 'Camera Off'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _switchAudioVideoMode,
                          icon: Icon(
                            _isVideoMode ? Icons.voicemail : Icons.video_call,
                          ),
                          label: Text(
                            _isVideoMode
                                ? 'Switch to Audio'
                                : 'Switch to Video',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _isInCall && _isVideoMode
                              ? (_isScreenSharing
                                    ? _stopScreenShare
                                    : _startScreenShare)
                              : null,
                          icon: Icon(
                            _isScreenSharing
                                ? Icons.stop_screen_share
                                : Icons.screen_share,
                          ),
                          label: Text(
                            _isScreenSharing ? 'Stop Share' : 'Start Share',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (_isInCall && _isVideoMode) ...[
                _buildVideoGrid(),
                const SizedBox(height: 10),
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
                            color: _textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _clearBoard,
                          icon: const Icon(Icons.cleaning_services_outlined),
                          label: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 210,
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF111A34),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _panelBorder),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: const [
                                Icon(Icons.edit, color: Colors.white, size: 18),
                                Icon(
                                  Icons.brush_outlined,
                                  color: _textMuted,
                                  size: 18,
                                ),
                                Icon(
                                  Icons.crop_square_outlined,
                                  color: _textMuted,
                                  size: 18,
                                ),
                                Icon(
                                  Icons.text_fields,
                                  color: _textMuted,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final canvasSize = Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                );

                                return GestureDetector(
                                  onPanStart: (details) =>
                                      _onBoardPanStart(details, canvasSize),
                                  onPanUpdate: (details) =>
                                      _onBoardPanUpdate(details, canvasSize),
                                  onPanEnd: (_) => _onBoardPanEnd(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F152A),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _panelBorder),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: _WhiteboardPainter(
                                              points: _boardPoints,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Icon(
                                            Icons.star_border,
                                            color: Colors.amber.shade400,
                                            size: 18,
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ColorDot(color: Colors.green.shade500),
                        const SizedBox(width: 8),
                        _ColorDot(color: Colors.blue.shade400),
                        const SizedBox(width: 8),
                        _ColorDot(color: Colors.purple.shade400),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages yet',
                            style: TextStyle(color: _textMuted),
                          ),
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
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 5,
                                  ),
                                  constraints: const BoxConstraints(
                                    maxWidth: 260,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        _primaryPurple,
                                        Color(0xFF7D66FF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    item['message'] ?? '',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: const Color(0xFF263155),
                                    child: Text(
                                      (item['nickname'] ?? '?').characters.first
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A213A),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['nickname'] ?? 'Unknown',
                                            style: const TextStyle(
                                              color: _textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item['message'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
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
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF11172B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _panelBorder),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.add_circle_outline),
                      color: _textMuted,
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
                    IconButton(
                      onPressed: _isInCall ? _toggleMute : _joinVoiceCall,
                      icon: Icon(_isInCall ? Icons.mic : Icons.mic_none),
                      color: _primaryPurple,
                    ),
                    IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send_rounded),
                      color: _primaryPurple,
                    ),
                  ],
                ),
              ),
            ],
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
    Color bgColor = const Color(0xFF1B2647);
    if (isPrimary) bgColor = _primaryPurple;
    if (isDanger) bgColor = const Color(0xFFE84A4A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: highlighted
              ? const Color(0xFF2D3A74)
              : const Color(0xFF121A33),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: highlighted ? _primaryPurple : _panelBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_bgTop, _bgBottom],
        ),
      ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _panelBorder),
      ),
      child: child,
    );
  }
}

class _WhiteboardPainter extends CustomPainter {
  const _WhiteboardPainter({required this.points});

  final List<_BoardPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (var index = 0; index < points.length - 1; index++) {
      final current = points[index];
      final next = points[index + 1];

      if (current.isBreak || next.isBreak) continue;

      final p1 = Offset(current.x * size.width, current.y * size.height);
      final p2 = Offset(next.x * size.width, next.y * size.height);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WhiteboardPainter oldDelegate) {
    return oldDelegate.points != points;
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
