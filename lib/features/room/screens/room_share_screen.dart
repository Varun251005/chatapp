import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../theme/spacing.dart';
import '../services/room_controller.dart';
import '../widgets/app_widgets.dart';
import '../widgets/qr_and_join_sheets.dart';

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
                    InfoCard(
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
                    InfoCard(
                      title: 'QR Code',
                      child: QrCard(data: room.qrPayload),
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
