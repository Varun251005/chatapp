from __future__ import annotations

from datetime import timedelta

from django.db import transaction
from django.utils import timezone

DEMO_ROOM_ID = "DEMO-1234"


def _room_to_dict(room: Room) -> dict:
    users = list(
        room.members.order_by("joined_at").values_list("nickname", flat=True)
    )
    muted_users = set((room.muted_users or []))
    return {
        "id": room.id,
        "users": users,
        "host": room.host,
        "presentation_mode": room.presentation_mode,
        "muted_users": muted_users,
    }


@transaction.atomic
def create_room(room_id: str, nickname: str) -> dict:
    from .models import Room, RoomMember

    room = Room.objects.create(
        id=room_id,
        host=nickname,
        presentation_mode=False,
        muted_users=[],
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


def is_host(room_id: str, nickname: str) -> bool:
    from .models import Room

    return Room.objects.filter(id=room_id, host=nickname).exists()


def set_presentation_mode(room_id: str, enabled: bool) -> dict:
    from .models import Room

    Room.objects.filter(id=room_id).update(presentation_mode=enabled)
    return get_room(room_id)


@transaction.atomic
def set_user_muted(room_id: str, nickname: str, muted: bool) -> dict:
    from .models import Room

    room = Room.objects.select_for_update().get(id=room_id)
    muted_users = set((room.muted_users or []))
    if muted:
        muted_users.add(nickname)
    else:
        muted_users.discard(nickname)
    room.muted_users = sorted(muted_users)
    room.save(update_fields=["muted_users", "updated_at"])
    return _room_to_dict(room)


@transaction.atomic
def kick_user(room_id: str, nickname: str) -> dict:
    from .models import Room, RoomMember

    room = Room.objects.select_for_update().get(id=room_id)

    RoomMember.objects.filter(room=room, nickname=nickname).delete()
    muted_users = set((room.muted_users or []))
    muted_users.discard(nickname)
    room.muted_users = sorted(muted_users)

    if room.host == nickname:
        new_host = (
            RoomMember.objects.filter(room=room)
            .order_by("joined_at")
            .values_list("nickname", flat=True)
            .first()
        )
        room.host = new_host

    room.save(update_fields=["host", "muted_users", "updated_at"])
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
