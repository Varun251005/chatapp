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

    room_id = uuid.uuid4().hex[:8]
    create_room(room_id, nickname)

    return JsonResponse(
        {
            "room_id": room_id,
            "room_link": f"/room/{room_id}",
            "users": [nickname],
            "host": nickname,
            "presentation_mode": False,
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

    room = join_room(room_id, nickname)
    return JsonResponse(
        {
            "room_id": room_id,
            "room_link": f"/room/{room_id}",
            "users": room["users"],
            "host": room.get("host"),
            "presentation_mode": room.get("presentation_mode", False),
            "message": "Joined room",
        }
    )
