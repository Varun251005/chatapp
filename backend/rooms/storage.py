from __future__ import annotations

from datetime import timedelta

from django.db import transaction
from django.utils import timezone


def _room_to_dict(room: Room) -> dict:
    users = list(room.members.order_by("joined_at").values_list("nickname", flat=True))
    return {
        "id": room.id,
        "room_type": room.room_type,
        "max_members": room.max_members,
        "users": users,
        "host": room.host,
        "room_link": f"/room/{room.id}",
    }


@transaction.atomic
def create_room(room_id: str, nickname: str, room_type: str = "chat", max_members: int = 4) -> dict:
    from .models import Room, RoomMember

    room, _created = Room.objects.get_or_create(
        id=room_id,
        defaults={
            "host": nickname,
            "room_type": room_type,
            "max_members": max_members,
        },
    )
    changed_fields = []
    if room.room_type != room_type:
        room.room_type = room_type
        changed_fields.append("room_type")
    if room.max_members != max_members:
        room.max_members = max_members
        changed_fields.append("max_members")
    if not room.host:
        room.host = nickname
        changed_fields.append("host")

    if changed_fields:
        room.save(update_fields=changed_fields + ["updated_at"])

    RoomMember.objects.get_or_create(room=room, nickname=nickname)
    return _room_to_dict(room)


def room_exists(room_id: str) -> bool:
    from .models import Room

    return Room.objects.filter(id=room_id).exists()


@transaction.atomic
def join_room(room_id: str, nickname: str) -> dict:
    from .models import Room, RoomMember

    room = Room.objects.select_for_update().get(id=room_id)
    if room.members.exclude(nickname=nickname).count() >= room.max_members:
        raise ValueError("Room is full")

    RoomMember.objects.get_or_create(room=room, nickname=nickname)
    if not room.host:
        room.host = nickname
        room.save(update_fields=["host", "updated_at"])
    return _room_to_dict(room)


def get_room(room_id: str) -> dict:
    from .models import Room

    room = Room.objects.get(id=room_id)
    return _room_to_dict(room)


@transaction.atomic
def register_presence(room_id: str, client_id: str, nickname: str) -> None:
    from .models import Room, RoomMember, RoomPresence

    room = Room.objects.select_for_update().get(id=room_id)
    RoomMember.objects.get_or_create(room=room, nickname=nickname)
    RoomPresence.objects.update_or_create(
        room=room,
        client_id=client_id,
        defaults={"nickname": nickname, "last_seen": timezone.now()},
    )


def touch_presence(room_id: str, client_id: str) -> None:
    from .models import RoomPresence

    RoomPresence.objects.filter(room_id=room_id, client_id=client_id).update(
        last_seen=timezone.now()
    )


@transaction.atomic
def unregister_presence(room_id: str, client_id: str) -> None:
    from .models import RoomPresence

    RoomPresence.objects.filter(room_id=room_id, client_id=client_id).delete()


@transaction.atomic
def cleanup_stale_presence(room_id: str, max_age_seconds: int = 90) -> None:
    from .models import RoomPresence

    cutoff = timezone.now() - timedelta(seconds=max_age_seconds)
    RoomPresence.objects.filter(room_id=room_id, last_seen__lt=cutoff).delete()


def list_presence(room_id: str) -> list[dict]:
    from .models import RoomPresence

    return list(
        RoomPresence.objects.filter(room_id=room_id)
        .order_by("connected_at")
        .values("client_id", "nickname")
    )


def presence_exists(room_id: str, client_id: str) -> bool:
    from .models import RoomPresence

    return RoomPresence.objects.filter(room_id=room_id, client_id=client_id).exists()


@transaction.atomic
def delete_room_if_empty(room_id: str) -> bool:
    from .models import Room

    room = Room.objects.filter(id=room_id).first()
    if not room:
        return False
    if room.presences.exists():
        return False
    room.delete()
    return True


@transaction.atomic
def add_message(room_id: str, sender_id: str, nickname: str, message: str, message_type: str = "chat") -> dict:
    from .models import RoomMessage

    room = Room.objects.get(id=room_id)
    message_obj = RoomMessage.objects.create(
        room=room,
        sender_id=sender_id,
        nickname=nickname,
        message=message,
        message_type=message_type,
    )
    return {
        "id": message_obj.id,
        "room_id": room_id,
        "sender_id": sender_id,
        "nickname": nickname,
        "message": message,
        "message_type": message_type,
        "created_at": message_obj.created_at.isoformat(),
    }


def list_messages(room_id: str, limit: int = 50) -> list[dict]:
    from .models import RoomMessage

    messages = []
    for item in RoomMessage.objects.filter(room_id=room_id).order_by("-created_at", "-id")[:limit].values(
        "id",
        "sender_id",
        "nickname",
        "message",
        "message_type",
        "created_at",
    ):
        item["created_at"] = item["created_at"].isoformat()
        messages.append(item)
    return list(reversed(messages))
