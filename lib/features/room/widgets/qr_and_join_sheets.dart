import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../theme/spacing.dart';
import '../services/room_controller.dart';
import 'app_widgets.dart';

class QrCard extends StatelessWidget {
  const QrCard({super.key, required this.data});

  final String data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: QrImageView(
            data: data,
            size: 220,
            backgroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

class JoinRoomSheet extends StatefulWidget {
  const JoinRoomSheet({super.key});

  @override
  State<JoinRoomSheet> createState() => _JoinRoomSheetState();
}

class _JoinRoomSheetState extends State<JoinRoomSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Join Room', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Paste invite link or room code'),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Join',
            onPressed: () {
              if (_controller.text.trim().isEmpty) return;
              context.read<RoomController>().joinRoom(_controller.text);
              Navigator.of(context).pop();
              context.go('/chat');
            },
          ),
        ],
      ),
    );
  }
}

class ScanQrSheet extends StatefulWidget {
  const ScanQrSheet({super.key});

  @override
  State<ScanQrSheet> createState() => _ScanQrSheetState();
}

class _ScanQrSheetState extends State<ScanQrSheet> {
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _scannerController = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canScan = !kIsWeb && _scannerController != null;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Scan QR', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.md),
          if (canScan)
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
                    final value = barcode?.rawValue;
                    if (value == null || value.isEmpty) {
                      return;
                    }
                    context.read<RoomController>().joinByScan(value);
                    Navigator.of(context).pop();
                    context.go('/chat');
                  },
                ),
              ),
            )
          else
            const Text('Camera scanning is unavailable here. Paste an invite link instead.'),
          const SizedBox(height: AppSpacing.md),
          TextField(
            decoration: const InputDecoration(hintText: 'Fallback: paste room link'),
            onSubmitted: (value) {
              if (value.trim().isEmpty) return;
              context.read<RoomController>().joinByScan(value);
              Navigator.of(context).pop();
              context.go('/chat');
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: 'https://chatsnap.app/room/blue-tiger?type=chat&max=4'));
            },
            child: const Text('Copy sample room link'),
          ),
        ],
      ),
    );
  }
}
