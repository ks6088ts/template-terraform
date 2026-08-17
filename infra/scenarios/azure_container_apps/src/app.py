import os
from contextlib import AsyncExitStack, asynccontextmanager

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from mcp.server.transport_security import TransportSecuritySettings

from mcp_server import mcp


def transport_security_settings() -> TransportSecuritySettings:
    allowed_hosts = [
        "127.0.0.1",
        "127.0.0.1:*",
        "localhost",
        "localhost:*",
        "[::1]",
        "[::1]:*",
    ]
    allowed_origins = [
        "http://127.0.0.1",
        "http://127.0.0.1:*",
        "http://localhost",
        "http://localhost:*",
        "http://[::1]",
        "http://[::1]:*",
    ]

    app_name = os.getenv("CONTAINER_APP_NAME")
    dns_suffix = os.getenv("CONTAINER_APP_ENV_DNS_SUFFIX")
    revision_hostname = os.getenv("CONTAINER_APP_HOSTNAME")
    azure_hostnames = set()

    if app_name and dns_suffix:
        azure_hostnames.add(f"{app_name}.{dns_suffix}")
    if revision_hostname:
        azure_hostnames.add(revision_hostname)

    for hostname in sorted(azure_hostnames):
        allowed_hosts.extend([hostname, f"{hostname}:*"])
        allowed_origins.append(f"https://{hostname}")

    return TransportSecuritySettings(
        allowed_hosts=allowed_hosts,
        allowed_origins=allowed_origins,
    )


@asynccontextmanager
async def lifespan(app: FastAPI):
    async with AsyncExitStack() as stack:
        await stack.enter_async_context(mcp.session_manager.run())
        yield


app = FastAPI(lifespan=lifespan)


@app.get("/health")
async def health():
    return JSONResponse({"status": "healthy"})


app.mount(
    "/",
    mcp.streamable_http_app(
        stateless_http=True,
        transport_security=transport_security_settings(),
    ),
)
