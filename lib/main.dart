import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

const Color _panelBorder = Color(0xFF2D355F);
const Color _textPrimary = Color(0xFFEAF0FF);
const Color _textMuted = Color(0xFF98A2C7);

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  String? _inviteRoomIdFromUrl() {
    final segments = Uri.base.pathSegments;
    if (segments.length >= 2 && segments.first == 'room') {
      final roomId = segments[1].trim();
      return roomId.isEmpty ? null : roomId;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final inviteRoomId = _inviteRoomIdFromUrl();
    return MaterialApp(
      title: 'Room Chat App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: NicknameScreen(roomIdFromLink: inviteRoomId),
    );
  }
}

class NicknameScreen extends StatefulWidget {
  const NicknameScreen({super.key, this.roomIdFromLink});

  final String? roomIdFromLink;

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _continueToLobby() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a nickname')));
      return;
    }

    final inviteRoomId = widget.roomIdFromLink?.trim();
    if (inviteRoomId != null && inviteRoomId.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ApiService.joinRoom(inviteRoomId, nickname);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoomScreen(
              nickname: nickname,
              roomId: inviteRoomId,
              roomLink: ApiService.roomInviteLink(inviteRoomId),
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
                      onPressed: _isLoading ? null : _continueToLobby,
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

      final roomId = roomData['room_id'] as String;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RoomScreen(
            nickname: widget.nickname,
            roomId: roomId,
            roomLink: ApiService.roomInviteLink(roomId),
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
            roomLink: ApiService.roomInviteLink(roomId),
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
    final trimmed = value.trim();

    final uri = Uri.tryParse(trimmed);
    if (uri != null) {
      final segments = uri.pathSegments;
      for (var i = 0; i < segments.length; i++) {
        if (segments[i] == 'room' && i + 1 < segments.length) {
          final roomId = segments[i + 1].trim();
          if (roomId.isNotEmpty) return roomId;
        }
      }
    }

    if (trimmed.contains('/room/')) {
      final parts = trimmed.split('/room/');
      return parts.last.split('?').first.split('#').first.trim();
    }

    return trimmed;
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
  bool _isCameraOn = true;
  bool _isVideoMode = true;
  bool _isScreenSharing = false;
  bool _lowBandwidthMode = false;
  final Map<String, String> _participantsById = {};
  int _mobileTabIndex = 0;
  bool _showChatPanel = true;
  bool _showParticipantsPanel = false;
  bool _sidebarExpanded = false;

  static const int _maxUsersInCall = 6;

  void _closeOverlays() {
    setState(() {
      _showChatPanel = false;
      _showParticipantsPanel = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _clientId = '${widget.nickname}-${DateTime.now().millisecondsSinceEpoch}';
    _initRenderers();
    _channel = WebSocketChannel.connect(
      ApiService.wsRoomUri(widget.roomId),
    );

    _channel.stream.listen((data) {
      final payload = jsonDecode(data as String) as Map<String, dynamic>;
      _handleSocketPayload(payload);
    });

    // Minimal room join (used for participants sync and WebRTC addressing).
    _channel.sink.add(
      jsonEncode({
        'type': 'participant_join',
        'sender_id': _clientId,
        'nickname': widget.nickname,
      }),
    );
  }

  @override
  void dispose() {
    try {
      _channel.sink.add(
        jsonEncode({
          'type': 'participant_leave',
          'sender_id': _clientId,
          'nickname': widget.nickname,
        }),
      );
    } catch (_) {}
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
    final type = payload['type']?.toString();

    if (type == 'participant_join') {
      final senderId = payload['sender_id']?.toString() ?? '';
      final nickname = payload['nickname']?.toString() ?? '';
      if (senderId.isEmpty || nickname.isEmpty) return;

      if (!mounted) return;
      setState(() {
        _participantsById[senderId] = nickname;
      });

      // If we're already in a call, proactively connect to the new participant.
      if (_isInCall && senderId != _clientId) {
        _createPeerConnection(senderId, createOffer: true);
      }
      return;
    }

    if (type == 'participant_leave') {
      final senderId = payload['sender_id']?.toString() ?? '';
      if (senderId.isEmpty) return;

      _removePeer(senderId);

      if (!mounted) return;
      setState(() {
        _participantsById.remove(senderId);
      });
      return;
    }

    if (type != null && type.startsWith('webrtc_')) {
      _handleSignalingMessage(payload);
      return;
    }

    // Chat (server always sends type=chat_message, but keep a fallback).
    final nickname = payload['nickname']?.toString() ?? 'Unknown';
    final message = payload['message']?.toString() ?? '';
    if (message.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _messages.add({
        'nickname': nickname,
        'message': message,
        'time': _formatTime(DateTime.now()),
      });
    });
  }

  String _formatTime(DateTime value) {
    var hour = value.hour % 12;
    if (hour == 0) hour = 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
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

      await _connectToCallParticipants();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start voice call: $error')),
      );
    }
  }

  Future<void> _connectToCallParticipants() async {
    final remoteIds = _participantsById.keys
        .where((id) => id != _clientId)
        .take(_maxUsersInCall - 1)
        .toList();

    for (final remoteId in remoteIds) {
      await _createPeerConnection(remoteId, createOffer: true);
    }
  }

  Future<void> _leaveVoiceCall() async {

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

    await _leaveVoiceCall();

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
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _ModeChip(
                    label: _lowBandwidthMode
                        ? 'Low Bandwidth ON'
                        : 'Low Bandwidth',
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
                padding: EdgeInsets.fromLTRB(16, 12, 16, 92 + bottomInset),
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
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16 + bottomInset,
          child: Center(
            child: _FloatingCallDock(
              isMuted: _isMuted,
              isCameraOn: _isCameraOn,
              isVideoMode: _isVideoMode,
              isScreenSharing: _isScreenSharing,
              micEnabled: true,
              cameraEnabled: _isVideoMode && !_isScreenSharing,
              onToggleMute: _toggleMute,
              onToggleCamera: _toggleCamera,
              onToggleShare: _isScreenSharing ? _stopScreenShare : _startScreenShare,
              onLeave: _leaveVoiceCall,
              onMore: () => _openCallMoreSheet(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCallScreen() {
    final tiles = <Map<String, dynamic>>[];
    final bottomInset = MediaQuery.of(context).padding.bottom;

    tiles.add({'name': 'You', 'renderer': _localRenderer, 'local': true});

    for (final entry in _peers.entries.take(_maxUsersInCall - 1)) {
      tiles.add({
        'name': _displayNameFromPeerId(entry.key),
        'renderer': entry.value.renderer,
        'local': false,
      });
    }

    return Stack(
      children: [
        Column(
          children: [
            if (_isScreenSharing)
              Container(
                margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    label: _lowBandwidthMode
                        ? 'Low Bandwidth ON'
                        : 'Low Bandwidth',
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
                padding: EdgeInsets.fromLTRB(8, 8, 8, 92 + bottomInset),
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
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 16 + bottomInset,
          child: Center(
            child: _FloatingCallDock(
              isMuted: _isMuted,
              isCameraOn: _isCameraOn,
              isVideoMode: _isVideoMode,
              isScreenSharing: _isScreenSharing,
              micEnabled: true,
              cameraEnabled: _isVideoMode && !_isScreenSharing,
              onToggleMute: _toggleMute,
              onToggleCamera: _toggleCamera,
              onToggleShare: _isScreenSharing ? _stopScreenShare : _startScreenShare,
              onLeave: _leaveVoiceCall,
              onMore: () => _openCallMoreSheet(context),
            ),
          ),
        ),
      ],
    );
  }

  void _openCallMoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Call controls',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(PhosphorIconsLight.x),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _ModeChip(
                    label: _lowBandwidthMode
                        ? 'Low Bandwidth ON'
                        : 'Low Bandwidth',
                    onTap: () {
                      Navigator.of(context).pop();
                      _toggleLowBandwidthMode();
                    },
                    highlighted: _lowBandwidthMode,
                    icon: _lowBandwidthMode
                        ? PhosphorIconsLight.wifiLow
                        : PhosphorIconsLight.wifiHigh,
                  ),
                  _ModeChip(
                    label: _isVideoMode ? 'Switch to Audio' : 'Switch to Video',
                    onTap: () {
                      Navigator.of(context).pop();
                      _switchAudioVideoMode();
                    },
                    highlighted: !_isVideoMode,
                    icon: _isVideoMode
                        ? PhosphorIconsLight.waveform
                        : PhosphorIconsLight.videoCamera,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _channel.sink.add(
      jsonEncode({
        'type': 'chat_message',
        'sender_id': _clientId,
        'nickname': widget.nickname,
        'message': text,
      }),
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
    final topInset = MediaQuery.of(context).padding.top;
    final displayParticipants = _participantsById.entries.take(4).toList();

    return PreferredSize(
      preferredSize: Size.fromHeight(topInset + 80 + (AppSpacing.sm * 2)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          topInset + AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: SizedBox(
          height: 80,
          child: Container(
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
                          height: 1.05,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.roomLink,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (showChatToggle)
                  IconButton(
                    onPressed: onToggleChat,
                    icon: Icon(
                      PhosphorIconsLight.chatDots,
                      color: chatVisible
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                  ),
                ...displayParticipants.map((participant) {
                  final nickname = participant.value;
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
                SizedBox(
                  height: 36,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(
                      PhosphorIconsLight.userPlus,
                      size: 16,
                    ),
                    label: const Text('Invite'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatPanel(BuildContext context, {bool showHeader = true}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                Text(
                  'Chat',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
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
                IconButton(
                  onPressed: () {},
                  icon: const Icon(PhosphorIconsLight.dotsThree),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Start the conversation!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final item = _messages[index];
                      final nickname = item['nickname'] ?? 'Unknown';
                      final isMine = nickname == widget.nickname;
                      final time = item['time'] ?? '';
                      final initials = nickname.isNotEmpty
                          ? nickname.characters.first.toUpperCase()
                          : '?';

                      final nameLabel = isMine ? 'You' : nickname;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: AppColors.accentSoft,
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        nameLabel,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        time,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: isMine
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      constraints:
                                          const BoxConstraints(maxWidth: 240),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isMine
                                            ? LinearGradient(
                                                colors: [
                                                  AppColors.accent,
                                                  AppColors.accent
                                                      .withOpacity(0.85),
                                                ],
                                              )
                                            : null,
                                        color: isMine
                                            ? null
                                            : AppColors.chatIncoming,
                                        borderRadius:
                                            BorderRadius.circular(18),
                                        border: isMine
                                            ? null
                                            : Border.all(
                                                color: AppColors.border,
                                              ),
                                      ),
                                      child: Text(
                                        item['message'] ?? '',
                                        style: TextStyle(
                                          color: isMine
                                              ? Colors.white
                                              : AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
              const Text(
                'Share room link',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      widget.roomLink,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: widget.roomLink),
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied room link')),
                      );
                    },
                    icon: const Icon(PhosphorIconsLight.copy),
                    color: AppColors.textSecondary,
                  ),
                ],
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
                    icon: PhosphorIconsLight.phoneDisconnect,
                    onPressed:
                        _isInCall ? _leaveVoiceCall : null,
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
                      ? PhosphorIconsLight.screencast
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
      ],
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
                '${_peers.length + 1} members',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          actions: const [SizedBox(width: AppSpacing.sm)],
        ),
        body: _GradientBackground(
          child: _isVideoMode
              ? _buildVideoCallScreen()
              : _buildVoiceCallScreen(),
        ),
      );
    }

    return Scaffold(
      appBar: _buildRoomHeader(
        context,
      ),
      body: _GradientBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 700;
            final isTablet = width >= 700 && width < 1200;

            if (isMobile) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Expanded(child: SingleChildScrollView(child: _buildCenterContent())),
                    const SizedBox(height: AppSpacing.sm),
                    NavigationBar(
                      selectedIndex: _mobileTabIndex,
                      onDestinationSelected: (index) async {
                        setState(() {
                          _mobileTabIndex = index;
                        });

                        if (index == 1) {
                          await showModalBottomSheet<void>(
                            context: context,
                            useSafeArea: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) {
                              return FractionallySizedBox(
                                heightFactor: 0.95,
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Chat',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.sm,
                                              vertical: AppSpacing.xs,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentSoft,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Live',
                                              style: TextStyle(
                                                color: AppColors.accent,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          IconButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            icon: const Icon(
                                              PhosphorIconsLight.x,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Expanded(
                                        child: _buildChatPanel(
                                          context,
                                          showHeader: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                          if (mounted) {
                            setState(() {
                              _mobileTabIndex = 0;
                            });
                          }
                          return;
                        }

                        if (index == 2) {
                          await showModalBottomSheet<void>(
                            context: context,
                            useSafeArea: true,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) {
                              return FractionallySizedBox(
                                heightFactor: 0.65,
                                child: _buildParticipantsPanel(context),
                              );
                            },
                          );
                          if (mounted) {
                            setState(() {
                              _mobileTabIndex = 0;
                            });
                          }
                          return;
                        }
                      },
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(PhosphorIconsLight.videoCamera),
                          label: 'Room',
                        ),
                        NavigationDestination(
                          icon: Icon(PhosphorIconsLight.chatDots),
                          label: 'Chat',
                        ),
                        NavigationDestination(
                          icon: Icon(PhosphorIconsLight.users),
                          label: 'Participants',
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            final sidebarWidth = _sidebarExpanded ? 240.0 : 72.0;
            final panelWidth = isTablet
              ? (width * 0.42).clamp(280.0, 320.0)
              : 320.0;
            final panelTopPadding = AppSpacing.md;
            final panelRightPadding = AppSpacing.md;
            final panelBottomPadding = AppSpacing.md;

            final activeSection = _showParticipantsPanel
              ? _MiniSidebarSection.participants
              : _showChatPanel
              ? _MiniSidebarSection.chat
              : _MiniSidebarSection.room;

            final showScrim = isTablet && (_showChatPanel || _showParticipantsPanel);
            final isChatDocked = !isTablet;
            final dockedRightInset = (_showChatPanel && isChatDocked)
              ? (panelWidth + panelRightPadding + AppSpacing.lg)
              : 0.0;

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MouseRegion(
                        onEnter: (_) {
                          if (!isTablet) {
                            setState(() {
                              _sidebarExpanded = true;
                            });
                          }
                        },
                        onExit: (_) {
                          if (!isTablet) {
                            setState(() {
                              _sidebarExpanded = false;
                            });
                          }
                        },
                        child: SizedBox(
                          width: sidebarWidth,
                          child: _MiniSidebar(
                            expanded: _sidebarExpanded,
                            active: activeSection,
                            onToggleExpand: () {
                              setState(() {
                                _sidebarExpanded = !_sidebarExpanded;
                              });
                            },
                            onRoom: () {
                              _closeOverlays();
                            },
                            onChat: () {
                              setState(() {
                                _showChatPanel = !_showChatPanel;
                                _showParticipantsPanel = false;
                              });
                            },
                            onParticipants: () {
                              setState(() {
                                _showParticipantsPanel = !_showParticipantsPanel;
                                _showChatPanel = false;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.only(right: dockedRightInset),
                          child: SingleChildScrollView(child: _buildCenterContent()),
                        ),
                      ),
                    ],
                  ),
                  if (showScrim)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _closeOverlays,
                        child: Container(
                          color: Colors.black.withOpacity(0.08),
                        ),
                      ),
                    ),
                  _SlidePanel(
                    visible: _showChatPanel,
                    width: panelWidth,
                    top: panelTopPadding,
                    right: panelRightPadding,
                    bottom: panelBottomPadding,
                    docked: isChatDocked,
                    child: _buildChatPanel(context),
                  ),
                  _SlidePanel(
                    visible: _showParticipantsPanel,
                    width: panelWidth,
                    top: panelTopPadding,
                    right: panelRightPadding,
                    bottom: panelBottomPadding,
                    docked: false,
                    child: _buildParticipantsPanel(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildParticipantsPanel(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final participants = _participantsById.entries.toList();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Participants', style: textTheme.titleMedium),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${participants.length}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: () {
                  if (MediaQuery.of(context).size.width >= 700) {
                    setState(() {
                      _showParticipantsPanel = false;
                    });
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(PhosphorIconsLight.x),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.separated(
              itemCount: participants.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final participant = participants[index];
                final nickname = participant.value;
                final initials = nickname.isNotEmpty
                    ? nickname.characters.first.toUpperCase()
                    : '?';

                return Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.accentSoft,
                      child: Text(
                        initials,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        nickname,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: widget.roomLink));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invite link copied')),
                );
              },
              icon: const Icon(PhosphorIconsLight.userPlus, size: 18),
              label: const Text('Invite Participants'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _MiniSidebarSection { room, chat, participants }

class _MiniSidebar extends StatelessWidget {
  const _MiniSidebar({
    required this.expanded,
    required this.active,
    required this.onToggleExpand,
    required this.onRoom,
    required this.onChat,
    required this.onParticipants,
  });

  final bool expanded;
  final _MiniSidebarSection active;
  final VoidCallback onToggleExpand;
  final VoidCallback onRoom;
  final VoidCallback onChat;
  final VoidCallback onParticipants;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              PhosphorIconsLight.hexagon,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _MiniSidebarItem(
            icon: PhosphorIconsLight.videoCamera,
            label: 'Room',
            expanded: expanded,
            active: active == _MiniSidebarSection.room,
            onTap: onRoom,
          ),
          _MiniSidebarItem(
            icon: PhosphorIconsLight.chatDots,
            label: 'Chat',
            expanded: expanded,
            active: active == _MiniSidebarSection.chat,
            onTap: onChat,
          ),
          _MiniSidebarItem(
            icon: PhosphorIconsLight.users,
            label: 'Participants',
            expanded: expanded,
            active: active == _MiniSidebarSection.participants,
            onTap: onParticipants,
          ),
          const Spacer(),
          InkWell(
            onTap: onToggleExpand,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 40,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                expanded
                    ? PhosphorIconsLight.caretLeft
                    : PhosphorIconsLight.caretRight,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSidebarItem extends StatelessWidget {
  const _MiniSidebarItem({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool expanded;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            if (expanded) ...[
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: active ? AppColors.textPrimary : AppColors.textSecondary,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SlidePanel extends StatelessWidget {
  const _SlidePanel({
    required this.visible,
    required this.width,
    required this.top,
    required this.right,
    required this.bottom,
    required this.child,
    required this.docked,
  });

  final bool visible;
  final double width;
  final double top;
  final double right;
  final double bottom;
  final Widget child;
  final bool docked;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      top: top,
      bottom: bottom,
      width: width,
      right: visible ? right : -(width + 24),
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: visible ? 1 : 0,
          child: child,
        ),
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

class _FloatingCallDock extends StatelessWidget {
  const _FloatingCallDock({
    required this.isMuted,
    required this.isCameraOn,
    required this.isVideoMode,
    required this.isScreenSharing,
    required this.micEnabled,
    required this.cameraEnabled,
    required this.onToggleMute,
    required this.onToggleCamera,
    required this.onToggleShare,
    required this.onMore,
    required this.onLeave,
  });

  final bool isMuted;
  final bool isCameraOn;
  final bool isVideoMode;
  final bool isScreenSharing;
  final bool micEnabled;
  final bool cameraEnabled;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleCamera;
  final VoidCallback onToggleShare;
  final VoidCallback onMore;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _DockCircleButton(
            icon: isMuted
                ? PhosphorIconsLight.microphoneSlash
                : PhosphorIconsLight.microphone,
            onTap: micEnabled ? onToggleMute : null,
            active: !isMuted,
          ),
          const SizedBox(width: 10),
          _DockCircleButton(
            icon: isCameraOn
                ? PhosphorIconsLight.videoCamera
                : PhosphorIconsLight.videoCameraSlash,
            onTap: cameraEnabled ? onToggleCamera : null,
            active: isVideoMode && isCameraOn,
          ),
          const SizedBox(width: 10),
          _DockCircleButton(
            icon: isScreenSharing
                ? PhosphorIconsLight.screencast
                : PhosphorIconsLight.monitorArrowUp,
            onTap: isVideoMode ? onToggleShare : null,
            active: isScreenSharing,
          ),
          const SizedBox(width: 10),
          _DockCircleButton(
            icon: PhosphorIconsLight.dotsThree,
            onTap: onMore,
          ),
          const SizedBox(width: 10),
          _DockCircleButton(
            icon: PhosphorIconsLight.phoneDisconnect,
            onTap: onLeave,
            danger: true,
          ),
        ],
      ),
    );
  }
}

class _DockCircleButton extends StatelessWidget {
  const _DockCircleButton({
    required this.icon,
    required this.onTap,
    this.active = false,
    this.danger = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool active;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    Color bgColor = AppColors.background;
    Color borderColor = AppColors.border;
    Color iconColor = AppColors.textSecondary;

    if (danger) {
      bgColor = AppColors.danger;
      borderColor = AppColors.danger;
      iconColor = Colors.white;
    } else if (active) {
      bgColor = AppColors.accentSoft;
      borderColor = AppColors.accentSoft;
      iconColor = AppColors.accent;
    }

    if (!enabled && !danger) {
      bgColor = AppColors.background;
      borderColor = AppColors.border;
      iconColor = AppColors.textSecondary;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Opacity(
        opacity: enabled || danger ? 1 : 0.55,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    );
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
                if (trailing case final t?) t,
              ],
            ),
            if (child case final c?) c,
          ],
        ),
      ),
    );
  }
}

class ApiService {
  static const String baseUrl = 'https://chatapp-jba7.onrender.com';

  static String roomInviteLink(String roomId) {
    if (kIsWeb) {
      return Uri.base.replace(path: '/room/$roomId', query: '').toString();
    }
    return '${baseUrl.replaceAll(RegExp(r"/+\$"), '')}/room/$roomId';
  }

  static Uri wsRoomUri(String roomId) {
    final httpUri = Uri.parse(baseUrl);
    final wsScheme = httpUri.scheme == 'https' ? 'wss' : 'ws';
    return Uri.parse('$wsScheme://${httpUri.authority}/ws/chat/$roomId/');
  }

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
