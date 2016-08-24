#! /bin/bash
# optimize, prep and install sserver
# Works on Ubuntu 14.04 and above
# thanks to teddysun and kengz

# Fail on the first error; killable by SIGINT
set -e
trap "exit" INT

# set path
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# get current dir
cur_dir=$(pwd)
# get public ip
pub_ip=$(curl -s http://whatismyip.akamai.com/)

clear

echo "
================================================
Running the Shadowsocks optimized installer for
Ubuntu.
================================================
"

echo "
=> Requesting permission upfront"
# Ask for the administrator password upfront
[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"
# sudo -v
# Keep-alive: update existing `sudo` time stamp until this script has finished
# thanks @kengz
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Disable selinux
function disable_selinux(){
if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    setenforce 0
fi
}


function optimize_system(){
    echo "
    ================================================
    Optimizing system for Shadowsocks
    ================================================
    "

    echo "
    => Setting higher writefile limits.
    "

    limits_conf=/etc/security/limits.conf
    if grep '* soft nofile 51200' limits_conf; then
      sudo echo "* soft nofile 51200" >> /etc/security/limits.conf
    fi
    if grep '* hard nofile 51200' limits_conf; then
      sudo echo "* hard nofile 51200" >> /etc/security/limits.conf
    fi
    sudo ulimit -n 51200
}

function install_shadowsocks(){
    check_presence

    echo "
    Optimize server for shadowsocks?
    Do not select if the optimizations have already been done.
    "
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) optimize_system; break;;
            No ) break;;
        esac
    done

    get_prerequisites
    install_ss
    install_cleanup
}

# Initialization step
action=$1
[ -z $1 ] && action=install
case "$action" in 
install)
    install_shadowsocks
    ;;
uninstall)
    uninstall_shadowsocks
    ;;
*)
    echo "Argument error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall}"
    ;;
esac