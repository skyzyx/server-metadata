# https://github.com/skyzyx/server-metadata
# By Ryan Parman
#
# Written against Bash 4.x.

if [[ -f /etc/environment ]]; then
    source /etc/environment;
fi;

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
if [[ $(which sw_vers 2>&1) != *"no sw_vers"* ]]; then
    echo "OS: $(sw_vers -productName) $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
elif [[ $(which python 2>&1) != *"no python"* ]]; then
    echo "OS: $(python -c 'import platform; print platform.linux_distribution()[0] + " " + platform.linux_distribution()[1]')"
fi;
if [[ $(which uname 2>&1) != *"no uname"* ]]; then
    echo "Kernel: $(uname) $(uname -r)"
fi;
echo ""
echo "NETWORK:"
if [[ $(which scutil 2>&1) != *"no scutil"* ]]; then
    echo "Hostname: $(scutil --get LocalHostName)"
elif [[ $(which hostname 2>&1) != *"no hostname"* ]]; then
    echo "Hostname: $(hostname)"
fi;
if [[ $(which ifconfig 2>&1) != *"no ifconfig"* ]]; then
    echo "Internal IP: $(ifconfig | awk -F "[: ]+" '/inet addr:/ { if ($4 != "127.0.0.1") print $4 }')"
fi;
echo ""
echo "HARDWARE:"
if [ -f /proc/cpuinfo ]; then
    echo "CPU Speed: $(cat /proc/cpuinfo | grep 'model name' | awk {'print $8'} | head -n 1)"
    echo "CPU Cores: $(cat /proc/cpuinfo | grep 'cpu cores' | awk {'print $4}' | head -n 1)"
fi;
if [ -f /proc/meminfo ]; then
    echo "Memory: $(expr $(cat /proc/meminfo | grep 'MemTotal:' | awk {'print $2}') / 1024) MB"
fi;
if [ -f /proc/uptime ]; then
    echo "System Uptime: $( __uptime )"
fi;
if [[ $(which uptime 2>&1) != *"no uptime"* ]]; then
    echo "Load Average: $(uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ *//g')"
fi;
echo ""
echo "SOFTWARE:"
echo "OpenSSL $(yum list openssl 2>&1 | grep -i "openssl.x86_64" | awk '{print $2}')"
if [[ $(which go 2>&1) != *"no go"* ]]; then
    echo -n "Golang: $(go version 2>&1 | sed -e "s/version go//" | awk '{print $2}')"
fi;
if [[ $(which java 2>&1) != *"no java"* ]]; then
    echo "$(java -version 2>&1 | head -n 2 | tail -n 1)"
fi;
if [[ $(which php 2>&1) != *"no php"* ]]; then
    echo -n "$(php --version 2>&1 | head -n 1 | sed -e "s/(cli).*//")"
fi;
if [[ $(which python 2>&1) != *"no python"* ]]; then
    echo -n "$(python --version)"
fi;
if [[ $(which python3 2>&1) != *"no python3"* ]]; then
    echo -n "$(python3 --version)"
fi;
if [[ $(which ruby 2>&1) != *"no ruby"* ]]; then
    echo -n "$(ruby --version | sed -e "s/(.*//" | sed -e "s/ruby/Ruby/")"
fi;
echo ""
echo "SERVICES:"
echo "Nginx $(nginx -v 2>&1 | sed -e "s/nginx version: //" | sed -e "s/nginx\///")"
echo "$(curl --version 2>&1 | head -n 1 | sed -e "s/ ([^\)]*)/:/")"
echo "$(__rsyslog)"
