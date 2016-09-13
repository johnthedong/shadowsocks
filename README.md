# Shadowsocks Auto-installer branch

Planned new features:
- Centralized deploy system for 1 button install on Ubuntu 14.01+ systems.
- Refactorings for a more streamlined install system
- More features in the pipeline



shadowsocks
===========

[![Build Status]][Travis CI]

A fast tunnel proxy that helps you bypass firewalls.

Features:
- TCP & UDP support
- User management API
- TCP Fast Open
- Workers and graceful restart
- Destination IP blacklist

Server
------

### Install

Debian / Ubuntu:

    apt-get install python-pip
    pip install shadowsocks

CentOS:

    yum install python-setuptools && easy_install pip
    pip install shadowsocks

Windows:

See [Install Server on Windows]

### Usage

    ssserver -p 443 -k password -m aes-256-cfb

To run in the background:

    sudo ssserver -p 443 -k password -m aes-256-cfb --user nobody -d start

To stop:

    sudo ssserver -d stop

To check the log:

    sudo less /var/log/shadowsocks.log

Check all the options via `-h`. You can also use a [Configuration] file
instead.

Documentation
-------------

You can find all the documentation in the [Wiki].

License
-------

Apache License







[Build Status]:      https://img.shields.io/travis/johnthedong/shadowsocks/master.svg?style=flat
[Travis CI]:         https://travis-ci.org/johnthedong/shadowsocks

