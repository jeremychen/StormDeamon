#!/bin/sh
# chkconfig: 2345 99 01
# description: This script starts the storm cluster inlcuding nimbus, supervisor, ui and logviewer
# AUTHOR: Somebody somebody-mail-list-here
# Script to startup/stop storm node 
#

#Notice: You need to set the STORMHOME before to run this script
STORMHOME="/home/storm/storm-0.9.0.1"
dataNow=`date +"%Y-%m-%d_%p_%I:%M:%S"`
BASHFILE=StormDaemon
DAEMONPID=/tmp/StormDaemon.pid
DAEMONMODE=0

kill_process_by_pid()
{
	pid=$1
    cc=`ps -eo pid | grep "\\\<$pid\\\>" | wc -l`
    if [ $cc -eq 1 ]; then
        kill -9 $pid
    fi
}

#return 1 when it is nimbus, 2 while supervisor
check_storm_node()
{
    nimbus=`cat /etc/sysconfig/network | grep HOSTNAME | grep "nimbus" | wc -l`
    supervisor=`cat /etc/sysconfig/network | grep HOSTNAME | grep "supervisor" | wc -l`
    if [ $nimbus -eq 1 ]; then
        echo 1
    elif [ $supervisor -eq 1 ]; then
        echo 2
    else
        echo 0
    fi
    return 1
}

check_service()
{
	s=$1
	arr=("backtype.storm.daemon.nimbus" "backtype.storm.ui.core" "backtype.storm.daemon.logviewer" "backtype.storm.daemon.supervisor")
	for service in ${arr[@]}; do
		if [ $service == $s ]; then
			echo 1
			return 1
		fi
	done
	echo 0
	return 0
}

get_service()
{
	s=$1
	if [ $s == "backtype.storm.daemon.nimbus" ]; then
		echo "nimbus"
		return 1
	fi

	if [ $s == "backtype.storm.ui.core" ]; then
		echo "ui"
		return 1
	fi

	if [ $s == "backtype.storm.daemon.logviewer" ]; then
		echo "logviewer"
		return 1
	fi

	if [ $s == "backtype.storm.daemon.supervisor" ]; then
		echo "supervisor"
		return 1
	fi
}

check_process_running()
{
    service=$1
    if [ -f ${STORMHOME}/.$service.pid ]; then
        pid=`cat ${STORMHOME}/.$service.pid`
        cc=`ps -eo pid | grep "\\\<$pid\\\>" | wc -l`
        #cc=`ps -eo pid | grep $pid | grep " $pid" | wc -l`
        echo $cc
    else
        lv=`ps -ef | grep ${STORMHOME} | grep $service | grep -v grep | wc -l`
        echo $lv
    fi
}

show_info()
{
    echo -e "\033[1;32;40m$1\033[0m"
}

show_warn()
{
    echo -e "\033[1;31;40m$1\033[0m"
}

logfile_bak()
{
    service=$1
	c=$(check_service $service)
	if [ $c -eq 0 ]; then
        show_warn "service name unexpected, not in nimbus, supervisor, ui, logviewer"
        return 0
	fi

    cd ${STORMHOME}/logs
    ls | grep log | grep $service | grep -v grep | grep -v "log_"| while read line
    do
        mv $line $line"_"$dataNow
    done
    cd ${STORMHOME}
}

######################
####### service ######
start_storm_service()
{
    if [ ! -f ${STORMHOME}/bin/storm ]; then
        show_warn "${STORMHOME}/bin/storm\": file does NOT exist, please check it."
        return 0
    fi

    service=$1
	c=$(check_service $service)
    if [ $c -eq 0 ]; then
        show_warn "service name unexpected, not in nimbus, supervisor, ui, logviewer"
        return 0
    fi

    cd ${STORMHOME}
    s=$(check_process_running $service)

    if [ ${s} -ne 0 ]; then
        if [ $DAEMONMODE -ne 1 ]; then
            show_warn "$service process already running."
        fi
        return 1
    fi
    
    logfile_bak $service
    cd ${STORMHOME}
    #${STORMHOME}/bin/storm $service > ${STORMHOME}/logs/start$service.log&
    ${STORMHOME}/bin/storm $(get_service $service) > ${STORMHOME}/logs/start.$service.log&
    chpid="$!"
    echo $chpid > ${STORMHOME}/.$service.pid
    sleep 1

    s=$(check_process_running $service)
    if [ ${s} -eq 0 ]; then
        show_warn "$service process start faliure, retrying."
        
        start_storm_service $service
    fi
    show_info "$service process start SUCCESS."
}

stop_storm_service()
{
    service=$1
	c=$(check_service $service)
    if [ $c -eq 0 ]; then
        show_warn "service name unexpected, not in nimbus, supervisor, ui, logviewer"
        return 0
    fi

    cd ${STORMHOME}
    s=$(check_process_running $service)
    if [ $s -eq 0 ]; then
        show_warn "$service process NOT running, can not stop it."
        return 1
    fi

    if [ -f ${STORMHOME}/.$service.pid ]; then
        pid=`cat ${STORMHOME}/.$service.pid`
        kill_process_by_pid $pid
        #cc=`ps -eo pid | grep "\\\<${pid}\\\>" | xargs kill -9`
        rm -f ${STORMHOME}/.$service.pid
    else
        pc=`ps -ef | grep \'${STORMHOME}\' | grep $service | grep -v grep | awk '{print $2}' | wc -l`
        if [ $pc -eq 1 ]; then
           lv=`ps -ef | grep \'${STORMHOME}\' | grep $service | grep -v grep | awk '{print $2}' | xargs kill -9`
        fi
    fi

    show_info "$service process stop SUCCESS."
}

######################
####### process ######
stop_storm_process()
{
    node=$(check_storm_node)
    if [ $node -eq 1 ]; then
        stop_storm_service "backtype.storm.daemon.nimbus"
        stop_storm_service "backtype.storm.daemon.logviewer"
        stop_storm_service "backtype.storm.ui.core"
    elif [ $node -eq 2 ]; then
        stop_storm_service "backtype.storm.daemon.supervisor"
        stop_storm_service "backtype.storm.daemon.logviewer"
    else
        show_warn "This script was NOT running on the storm server."
    fi
}

start_storm_process()
{
    node=$(check_storm_node)

    if [ $node -eq 1 ]; then
        start_storm_service "backtype.storm.daemon.nimbus"
        start_storm_service "backtype.storm.daemon.logviewer"
        start_storm_service "backtype.storm.ui.core"
    elif [ $node -eq 2 ]; then
        start_storm_service "backtype.storm.daemon.supervisor"
        start_storm_service "backtype.storm.daemon.logviewer"
    else
        show_warn "This script SHOULD be running on the storm server."
    fi
}

check_storm_status()
{
    #Parameter $1=nimbus supervisor ui logviewer
    #arr=("nimbus" "supervisor" "ui" "logviewer")
    arr=("backtype.storm.daemon.nimbus" "backtype.storm.ui.core" "backtype.storm.daemon.logviewer" "backtype.storm.daemon.supervisor")
    node=$(check_storm_node)
    if [ $node -eq 1 ]; then
        arr=("backtype.storm.daemon.nimbus" "backtype.storm.ui.core" "backtype.storm.daemon.logviewer")
    elif [ $node -eq 2 ]; then
        arr=("backtype.storm.daemon.supervisor" "backtype.storm.daemon.logviewer")
    fi

    for service in ${arr[@]}; do
        s=$(check_process_running $service)
        if [ ${s} -ne 0 ]; then
            show_info "$service is running."
        else
            show_warn "$service is NOT running."
        fi
    done
}

######################
####### daemon #######
_start_storm_daemon()
{
    while true;
    do
        chpid="$BASHPID"
        echo $chpid > $DAEMONPID

        start_storm_process
        let "DAEMONMODE=1"
        sleep 5
    done
}

start_storm_daemon()
{
    if [ -f $DAEMONPID ]; then
        pid=`cat $DAEMONPID`
        cc=`ps -eo pid | grep "\\\<$pid\\\>" | wc -l`
        if [ ${cc} -ne 0 ]; then
            show_warn "$BASHFILE already run in daemon."
            return 
        fi
    fi

    (_start_storm_daemon)&
    
    show_info "$BASHFILE run in daemon SUCCESS."
    return 1
}

stop_storm_daemon()
{
    if [ -f $DAEMONPID ]; then
        pid=`cat $DAEMONPID`
        cc=`ps -eo pid | grep "\\\<$pid\\\>" | grep -v grep |wc -l`
        #ps -eo pid | grep '\<$pid\>' | grep -v grep
        if [ ${cc} -ne 0 ]; then
            #kill -9 $pid
            kill_process_by_pid $pid
            rm -f $DAEMONPID
            show_info "$BASHFILE process stop SUCCESS"
        else
            show_warn "$BASHFILE process does NOT run in daemon"
        fi
    else
        show_warn "$BASHFILE process does NOT run in daemon"
    fi
}

check_daemon_status()
{
    if [ -f $DAEMONPID ]; then
        pid=`cat $DAEMONPID`
        cc=`ps -eo pid | grep "\\\<$pid\\\>" | grep -v grep |wc -l`
        if [ ${cc} -ne 0 ]; then
            show_info "$BASHFILE is running"
        else
            show_warn "$BASHFILE is NOT running"
        fi
    else
        show_warn "$BASHFILE is NOT running"
    fi
}

###############################
############# Usage #########
show_usage()
{
    show_info "Usage: $BASHFILE {start|stop|status|restart|startStorm|stopStorm}."
    show_info "Description:"
    show_info "  start  : Start the daemon and the storm process.System will launch the storm process in 5 seconds"
    show_info "  stop   : Stop the storm daemon and process."
    show_info "  restart: Just call the stop and then start"
    show_info "  startStorm:  Start the storm process not in daemon"
    show_info "  stopStorm :  Stop the storm process(if you want to stop the storm, call the stop should be better)"
    show_info ""
    show_info "Notice: "
    show_info "  1. You need to set the environment variable \${STORMHOME} before to run this script."
    show_info "  2. Checkup the file \"/etc/sysconfig/network\", and the HOSTNAME in the file should be follow:"
    show_info "      1) For nimbus node, the value should be contain a keyword \"nimbus\""
    show_info "      2) For supervisor node, the value should be contain a keyword \"supervisor\""
    show_info ""
    exit
}

if [ ! -f ${STORMHOME}/bin/storm ]; then
    show_warn "\033[1;31;40mCheck failure: \${STORMHOME} is null or the file does not exist: \"\${STORMHOME}/bin/storm\"\033[0m"
    show_usage
fi
case "$1" in
    start)
        start_storm_daemon
        exit
        ;;
    stop)
        stop_storm_daemon
        stop_storm_process
        exit
        ;;
    status)
        check_daemon_status
        check_storm_status
        ;;
    restart)
        stop_storm_daemon
        stop_storm_process
        start_storm_daemon
        exit
        ;;
    startStorm)
        start_storm_process
        exit
        ;;
    stopStorm)
        stop_storm_process
        exit
        ;;
    *)  
        show_usage
        ;;
esac
