import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/room_models.dart';
import '../services/room_controller.dart';
import '../widgets/app_widgets.dart';
import '../../../theme/spacing.dart';

class CreateRoomScreen extends StatelessWidget {
  const CreateRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoomController>(
      builder: (context, controller, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Create Room')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SectionTitle(
                      title: 'Room Type',
                      subtitle: 'Choose the kind of room you want to create.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: RoomType.values.map((roomType) {
                        final isSelected = controller.selectedRoomType == roomType;
                        return ChoiceChip(
                          selected: isSelected,
                          label: Text(roomType.label),
                          onSelected: (_) => controller.setRoomType(roomType),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const SectionTitle(
                      title: 'Max Members',
                      subtitle: 'Keep it small and focused.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: <int>[2, 4].map((value) {
                        return ChoiceChip(
                          selected: controller.selectedMaxMembers == value,
                          label: Text('$value'),
                          onSelected: (_) => controller.setMaxMembers(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    PrimaryButton(
                      label: 'Create',
                      onPressed: () {
                        controller.createRoom();
                        context.go('/share');
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
