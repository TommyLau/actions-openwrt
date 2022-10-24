#!/bin/bash

# Setup version information
OPENWRT_VERSION="${OPENWRT_VERSION:-22.03.2}"
OPENWRT_URL="https://downloads.openwrt.org/releases/${OPENWRT_VERSION}/targets/${DEVICE_TARGET}/${DEVICE_SUB_TARGET}"
SDK_URL="${OPENWRT_URL}/openwrt-sdk-${OPENWRT_VERSION}-${DEVICE_TARGET}-${DEVICE_SUB_TARGET}_gcc-11.2.0_musl.Linux-x86_64.tar.xz"
BUILDER_URL="${OPENWRT_URL}/openwrt-imagebuilder-${OPENWRT_VERSION}-${DEVICE_TARGET}-${DEVICE_SUB_TARGET}.Linux-x86_64.tar.xz"
TIMEZONE=Asia/Shanghai

# Install build essential
sudo rm -rf /etc/apt/sources.list.d/* /usr/share/dotnet /usr/local/lib/android /opt/ghc
sudo -E apt-get -qq update
sudo -E apt-get -qq install -y --no-install-recommends subversion build-essential libncurses5-dev zlib1g-dev gawk git ccache gettext libssl-dev xsltproc zip upx gcc-multilib g++-multilib
sudo -E apt-get -qq autoremove --purge
sudo -E apt-get -qq clean

# Set timezone
sudo timedatectl set-timezone "$TIMEZONE"

# Prepare enivronment for GitHub Action
echo "OPENWRT_URL=$OPENWRT_URL" >>$GITHUB_ENV
echo "SDK_URL=$SDK_URL" >>$GITHUB_ENV
echo "BUILDER_URL=$BUILDER_URL" >>$GITHUB_ENV
