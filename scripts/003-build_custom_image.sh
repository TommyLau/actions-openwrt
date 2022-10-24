#!/bin/bash

# Download OpenWrt Image Builder
curl -SL "$BUILDER_URL" -o builder.tar.xz
mkdir builder
tar Jxvf builder.tar.xz -C builder --strip-components=1

# Prepare custom packages
mkdir -p builder/packages
cp -v sdk/bin/targets/*/*/packages/kmod-nft-fullcone*.ipk builder/packages
cp -v sdk/bin/packages/*/base/firewall4*.ipk builder/packages
cp -v sdk/bin/packages/*/base/libnftnl*.ipk builder/packages
cp -v sdk/bin/packages/*/base/nftables*.ipk builder/packages

# Build image with custom files & packages
cd builder
make image FILES="../files" PACKAGES=" \
-dnsmasq \
coreutils-base64 \
curl \
ddns-scripts-cloudflare \
dnsmasq-full \
iperf3 \
jq \
kmod-nft-fullcone \
luci \
luci-app-acme \
luci-app-ddns \
luci-app-upnp \
luci-app-wol \
luci-base \
luci-i18n-acme-zh-cn \
luci-i18n-base-zh-cn \
luci-i18n-ddns-zh-cn \
luci-i18n-firewall-zh-cn \
luci-i18n-opkg-zh-cn \
luci-i18n-upnp-zh-cn \
luci-i18n-wol-zh-cn \
nebula \
nebula-service \
tmux \
vim"

# Store firmware path for later firmware upload
cd bin/targets/*/*
echo "FIRMWARE_PATH=$PWD" >> $GITHUB_ENV
