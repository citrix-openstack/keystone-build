. /etc/rc.d/init.d/functions

user="keystone"
configfile="/etc/keystone/keystone.conf"
logconf="/etc/keystone/logging.cnf"
pidfile="/var/run/keystone/$name.pid"
lockfile="/var/lock/subsys/openstack-$name"

[ -f "/etc/sysconfig/openstack-keystone-common" ] && . "/etc/sysconfig/openstack-keystone-common"
[ -f "/etc/sysconfig/openstack-$name" ] && . "/etc/sysconfig/openstack-$name"

OPTIONS="-c $configfile --log-config $logconf $KEYSTONE_COMMON_OPTIONS $OPTIONS"

export PYTHON_EGG_CACHE=/tmp/$user/PYTHON_EGG_CACHE

start() {
    echo -n "Starting $name: "
    daemonize -p "$pidfile" -u "$user" -l "$lockfile" \
              -a -e "/var/log/keystone/$name-stderr.log" "/usr/bin/$name" $OPTIONS
    retval=$?
    [ $retval -eq 0 ] && touch "$lockfile"
    [ $retval -eq 0 ] && success || failure
    echo
    return $retval
}

stop() {
    echo -n "Stopping $name: "
    killproc -p "$pidfile" "/usr/bin/$name"
    retval=$?
    rm -f "$lockfile"
    echo
    return $retval
}

restart() {
    stop
    start
}

rh_status() {
    status -p "$pidfile" "/usr/bin/$name"
}

rh_status_q() {
    rh_status &> /dev/null
}

case "$1" in
    start)
        rh_status_q && exit 0
        $1
        ;;
    stop)
        rh_status_q || exit 0
        $1
        ;;
    restart)
        $1
        ;;
    reload)
        ;;
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
        restart
        ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart}"
        exit 2
esac
exit $?
