import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';
import '../widgets/app_widgets.dart';
import '../widgets/qr_and_join_sheets.dart';

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
                  const BrandMark(compact: true),
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
      builder: (_) => const JoinRoomSheet(),
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
