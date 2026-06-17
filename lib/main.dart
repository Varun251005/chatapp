import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'theme/app_theme.dart';
import 'theme/colors.dart';
import 'theme/spacing.dart';

void main() {
  runApp(const ChatSnapApp());
}

enum RoomType { chat, voice, video }

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

  IconData get icon {
    switch (this) {
      case RoomType.chat:
        return Icons.chat_bubble_outline;
      case RoomType.voice:
        return Icons.mic_none;
      case RoomType.video:
        return Icons.videocam_outlined;
    }
  }
}

enum CallMode { idle, voice, video }

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

  late final String inviteLink =
      'https://chatsnap.app/room/$roomId?type=${roomType.name}&max=$maxMembers';
  late final String qrPayload = inviteLink;
}

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

  void joinByScan(String rawValue) {
    joinRoom(rawValue);
  }

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

class ChatSnapApp extends StatelessWidget {
  const ChatSnapApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: '/splash',
    routes: <RouteBase>[
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/create', builder: (context, state) => const CreateRoomScreen()),
      GoRoute(path: '/share', builder: (context, state) => const RoomShareScreen()),
      GoRoute(path: '/chat', builder: (context, state) => const ChatRoomScreen()),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RoomController(),
      child: MaterialApp.router(
        title: 'ChatSnap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        routerConfig: _router,
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1100), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFFFF7F0), AppColors.background],
          ),
        ),
        child: const Center(child: _BrandMark()),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _BrandMark(compact: true),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Create temporary rooms and invite people with a link or QR code.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(label: 'Create Room', onPressed: () => context.go('/create')),
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    label: 'Join Room',
                    onPressed: () => _openJoinSheet(context),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SecondaryButton(
                    label: 'Scan QR',
                    onPressed: () => _openScanSheet(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openJoinSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _JoinRoomSheet(),
    );
  }

  void _openScanSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _ScanQrSheet(),
    );
  }
}

class CreateRoomScreen extends StatelessWidget {
  const CreateRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Create Room')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SectionTitle(
                      title: 'Room Type',
                      subtitle: 'Choose the kind of room you want to create.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: RoomType.values.map((roomType) {
                        final isSelected = controller.selectedRoomType == roomType;
                        return ChoiceChip(
                          selected: isSelected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(roomType.icon, size: 18),
                              const SizedBox(width: 8),
                              Text(roomType.label),
                            ],
                          ),
                          onSelected: (_) => controller.setRoomType(roomType),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionTitle(
                      title: 'Max Members',
                      subtitle: 'Keep it small and focused.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: <int>[2, 4].map((value) {
                        return ChoiceChip(
                          selected: controller.selectedMaxMembers == value,
                          label: Text('$value'),
                          onSelected: (_) => controller.setMaxMembers(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Create',
                      onPressed: () {
                        controller.createRoom();
                        context.go('/share');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class RoomShareScreen extends StatelessWidget {
  const RoomShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomController>(
      builder: (context, controller, _) {
        final room = controller.currentRoom;

        if (room == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Room Created')),
            body: Center(
              child: PrimaryButton(label: 'Back Home', onPressed: () => context.go('/home')),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Room Created')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      'Room Name',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      room.roomName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _InfoCard(
                      title: 'Invite Link',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SelectableText(room.inviteLink),
                          const SizedBox(height: AppSpacing.md),
                          SecondaryButton(
                            label: 'Copy',
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: room.inviteLink));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invite link copied')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _InfoCard(
                      title: 'QR Code',
                      child: Center(
                        child: QrImageView(
                          data: room.qrPayload,
                          size: 220,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Start Room',
                      onPressed: () {
                        controller.startRoom();
                        context.go('/chat');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ChatRoomScreen extends StatelessWidget {
  const ChatRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomController>(
      builder: (context, controller, _) {
        final room = controller.currentRoom;

        if (room == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat Room')),
            body: Center(
              child: PrimaryButton(label: 'Back Home', onPressed: () => context.go('/home')),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(room.roomName)),
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
                  child: Row(
                    children: <Widget>[
                      Text(
                        'Members: ${controller.memberCount}/${room.maxMembers}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Chip(label: Text(room.roomType.label)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                  child: _InfoCard(
                    title: 'Call Status',
                    child: Text(_callLabel(controller.callMode)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE9E5E1)),
                    ),
                    child: ListView.separated(
                      itemCount: controller.messages.length,
                      separatorBuilder: (context, _) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final message = controller.messages[index];
                        return _MessageBubble(message: message);
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: controller.messageController,
                          decoration: const InputDecoration(hintText: 'Message box'),
                          minLines: 1,
                          maxLines: 4,
                          onSubmitted: (_) => controller.sendMessage(),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filled(
                        onPressed: controller.canSend ? controller.sendMessage : null,
                        icon: const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      SecondaryButton(
                        label: controller.callMode == CallMode.voice ? 'End Voice Call' : 'Voice Call',
                        onPressed: controller.toggleVoiceCall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SecondaryButton(
                        label: controller.callMode == CallMode.video ? 'End Video Call' : 'Video Call',
                        onPressed: controller.toggleVideoCall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      DangerButton(
                        label: 'Leave Room',
                        onPressed: () {
                          controller.leaveRoom();
                          context.go('/home');
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _callLabel(CallMode callMode) {
    switch (callMode) {
      case CallMode.idle:
        return 'Ready';
      case CallMode.voice:
        return 'Voice call active';
      case CallMode.video:
        return 'Video call active';
    }
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 88.0 : 108.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            shape: BoxShape.circle,
            boxShadow: AppTheme.softShadow,
          ),
          child: const Icon(Icons.forum_rounded, color: AppColors.accent, size: 44),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'ChatSnap',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: compact ? 34 : 42,
              ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final RoomMessage message;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(message.text),
        ),
      );
    }

    final alignment = message.isMine ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isMine ? AppColors.accent : AppColors.chatIncoming;
    final textColor = message.isMine ? Colors.white : AppColors.textPrimary;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              message.sender,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(message.text, style: TextStyle(color: textColor)),
          ],
        ),
      ),
    );
  }
}

class _JoinRoomSheet extends StatefulWidget {
  const _JoinRoomSheet();

  @override
  State<_JoinRoomSheet> createState() => _JoinRoomSheetState();
}

class _JoinRoomSheetState extends State<_JoinRoomSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Join Room', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Paste invite link or room code'),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Join',
            onPressed: () {
              if (_controller.text.trim().isEmpty) return;
              context.read<RoomController>().joinRoom(_controller.text);
              Navigator.of(context).pop();
              context.go('/chat');
            },
          ),
        ],
      ),
    );
  }
}

class _ScanQrSheet extends StatefulWidget {
  const _ScanQrSheet();

  @override
  State<_ScanQrSheet> createState() => _ScanQrSheetState();
}

class _ScanQrSheetState extends State<_ScanQrSheet> {
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _scannerController = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canScan = !kIsWeb && _scannerController != null;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Scan QR', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          if (canScan)
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
                    final value = barcode?.rawValue;
                    if (value == null || value.isEmpty) {
                      return;
                    }
                    context.read<RoomController>().joinByScan(value);
                    Navigator.of(context).pop();
                    context.go('/chat');
                  },
                ),
              ),
            )
          else
            const Text('Camera scanning is unavailable here. Paste an invite link instead.'),
          const SizedBox(height: AppSpacing.md),
          TextField(
            decoration: const InputDecoration(hintText: 'Fallback: paste room link'),
            onSubmitted: (value) {
              if (value.trim().isEmpty) return;
              context.read<RoomController>().joinByScan(value);
              Navigator.of(context).pop();
              context.go('/chat');
            },
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}

class DangerButton extends StatelessWidget {
  const DangerButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
        ),
        child: Text(label),
      ),
    );
  }
}