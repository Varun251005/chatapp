import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../models/room_models.dart';
import '../services/room_controller.dart';
import '../widgets/app_widgets.dart';
import '../widgets/workspace_shell.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _roomNameController = TextEditingController();

  @override
  void dispose() {
    _roomNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatSnapWorkspaceShell(
      selected: ChatSnapSection.create,
      onHome: () => context.go('/home'),
      onCreate: () => context.go('/create'),
      onJoin: () => context.go('/join'),
      onScan: () {},
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Consumer<RoomController>(
            builder: (context, controller, _) {
              return Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Create New Room', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Set up your room preferences', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 28),
                    _SectionLabel(title: 'Room Type'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _TypeCard(label: 'Chat', subtitle: 'Text messaging', icon: Icons.chat_bubble_rounded, selected: controller.selectedRoomType == RoomType.chat, onTap: () => controller.setRoomType(RoomType.chat))),
                        const SizedBox(width: 12),
                        Expanded(child: _TypeCard(label: 'Voice', subtitle: 'Voice call', icon: Icons.mic_rounded, selected: controller.selectedRoomType == RoomType.voice, onTap: () => controller.setRoomType(RoomType.voice))),
                        const SizedBox(width: 12),
                        Expanded(child: _TypeCard(label: 'Video', subtitle: 'Video call', icon: Icons.videocam_rounded, selected: controller.selectedRoomType == RoomType.video, onTap: () => controller.setRoomType(RoomType.video))),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _SectionLabel(title: 'Max Members'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _MemberCard(label: '2 Members', selected: controller.selectedMaxMembers == 2, onTap: () => controller.setMaxMembers(2))),
                        const SizedBox(width: 12),
                        Expanded(child: _MemberCard(label: '4 Members', selected: controller.selectedMaxMembers == 4, onTap: () => controller.setMaxMembers(4))),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Align(alignment: Alignment.centerLeft, child: Text('Room Name (optional)', style: TextStyle(fontWeight: FontWeight.w700))),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _roomNameController,
                      decoration: const InputDecoration(hintText: 'blue-tiger'),
                    ),
                    const SizedBox(height: 10),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Leave blank to generate a random name', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                      label: controller.isBusy ? 'Creating...' : 'Create Room',
                      onPressed: controller.isBusy
                          ? null
                          : () async {
                              try {
                                await controller.createRoom(roomName: _roomNameController.text);
                                if (context.mounted) {
                                  context.go('/share');
                                }
                              } catch (_) {}
                            },
                    ),
                    if (controller.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(controller.errorMessage!, style: const TextStyle(color: AppColors.danger)),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.label, required this.subtitle, required this.icon, required this.selected, required this.onTap});

  final String label;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected ? AppColors.accent : AppColors.border;
    final bg = selected ? AppColors.accentSoft : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 96,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: selected ? 1.4 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? AppColors.accent : AppColors.textSecondary, size: 28),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accentSoft : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? AppColors.accent : AppColors.border, width: selected ? 1.4 : 1),
          ),
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: selected ? AppColors.accent : AppColors.textPrimary)),
        ),
      ),
    );
  }
}
