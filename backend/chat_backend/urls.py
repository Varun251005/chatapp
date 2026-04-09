from django.urls import include, path

urlpatterns = [
    path("api/rooms/", include("rooms.urls")),
]
