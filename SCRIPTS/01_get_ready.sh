#!/bin/bash
#Master+jayanta525
notExce(){
git clone -b master https://git.openwrt.org/openwrt/openwrt.git openwrt
cd openwrt
patch -p1 < ../PATCH/jayanta525/001-rockchip-add-support-for-rk3328-radxa-rock-pi-e.patch
patch -p1 < ../PATCH/jayanta525/002-rockchip-add-support-for-FriendlyARM-NanoPi-R2S.patch
cd ..
}
#等待上游修复后使用
git clone -b nanopi-r2s https://github.com/blocktrron/openwrt openwrt
cd openwrt
git config --local user.email "action@github.com" && git config --local user.name "GitHub Action"
git remote add upstream https://github.com/openwrt/openwrt.git && git fetch upstream
git rebase upstream/master
cd ..
git clone -b dev-19.07 --single-branch https://github.com/Lienol/openwrt openwrt-lienol
exit 0
