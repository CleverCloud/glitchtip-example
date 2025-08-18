#!/bin/bash

if [ "${START_TARGET}" = "worker" ]; then
  mkdir /tmp/sandboxed
	cd /tmp/sandboxed && nohup python -m http.server 8080 &
	/code/bin/run-celery-with-beat.sh
else
  /code/bin/start.sh
fi

