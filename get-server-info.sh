# https://github.com/skyzyx/server-metadata
# By Ryan Parman

echo "#-------------------------------------------------------------------------------"

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
echo "Active Shell: $SHELL"
$(echo $SHELL) --version | head -n 1

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
    echo "CPU Speed: $(cat /proc/cpuinfo | grep 'model name' | sed -e "s/.*@ *//" | head -n 1)"
    echo "CPU Cores: $(nproc)"
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

echo "SHELLS:"
if [[ $(which bash 2>&1) != *"no bash"* && $(which bash 2>&1) ]]; then
    echo "Bash shell $(bash --version 2>&1 | head -n 1 | sed -e "s/-release.*//" | sed -e "s/GNU bash, version //")"
fi;
if [[ $(which csh 2>&1) != *"no csh"* && $(which csh 2>&1) ]]; then
    echo "C-shell $(csh --version | sed -e "s/ (.*)//g")"
fi;
if [[ $(which fish 2>&1) != *"no fish"* && $(which fish 2>&1) ]]; then
    echo "Fish shell $(fish --version 2>&1 | sed -e "s/.*version //")"
fi;
if [[ $(which ksh 2>&1) != *"no ksh"* && $(which ksh 2>&1) ]]; then
    echo "Korn shell $(ksh --version 2>&1 | sed -e "s/.*) //")"
fi;
if [[ $(which zsh 2>&1) != *"no zsh"* && $(which zsh 2>&1) ]]; then
    echo "Z-shell $(zsh --version | sed -e "s/ (.*//" | sed -e "s/zsh //")"
fi;

#-------------------------------------------------------------------------------
echo ""

hhvm=false
echo "RUNTIMES/COMPILERS:"
if [[ $(which gcc 2>&1) != *"no gcc"* && $(which gcc 2>&1) ]]; then
    echo "GCC: $(gcc --version 2>/dev/null | head -n 1 | sed -e "s/Apple //" | sed -e "s/version //")"
fi;
if [[ $(which go 2>&1) != *"no go"* && $(which go 2>&1) ]]; then
    echo "Golang: $(go version 2>&1 | sed -e "s/version go//" | awk '{print $2}')"
fi;
if [[ $(which hhvm 2>&1) != *"no hhvm"* && $(which hhvm 2>&1) ]]; then
    hhvm=true
    echo "HHVM $(hhvm --version | head -n 1 | sed -e "s/HipHop VM //" | sed -e "s/ (.*//")"
fi;
if [[ $(which java 2>&1) != *"no java"* && $(which java 2>&1) ]]; then
    echo "Java $(java -version 2>&1 | head -n 2 | tail -n 1 | sed -e "s/.*build //" | tr -d ")" )"
fi;
if [[ $(which clang 2>&1) != *"no clang"* && $(which clang 2>&1) ]]; then # LLVM
    echo "LLVM/Clang: $(clang --version 2>/dev/null | head -n 1 | sed -e "s/Apple //" | sed -e "s/version //")"
fi;
if [[ $(which node 2>&1) != *"no node"* && $(which node 2>&1) ]]; then
    echo "Node.js $(node --version 2>&1)"
fi;
if [[ $(which php 2>&1) != *"no php"* && $(which php 2>&1) && $hhvm == false ]]; then
    echo "$(php --version 2>&1 | head -n 1 | sed -e "s/(cli).*//")"
fi;
if [[ $(which python 2>&1) != *"no python"* && $(which python 2>&1) ]]; then
    echo "$(python --version 2>&1)"
fi;
if [[ $(which python26 2>&1) != *"no python"* && $(which python26 2>&1) ]]; then
    echo "$(python26 --version 2>&1)"
fi;
if [[ $(which python2.6 2>&1) != *"no python"* && $(which python2.6 2>&1) ]]; then
    echo "$(python2.6 --version 2>&1)"
fi;
if [[ $(which python27 2>&1) != *"no python"* && $(which python27 2>&1) ]]; then
    echo "$(python27 --version 2>&1)"
fi;
if [[ $(which python2.7 2>&1) != *"no python"* && $(which python2.7 2>&1) ]]; then
    echo "$(python2.7 --version 2>&1)"
fi;
if [[ $(which python3 2>&1) != *"no python3"* && $(which python3 2>&1) ]]; then
    echo "$(python3 --version 2>&1)"
fi;
if [[ $(which python34 2>&1) != *"no python3"* && $(which python34 2>&1) ]]; then
    echo "$(python34 --version 2>&1)"
fi;
if [[ $(which python3.4 2>&1) != *"no python3"* && $(which python3.4 2>&1) ]]; then
    echo "$(python3.4 --version 2>&1)"
fi;
if [[ $(which python35 2>&1) != *"no python3"* && $(which python35 2>&1) ]]; then
    echo "$(python35 --version 2>&1)"
fi;
if [[ $(which python3.5 2>&1) != *"no python3"* && $(which python3.5 2>&1) ]]; then
    echo "$(python3.5 --version 2>&1)"
fi;
if [[ $(which ruby 2>&1) != *"no ruby"* && $(which ruby 2>&1) ]]; then
    echo "$(ruby --version | sed -e "s/(.*//" | sed -e "s/ruby/Ruby/")"
fi;
if [[ $(which scalac 2>&1) != *"no scalac"* && $(which scalac 2>&1) ]]; then
    echo "Scala $(scalac -version 2>&1 | sed -e "s/.*version //" | sed -e "s/ -- .*//")"
fi;
if [[ $(which swift 2>&1) != *"no swift"* && $(which swift 2>&1) ]]; then
    echo "Swift $(swift -version | head -n 1 | sed -e "s/.*version //")"
fi;

#-------------------------------------------------------------------------------
echo ""

echo "VERSION CONTROL:"
if [[ $(which cvs 2>&1) != *"no cvs"* && $(which cvs 2>&1) ]]; then
    echo "CVS $(cvs --version | head -n 2 | tail -n 1 | sed -e "s/.*CVS) //" | sed -e "s/ (.*//")"
fi;
if [[ $(which git 2>&1) != *"no git"* && $(which git 2>&1) ]]; then
    echo "$(git version | sed -e "s/git version/Git/" | head -n 1)"
fi;
if [[ $(which hg 2>&1) != *"no hg"* && $(which hg 2>&1) ]]; then
    echo "Mercurial $(hg --version | head -n 1 | sed -e "s/.*version //" | sed -e "s/)//")"
fi;
if [[ $(which svn 2>&1) != *"no svn"* && $(which svn 2>&1) ]]; then
    echo "Subversion $(svn --version | head -n 1 | sed -e "s/.*version //")"
fi;

#-------------------------------------------------------------------------------
echo ""

echo "EDITORS:"
if [[ $(which emacs 2>&1) != *"no emacs"* && $(which emacs 2>&1) ]]; then
    echo "$(emacs --version | head -n 1)"
fi;
if [[ $(which nano 2>&1) != *"no nano"* && $(which nano 2>&1) ]]; then
    echo "$(nano --version | head -n 1 | sed -e "s/ (.*)//" | sed -e "s/^ *//")"
fi;
if [[ $(which vi 2>&1) != *"no vi"* && $(which vi 2>&1) ]]; then
    echo "$(vi --version | head -n 1 | sed -e "s/ (.*)//")"
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
if [[ $(which docker-compose 2>&1) != *"no docker-compose"* && $(which docker-compose 2>&1) ]]; then
    echo "Docker Compose $(docker-compose --version | head -n 1 | sed -e "s/.*version:* //")"
fi;
if [[ $(which docker-machine 2>&1) != *"no docker-machine"* && $(which docker-machine 2>&1) ]]; then
    echo "Docker Machine $(docker-machine --version | head -n 1 | sed -e "s/.*version //")"
fi;
if [[ $(which docker-swarm 2>&1) != *"no docker-swarm"* && $(which docker-swarm 2>&1) ]]; then
    echo "Docker Swarm $(docker-swarm --version | head -n 1 | sed -e "s/.*version //")"
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
if [[ $(which vagrant 2>&1) != *"no vagrant"* && $(which vagrant 2>&1) ]]; then
    echo "$(vagrant --version 2>&1 | head -n 1)"
fi;

#-------------------------------------------------------------------------------
echo ""

echo "SERVICES:"
if [[ $(which docker 2>&1) != *"no docker"* && $(which docker 2>&1) ]]; then
    echo "Docker $(docker --version | sed -e "s/.*version //" | sed -e "s/,.*//")"
fi;
if [[ $(which etcd 2>&1) != *"no etcd"* && $(which etcd 2>&1) ]]; then
    echo "etcd $(etcd --version | sed -e "s/.*version //")"
fi;
if [[ $(which fleet 2>&1) != *"no fleet"* && $(which fleet 2>&1) ]]; then
    echo "Fleet $(fleet --version | sed -e "s/.*version //")"
fi;
if [[ $(which httpd 2>&1) != *"no httpd"* && $(which httpd 2>&1) ]]; then
    echo "$(httpd -v | grep -i "Server version:" | sed -e "s/Server version: *//" | sed -e "s/Apache\//httpd /")"
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
    echo "$(redis-server --version | sed -e "s/ server v=/ /" | sed -e "s/sha=.*//" | sed -e "s/ server version//" | sed -e "s/ (.*//")"
fi;
if [[ $(which rsyslogd 2>&1) != *"no rsyslogd"* && $(which rsyslogd 2>&1) ]]; then
    echo "$(rsyslogd -v 2>&1 | head -n 1 | sed -e "s/,.*//")"
fi;
if [[ $(which unicorn 2>&1) != *"no unicorn"* && $(which unicorn 2>&1) ]]; then
    echo "$(unicorn -v | sed -e "s/unicorn v/Unicorn /")"
fi;

#-------------------------------------------------------------------------------
echo ""

echo "LOGGERS:"
ls -d /etc/*syslog*.conf | sed -e "s/\/etc\///" | sed -e "s/.conf//"

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

echo "#-------------------------------------------------------------------------------"
