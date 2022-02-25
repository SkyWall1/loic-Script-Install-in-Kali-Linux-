#!/bin/bash
# This script installs, updates and runs LOIC on Kali Linux.
# Supported distributions:
#    * Debian Bullseye ID=kali 	VERSION="2022"
#
# Before using you must install monodevelop from:
# https://www.monodevelop.com/download/#fndtn-download-lin
#
# Usage: bash ./loic.sh <install|update|run>
#
# Add the Mono repository to your system
#The package repository hosts the packages you need, add it with the following commands.
# Note: the packages should work on newer Debian versions too but we only test the ones listed below.
# Debian 10 (i386, amd64, armhf, armel) <for> Debian 11 Bullseye
sudo apt install apt-transport-https dirmngr gnupg ca-certificates
sudo wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
sudo apt-get install gnupg
sudo apt-get install -y mongodb-org mongodb-org-database mongodb-org-server mongodb-org-shell mongodb-org-mongos mongodb-org-tools
sudo apt-get install gnupg2
sudo wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
sudo echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list
sudo echo "deb http://ftp.de.debian.org/debian buster main"
sudo apt update
sudo apt-get install -y mongodb-org
sudo systemctl start mongod
sudo systemctl enable mongod
sudo apt --fix-broken install
GIT_REPO=https://github.com/NewEraCracker/LOIC.git
GIT_BRANCH=master
DEB_MONO_PKG="monodevelop mono-devel mono-runtime-common mono-runtime libmono-system-windows-forms4.0-cil"
FED_MONO_PKG="mono-basic mono-devel monodevelop mono-tools"
lower() {
    tr '[A-Z]' '[a-z]'
}
what_distro() {
#   if which lsb_release ; then
#       echo lsb_release -si | lower
#   el
    if grep -qri ubuntu /etc/*-release ; then
        echo "ubuntu"
    elif [[ -e /etc/fedora-release ]] ; then
        echo "fedora"
    else
        # Assume Debian-based
        echo "debian"
    fi
}
DISTRO=$(what_distro)
ensure_git() {
    if ! which git ; then
        if [[ $DISTRO = 'ubuntu' || $DISTRO = 'debian' ]] ; then
            sudo apt-get install git
        elif [[ $DISTRO = 'fedora' ]] ; then
            sudo yum install git
        fi
    fi
}
is_loic() {
    is_loic_git || { [[ -d LOIC ]] && cd LOIC && is_loic_git; }
}
is_loic_git() {
    [[ -d .git ]] && grep -q LOIC .git/config
}
get_loic() {
    ensure_git
    if ! is_loic ; then
        git clone $GIT_REPO -b $GIT_BRANCH
    fi
}
compile_loic() {
    get_loic
    if ! is_loic ; then
        echo "Error: You are not in a LOIC repository."
        exit 1
    fi
    if [[ $DISTRO = 'ubuntu' || $DISTRO = 'debian' ]] ; then
        sudo apt-get install $DEB_MONO_PKG
    elif [[ $DISTRO = 'fedora' ]] ; then
        sudo yum install $FED_MONO_PKG
    fi
    cd src; xbuild /p:TargetFrameworkVersion="v4.0"
}
run_loic() {
    is_loic
    if [[ ! -e src/bin/Debug/LOIC.exe ]] ; then
        compile_loic
    fi
    if ! which mono ; then
        if [[ $DISTRO = 'ubuntu' || $DISTRO = 'debian' ]] ; then
            sudo apt-get install mono-runtime
        elif [[ $DISTRO = 'fedora' ]] ; then
            sudo yum install mono-runtime
        fi
    fi
    cp -n ./src/app.config ./src/bin/Debug/LOIC.exe.config
    mono --runtime=v4.0.30319 src/bin/Debug/LOIC.exe
}
update_loic() {
    ensure_git
    if is_loic ; then
        git pull --rebase
        compile_loic
    else
        echo "Error: You are not in a LOIC repository."
    fi
}
case $1 in
    install)
        compile_loic
        ;;
    update)
        update_loic
        ;;
    run)
        run_loic
        ;;
    *)
        echo "Usage: $0 <install|update|run>"
        ;;
esac
