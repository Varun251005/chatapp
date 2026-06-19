import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/spacing.dart';

class VideoCallScreen extends StatelessWidget {
  const VideoCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/chat'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('blue-tiger'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: Text('00:12:45', style: TextStyle(color: Colors.white70))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: const [
                  _VideoTile(name: 'Rahul', color: Color(0xFF302A3F)),
                  _VideoTile(name: 'Anita', color: Color(0xFF4A3648)),
                  _VideoTile(name: 'You', color: Color(0xFF2E3A52)),
                  _VideoTile(name: 'Waiting...', isWaiting: true, color: Color(0xFF1D2330)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF101626),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _VideoControl(icon: Icons.mic_none_rounded, label: 'Mute'),
                  _VideoControl(icon: Icons.videocam_off_outlined, label: 'Stop Video'),
                  _VideoControl(icon: Icons.screen_share_outlined, label: 'Share Screen'),
                  _VideoControl(icon: Icons.people_outline, label: 'Members'),
                  _VideoControl(icon: Icons.chat_bubble_outline, label: 'Chat'),
                  _VideoControl(icon: Icons.more_horiz, label: 'More'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  const _VideoTile({required this.name, required this.color, this.isWaiting = false});

  final String name;
  final Color color;
  final bool isWaiting;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withAlpha(178)],
          ),
        ),
        child: Center(
          child: isWaiting
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 48, color: Colors.white54),
                    SizedBox(height: 12),
                    Text('Waiting...', style: TextStyle(color: Colors.white70)),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(radius: 34, backgroundColor: Colors.white24, child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700))),
                    const SizedBox(height: 12),
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
        ),
      ),
    );
  }
}

class _VideoControl extends StatelessWidget {
  const _VideoControl({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white10,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}