import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/app_theme.dart';
import '../../../theme/colors.dart';
import '../widgets/qr_and_join_sheets.dart';
import '../widgets/workspace_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChatSnapWorkspaceShell(
      selected: ChatSnapSection.home,
      onHome: () => context.go('/home'),
      onCreate: () => context.go('/create'),
      onJoin: () => context.go('/join'),
      onScan: () => _openScanSheet(context),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Container(
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                    children: const [
                      TextSpan(text: 'Welcome to '),
                      TextSpan(
                        text: 'ChatSnap',
                        style: TextStyle(color: AppColors.accent),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Connect instantly with friends using rooms',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 138,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      Positioned(
                        left: 240,
                        top: 16,
                        child: Container(width: 44, height: 44, decoration: const BoxDecoration(color: Color(0xFFE9DFFF), shape: BoxShape.circle)),
                      ),
                      Positioned(
                        right: 244,
                        top: 40,
                        child: Container(width: 28, height: 28, decoration: const BoxDecoration(color: Color(0xFFD8CCFF), shape: BoxShape.circle)),
                      ),
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [BoxShadow(color: Color(0x266E57F7), blurRadius: 20, offset: Offset(0, 8))],
                        ),
                        child: const Icon(Icons.forum_rounded, color: Colors.white, size: 36),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _HomeActionCard(
                        title: 'Create Room',
                        subtitle: 'Create a new room',
                        icon: Icons.add_circle,
                        color: const Color(0xFF6E57F7),
                        onTap: () => context.go('/create'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _HomeActionCard(
                        title: 'Join Room',
                        subtitle: 'Join with a link',
                        icon: Icons.login_rounded,
                        color: const Color(0xFF26B36D),
                        onTap: () => context.go('/join'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _HomeActionCard(
                        title: 'Scan QR Code',
                        subtitle: 'Scan and join',
                        icon: Icons.qr_code_2_rounded,
                        color: const Color(0xFF2F7AF8),
                        onTap: () => _openScanSheet(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openScanSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ScanQrSheet(),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(31),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
