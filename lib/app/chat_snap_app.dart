import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes/app_router.dart';
import '../features/room/services/room_controller.dart';
import '../theme/app_theme.dart';

class ChatSnapApp extends StatelessWidget {
  const ChatSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RoomController(),
      child: MaterialApp.router(
        title: 'ChatSnap',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme(),
        routerConfig: buildAppRouter(),
      ),
    );
  }
}
