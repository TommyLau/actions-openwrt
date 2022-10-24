#!/bin/bash

# Download OpenWrt SDK
curl -SL "$SDK_URL" -o sdk.tar.xz
mkdir sdk
tar Jxvf sdk.tar.xz -C sdk --strip-components=1
mkdir -p sdk/staging_dir/host/bin
ln -sf /usr/bin/upx sdk/staging_dir/host/bin/upx

# Update seed config
[ -e $CONFIG_FILE ] && cp $CONFIG_FILE sdk/.config

# Switch to SDK directory
cd sdk

# Update feeds
./scripts/feeds update -a

# ------------------------------------------------------------
# Patches
# ------------------------------------------------------------
# Fullcone NAT support for nftables
git clone https://github.com/TommyLau/nft-fullcone.git package/nft-fullcone
mv feeds/base/package/libs/libnftnl package
mv feeds/base/package/network/utils/nftables package
mv feeds/base/package/network/config/firewall4 package
rsync -a ../patches/libnftnl-1.2.1/001-add-fullcone-expression-support.patch package/libnftnl/patches/
rsync -a ../patches/nftables-1.0.2/002-add-fullcone-expression-support.patch package/nftables/patches/
rsync -a ../patches/firewall4/001-firewall4-2022-10-14-add-fullcone-support.patch package/firewall4/patches/

# Use higher version, so that image builder won't download from Internet instead of using local packages
sed -i 's/$(AUTORELEASE)/99/' package/libnftnl/Makefile
sed -i 's/PKG_RELEASE:=2.1/PKG_RELEASE:=99/' package/nftables/Makefile
sed -i 's/2022-10-14/2099-12-31/' package/firewall4/Makefile

# Reindex feeds for pathces
./scripts/feeds update -i

# Install custom packages and dependencies
./scripts/feeds install kmod-nft-fullcone
./scripts/feeds install libnftnl libmnl
./scripts/feeds install nftables jansson
./scripts/feeds install firewall4

# Build custom packages
make defconfig
make -j$(nproc) || make -j1 V=s || make -j1 V=sc
echo "BUILD_TIME=$(date +"%Y%m%d%H%M")" >> $GITHUB_ENV
