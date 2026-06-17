import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../theme/spacing.dart';
import '../models/room_models.dart';
import '../services/room_controller.dart';
import '../widgets/app_widgets.dart';

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
                  child: InfoCard(
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
            color: const Color(0xFFFFF1E8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(message.text),
        ),
      );
    }

    final alignment = message.isMine ? Alignment.centerRight : Alignment.centerLeft;
    final color = message.isMine ? const Color(0xFFFF8A4C) : const Color(0xFFF5F5F5);
    final textColor = message.isMine ? Colors.white : const Color(0xFF1F2937);

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
