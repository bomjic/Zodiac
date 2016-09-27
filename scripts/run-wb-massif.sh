#! /bin/sh

configuration=$1

source ./support_script.sh

check

echo "Fsck swap..."
fsck.ext4 /dev/sda1
mount /dev/sda1 /mnt/hd
sleep 5
if [ -e /mnt/hd/swapfile ];.
 then
  echo "Add swap..."
  swapon /mnt/hd/swapfile
 else
  echo "Make swapfile..."
  dd if=/dev/zero of=/mnt/hd/swapfile bs=1M count=1024
  mkswap /mnt/hd/swapfile
  echo "Add new swap..."
  swapon /mnt/hd/swapfile
fi

rm -f /mnt/flash/dhcpc/*eth1*

export TZ=EST+5EDT,M3.2.0/2,M11.1.0/2

export SKIA_ENABLE_KEY_SERVER=1
export SKIA_DISABLE_KEYBOARD=1
export DVBS_LOGGER_UPLOAD_INTERFACE=ETH

LOCAL_NFS_ROOT_DIR=/mnt/flash/zodiac/build

CONFIGS_DIR=$LOCAL_NFS_ROOT_DIR/home/zodiac
NFS_LIBS_DIR=$LOCAL_NFS_ROOT_DIR/usr/lib
NFS_BINS_DIR=$LOCAL_NFS_ROOT_DIR/usr/bin

PATH_ZODIAC_HOME=$CONFIGS_DIR
PATH_ZODIAC_STORE=/mnt/flash/zodiac

export PATH_ZODIAC_STORE_CAS=$PATH_ZODIAC_STORE/cas
export PATH_ZODIAC_STORE_SWTV=$PATH_ZODIAC_STORE/swtv
export PATH_ZODIAC_STORE_SNMP=$PATH_ZODIAC_STORE/snmp

export DVBS_CONFIG_FILE=$PATH_ZODIAC_HOME/dvbs.yaml
export SWTV_CONFIG_FILE=$PATH_ZODIAC_HOME/swtv.yaml
export DSGCC_PROXY_CONFIG_FILE=$PATH_ZODIAC_HOME/DSG-CC_Proxy.yaml
export DVBS_IPC_CONFIG_FILE=$PATH_ZODIAC_HOME/ipc.yaml
export DVBS_NETWORK_CONFIG_FILE=$PATH_ZODIAC_HOME/network.yaml
export EAS_CONFIG_FILE=$PATH_ZODIAC_HOME/EAS.yaml
export CAROUSELS_CONFIG_FILE=$PATH_ZODIAC_HOME/carousels.yaml
export DVBS_NVM_CONFIG_FILE=$PATH_ZODIAC_STORE/dvbs_nvm.yaml
export SKIA_KEYBOARD_LOCATION=$PATH_ZODIAC_HOME/keyboard
export SNMPCONFPATH=$PATH_ZODIAC_HOME
export POWERUP_NVM_SETTINGS_DIRECTORY=$PATH_ZODIAC_STORE/settings
export dal_splash_image=$PATH_ZODIAC_HOME/boot/splash_screen.jpg
export DVBS_LOG_SETTINGS_NVM_PATH=$PATH_ZODIAC_STORE/logger.cfg
export DVBS_DUMP_DIRECTORY_PATH=$PATH_ZODIAC_STORE/dumps
export SUPERVISOR_TEMP_DIRECTORY_PATH=${PATH_ZODIAC_STORE}/temp
export msg_modules="nexus_stc_channel,nexus_demux,nexus_parser_band,nexus_pid_channel_scrambling,nexus_transport_module,pcrlib"
export DVBS_SUPERVISOR_DONT_HANDLE_SIGNALS=1
export DVBS_LOG_LEVEL=6
export hdmi_i2c_software_mode=n

export SNMPCONFPATH=${PATH_ZODIAC_HOME}
export PATH_ZODIAC_STORE_RUN=${PATH_ZODIAC_STORE}/bin
export SUPERVISOR_BOOTLOG_DIRECTORY_PATH=${PATH_ZODIAC_STORE}/boot
export X509_DOWNLOAD_CERT=/etc/ssl/certs/zodiacved.pem
export POWERUP_DEFAULT_NETWORK=RF
export CMD2K_DEBUG=1
export HISTORY_SHARED_BUFFER_NAME=/tmp/history_shared

if [ $configuration == "nfs" ]; 
  then
    export POWERUP_SETTINGS_FILE=$PATH_ZODIAC_HOME/settings.ini
    export DVBS_CONFIG_FILE=$PATH_ZODIAC_HOME/dvbs.yaml
    export DPI_CONTAINER_CONFIG_PATH=$PATH_ZODIAC_HOME/dvbs.yaml
    export POWERUP_PROFILE_INI=$PATH_ZODIAC_HOME/profile.ini
    export NCAS_HOST_APP_CONFIG_FILE=$PATH_ZODIAC_HOME/ncas_host_app.yaml
    export SUPERVISOR_CONFIG_FILE=$PATH_ZODIAC_HOME/supervisor.yaml
  else
    export SUPERVISOR_CONFIG_FILE=$PATH_ZODIAC_HOME/supervisor_$configuration.yaml
fi

echo "Making Directories"
mkdir -p $PATH_ZODIAC_STORE
mkdir -p $PATH_ZODIAC_STORE_CAS
mkdir -p $PATH_ZODIAC_STORE_SWTV
mkdir -p $PATH_ZODIAC_STORE_SNMP
mkdir -p $DVBS_DUMP_DIRECTORY_PATH
mkdir -p $SUPERVISOR_TEMP_DIRECTORY_PATH

if [ -h $LOCAL_NFS_ROOT_DIR ]; then
    rm $LOCAL_NFS_ROOT_DIR
fi
ln -fs `pwd`/../../ $LOCAL_NFS_ROOT_DIR

export DVBS_DISABLE_BREAKPAD=1
export CMD2K_DEBUG=1

export LD_LIBRARY_PATH=$NFS_LIBS_DIR:$LD_LIBRARY_PATH
export DAL_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
export SUPERVISOR_VERSION=`cat $CONFIGS_DIR/version.txt`

echo "Starting Supervisor version: $SUPERVISOR_VERSION"
stty eof undef

# Reload nexus.ko, just for sure...
if [ -f nexus.ko ]; then
 rmmod nexus
 insmod $NFS_BINS_DIR/nexus.ko
fi

# Just kill all udevd if exists.
killall -9 udevd
sleep 1

cd $LOCAL_NFS_ROOT_DIR/dbg
/bin/valgrind/bin/valgrind-di-server 1500 &

boxno=`ifconfig eth0 | grep inet | awk -F'192.168.1.' '{print $2}' | awk '{print $1}'`;
path="/bin/mbaikov/massif_reports";
workdir=$path/box$boxno;

rm -rf "$workdir";

mkdir -p $workdir;
if [ ! -d $workdir ]; then
    echo "Unable to create working directory";
    exit 1;
fi

/bin/mbaikov/scripts/dump_mem_snapshot/dump.sh 1800 &

if [ "$configuration" == "nfs" ]; 
  then
    # On non nfs configs udevd will be started by DALManager.
    if [ -x udevd ]; 
      then
        echo "Running udev daemon..."
        $NFS_BINS_DIR/udevd --daemon
        sleep 1
      else
        echo "udev daemon not found"
    fi
    cd $NFS_BINS_DIR
    /bin/valgrind/bin/valgrind -v --run-libc-freeres=no --debuginfo-server=127.0.0.1:1500 \
    --tool=massif --threshold=0.01 --peak-inaccuracy=0.1 --time-unit=ms --massif-out-file=$workdir/massif.snapshot_extremums.%p --depth=70 --detailed-freq=2 --vex-iropt-register-updates=allregs-at-mem-access \
    --trace-children=yes --trace-children-skip=/usr/bin/dsgcc,/usr/bin/oem_cdl,/usr/bin/dsgmanager,/bin/ps,/bin/sh,/bin/mkdir,/bin/mount,/usr/bin/hostdhcp,/sbin/udhcpc,/etc/udhcpc.script,/bin/cat,/bin/top,/sbin/ifconfig,/usr/bin/oem_snmp,$NFS_BINS_DIR/dsgcc,$NFS_BINS_DIR/dsgmanager,$NFS_BINS_DIR/oem_snmp,$NFS_BINS_DIR/oem_cdl,$NFS_BINS_DIR/ata_id,$NFS_BINS_DIR/dpi_host_app,$NFS_BINS_DIR/history,$NFS_BINS_DIR/sdvd,$NFS_BINS_DIR/ncas_host_app \
    --suppressions=/bin/valgrind/lib/valgrind/zodiac_mk.supp --suppressions=/bin/valgrind/lib/valgrind/default.supp \
    $NFS_BINS_DIR/supervisor $NFS_BINS_DIR/powerup-launcher
  else
    cd $PATH_ZODIAC_STORE
    /bin/valgrind/bin/valgrind -v --run-libc-freeres=no --debuginfo-server=127.0.0.1:1500 \
    --tool=massif --threshold=0.01 --peak-inaccuracy=0.1 --time-unit=ms --massif-out-file=$workdir/massif.snapshot_extremums.%p --depth=70 --detailed-freq=2 --vex-iropt-register-updates=allregs-at-mem-access \
    --trace-children=yes --trace-children-skip=/usr/bin/dsgcc,/usr/bin/oem_cdl,/usr/bin/dsgmanager,/bin/ps,/bin/sh,/bin/mkdir,/bin/mount,/usr/bin/hostdhcp,/sbin/udhcpc,/etc/udhcpc.script,/bin/cat,/bin/top,/sbin/ifconfig,/usr/bin/oem_snmp,$NFS_BINS_DIR/dsgcc,$NFS_BINS_DIR/dsgmanager,$NFS_BINS_DIR/oem_snmp,$NFS_BINS_DIR/oem_cdl,$NFS_BINS_DIR/ata_id,$NFS_BINS_DIR/dpi_host_app,$NFS_BINS_DIR/history,$NFS_BINS_DIR/sdvd,$NFS_BINS_DIR/ncas_host_app,udevd,sdvd,ncas_host_app \
    --suppressions=/bin/valgrind/lib/valgrind/zodiac_mk.supp --suppressions=/bin/valgrind/lib/valgrind/default.supp \
    $NFS_BINS_DIR/supervisor
fi

EXIT_CODE=$?
EXIT_TIME=`date`

echo "Supervisor has crashed at $EXIT_TIME, exit code $EXIT_CODE"

