import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../services/room_controller.dart';
import '../widgets/app_widgets.dart';
import '../widgets/workspace_shell.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  int _tabIndex = 0;

  @override
  void dispose() {
    _linkController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatSnapWorkspaceShell(
      selected: ChatSnapSection.join,
      onHome: () => context.go('/home'),
      onCreate: () => context.go('/create'),
      onJoin: () => context.go('/join'),
      onScan: () {},
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
              boxShadow: AppTheme.softShadow,
            ),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Join a Room', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Enter a room link or code to connect instantly.', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _TabButton(label: 'Join with Link', active: _tabIndex == 0, onTap: () => setState(() => _tabIndex = 0))),
                    const SizedBox(width: 10),
                    Expanded(child: _TabButton(label: 'Join with Code', active: _tabIndex == 1, onTap: () => setState(() => _tabIndex = 1))),
                  ],
                ),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _tabIndex == 0 ? _JoinByLink(controller: _linkController) : _JoinByCode(controller: _codeController),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JoinByLink extends StatelessWidget {
  const _JoinByLink({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('link'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Paste Invite Link', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        TextField(controller: controller, decoration: const InputDecoration(hintText: 'https://chatsnap.app/join/room-name')),
        const SizedBox(height: 16),
        Consumer<RoomController>(
          builder: (context, roomController, _) {
            return PrimaryButton(
              label: roomController.isBusy ? 'Joining...' : 'Join Room',
              onPressed: roomController.isBusy
                  ? null
                  : () async {
                      try {
                        await roomController.joinRoom(controller.text);
                        if (context.mounted) {
                          context.go('/share');
                        }
                      } catch (_) {}
                    },
            );
          },
        ),
      ],
    );
  }
}

class _JoinByCode extends StatelessWidget {
  const _JoinByCode({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('code'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Enter Room Code', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        TextField(controller: controller, decoration: const InputDecoration(hintText: 'blue-tiger')),
        const SizedBox(height: 16),
        Consumer<RoomController>(
          builder: (context, roomController, _) {
            return PrimaryButton(
              label: roomController.isBusy ? 'Joining...' : 'Join Room',
              onPressed: roomController.isBusy
                  ? null
                  : () async {
                      try {
                        await roomController.joinRoom(controller.text);
                        if (context.mounted) {
                          context.go('/share');
                        }
                      } catch (_) {}
                    },
            );
          },
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.accentSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? AppColors.accent : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.accent : AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}