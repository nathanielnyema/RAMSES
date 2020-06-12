from datetime import timedelta,datetime

CELERYBEAT_SCHEDULE={
    'pull-classify-save':{
        'task':'stream.async_stream',
        'schedule':timedelta(seconds=10),
    }
}