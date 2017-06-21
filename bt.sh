#!/bin/bash
# chkconfig: 2345 55 25
# description: bt Cloud Service

### BEGIN INIT INFO
# Provides:          bt
# Required-Start:    $all
# Required-Stop:     $all
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts bt
# Description:       starts the bt
### END INIT INFO
panel_path=/www/server/panel
cd $panel_path
panel_start()
{
	isStart=`ps aux |grep 'python main.pyc'|grep -v grep|awk '{print $2}'`
	if [ "$isStart" == '' ];then
		echo -e "Starting Bt-Panel... \c"
		if [ -f 'main.py' ];then
			python -m py_compile main.py
		fi
		nohup python main.pyc `cat data/port.pl` > /tmp/panelBoot.pl 2>&1 &
		sleep 0.2
		isStart=`ps aux |grep 'python main.pyc'|grep -v grep|awk '{print $2}'`
		if [ "$isStart" == '' ];then
			echo -e "\033[31mfailed\033[0m"
			echo -e "\033[31mError: BT-Panel service startup failed.\033[0m"
			return;
		fi
		echo -e "\033[32mdone\033[0m"
	else
		echo "Starting Bt-Panel... Bt-Panel (pid $isStart) already running"
	fi

	isStart=`ps aux |grep 'python task.pyc$'|awk '{print $2}'`
	if [ "$isStart" == '' ];then
		echo -e "Starting Bt-Tasks... \c"
		if [ -f 'task.py' ];then
			python -m py_compile task.py
		fi
		nohup python task.pyc > /tmp/panelTask.pl 2>&1 &
		sleep 0.2
		isStart=`ps aux |grep 'python task.pyc$'|awk '{print $2}'`
		if [ "$isStart" == '' ];then
			echo -e "\033[31mfailed\033[0m"
			echo -e "\033[31mError: BT-Task service startup failed.\033[0m"
			return;
		fi
		echo -e "\033[32mdone\033[0m"
	else
		echo "Starting Bt-Tasks... Bt-Tasks (pid $isStart) already running"
	fi
}

panel_stop()
{
	echo -e "Stopping Bt-Tasks... \c";
	pids=`ps aux | grep 'python task.pyc$'|awk '{print $2}'`
	arr=($pids)

	for p in ${arr[@]}
	do
		kill -9 $p
	done
	echo -e "\033[32mdone\033[0m"

	echo -e "Stopping Bt-Panel... \c";
	pids=`ps aux | grep 'python main.pyc'|grep -v grep|awk '{print $2}'`
	arr=($pids)

	for p in ${arr[@]}
	do
		kill -9 $p
	done
	echo -e "\033[32mdone\033[0m"
}

case "$1" in
        'start')
                panel_start
                ;;
        'stop')
                panel_stop
                ;;
        'restart')
                panel_stop
				sleep 0.2
                panel_start
                ;;
esac