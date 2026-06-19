import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
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
            body: Center(
              child: PrimaryButton(label: 'Back Home', onPressed: () => context.go('/home')),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.roomName, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('${controller.memberCount}/${room.maxMembers} members', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
            actions: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.person_add_alt_1_outlined)),
              IconButton(onPressed: controller.toggleVoiceCall, icon: const Icon(Icons.call_outlined)),
              IconButton(onPressed: () => context.go('/video'), icon: const Icon(Icons.videocam_outlined)),
              PopupMenuButton<void>(itemBuilder: (_) => [const PopupMenuItem(child: Text('More'))]),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border),
                              boxShadow: AppTheme.softShadow,
                            ),
                            child: ListView.separated(
                              itemCount: controller.messages.length,
                              reverse: false,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final message = controller.messages[index];
                                return _MessageBubble(message: message);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _Composer(
                          controller: controller,
                          onSend: controller.sendMessage,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Text('Members (${controller.memberCount})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                              const Spacer(),
                              const Icon(Icons.circle, size: 8, color: AppColors.success),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.separated(
                              itemCount: controller.memberCount,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final names = controller.currentRoom == null ? const ['You'] : [controller.nickname];
                                final name = index < names.length ? names[index] : 'Member ${index + 1}';
                                return _MemberRow(name: name, online: index == 0);
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                            label: const Text('Invite Friends'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
          child: Text(message.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
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

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final RoomController controller;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.attach_file_rounded)),
          Expanded(
            child: TextField(
              controller: controller.messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                fillColor: Colors.transparent,
              ),
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(onPressed: controller.canSend ? onSend : null, icon: const Icon(Icons.send_rounded, color: AppColors.accent)),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.name, required this.online});

  final String name;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.accentSoft,
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(online ? 'Online' : 'Offline', style: TextStyle(color: online ? AppColors.success : AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
