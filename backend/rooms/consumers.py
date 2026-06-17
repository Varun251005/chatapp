import json

from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncWebsocketConsumer

from .storage import list_presence, register_presence, room_exists, touch_presence, unregister_presence


class RoomConsumer(AsyncWebsocketConsumer):
    async def _broadcast(self, payload: dict) -> None:
        await self.channel_layer.group_send(
            self.group_name,
            {
                "type": "broadcast_payload",
                "payload": payload,
            },
        )

    async def connect(self):
        self.room_id = self.scope["url_route"]["kwargs"]["room_id"]
        self.group_name = f"room_{self.room_id}"
        self.client_id = None
        self.nickname = None

        exists = await database_sync_to_async(room_exists)(self.room_id)
        if not exists:
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

            # Bind this socket to a participant identity.
from .storage import (
    add_message,
    delete_room_if_empty,
    list_messages,
)
            self.client_id = client_id
            self.nickname = nickname

            await database_sync_to_async(register_presence)(self.room_id, client_id, nickname)

            # Send an initial roster to this client using allowed event type(s).
            presences = await database_sync_to_async(list_presence)(self.room_id)
            for presence in presences:
                presence_id = presence.get("client_id")
                if not presence_id or presence_id == client_id:
                    continue
    async def _send_room_snapshot(self, target_sender_id: str | None = None) -> None:
        presences = await database_sync_to_async(list_presence)(self.room_id)
        messages = await database_sync_to_async(list_messages)(self.room_id)
        await self.send(
            text_data=json.dumps(
                {
                    "type": "room_state",
                    "room_id": self.room_id,
                    "room_type": self.room_type,
                    "max_members": self.max_members,
                    "host": self.host,
                    "participants": presences,
                    "member_count": len(presences),
                    "messages": messages,
                    "target_sender_id": target_sender_id,
                }
            )
        )
                await self.send(
                    text_data=json.dumps(
                        {
                            "type": "participant_join",
                            "sender_id": presence_id,
                            "nickname": presence.get("nickname"),
                        }
                    )
                )

            await self._broadcast(
                {
                    "type": "participant_join",
                    "sender_id": client_id,
                    "nickname": nickname,
                }
            )
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
            return

        if message_type in {"webrtc_offer", "webrtc_answer", "webrtc_ice"}:
            await self._broadcast_room_snapshot()
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

            await self.channel_layer.group_send(
                self.group_name,
                {
                    "type": "chat_message",
                    "message": message,
                    "nickname": nickname,
                    "sender_id": sender_id,
                },
            )
            return

    async def chat_message(self, event):
        await self.send(
            text_data=json.dumps(
                {
                    "type": "chat_message",
                    "message": event["message"],
                    "nickname": event["nickname"],
                    "sender_id": event.get("sender_id"),
                }
            )
        )

    async def broadcast_payload(self, event):
        await self.send(text_data=json.dumps(event["payload"]))
