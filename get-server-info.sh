# https://github.com/skyzyx/server-metadata
# By Ryan Parman
#
# Expects Python to be installed.
# Written against Bash 4.x.

if [[ -f /etc/environment ]]; then
    source /etc/environment;
fi;

function if_installed() {
    if [ "$1" != "" ]; then
        if [[ $(which $1 2>&1) =~ "no $1" ]]; then
            echo 0;
        else
            echo 1;
        fi;
    fi;
}

function __uptime() {
    uptime=$(cat /proc/uptime)
    uptime=${uptime%%.*}
    seconds=$(( uptime%60 ))
    minutes=$(( uptime/60%60 ))
    hours=$(( uptime/60/60%24 ))
    days=$(( uptime/60/60/24 ))
    uptime="$days"d", $hours"h", $minutes"m", $seconds"s""
    echo $uptime
}

function __rsyslog() {
    rsl="$(rsyslogd -v 2>&1)"
    rsl="$(echo "$rsl" | grep -vi "no" | grep -vi "rsyslog.com" | grep ".")"
    rsl="$(echo "$rsl" | sed -e "s/:\s*Yes//" | sed -e "s/^\s*/ /" | sed -e "s/^\s*//")"
    rsl="$(echo "$rsl" | awk '{printf "%s, ", $0} END {print ""}' | awk '{sub(/, $/,""); print}')"
    rsl="$(echo "$rsl" | sed -e "s/:,/:/")"
    echo "$rsl"
}

echo "OPERATING SYSTEM:"
if [ $(if_installed sw_vers) ]; then # OS X
    echo "OS: $(sw_vers -productName) $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
elif [ $(if_installed python) ]; then # Linux
    echo "OS: $(python -c 'import platform; print platform.linux_distribution()[0] + " " + platform.linux_distribution()[1]')"
fi;
[[ $(if_installed uname) ]] && echo "Kernel: $(uname) $(uname -r)"
echo ""
echo "NETWORK:"
if [ $(if_installed scutil) ]; then # OS X
    echo "Hostname: $(scutil --get LocalHostName)"
elif [ $(if_installed hostname) ]; then
    echo "Hostname: $(hostname)"
fi;
[[ $(if_installed ifconfig) ]] && echo "Internal IP: $(ifconfig | awk -F "[: ]+" '/inet addr:/ { if ($4 != "127.0.0.1") print $4 }')"
echo ""
echo "HARDWARE:"
[[ -f /proc/cpuinfo ]] && echo "CPU Speed: $(cat /proc/cpuinfo | grep 'model name' | awk {'print $8'} | head -n 1)"
[[ -f /proc/cpuinfo ]] && echo "CPU Cores: $(cat /proc/cpuinfo | grep 'cpu cores' | awk {'print $4}' | head -n 1)"
[[ -f /proc/meminfo ]] && echo "Memory: $(expr $(cat /proc/meminfo | grep 'MemTotal:' | awk {'print $2}') / 1024) MB"
echo "System Uptime: $( __uptime )"
[[ $(if_installed uptime) ]] && echo "Load Average: $(uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ *//g')"
echo ""
echo "SOFTWARE:"
echo "OpenSSL $(yum list openssl 2>&1 | grep -i "openssl.x86_64" | awk '{print $2}')"
echo -n "$(python --version)"
echo "$(java -version 2>&1 | head -n 2 | tail -n 1)"
echo ""
echo "SERVICES:"
echo "Nginx $(nginx -v 2>&1 | sed -e "s/nginx version: //" | sed -e "s/nginx\///")"
echo "$(curl --version 2>&1 | head -n 1 | sed -e "s/ ([^\)]*)/:/")"
echo "$(__rsyslog)"
