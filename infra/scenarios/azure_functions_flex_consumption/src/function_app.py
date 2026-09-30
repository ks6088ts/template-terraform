import azure.functions as func
import logging
import json
import os

from azure.identity import ManagedIdentityCredential
from azure.storage.blob import BlobServiceClient
from opentelemetry import trace

app = func.FunctionApp()
tracer = trace.get_tracer(__name__)


def create_hello_response(req: func.HttpRequest) -> func.HttpResponse:
    name = req.params.get("name")
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            req_body = {}
        name = req_body.get("name")

    if name:
        return func.HttpResponse(f"Hello, {name}!")

    return func.HttpResponse("Hello, World!")


@app.timer_trigger(
    schedule="%TIMER_SCHEDULE%",
    arg_name="myTimer",
    run_on_startup=False,
    use_monitor=True,
)
def hello_world_timer(myTimer: func.TimerRequest) -> None:
    if myTimer.past_due:
        logging.warning("The timer is past due!")

    logging.info("flex-timer-check: completed")


@app.route(route="hello", auth_level=func.AuthLevel.ANONYMOUS)
def hello_world_http(req: func.HttpRequest) -> func.HttpResponse:
    """
    App Service 組み込み認証で保護する HTTP トリガー関数
    GET/POST リクエストで "hello world" を返す
    """
    logging.info("HTTP trigger function processed a request.")

    with tracer.start_as_current_span("flex-otel-check"):
        return create_hello_response(req)


@app.route(route="hello-key", auth_level=func.AuthLevel.FUNCTION)
def hello_world_http_with_function_key(req: func.HttpRequest) -> func.HttpResponse:
    """
    Function Key で保護する HTTP トリガー関数
    GET/POST リクエストで "hello world" を返す
    """
    logging.info("Function Key HTTP trigger processed a request.")

    return create_hello_response(req)


@app.route(route="storage-check", auth_level=func.AuthLevel.ANONYMOUS, methods=["GET"])
def storage_check(req: func.HttpRequest) -> func.HttpResponse:
    """Easy Auth protects this read-only managed-identity Storage probe."""
    endpoint = os.environ["STORAGE_ACCOUNT_BLOB_ENDPOINT"]
    container = os.environ["STORAGE_CONTAINER_NAME"]
    try:
        client = BlobServiceClient(account_url=endpoint, credential=ManagedIdentityCredential())
        client.get_container_client(container).get_container_properties()
    except Exception:
        logging.exception("Storage managed identity probe failed")
        return func.HttpResponse('{"status":"unavailable"}', status_code=503, mimetype="application/json")

    return func.HttpResponse(
        json.dumps({"status": "ok", "container": container}),
        mimetype="application/json",
    )
