from django.urls import path

from .consumers import RoomChatConsumer

websocket_urlpatterns = [
    path("ws/chat/<str:room_id>/", RoomChatConsumer.as_asgi()),
]
