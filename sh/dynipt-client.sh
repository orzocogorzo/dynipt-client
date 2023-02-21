#!/bin/sh

cd $(dirname $0) && cd ..

HOME=$PWD
PYTHON=$HOME/.venv/bin/python
SCRIPT=$HOME/main.py
RUNAS=dynipt
LOGFILE=$HOME/var/messages

start() {
  	sudo -u $RUNAS $PYTHON $SCRIPT start 1> /dev/null 2>&1 &
  	echo $! > var/process.pid
	echo "DynIPt client is running"
}

stop() {
	if [ -f $HOME/var/process.pid ]; then
  		kill -15 $(cat $HOME/var/process.pid)
		rm $HOME/var/process.pid
		echo "DynIPt client stopped"
	else
		echo "DynIPt client is not running"
	fi
}

restart() {
    	stop
    	start 
}

status() {
  	sudo -u $RUNAS $PYTHON $SCRIPT status >&2
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
