from __future__ import annotations

from django.db import models
from django.utils import timezone


class Room(models.Model):
    ROOM_TYPES = [
        ("chat", "Chat"),
        ("voice", "Voice"),
        ("video", "Video"),
    ]

    id = models.CharField(primary_key=True, max_length=64)
    host = models.CharField(max_length=128, blank=True, null=True)
    room_type = models.CharField(max_length=16, choices=ROOM_TYPES, default="chat")
    max_members = models.PositiveSmallIntegerField(default=4)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:  # pragma: no cover
        return f"Room({self.id})"


class RoomMember(models.Model):
    room = models.ForeignKey(Room, on_delete=models.CASCADE, related_name="members")
    nickname = models.CharField(max_length=128)
    joined_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["room", "nickname"],
                name="uniq_roommember_room_nickname",
            )
        ]

    def __str__(self) -> str:  # pragma: no cover
        return f"RoomMember({self.room_id}, {self.nickname})"


class RoomPresence(models.Model):
    room = models.ForeignKey(Room, on_delete=models.CASCADE, related_name="presences")
    client_id = models.CharField(max_length=128)
    nickname = models.CharField(max_length=128)
    connected_at = models.DateTimeField(auto_now_add=True)
    last_seen = models.DateTimeField(default=timezone.now)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["room", "client_id"],
                name="uniq_roompresence_room_client_id",
            )
        ]
        indexes = [models.Index(fields=["room", "last_seen"])]

    def __str__(self) -> str:  # pragma: no cover
        return f"RoomPresence({self.room_id}, {self.client_id})"


class RoomMessage(models.Model):
    room = models.ForeignKey(Room, on_delete=models.CASCADE, related_name="messages")
    sender_id = models.CharField(max_length=128)
    nickname = models.CharField(max_length=128)
    message = models.TextField()
    message_type = models.CharField(max_length=24, default="chat")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["created_at", "id"]

    def __str__(self) -> str:  # pragma: no cover
        return f"RoomMessage({self.room_id}, {self.nickname})"
