#! /bin/sh

if [ "$#" -ne 1 ]; then
    echo "Only pass as an argument the path to your mongo bin"
    exit 1
fi

export PATH=$PATH:$1

(mongo &)

(redis-server &)

(celery -A dashboard.celery beat &)

(celery worker -A dashboard.celery --loglevel=info --pool=solo&)

python3 dashboard.py

