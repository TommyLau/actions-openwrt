#!/bin/bash
sudo rm -rf /etc/apt/sources.list.d/* /usr/share/dotnet /usr/local/lib/android /opt/ghc
sudo -E apt-get -qq update
sudo -E apt-get -qq install -y --no-install-recommends subversion build-essential libncurses5-dev zlib1g-dev gawk git ccache gettext libssl-dev xsltproc zip upx gcc-multilib g++-multilib
sudo -E apt-get -qq autoremove --purge
sudo -E apt-get -qq clean
sudo timedatectl set-timezone "$TIMEZONE"
OPENWRT_URL=`eval echo "$OPENWRT_URL"`
SDK_URL=`eval echo "$SDK_URL"`
BUILDER_URL=`eval echo "$BUILDER_URL"`
echo "OPENWRT_URL=$OPENWRT_URL" >> $GITHUB_ENV
echo "SDK_URL=$SDK_URL" >> $GITHUB_ENV
echo "BUILDER_URL=$BUILDER_URL" >> $GITHUB_ENV
