#! /bin/bash
# optimize, prep and install sserver
# Works on Ubuntu 14.04 and above
# Created by John Koh. (github: johnthedong)
# thanks to teddysun and kengz

#TODO:
# [] move script to johnthedong/shadowsocks_installer_script
# [] check_presence
# [x] optimize_system
# [] get_prerequisites
# [] install_ss
# [] install_cleanup

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# -------------------------Setup preinstall files------------------------
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

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

# backup urls to get the files
john_libsodium_url=https://github.com/johnthedong/shadowsocks_easy_installer/blob/john/server-automation/requirements/libsodium/libsodium-1.0.11.tar.gz
john_shadowsocks_url=https://github.com/johnthedong/shadowsocks_easy_installer/blob/john/server-automation/requirements/shadowsocks/shadowsocks-master.zip

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

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# -------------------------Helper/shared functions-----------------------
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

# Disable selinux
function disable_selinux(){
    if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        setenforce 0
    fi
}

function write_if_not_present(){
    if grep -i $1 $2; then
        # delete line if present. clears commented out same entries
        sudo sed -i '' "/$1/d" $2
    fi
    sudo echo $1 >> $2
}

# -----------------------------------------------------------------------
# -----------------------------------------------------------------------
# -----------------------------Main functions----------------------------
# -----------------------------------------------------------------------
# -----------------------------------------------------------------------

# check if ss is already installed
# todo: if installed, clear
function check_presence(){

}

# optimize based on 
# https://www.vpndada.com/how-to-setup-shadowsocks-server-on-amazon-ec2/
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
    write_if_not_present '* soft nofile 51200' limits_conf
    write_if_not_present '* hard nofile 51200' limits_conf
    sudo ulimit -n 51200

    echo "
    => Tweak sysctl settings.
    "
    sysctl_conf=/etc/sysctl.conf

    write_if_not_present 'fs.file-max = 51200' sysctl_conf
    write_if_not_present 'net.core.rmem_max = 67108864' sysctl_conf
    write_if_not_present 'net.core.wmem_max = 67108864' sysctl_conf
    write_if_not_present 'net.core.netdev_max_backlog = 250000' sysctl_conf
    write_if_not_present 'net.core.somaxconn = 4096' sysctl_conf
    write_if_not_present 'net.ipv4.tcp_syncookies = 1' sysctl_conf
    write_if_not_present 'net.ipv4.tcp_tw_reuse = 1' sysctl_conf
    write_if_not_present 'net.ipv4.tcp_tw_recycle = 0' sysctl_conf
    write_if_not_present 'net.ipv4.tcp_fin_timeout = 30' sysctl_conf
    write_if_not_present 'net.ipv4.tcp_keepalive_time = 1200' sysctl_conf
    write_if_not_present 'net.ipv4.ip_local_port_range = 10000 65000' sysctl_conf
    write_if_not_present 'net.ipv4.tcp_max_syn_backlog = 8192' sysctl_conf
    write_if_not_present 'net.ipv4.tcp_max_tw_buckets = 5000' sysctl_conf
    write_if_not_present 'net.ipv4.tcp_fastopen = 3' sysctl_conf
    write_if_not_present 'net.ipv4.tcp_mem = 25600 51200 102400' sysctl_conf
    write_if_not_present 'net.ipv4.tcp_rmem = 4096 87380 67108864' sysctl_conf
    write_if_not_present 'net.ipv4.tcp_wmem = 4096 65536 67108864' sysctl_conf
    write_if_not_present 'net.ipv4.tcp_mtu_probing = 1' sysctl_conf

    # if latency too high, use hybla, else htcp
    echo "
    Is the server close to the intended use location? 
    (latency lower then 100, e.g.: Japan/Korea to China)
    "
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) write_if_not_present 'net.ipv4.tcp_congestion_control = htcp' sysctl_conf; break;;
            No ) write_if_not_present 'net.ipv4.tcp_congestion_control = hybla' sysctl_conf; break;;
        esac
    done

    sudo sysctl -p
    modprobe tcp_htcp
}

# check if ss is already running
function check_presence(){
# check syspath if present
# check ps if it's running behind
# check version if it's up to date
}

# get all prerequisites for shadowsocks
function get_prerequisites(){
    echo "Downloading libsodium"
    if ! wget --no-check-certificate -O libsodium-1.0.11.tar.gz https://github.com/jedisct1/libsodium/releases/download/1.0.11/libsodium-1.0.11.tar.gz; then
        echo "Failed to get libsodium from the original author"
        echo "Downloading libsodium from the backup location"
        if ! wget --no-check-certificate -O libsodium-1.0.11.tar.gz john_libsodium_url; then
            echo "Failed to download libsodium from both sources!!"
            exit 1
    fi
    
    tar zxf libsodium-1.0.11.tar.gz
    if [ $? -ne 0 ]; then
        echo "Failed to untar libsodium!"
        exit 1
    fi

    echo "Downloading shadowsocks"
    if ! wget --no-check-certificate -O shadowsocks-master.zip https://github.com/shadowsocks/shadowsocks/archive/master.zip; then
        echo "Failed to get shadowsocks from the original author"
        echo "Downloading shadowsocks from the backup location"
        if ! wget --no-check-certificate -O shadowsocks-master.zip john_shadowsocks_url; then
            echo "Failed to download Shadowsocks file!"
            exit 1
    fi

    unzip -q shadowsocks-master.zip
    if [ $? -ne 0 ]; then
        echo "Failed to unzip shadowsocks-master.zip!"
        exit 1
    fi
}

# actual installation script
function install_ss(){
    # setup autorun on boot
    write_if_not_present '/usr/bin/python /usr/local/bin/ssserver -c /etc/shadowsocks.json -d start' /etc/rc.local
}

# remove installation files
# also clear up temp files
function install_cleanup(){
    cd ${cur_dir}
    rm -f shadowsocks-master.zip
    rm -rf shadowsocks-master
    rm -f libsodium-1.0.11.tar.gz
    rm -rf libsodium-1.0.11
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
    #if fails/bad commands given
    echo "Argument error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall}"
    ;;
esac