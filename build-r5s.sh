#!/usr/bin/bash
git pull
if [ $? != 0 ];then
        echo 'pull fail'
        exit 1
fi

#replace mac80211
rm -rf package/kernel/mac80211 
rm -rf package/kernel/rtl8821cu
rm -rf package/kernel/mt76
rm -rf package/network/services/hostapd

svn export https://github.com/openwrt/openwrt/trunk/package/kernel/mac80211 package/kernel/mac80211
svn export https://github.com/openwrt/openwrt/trunk/package/kernel/mt76 package/kernel/mt76
svn export https://github.com/openwrt/openwrt/trunk/package/network/services/hostapd package/network/services/hostapd

./scripts/feeds update -a
# ./scripts/feeds update luci
# ./scripts/feeds update packages
# ./scripts/feeds update routing
# ./scripts/feeds update telephony
./scripts/feeds install -a

if [ ! -d "package/ddns-go" ]; then
git clone https://github.com/sirpdboy/luci-app-ddns-go.git package/ddns-go
else
pushd package/ddns-go
git pull
popd
fi


make defconfig


sed -i "s/CONFIG_DEFAULT_TARGET_OPTIMIZATION=\"-Os -pipe -mcpu=generic\"/CONFIG_DEFAULT_TARGET_OPTIMIZATION=\"-O3 -pipe -mtune=cortex-a55\"/" .config
sed -i "s/CONFIG_TARGET_OPTIMIZATION=\"-Os -pipe -mcpu=generic\"/CONFIG_TARGET_OPTIMIZATION=\"-O3 -pipe -mtune=cortex-a55\"/" .config
sed -i 's/CONFIG_CPU_TYPE="generic"/CONFIG_CPU_TYPE="cortex-a55"/' .config
sed -i 's/192.168.1./192.168.125./' .config
sed -i 's/192.168.125.1/192.168.125.10/' .config
c=$(grep -c default_qdisc package/feeds/luci/luci-app-turboacc/root/etc/init.d/turboacc)
if [ $c = 0 ]; then
patch -p1 < turboacc.patch
fi
if [ $? = 0 ]; then
nohup make download -j8 >> makelog.txt 2>&1 &&  make V=s -j1 >> makelog.txt 2>&1 &
fi
