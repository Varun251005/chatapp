import json

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncWebsocketConsumer

from .storage import (
    add_message,
    delete_room_if_empty,
    get_room,
    list_messages,
    list_presence,
    register_presence,
    room_exists,
    touch_presence,
    unregister_presence,
)


class RoomConsumer(AsyncWebsocketConsumer):
    async def connect(self):
        self.room_id = self.scope["url_route"]["kwargs"]["room_id"]
        self.group_name = f"room_{self.room_id}"
        self.client_id = None
        self.nickname = None

        exists = await database_sync_to_async(room_exists)(self.room_id)
        if not exists:
            await self.close(code=4004)
            return

        room = await database_sync_to_async(get_room)(self.room_id)
        self.room_type = room.get("room_type", "chat")
        self.max_members = room.get("max_members", 4)
        self.host = room.get("host")

        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()

    async def disconnect(self, close_code):
        await self._remove_member()
        await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive(self, text_data):
        try:
            payload = json.loads(text_data)
        except json.JSONDecodeError:
            return

        message_type = str(payload.get("type", "")).strip()

        if self.client_id:
            await database_sync_to_async(touch_presence)(self.room_id, self.client_id)

        if message_type == "participant_join":
            client_id = str(payload.get("sender_id", "")).strip()
            nickname = str(payload.get("nickname", "")).strip()
            if not client_id or not nickname:
                return

            self.client_id = client_id
            self.nickname = nickname

            await database_sync_to_async(register_presence)(self.room_id, client_id, nickname)
            await self._send_room_snapshot()
            await self._broadcast(
                {
                    "type": "participant_join",
                    "sender_id": client_id,
                    "nickname": nickname,
                }
            )
            await self._broadcast_room_snapshot()
            return

        if message_type == "participant_leave":
            sender_id = str(payload.get("sender_id", "")).strip()
            if not sender_id or not self.client_id or sender_id != self.client_id:
                return

            nickname = self.nickname
            await database_sync_to_async(unregister_presence)(self.room_id, sender_id)
            self.client_id = None
            self.nickname = None

            if nickname:
                await self._broadcast(
                    {
                        "type": "participant_leave",
                        "sender_id": sender_id,
                        "nickname": nickname,
                    }
                )
                await self._broadcast_room_snapshot()

            await database_sync_to_async(delete_room_if_empty)(self.room_id)
            return

        if message_type in {"webrtc_ready", "webrtc_offer", "webrtc_answer", "webrtc_ice", "webrtc_leave"}:
            sender_id = str(payload.get("sender_id", "")).strip()
            if not sender_id or not self.client_id or sender_id != self.client_id:
                return
            await self._broadcast(payload)
            return

        if message_type == "chat_message":
            sender_id = str(payload.get("sender_id", "")).strip()
            nickname = str(payload.get("nickname", "")).strip()
            message = str(payload.get("message", "")).strip()
            if not sender_id or not nickname or not message:
                return

            saved_message = await database_sync_to_async(add_message)(
                self.room_id,
                sender_id,
                nickname,
                message,
                "chat",
            )
            await self._broadcast(
                {
                    "type": "chat_message",
                    "message": message,
                    "nickname": nickname,
                    "sender_id": sender_id,
                    "created_at": saved_message["created_at"],
                }
            )
            return

    async def _remove_member(self):
        if not self.client_id:
            return

        client_id = self.client_id
        nickname = self.nickname

        await database_sync_to_async(unregister_presence)(self.room_id, client_id)
        self.client_id = None
        self.nickname = None

        if nickname:
            await self._broadcast(
                {
                    "type": "participant_leave",
                    "sender_id": client_id,
                    "nickname": nickname,
                }
            )
            await self._broadcast_room_snapshot()

        await database_sync_to_async(delete_room_if_empty)(self.room_id)

    async def _send_room_snapshot(self):
        room = await database_sync_to_async(get_room)(self.room_id)
        presences = await database_sync_to_async(list_presence)(self.room_id)
        messages = await database_sync_to_async(list_messages)(self.room_id)
        await self.send(
            text_data=json.dumps(
                {
                    "type": "room_state",
                    "room_id": self.room_id,
                    "room_type": room.get("room_type", self.room_type),
                    "max_members": room.get("max_members", self.max_members),
                    "host": room.get("host", self.host),
                    "participants": presences,
                    "member_count": len(presences),
                    "messages": messages,
                }
            )
        )

    async def _broadcast_room_snapshot(self):
        room = await database_sync_to_async(get_room)(self.room_id)
        presences = await database_sync_to_async(list_presence)(self.room_id)
        await self._broadcast(
            {
                "type": "room_participants",
                "room_id": self.room_id,
                "room_type": room.get("room_type", self.room_type),
                "max_members": room.get("max_members", self.max_members),
                "host": room.get("host", self.host),
                "participants": presences,
                "member_count": len(presences),
            }
        )

    async def _broadcast(self, payload: dict) -> None:
        await self.channel_layer.group_send(
            self.group_name,
            {
                "type": "broadcast_payload",
                "payload": payload,
            },
        )

    async def broadcast_payload(self, event):
        await self.send(text_data=json.dumps(event["payload"]))
