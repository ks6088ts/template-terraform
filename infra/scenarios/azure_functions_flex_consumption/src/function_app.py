import azure.functions as func
import logging

app = func.FunctionApp()


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
    schedule="0 0 * * * *",  # 1時間ごとに実行 (毎時0分0秒)
    arg_name="myTimer",
    run_on_startup=False,
    use_monitor=False,
)
def hello_world_timer(myTimer: func.TimerRequest) -> None:
    """
    1時間ごとに "hello world" を出力するタイマートリガー関数
    """
    if myTimer.past_due:
        logging.warning("The timer is past due!")

    logging.info("hello world")


@app.route(route="hello", auth_level=func.AuthLevel.ANONYMOUS)
def hello_world_http(req: func.HttpRequest) -> func.HttpResponse:
    """
    App Service 組み込み認証で保護する HTTP トリガー関数
    GET/POST リクエストで "hello world" を返す
    """
    logging.info("HTTP trigger function processed a request.")

    return create_hello_response(req)


@app.route(route="hello-key", auth_level=func.AuthLevel.FUNCTION)
def hello_world_http_with_function_key(req: func.HttpRequest) -> func.HttpResponse:
    """
    Function Key で保護する HTTP トリガー関数
    GET/POST リクエストで "hello world" を返す
    """
    logging.info("Function Key HTTP trigger processed a request.")

    return create_hello_response(req)
