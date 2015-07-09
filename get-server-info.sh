# https://github.com/skyzyx/server-metadata
# By Ryan Parman
#
# Written against Bash 4.x.

if [[ -f /etc/environment ]]; then
    source /etc/environment;
fi;

# Which version of sed do we have available?
if [[ $(sed --help 2>&1) && $? -eq 0 ]]; then
    gnused=true
    sed=sed
elif [[ $(gsed --help 2>&1) && $? -eq 0 ]]; then
    gnused=true
    sed=gsed
else
    gnused=false
    sed=sed
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

#-------------------------------------------------------------------------------

echo "OPERATING SYSTEM:"
if [[ $(which sw_vers 2>&1) != *"no sw_vers"* && $(which sw_vers 2>&1) ]]; then
    echo "OS: $(sw_vers -productName) $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
elif [[ $(which python 2>&1) != *"no python"* && $(which python 2>&1) ]]; then
    echo "OS: $(python -c 'import platform; print platform.linux_distribution()[0] + " " + platform.linux_distribution()[1]')"
fi;
if [[ $(which uname 2>&1) != *"no uname"* && $(which uname 2>&1) ]]; then
    echo "Kernel: $(uname) $(uname -r)"
fi;

#-------------------------------------------------------------------------------
echo ""

echo "NETWORK:"
if [[ $(which scutil 2>&1) != *"no scutil"* && $(which scutil 2>&1) ]]; then
    echo "Hostname: $(scutil --get LocalHostName)"
elif [[ $(which hostname 2>&1) != *"no hostname"* && $(which hostname 2>&1) ]]; then
    echo "Hostname: $(hostname)"
fi;
if [[ $(which ifconfig 2>&1) != *"no ifconfig"* && $(which ifconfig 2>&1) ]]; then
    echo "Internal IP(s): $(ifconfig | awk -F "[: ]+" '/inet addr:/ { if ($4 != "127.0.0.1") print $4 }' | awk '{printf "%s, ", $0} END {print ""}' | awk '{sub(/, $/,""); print}')"
fi;

#-------------------------------------------------------------------------------
echo ""

echo "HARDWARE:"
if [ -f /proc/cpuinfo ]; then
    echo "CPU Speed: $(cat /proc/cpuinfo | grep 'model name' | awk {'print $8'} | head -n 1)"
    echo "CPU Cores: $(cat /proc/cpuinfo | grep 'cpu cores' | awk {'print $4}' | head -n 1)"
elif [[ $(which sysctl 2>&1) != *"no sysctl"* && $(which sysctl 2>&1) ]]; then
    echo "CPU Speed: $(sysctl -n machdep.cpu.brand_string | sed -e "s/.*@ *//")"
    echo "CPU Cores: $(sysctl -n hw.ncpu)"
fi;
if [ -f /proc/meminfo ]; then
    echo "Memory: $(expr $(cat /proc/meminfo | grep 'MemTotal:' | awk {'print $2}') / 1024) MB"
elif [[ $(which sysctl 2>&1) != *"no sysctl"* && $(which sysctl 2>&1) ]]; then
    echo "Memory: $(expr $(sysctl -n hw.memsize) / 1024 / 1024) MB"
fi;
if [ -f /proc/uptime ]; then
    echo "System Uptime: $( __uptime )"
fi;
if [[ $(which uptime 2>&1) != *"no uptime"* && $(which uptime 2>&1) ]]; then
    echo "Load Average: $(uptime | awk -F'load average:' '{ print $2 }' | sed 's/^ *//g')"
fi;

#-------------------------------------------------------------------------------
echo ""

echo "SOFTWARE:"
if [[ $(which awk 2>&1) != *"no awk"* && $(which awk 2>&1) ]]; then
    echo "$(awk --version 2>&1 | head -n 1)"
fi;
if [[ $(which curl 2>&1) != *"no curl"* && $(which curl 2>&1) ]]; then
    echo "$(curl --version 2>&1 | head -n 1 | sed -e "s/ ([^\)]*)/:/")"
fi;
if [[ $(which git 2>&1) != *"no git"* && $(which git 2>&1) ]]; then
    echo "$(git version | sed -e "s/git version/Git/" | head -n 1)"
fi;
if [[ $(which openssl 2>&1) != *"no openssl"* && $(which openssl 2>&1) ]] && [[ $(which apt-get 2>&1) != *"no apt-get"* && $(which apt-get 2>&1) ]]; then
    echo "$(apt-cache show openssl | grep 'Version:' | head -n 1 | sed 's/Version:/OpenSSL/')"
elif [[ $(which openssl 2>&1) != *"no openssl"* && $(which openssl 2>&1) ]] && [[ $(which yum 2>&1) != *"no yum"* && $(which yum 2>&1) ]]; then
    echo "OpenSSL $(yum list openssl 2>&1 | grep -i "openssl.x86_64" | awk '{print $2}')"
else
    echo "$(openssl version)"
fi;
if [[ $gnused == true ]]; then
    echo "$($sed --version 2>&1 | head -n 1)"
fi;

#-------------------------------------------------------------------------------
echo ""

echo "RUNTIMES:"
if [[ $(which go 2>&1) != *"no go"* && $(which go 2>&1) ]]; then
    echo "Golang: $(go version 2>&1 | sed -e "s/version go//" | awk '{print $2}')"
fi;
if [[ $(which java 2>&1) != *"no java"* && $(which java 2>&1) ]]; then
    echo "Java $(java -version 2>&1 | head -n 2 | tail -n 1 | sed -e "s/.*build //" | tr -d ")" )"
fi;
if [[ $(which node 2>&1) != *"no node"* && $(which node 2>&1) ]]; then
    echo "Node.js $(node --version 2>&1)"
fi;
if [[ $(which php 2>&1) != *"no php"* && $(which php 2>&1) ]]; then
    echo "$(php --version 2>&1 | head -n 1 | sed -e "s/(cli).*//")"
fi;
if [[ $(which python 2>&1) != *"no python"* && $(which python 2>&1) ]]; then
    echo -n "$(python --version)"
fi;
if [[ $(which python3 2>&1) != *"no python3"* && $(which python3 2>&1) ]]; then
    echo "$(python3 --version)"
fi;
if [[ $(which ruby 2>&1) != *"no ruby"* && $(which ruby 2>&1) ]]; then
    echo "$(ruby --version | sed -e "s/(.*//" | sed -e "s/ruby/Ruby/")"
fi;

#-------------------------------------------------------------------------------
echo ""

echo "SERVICES:"
if [[ $(which httpd 2>&1) != *"no httpd"* && $(which httpd 2>&1) ]]; then
    echo "$(httpd -v | grep -i "Server version:" | sed -e "s/Server version: *//")"
fi;
if [[ $(which mongo 2>&1) != *"no mongo"* && $(which mongo 2>&1) ]]; then
    echo "$(mongo --version | sed -e "s/ shell version://")"
fi;
if [[ $(which mysql 2>&1) != *"no mysql"* && $(which mysql 2>&1) ]]; then
    echo "MySQL $(mysql --version | sed -e "s/.*Distrib *//" | sed -e "s/,.*//")"
fi;
if [[ $(which nginx 2>&1) != *"no nginx"* && $(which nginx 2>&1) ]]; then
    echo "Nginx $(nginx -v 2>&1 | sed -e "s/nginx version: //" | sed -e "s/nginx\///")"
fi;
if [[ $(which psql 2>&1) != *"no psql"* && $(which psql 2>&1) ]]; then
    echo "PostgreSQL $(psql -V | sed -e "s/.*) *//")"
fi;
if [[ $(which redis-server 2>&1) != *"no redis-server"* && $(which redis-server 2>&1) ]]; then
    echo "$(redis-server --version | sed -e "s/ server v=/ /" | sed -e "s/sha=.*//")"
fi;
if [[ $(which rsyslogd 2>&1) != *"no rsyslogd"* && $(which rsyslogd 2>&1) ]]; then
    echo "$(__rsyslog)"
fi;
if [[ $(which unicorn 2>&1) != *"no unicorn"* && $(which unicorn 2>&1) ]]; then
    echo "$(unicorn -v | sed -e "s/unicorn v/Unicorn /")"
fi;

#-------------------------------------------------------------------------------
echo ""

echo "PACKAGE MANAGERS:"
if [[ $(which apt-get 2>&1) != *"no apt-get"* && $(which apt-get 2>&1) ]]; then
    echo "APT $(apt-get --version | head -n 1 | sed -e "s/apt //" | sed -e "s/ .*//")"
fi;
if [[ $(which bundler 2>&1) != *"no bundler"* && $(which bundler 2>&1) ]]; then
    echo "$(bundler -v | sed -e "s/ version//")"
fi;
if [[ $(which composer 2>&1) != *"no composer"* && $(which composer 2>&1) ]]; then
    if [[ $gnused == true ]]; then
        echo "$(composer --version)" | sed -e "s/ version//" | sed -e "s/ (.*)//" | $sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"
    else
        echo "$(composer --version)" | sed -e "s/ version//" | sed -e "s/ (.*)//"
    fi;
fi;
if [[ $(which brew 2>&1) != *"no brew"* && $(which brew 2>&1) ]]; then
    echo "Homebrew $(brew --version)"
fi;
if [[ $(which npm 2>&1) != *"no npm"* && $(which npm 2>&1) ]]; then
    echo "npm $(npm --version)"
fi;
if [[ $(which pip 2>&1) != *"no pip"* && $(which pip 2>&1) ]]; then
    echo "$(pip --version 2>&1 | sed -e "s/from.*(/(/")"
fi;
if [[ $(which pip3 2>&1) != *"no pip3"* && $(which pip3 2>&1) ]]; then
    echo "$(pip3 --version 2>&1 | sed -e "s/from.*(/(/")"
fi;
if [[ $(which gem 2>&1) != *"no gem"* && $(which gem 2>&1) ]]; then
    echo "RubyGems $(gem --version)"
fi;
if [[ $(which easy_install 2>&1) != *"no easy_install"* && $(which easy_install 2>&1) ]]; then
    echo "$(easy_install --version)"
fi;
if [[ $(which yum 2>&1) != *"no yum"* && $(which yum 2>&1) ]]; then
    echo "YUM $(yum --version | head -n 1)"
fi;
