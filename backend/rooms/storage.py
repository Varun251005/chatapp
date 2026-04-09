DEMO_ROOM_ID = "DEMO-1234"

rooms = {
    DEMO_ROOM_ID: {
        "id": DEMO_ROOM_ID,
        "users": [],
        "host": None,
        "presentation_mode": False,
        "muted_users": set(),
    }
}


def create_room(room_id: str, nickname: str) -> dict:
    rooms[room_id] = {
        "id": room_id,
        "users": [nickname],
        "host": nickname,
        "presentation_mode": False,
        "muted_users": set(),
    }
    return rooms[room_id]


def room_exists(room_id: str) -> bool:
    return room_id in rooms


def join_room(room_id: str, nickname: str) -> dict:
    room = rooms[room_id]
    if nickname not in room["users"]:
        room["users"].append(nickname)
    if room.get("host") is None:
        room["host"] = nickname
    return room


def get_room(room_id: str) -> dict:
    return rooms[room_id]


def is_host(room_id: str, nickname: str) -> bool:
    room = rooms[room_id]
    return room.get("host") == nickname


def set_presentation_mode(room_id: str, enabled: bool) -> dict:
    room = rooms[room_id]
    room["presentation_mode"] = enabled
    return room


def set_user_muted(room_id: str, nickname: str, muted: bool) -> dict:
    room = rooms[room_id]
    muted_users = room.setdefault("muted_users", set())
    if muted:
        muted_users.add(nickname)
    else:
        muted_users.discard(nickname)
    return room


def kick_user(room_id: str, nickname: str) -> dict:
    room = rooms[room_id]
    if nickname in room["users"]:
        room["users"].remove(nickname)
    room.setdefault("muted_users", set()).discard(nickname)

    if room.get("host") == nickname:
        room["host"] = room["users"][0] if room["users"] else None

    return room
