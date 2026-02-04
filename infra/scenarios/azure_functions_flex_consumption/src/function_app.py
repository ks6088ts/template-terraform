import azure.functions as func
import logging

app = func.FunctionApp()


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


@app.route(route="hello", auth_level=func.AuthLevel.FUNCTION)
def hello_world_http(req: func.HttpRequest) -> func.HttpResponse:
    """
    Function Key で認証する HTTP トリガー関数
    GET/POST リクエストで "hello world" を返す
    """
    logging.info("HTTP trigger function processed a request.")

    name = req.params.get("name")
    if not name:
        try:
            req_body = req.get_json()
        except ValueError:
            req_body = {}
        name = req_body.get("name")

    if name:
        return func.HttpResponse(f"Hello, {name}!")
    else:
        return func.HttpResponse("Hello, World!")
