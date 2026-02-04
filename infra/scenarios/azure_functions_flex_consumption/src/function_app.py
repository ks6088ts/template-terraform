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
