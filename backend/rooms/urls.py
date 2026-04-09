from django.urls import path

from .views import create_room_view, join_room_view

urlpatterns = [
    path("create/", create_room_view, name="create_room"),
    path("join/", join_room_view, name="join_room"),
]
