import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../models/room_models.dart';
import '../services/room_controller.dart';
import '../widgets/app_widgets.dart';
import '../widgets/qr_and_join_sheets.dart';
import '../widgets/workspace_shell.dart';

class RoomShareScreen extends StatelessWidget {
  const RoomShareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomController>(
      builder: (context, controller, _) {
        final room = controller.currentRoom;

        if (room == null) {
          return ChatSnapWorkspaceShell(
            selected: ChatSnapSection.create,
            onHome: () => context.go('/home'),
            onCreate: () => context.go('/create'),
            onJoin: () => context.go('/join'),
            onScan: () {},
            child: Center(
              child: PrimaryButton(label: 'Back Home', onPressed: () => context.go('/home')),
            ),
          );
        }

        return ChatSnapWorkspaceShell(
          selected: ChatSnapSection.create,
          onHome: () => context.go('/home'),
          onCreate: () => context.go('/create'),
          onJoin: () => context.go('/join'),
          onScan: () {},
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text('Room Created Successfully! 🎉', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          const Text('Share the link or QR code with your friends', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'Room Name',
                            child: Row(
                              children: [
                                Text(room.roomName, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.accent, fontWeight: FontWeight.w800)),
                                const SizedBox(width: 8),
                                const Icon(Icons.copy_rounded, color: AppColors.iconMuted, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _SummaryCard(
                            title: 'Invite Link',
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(room.inviteLink, style: const TextStyle(color: AppColors.accent)),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(text: room.inviteLink));
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite link copied')));
                                    }
                                  },
                                  child: const Text('Copy'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 800) {
                          return Column(
                            children: [
                              _SummaryCard(title: 'QR Code', child: QrCard(data: room.qrPayload)),
                              const SizedBox(height: 18),
                              _SummaryCard(
                                title: 'Room Details',
                                child: _RoomDetails(room: room),
                              ),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _SummaryCard(title: 'QR Code', child: QrCard(data: room.qrPayload))),
                            const SizedBox(width: 18),
                            Expanded(child: _SummaryCard(title: 'Room Details', child: _RoomDetails(room: room))),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label: 'Start Room',
                      onPressed: () async {
                        await controller.startRoom();
                        if (context.mounted) {
                          context.go('/chat');
                        }
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RoomDetails extends StatelessWidget {
  const _RoomDetails({required this.room});

  final RoomSession room;

  @override
  Widget build(BuildContext context) {
    final details = <MapEntry<String, String>>[
      MapEntry('Type', room.roomType.label),
      MapEntry('Max Members', '${room.maxMembers}'),
      MapEntry('Room ID', room.roomId),
      MapEntry('Invite Link', room.inviteLink),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: details
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 100, child: Text(entry.key, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                  Expanded(child: Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
