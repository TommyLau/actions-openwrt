#!/bin/bash

# Download OpenWrt SDK
curl -SL "$SDK_URL" -o sdk.tar.xz 2>/dev/null
mkdir sdk
tar Jxvf sdk.tar.xz -C sdk --strip-components=1 >/dev/null
mkdir -p sdk/staging_dir/host/bin
ln -sf /usr/bin/upx sdk/staging_dir/host/bin/upx

# Switch to SDK directory
cd sdk

# Update feeds
./scripts/feeds update -a 2>/dev/null

# ------------------------------------------------------------
# Patches
# ------------------------------------------------------------
# Fullcone NAT support for nftables
git clone https://github.com/TommyLau/nft-fullcone.git package/kmod-nft-fullcone 2>/dev/null
mv -v feeds/base/package/libs/libnftnl package
mv -v feeds/base/package/network/utils/nftables package
mv -v feeds/base/package/network/config/firewall4 package
rsync -a ../patches/libnftnl-1.2.1/001-add-fullcone-expression-support.patch package/libnftnl/patches/
rsync -a ../patches/nftables-1.0.2/002-add-fullcone-expression-support.patch package/nftables/patches/
rsync -a ../patches/firewall4/001-firewall4-2022-10-14-add-fullcone-support.patch package/firewall4/patches/

# Use higher version, so that image builder won't download from Internet instead of using local packages
sed -i 's/$(AUTORELEASE)/99/' package/libnftnl/Makefile
sed -i 's/PKG_RELEASE:=2.1/PKG_RELEASE:=99/' package/nftables/Makefile
sed -i 's/2022-10-14/2099-12-31/' package/firewall4/Makefile

# Reindex feeds for pathces
./scripts/feeds update -i 2>/dev/null

# Install custom packages and dependencies
./scripts/feeds install kmod-nft-fullcone 2>/dev/null
./scripts/feeds install libnftnl libmnl 2>/dev/null
./scripts/feeds install nftables jansson 2>/dev/null
./scripts/feeds install firewall4 2>/dev/null

# Update seed config
CONFIG_FILE="${GITHUB_WORKSPACE}/configs/"$(echo ${DEVICE_NAME}.config | tr '[:upper:]' '[:lower:]')
[ -e $CONFIG_FILE ] && cp -v $CONFIG_FILE .config

# Build custom packages
make defconfig
make -j$(nproc) || make -j1 V=s || make -j1 V=sc
echo "BUILD_TIME=$(date +"%Y%m%d%H%M")" >>$GITHUB_ENV
