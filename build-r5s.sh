#!/usr/bin/bash
git pull
if [ $? != 0 ];then
        echo 'pull fail'
        exit 1
fi

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
