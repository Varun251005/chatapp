import json

from channels.generic.websocket import AsyncWebsocketConsumer

from .storage import (
    cleanup_stale_presence,
    get_room,
    is_host,
    kick_user,
    list_presence,
    presence_exists,
    register_presence,
    room_exists,
    set_presentation_mode,
    set_user_muted,
    touch_presence,
    unregister_presence,
)


class RoomConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_id = self.scope["url_route"]["kwargs"]["room_id"]
        self.group_name = f"room_{self.room_id}"
        self.client_id = None
        self.nickname = None

        if not room_exists(self.room_id):
            await self.close(code=4004)
            return

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self._remove_member()
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def _remove_member(self):
        if not self.client_id:
            return

        unregister_presence(self.room_id, self.client_id)

        self.client_id = None

        await self.channel_layer.group_send(
            self.group_name,
            {
                "type": "room_participants",
                "participants": self._participants_payload(),
            },
        )

    def _participants_payload(self):
        cleanup_stale_presence(self.room_id)
        try:
            room = get_room(self.room_id)
        except Exception:
            return []

        host_nickname = room.get("host")
        muted_users = room.get("muted_users", set())
        presences = list_presence(self.room_id)
        return [
            {
                "client_id": presence["client_id"],
                "nickname": presence["nickname"],
                "is_host": presence["nickname"] == host_nickname,
                "is_muted": presence["nickname"] in muted_users,
            }
            for presence in presences
        ]

    async def _send_room_state(self, target_client_id=None):
        room = get_room(self.room_id)
        payload = {
            "type": "room_state",
            "host": room.get("host"),
            "presentation_mode": room.get("presentation_mode", False),
            "muted_users": list(room.get("muted_users", set())),
        }
        if target_client_id:
            payload["target_id"] = target_client_id

        await self.channel_layer.group_send(
            self.group_name,
            {
                "type": "signal_message",
                "payload": payload,
            },
        )

    async def _send_kick(self, target_client_id):
        await self.channel_layer.group_send(
            self.group_name,
            {
                "type": "signal_message",
                "payload": {
                    "type": "room_kicked",
                    "target_id": target_client_id,
                },
            },
        )

    async def _send_user_muted(self, target_client_id, muted):
        await self.channel_layer.group_send(
            self.group_name,
            {
                "type": "signal_message",
                "payload": {
                    "type": "room_user_muted",
                    "target_id": target_client_id,
                    "muted": muted,
                },
            },
        )

    async def receive(self, text_data):
        try:
            payload = json.loads(text_data)
        except json.JSONDecodeError:
            return

        message_type = str(payload.get("type", "")).strip()

        if self.client_id:
            touch_presence(self.room_id, self.client_id)

        if message_type == "room_register":
            client_id = str(payload.get("sender_id", "")).strip()
            nickname = str(payload.get("nickname", "")).strip()
            if not client_id or not nickname:
                return

            self.client_id = client_id
            self.nickname = nickname

            register_presence(self.room_id, client_id, nickname)

            await self._send_room_state()
            await self.channel_layer.group_send(
                self.group_name,
                {
                    "type": "room_participants",
                    "participants": self._participants_payload(),
                },
            )
            return

        if message_type == "host_set_presentation_mode":
            sender_id = str(payload.get("sender_id", "")).strip()
            enabled = bool(payload.get("enabled", False))
            if not self.client_id or sender_id != self.client_id:
                return

            if not self.nickname or not is_host(self.room_id, self.nickname):
                return

            room = set_presentation_mode(self.room_id, enabled)
            if enabled:
                host_name = room.get("host")
                for presence in list_presence(self.room_id):
                    if presence["nickname"] != host_name:
                        set_user_muted(self.room_id, presence["nickname"], True)
                        await self._send_user_muted(presence["client_id"], True)

            await self._send_room_state()
            await self.channel_layer.group_send(
                self.group_name,
                {
                    "type": "room_participants",
                    "participants": self._participants_payload(),
                },
            )
            return

        if message_type == "host_mute_user":
            sender_id = str(payload.get("sender_id", "")).strip()
            target_id = str(payload.get("target_id", "")).strip()
            muted = bool(payload.get("muted", True))

            if not self.client_id or sender_id != self.client_id:
                return

            if not self.nickname or not is_host(self.room_id, self.nickname):
                return

            if not target_id or not presence_exists(self.room_id, target_id):
                return

            target_nickname = next(
                (
                    presence["nickname"]
                    for presence in list_presence(self.room_id)
                    if presence["client_id"] == target_id
                ),
                None,
            )
            if not target_nickname:
                return

            if target_nickname == self.nickname:
                return

            set_user_muted(self.room_id, target_nickname, muted)
            await self._send_user_muted(target_id, muted)
            await self.channel_layer.group_send(
                self.group_name,
                {
                    "type": "room_participants",
                    "participants": self._participants_payload(),
                },
            )
            return

        if message_type == "host_kick_user":
            sender_id = str(payload.get("sender_id", "")).strip()
            target_id = str(payload.get("target_id", "")).strip()

            if not self.client_id or sender_id != self.client_id:
                return

            if not self.nickname or not is_host(self.room_id, self.nickname):
                return

            if not target_id or not presence_exists(self.room_id, target_id):
                return

            target_nickname = next(
                (
                    presence["nickname"]
                    for presence in list_presence(self.room_id)
                    if presence["client_id"] == target_id
                ),
                None,
            )
            if not target_nickname:
                return

            if target_nickname == self.nickname:
                return

            kick_user(self.room_id, target_nickname)
            await self._send_kick(target_id)
            unregister_presence(self.room_id, target_id)

            await self._send_room_state()
            await self.channel_layer.group_send(
                self.group_name,
                {
                    "type": "room_participants",
                    "participants": self._participants_payload(),
                },
            )
            return

        if message_type in {
            "webrtc_ready",
            "webrtc_offer",
            "webrtc_answer",
            "webrtc_ice",
            "webrtc_leave",
            "whiteboard_draw",
            "whiteboard_clear",
        }:
            sender_id = str(payload.get("sender_id", "")).strip()
            if not sender_id or not self.client_id or sender_id != self.client_id:
                return

            await self.channel_layer.group_send(
                self.group_name,
                {
                    "type": "signal_message",
                    "payload": payload,
                },
            )
            return

        message = str(payload.get("message", "")).strip()
        nickname = str(payload.get("nickname", "")).strip()

        if not message or not nickname:
            return

        await self.channel_layer.group_send(
            self.group_name,
            {
                "type": "chat_message",
                "message": message,
                "nickname": nickname,
            },
        )

    async def chat_message(self, event):
        await self.send(
            text_data=json.dumps(
                {
                    "type": "chat_message",
                    "message": event["message"],
                    "nickname": event["nickname"],
                }
            )
        )

    async def signal_message(self, event):
        await self.send(text_data=json.dumps(event["payload"]))

    async def room_participants(self, event):
        await self.send(
            text_data=json.dumps(
                {
                    "type": "room_participants",
                    "participants": event["participants"],
                }
            )
        )
