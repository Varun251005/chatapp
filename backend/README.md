# Django backend (in-memory rooms + realtime chat)

This folder contains beginner-friendly Django code for room creation/joining and realtime chat.

## Files

- `rooms/storage.py`: in-memory dictionary storage (`rooms = {}`)
- `rooms/views.py`: create and join API views
- `rooms/urls.py`: room API routes
- `rooms/consumers.py`: websocket consumer for room chat
- `rooms/routing.py`: websocket route definitions
- `chat_backend/urls.py`: project URL includes
- `chat_backend/asgi.py`: ASGI app with Channels websocket support
- `chat_backend/routing.py`: root websocket routing
- `requirements.txt`: Django + Channels dependencies

## API endpoints

- `POST /api/rooms/create/` with JSON `{ "nickname": "alice" }`
- `POST /api/rooms/join/` with JSON `{ "room_id": "abcd1234", "nickname": "bob" }`

## Important note

Because storage is in memory, all rooms are lost when the Django server restarts.

## Example Django wiring

In your Django `settings.py`, make sure:

```python
INSTALLED_APPS = [
    # ...
    "channels",
    "rooms",
]

ASGI_APPLICATION = "chat_backend.asgi.application"

CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels.layers.InMemoryChannelLayer",
    }
}
```

In your project `urls.py`:

```python
from django.urls import include, path

urlpatterns = [
    path("api/rooms/", include("rooms.urls")),
]
```

## WebSocket endpoint

- `ws://<host>:<port>/ws/chat/<room_id>/`

Each room uses its own Channels group name: `room_<room_id>`.

## WebRTC signaling messages

Signaling uses the same room websocket connection.

- `webrtc_ready`
- `webrtc_offer` with `sdp`
- `webrtc_answer` with `sdp`
- `webrtc_ice` with `candidate` object
- `webrtc_leave`

All signaling payloads include `sender_id` so clients can ignore their own messages.

## Whiteboard websocket data format

Whiteboard uses the same room websocket.

- Draw point:

```json
{
    "type": "whiteboard_draw",
    "action": "start|move|end",
    "x": 0.42,
    "y": 0.37,
    "sender_id": "user-123"
}
```

`x` and `y` are normalized values (0 to 1), so rendering stays consistent across screen sizes.

- Clear board:

```json
{
    "type": "whiteboard_clear",
    "sender_id": "user-123"
}
```

## Host control system

- First room user is host (`room.host`).
- On websocket `room_register`, server sends:
    - `room_state` (`host`, `presentation_mode`, `muted_users`)
    - `room_participants` (live participant list with host/mute flags)

Host-only websocket actions:

- `host_set_presentation_mode` with `enabled: true|false`
- `host_mute_user` with `target_id` and `muted: true|false`
- `host_kick_user` with `target_id`

Synced server events:

- `room_state`
- `room_participants`
- `room_user_muted` (targeted by `target_id`)
- `room_kicked` (targeted by `target_id`)

Presentation mode behavior:

- When enabled, server mutes all non-host users.
- Host remains unmuted.

## Run

```bash
cd backend
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

## Quick health check

Before opening Flutter web, verify backend API:

```bash
curl -X POST http://127.0.0.1:8000/api/rooms/create/ \
    -H "Content-Type: application/json" \
    -d '{"nickname":"test"}'
```

Expected: JSON with `room_id` and `room_link`.

If Flutter shows `ClientException: Failed to fetch`, usually backend is not running or running on a different port.

## Flutter websocket

The Flutter app connects to:

- `ws://127.0.0.1:8000/ws/chat/<room_id>/`

If you run Flutter on an Android emulator, use `10.0.2.2` instead of `127.0.0.1`.
