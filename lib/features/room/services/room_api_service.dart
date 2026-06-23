import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/room_models.dart';

class RoomApiService {
  RoomApiService({
    this.httpBaseUrl = roomShareBaseUrl,
    String? websocketBaseUrl,
  }) : websocketBaseUrl = websocketBaseUrl ?? httpBaseUrl.replaceFirst('http', 'ws');

  final String httpBaseUrl;
  final String websocketBaseUrl;

  Future<Map<String, dynamic>> createRoom({
    required String roomId,
    required String nickname,
    required RoomType roomType,
    required int maxMembers,
  }) async {
    final response = await http.post(
      Uri.parse('$httpBaseUrl/api/rooms/create/'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'room_id': roomId,
        'nickname': nickname,
        'room_type': roomType.name,
        'max_members': maxMembers,
      }),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> joinRoom({
    required String roomId,
    required String nickname,
  }) async {
    final response = await http.post(
      Uri.parse('$httpBaseUrl/api/rooms/join/'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'room_id': roomId,
        'nickname': nickname,
      }),
    );
    return _decodeResponse(response);
  }

  WebSocketChannel connectRoomSocket(String roomId) {
    return WebSocketChannel.connect(Uri.parse('$websocketBaseUrl/ws/chat/$roomId/'));
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final body = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final error = (body['error'] as String?) ?? 'Request failed (${response.statusCode})';
    throw Exception(error);
  }
}
