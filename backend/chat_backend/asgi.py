import os

from channels.auth import AuthMiddlewareStack
from channels.routing import ProtocolTypeRouter, URLRouter
from django.core.asgi import get_asgi_application

import chat_backend.routing

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "chat_backend.settings")

django_asgi_app = get_asgi_application()

application = ProtocolTypeRouter(
    {
        "http": django_asgi_app,
        "websocket": AuthMiddlewareStack(
            URLRouter(chat_backend.routing.websocket_urlpatterns)
        ),
    }
)
