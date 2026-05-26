from __future__ import annotations

from datetime import timedelta

from django.db import transaction
from django.utils import timezone


def _room_to_dict(room: Room) -> dict:
    users = list(
        room.members.order_by("joined_at").values_list("nickname", flat=True)
    )
    return {
        "id": room.id,
        "users": users,
        "host": room.host,
    }


@transaction.atomic
def create_room(room_id: str, nickname: str) -> dict:
    from .models import Room, RoomMember

    room = Room.objects.create(
        id=room_id,
        host=nickname,
    )
    RoomMember.objects.create(room=room, nickname=nickname)
    return _room_to_dict(room)


def room_exists(room_id: str) -> bool:
    from .models import Room

    return Room.objects.filter(id=room_id).exists()


@transaction.atomic
def join_room(room_id: str, nickname: str) -> dict:
    from .models import Room, RoomMember

    room = Room.objects.select_for_update().get(id=room_id)
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
