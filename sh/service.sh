#!/bin/sh

PYTHON=/opt/dynipt-client/.venv/bin/python
SCRIPT=/opt/dynipt-client/main.py
RUNAS=dynipt
LOGFILE=/var/log/messages

start() {
    
  su -c "$PYTHON $SCRIPT start" $RUNAS >&2
}

stop() {
  su -c "$PYTHON $SCRIPT stop" $RUNAS >&2
}

restart() {
    stop
    start 
}

status() {
  su -c "$PYTHON $SCRIPT status" >&2
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  status)
    status
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}"
esac
