import 'package:flutter/material.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

enum ChatSnapSection { home, create, join }

class ChatSnapWorkspaceShell extends StatelessWidget {
  const ChatSnapWorkspaceShell({
    super.key,
    required this.selected,
    required this.child,
    required this.onHome,
    required this.onCreate,
    required this.onJoin,
    required this.onScan,
  });

  final ChatSnapSection selected;
  final Widget child;
  final VoidCallback onHome;
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;

            if (!wide) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: child,
              );
            }

            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  _Sidebar(
                    selected: selected,
                    onHome: onHome,
                    onCreate: onCreate,
                    onJoin: onJoin,
                    onScan: onScan,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: child,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selected,
    required this.onHome,
    required this.onCreate,
    required this.onJoin,
    required this.onScan,
  });

  final ChatSnapSection selected;
  final VoidCallback onHome;
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.sidebarTop, AppColors.sidebarBottom],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.forum_rounded, size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Text(
                'ChatSnap',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SidebarItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: selected == ChatSnapSection.home,
            onTap: onHome,
          ),
          _SidebarItem(
            icon: Icons.add_circle_outline_rounded,
            label: 'Create Room',
            selected: selected == ChatSnapSection.create,
            onTap: onCreate,
          ),
          _SidebarItem(
            icon: Icons.login_rounded,
            label: 'Join Room',
            selected: selected == ChatSnapSection.join,
            onTap: onJoin,
          ),
          _SidebarItem(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Scan QR Code',
            selected: false,
            onTap: onScan,
          ),
          const Spacer(),
          _SidebarItem(
            icon: Icons.info_outline_rounded,
            label: 'About',
            selected: false,
            onTap: () {},
          ),
          _SidebarItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            selected: false,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(icon, size: 17, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
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