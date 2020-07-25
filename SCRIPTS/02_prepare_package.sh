#!/bin/bash
clear
##准备工作
#使用19.07的feed源
rm -f ./feeds.conf.default
wget https://raw.githubusercontent.com/openwrt/openwrt/openwrt-19.07/feeds.conf.default
wget -P include/ https://raw.githubusercontent.com/openwrt/openwrt/openwrt-19.07/include/scons.mk
#remove annoying snapshot tag
sed -i 's,SNAPSHOT,,g' include/version.mk
sed -i 's,snapshots,,g' package/base-files/image-config.in
#使用O3级别的优化
sed -i 's/Os/O3/g' include/target.mk
sed -i 's/O2/O3/g' ./rules.mk

#更新feed
./scripts/feeds update -a && ./scripts/feeds install -a

# use master branch version miniupnpd
rm -rf ./feeds/packages/net/miniupnpd
svn co https://github.com/openwrt/packages/trunk/net/miniupnpd feeds/packages/net/miniupnpd
svn co https://github.com/openwrt/packages/trunk/libs/libcap-ng feeds/packages/libs/libcap-ng
cp ../PATCH/400-ipv6-disable.patch feeds/packages/net/miniupnpd/patches/
# tar zxf ../miniupnpd.tar.gz -C ./feeds/packages/net/
# patch mwan3
cp ../PATCH/mwan3-add-workaround-for-procd-change.patch feeds/packages/
pushd feeds/packages
git apply mwan3-add-workaround-for-procd-change.patch
popd

./scripts/feeds update -a && ./scripts/feeds install -a

#irqbalance
sed -i 's/0/1/g' feeds/packages/utils/irqbalance/files/irqbalance.config

##必要的patch
#等待上游修复后使用
#patch i2c0
cp -f ../PATCH/998-rockchip-enable-i2c0-on-NanoPi-R2S.patch ./target/linux/rockchip/patches-5.4/998-rockchip-enable-i2c0-on-NanoPi-R2S.patch
#patch r8152 led
cp -f ../PATCH/991-r8152-Add-module-param-for-customized-LEDs.patch ./target/linux/rockchip/patches-5.4/991-r8152-Add-module-param-for-customized-LEDs.patch
#some rework
cp -f ../PATCH/rework/005-rockchip-rk3328-add-idle-state.patch ./target/linux/rockchip/patches-5.4/005-rockchip-rk3328-add-idle-state.patch
cp -f ../PATCH/rework/102-rockchip-add-usb3-controller-driver-for-RK3328-SoCs.patch ./target/linux/rockchip/patches-5.4/102-rockchip-add-usb3-controller-driver-for-RK3328-SoCs.patch
cp -f ../PATCH/rework/103-rockchip-add-hwmon-support-for-SoCs-and-GPUs.patch ./target/linux/rockchip/patches-5.4/103-rockchip-add-hwmon-support-for-SoCs-and-GPUs.patch
#patch rk-crypto
patch -p1 < ../PATCH/kernel_crypto-add-rk3328-crypto-support.patch
#patch rk3328_config
patch -p1 < ../PATCH/0001-target-linux-improve-friendlyarm-nanopi-r2s-support.patch
#patch jsonc
patch -p1 < ../PATCH/use_json_object_new_int64.patch
#patch dnsmasq
patch -p1 < ../PATCH/dnsmasq-add-filter-aaaa-option.patch
patch -p1 < ../PATCH/luci-add-filter-aaaa-option.patch
cp -f ../PATCH/900-add-filter-aaaa-option.patch ./package/network/services/dnsmasq/patches/900-add-filter-aaaa-option.patch
rm -rf ./package/base-files/files/etc/init.d/boot
wget -P package/base-files/files/etc/init.d https://raw.githubusercontent.com/project-openwrt/openwrt/18.06-kernel5.4/package/base-files/files/etc/init.d/boot
#Patch FireWall 以增添fullcone功能 
mkdir package/network/config/firewall/patches
wget -P package/network/config/firewall/patches/ https://github.com/LGA1150/fullconenat-fw3-patch/raw/master/fullconenat.patch
# Patch LuCI 以增添fullcone开关
pushd feeds/luci
wget -O- https://github.com/LGA1150/fullconenat-fw3-patch/raw/master/luci.patch | git apply
popd
# Patch Kernel 以解决fullcone冲突
pushd target/linux/generic/hack-5.4
#wget https://raw.githubusercontent.com/project-openwrt/openwrt/18.06-kernel5.4/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
wget https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/hack-5.4/952-net-conntrack-events-support-multiple-registrant.patch
popd
#Patch FireWall 以增添SFE
patch -p1 < ../PATCH/luci-app-firewall_add_sfe_switch.patch
# SFE内核补丁
pushd target/linux/generic/hack-5.4
#wget https://raw.githubusercontent.com/MeIsReallyBa/Openwrt-sfe-flowoffload-linux-5.4/master/999-shortcut-fe-support.patch
#wget https://raw.githubusercontent.com/project-openwrt/openwrt/18.06-kernel5.4/target/linux/generic/hack-5.4/953-net-patch-linux-kernel-to-support-shortcut-fe.patch
wget https://raw.githubusercontent.com/coolsnowwolf/lede/master/target/linux/generic/hack-5.4/999-shortcut-fe-support.patch
popd
#OC
#cp -f ../PATCH/999-unlock-1608mhz-rk3328.patch ./target/linux/rockchip/patches-5.4/999-unlock-1608mhz-rk3328.patch

##获取额外package
#更换Node版本
rm -rf ./feeds/packages/lang/node
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node feeds/packages/lang/node
rm -rf ./feeds/packages/lang/node-arduino-firmata
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-arduino-firmata feeds/packages/lang/node-arduino-firmata
rm -rf ./feeds/packages/lang/node-cylon
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-cylon feeds/packages/lang/node-cylon
rm -rf ./feeds/packages/lang/node-hid
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-hid feeds/packages/lang/node-hid
rm -rf ./feeds/packages/lang/node-homebridge
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-homebridge feeds/packages/lang/node-homebridge
rm -rf ./feeds/packages/lang/node-serialport
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-serialport feeds/packages/lang/node-serialport
rm -rf ./feeds/packages/lang/node-serialport-bindings
svn co https://github.com/nxhack/openwrt-node-packages/trunk/node-serialport-bindings feeds/packages/lang/node-serialport-bindings
#更换GCC版本
rm -rf ./feeds/packages/devel/gcc
svn co https://github.com/openwrt/packages/trunk/devel/gcc feeds/packages/devel/gcc
#更换Golang版本
rm -rf ./feeds/packages/lang/golang
svn co https://github.com/openwrt/packages/trunk/lang/golang feeds/packages/lang/golang
#beardropper
git clone https://github.com/NateLol/luci-app-beardropper package/luci-app-beardropper
sed -i 's/"luci.fs"/"luci.sys".net/g' package/luci-app-beardropper/luasrc/model/cbi/beardropper/setting.lua
sed -i '/firewall/d' package/luci-app-beardropper/root/etc/uci-defaults/luci-beardropper
#luci-app-freq
#svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/luci-app-cpufreq package/lean/luci-app-cpufreq
#patch -p1 < ../PATCH/luci-app-freq.patch
#京东签到
git clone https://github.com/jerrykuku/node-request package/new/node-request
git clone https://github.com/jerrykuku/luci-app-jd-dailybonus package/new/luci-app-jd-dailybonus
#arpbind
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-arpbind package/lean/luci-app-arpbind
#Adbyby
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-adbyby-plus package/lean/luci-app-adbyby-plus
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/adbyby package/lean/coremark/adbyby
#访问控制
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-accesscontrol package/lean/luci-app-accesscontrol
#AutoCore
svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/autocore package/lean/autocore
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/coremark package/lean/coremark
sed -i 's,-DMULTIT,-Ofast -DMULTIT,g' package/lean/coremark/Makefile
#迅雷快鸟
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-xlnetacc package/lean/luci-app-xlnetacc
#DDNS
rm -rf ./feeds/packages/net/ddns-scripts
rm -rf ./feeds/luci/applications/luci-app-ddns
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_aliyun package/lean/ddns-scripts_aliyun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ddns-scripts_dnspod package/lean/ddns-scripts_dnspod
svn co https://github.com/openwrt/packages/branches/openwrt-18.06/net/ddns-scripts feeds/packages/net/ddns-scripts
svn co https://github.com/openwrt/luci/branches/openwrt-18.06/applications/luci-app-ddns feeds/luci/applications/luci-app-ddns
#Pandownload
svn co https://github.com/project-openwrt/openwrt/branches/master/package/lean/pandownload-fake-server package/lean/pandownload-fake-server
#oled
git clone -b master --single-branch https://github.com/NateLol/luci-app-oled package/new/luci-app-oled
#网易云解锁
git clone -b master --single-branch https://github.com/project-openwrt/luci-app-unblockneteasemusic package/new/UnblockNeteaseMusic
#定时重启
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-autoreboot package/lean/luci-app-autoreboot
#argon主题
git clone -b master --single-branch https://github.com/jerrykuku/luci-theme-argon package/new/luci-theme-argon
#edge主题
git clone -b master --single-branch https://github.com/garypang13/luci-theme-edge package/new/luci-theme-edge
#AdGuard
cp -rf ../openwrt-lienol/package/diy/luci-app-adguardhome ./package/new/luci-app-adguardhome
#cp -rf ../openwrt-lienol/package/diy/adguardhome ./package/new/AdGuardHome
#git clone -b master --single-branch https://github.com/rufengsuixing/luci-app-adguardhome package/new/luci-app-adguardhome
svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ntlf9t/AdGuardHome package/new/AdGuardHome
#ChinaDNS
git clone -b luci --single-branch https://github.com/pexcn/openwrt-chinadns-ng package/new/luci-chinadns-ng
git clone -b master --single-branch https://github.com/pexcn/openwrt-chinadns-ng package/new/chinadns-ng
#SSRP
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus package/lean/luci-app-ssr-plus
rm -rf ./package/lean/luci-app-ssr-plus/luasrc/view/shadowsocksr/ssrurl.htm
wget -P package/lean/luci-app-ssr-plus/luasrc/view/shadowsocksr https://raw.githubusercontent.com/QiuSimons/Others/master/luci-app-ssr-plus/luasrc/view/shadowsocksr/ssrurl.htm
#turn off network sniffing
sed -i "s/enabled = true/enabled = false/g" package/lean/luci-app-ssr-plus/root/usr/share/shadowsocksr/genv2config.lua
#rm -rf ./package/lean/luci-app-ssr-plus/root/etc/init.d/shadowsocksr
#wget -P package/lean/luci-app-ssr-plus/root/etc/init.d https://raw.githubusercontent.com/QiuSimons/Others/master/luci-app-ssr-plus-177-1/root/etc/init.d/shadowsocksr
#SSRP依赖
rm -rf ./feeds/packages/net/kcptun
rm -rf ./feeds/packages/net/shadowsocks-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shadowsocksr-libev package/lean/shadowsocksr-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/pdnsd-alt package/lean/pdnsd
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/v2ray package/lean/v2ray
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/kcptun package/lean/kcptun
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/v2ray-plugin package/lean/v2ray-plugin
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/srelay package/lean/srelay
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/microsocks package/lean/microsocks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/dns2socks package/lean/dns2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/redsocks2 package/lean/redsocks2
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/proxychains-ng package/lean/proxychains-ng
#git clone -b master --single-branch https://github.com/pexcn/openwrt-ipt2socks package/lean/ipt2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipt2socks package/lean/ipt2socks
#git clone -b master --single-branch https://github.com/aa65535/openwrt-simple-obfs package/lean/simple-obfs
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/simple-obfs package/lean/simple-obfs
svn co https://github.com/coolsnowwolf/packages/trunk/net/shadowsocks-libev package/lean/shadowsocks-libev
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/trojan package/lean/trojan
svn co https://github.com/project-openwrt/openwrt/trunk/package/lean/tcpping package/lean/tcpping
#PASSWALL
svn co https://github.com/Lienol/openwrt-package/trunk/lienol/luci-app-passwall package/new/luci-app-passwall
cp -f ../PATCH/move_passwall_2_services.sh ./package/new/luci-app-passwall/move_passwall_2_services.sh
pushd package/new/luci-app-passwall
bash move_passwall_2_services.sh
popd
svn co https://github.com/Lienol/openwrt-package/trunk/package/tcping package/new/tcping
svn co https://github.com/Lienol/openwrt-package/trunk/package/trojan-go package/new/trojan-go
svn co https://github.com/Lienol/openwrt-package/trunk/package/brook package/new/brook
svn co https://github.com/Lienol/openwrt-package/trunk/package/trojan package/new/trojan
#订阅转换
# svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/subconverter package/new/subconverter
# svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/jpcre2 package/new/jpcre2
# svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/rapidjson package/new/rapidjson
# svn co https://github.com/project-openwrt/openwrt/branches/openwrt-19.07/package/ctcgfw/duktape package/new/duktape
#清理内存
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ramfree package/lean/luci-app-ramfree
#打印机
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-usb-printer package/lean/luci-app-usb-printer
#流量监视
git clone -b master --single-branch https://github.com/brvphoenix/wrtbwmon package/new/wrtbwmon
git clone -b master --single-branch https://github.com/brvphoenix/luci-app-wrtbwmon package/new/luci-app-wrtbwmon
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-wrtbwmon package/lean/luci-app-wrtbwmon
#流量监管
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-netdata package/lean/luci-app-netdata
#OpenClash
# svn co https://github.com/vernesong/OpenClash/branches/master/luci-app-openclash package/new/luci-app-openclash
#SeverChan
git clone -b master --single-branch https://github.com/tty228/luci-app-serverchan package/new/luci-app-serverchan
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/network/utils/iputils package/network/utils/iputils
#SmartDNS
svn co https://github.com/pymumu/smartdns/trunk/package/openwrt package/new/smartdns
git clone -b lede --single-branch https://github.com/pymumu/luci-app-smartdns package/new/luci-app-smartdns/
#上网APP过滤
git clone -b master --single-branch https://github.com/destan19/OpenAppFilter package/new/OpenAppFilter
#nps
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/npc package/npc
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-nps package/luci-app-nps
#mwan3 helper
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-mwan3helper package/lean/luci-app-mwan3helper
#Docker
svn co https://github.com/lisaac/luci-app-dockerman/trunk/applications/luci-app-dockerman package/luci-app-dockerman
svn co https://github.com/lisaac/luci-lib-docker/trunk/collections/luci-lib-docker package/luci-lib-docker
svn co https://github.com/openwrt/packages/trunk/utils/docker-ce package/utils/docker-ce
svn co https://github.com/openwrt/packages/trunk/utils/cgroupfs-mount package/utils/cgroupfs-mount
svn co https://github.com/openwrt/packages/trunk/utils/containerd package/utils/containerd
svn co https://github.com/openwrt/packages/trunk/utils/libnetwork package/utils/libnetwork
svn co https://github.com/openwrt/packages/trunk/utils/tini package/utils/tini
svn co https://github.com/openwrt/packages/trunk/utils/runc package/utils/runc
rm -rf ./package/lang/golang
svn co https://github.com/openwrt/packages/trunk/lang/golang package/lang/golang
#补全部分依赖（实际上并不会用到
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/utils/fuse package/utils/fuse
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/network/services/samba36 package/network/services/samba36
svn co https://github.com/openwrt/openwrt/branches/openwrt-19.07/package/libs/libconfig package/libs/libconfig
rm -rf ./feeds/packages/utils/collectd
svn co https://github.com/openwrt/packages/trunk/utils/collectd feeds/packages/utils/collectd
#FullCone模块
git clone -b master --single-branch https://github.com/QiuSimons/openwrt-fullconenat package/fullconenat
#翻译及部分功能优化
git clone -b master --single-branch https://github.com/QiuSimons/addition-trans-zh package/lean/lean-translate
#SFE
#svn co https://github.com/MeIsReallyBa/Openwrt-sfe-flowoffload-linux-5.4/trunk/shortcut-fe package/new/shortcut-fe
#svn co https://github.com/project-openwrt/openwrt/branches/18.06-kernel5.4/package/lean/shortcut-fe package/new/shortcut-fe
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shortcut-fe package/new/shortcut-fe
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/fast-classifier package/new/fast-classifier
#cp -f ../PATCH/shortcut-fe package/base-files/files/etc/init.d/shortcut-fe
#IPSEC
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-ipsec-vpnd package/lean/luci-app-ipsec-vpnd
#回滚zstd
rm -rf ./feeds/packages/utils/zstd
svn co https://github.com/QiuSimons/Others/trunk/zstd feeds/packages/utils/zstd
#frp
rm -f ./feeds/luci/applications/luci-app-frps
rm -f ./feeds/luci/applications/luci-app-frpc
rm -rf ./feeds/packages/net/frp
rm -f ./package/feeds/packages/frp
git clone https://github.com/lwz322/luci-app-frps.git package/lean/luci-app-frps
git clone https://github.com/kuoruan/luci-app-frpc.git package/lean/luci-app-frpc
#svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/frp packages/lean/frp
svn co https://github.com/openwrt/packages/trunk/net/frp package/feeds/packages/frp

##最后的收尾工作
#Lets Fuck
mkdir package/base-files/files/usr/bin
cp -f ../PATCH/fuck package/base-files/files/usr/bin/fuck
cp -f ../PATCH/chinadnslist package/base-files/files/usr/bin/chinadnslist
#最大连接
sed -i 's/16384/65536/g' package/kernel/linux/files/sysctl-nf-conntrack.conf
#修正架构
#sed -i "s,boardinfo.system,'ARMv8',g" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
#adjust_network
cp -f ../PATCH/adjust_network package/base-files/files/etc/init.d/zzz_adjust_network
#i2c_oled
#cp -f ../I2C/i2c_ssd package/base-files/files/usr/bin/i2c_ssd
#cp -f ../I2C/OLED_R2S package/base-files/files/etc/init.d/OLED_R2S
#modify gateway address
sed -i 's/192.168.1.1/192.168.88.1/g' package/base-files/files/bin/config_generate
#删除已有配置
rm -rf .config
#授予权限
chmod -R 755 ./

exit 0
