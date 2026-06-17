import 'package:go_router/go_router.dart';

import '../../features/room/screens/chat_room_screen.dart';
import '../../features/room/screens/create_room_screen.dart';
import '../../features/room/screens/home_screen.dart';
import '../../features/room/screens/room_share_screen.dart';
import '../../features/room/screens/splash_screen.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/splash',
    routes: <RouteBase>[
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/create', builder: (context, state) => const CreateRoomScreen()),
      GoRoute(path: '/share', builder: (context, state) => const RoomShareScreen()),
      GoRoute(path: '/chat', builder: (context, state) => const ChatRoomScreen()),
    ],
  );
}
