#!/bin/bash

# Download OpenWrt Image Builder
curl -SL "$BUILDER_URL" -o builder.tar.xz 2>/dev/null
mkdir builder
tar Jxvf builder.tar.xz -C builder --strip-components=1 >/dev/null

# Prepare custom packages
mkdir -p builder/packages
cp -v \
    sdk/bin/targets/*/*/packages/kmod-nft-fullcone*.ipk \
    sdk/bin/packages/*/base/firewall4*.ipk \
    sdk/bin/packages/*/base/libnftnl*.ipk \
    sdk/bin/packages/*/base/nftables*.ipk \
    sdk/bin/packages/*/base/stun-client*.ipk \
    builder/packages

# Build image with custom files & packages
cd builder
make image FILES="../files" PACKAGES=" \
-dnsmasq \
acme-acmesh-dnsapi \
coreutils-base64 \
curl \
ddns-scripts-cloudflare \
dnsmasq-full \
drill \
iperf3 \
jq \
kmod-nft-fullcone \
luci \
luci-app-acme \
luci-app-ddns \
luci-app-ttyd \
luci-app-upnp \
luci-app-wol \
luci-base \
luci-i18n-acme-zh-cn \
luci-i18n-base-zh-cn \
luci-i18n-ddns-zh-cn \
luci-i18n-firewall-zh-cn \
luci-i18n-opkg-zh-cn \
luci-i18n-ttyd-zh-cn \
luci-i18n-upnp-zh-cn \
luci-i18n-wol-zh-cn \
luci-proto-nebula \
nebula \
nebula-proto \
openssh-sftp-server \
rsync \
shadowsocks-libev-ss-server \
stun-client \
tmux \
vim"

# Store firmware path for later firmware upload
cd bin/targets/*/*
echo "FIRMWARE_PATH=$PWD" >>$GITHUB_ENV
