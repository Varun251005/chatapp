import 'package:go_router/go_router.dart';

import '../../features/room/screens/chat_room_screen.dart';
import '../../features/room/screens/create_room_screen.dart';
import '../../features/room/screens/home_screen.dart';
import '../../features/room/screens/join_room_screen.dart';
import '../../features/room/screens/room_share_screen.dart';
import '../../features/room/screens/splash_screen.dart';
import '../../features/room/screens/video_call_screen.dart';

GoRouter buildAppRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: <RouteBase>[
      GoRoute(path: '/', redirect: (context, state) => '/home'),
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/create', builder: (context, state) => const CreateRoomScreen()),
      GoRoute(path: '/join', builder: (context, state) => const JoinRoomScreen()),
      GoRoute(path: '/share', builder: (context, state) => const RoomShareScreen()),
      GoRoute(path: '/chat', builder: (context, state) => const ChatRoomScreen()),
      GoRoute(path: '/video', builder: (context, state) => const VideoCallScreen()),
    ],
  );
}
