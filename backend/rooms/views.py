import json
import uuid

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt

from .storage import create_room, join_room, room_exists


@csrf_exempt
def create_room_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        payload = json.loads(request.body or "{}")
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    nickname = str(payload.get("nickname", "")).strip()
    if not nickname:
        return JsonResponse({"error": "Nickname is required"}, status=400)

    room_id = str(payload.get("room_id", "")).strip() or uuid.uuid4().hex[:8]
    room_type = str(payload.get("room_type", "chat")).strip() or "chat"
    max_members_raw = str(payload.get("max_members", 4)).strip()
    max_members = int(max_members_raw) if max_members_raw.isdigit() else 4
    room = create_room(room_id, nickname, room_type=room_type, max_members=max_members)

    return JsonResponse(
        {
            "room_id": room["id"],
            "room_link": room["room_link"],
            "room_type": room["room_type"],
            "max_members": room["max_members"],
            "users": room["users"],
            "host": room.get("host"),
        }
    )


@csrf_exempt
def join_room_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "Only POST allowed"}, status=405)

    try:
        payload = json.loads(request.body or "{}")
    except json.JSONDecodeError:
        return JsonResponse({"error": "Invalid JSON"}, status=400)

    room_id = str(payload.get("room_id", "")).strip()
    nickname = str(payload.get("nickname", "")).strip()

    if not room_id or not nickname:
        return JsonResponse(
            {"error": "room_id and nickname are required"},
            status=400,
        )

    if not room_exists(room_id):
        return JsonResponse({"error": "Room does not exist"}, status=404)

    try:
        room = join_room(room_id, nickname)
    except ValueError as error:
        return JsonResponse({"error": str(error)}, status=409)

    return JsonResponse(
        {
            "room_id": room["id"],
            "room_link": room["room_link"],
            "room_type": room["room_type"],
            "max_members": room["max_members"],
            "users": room["users"],
            "host": room.get("host"),
            "message": "Joined room",
        }
    )
