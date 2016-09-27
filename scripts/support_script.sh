#! /bin/sh

rm -R /mnt/flash/zodiac/
mkdir /mnt/flash/zodiac/



# Support functions
supported_configs="nfs http oob nfs_dal no_bootm"

help()
{
        echo "${0##*/}: run NFS build in different configuration."
        echo ""
        echo "Usage: $0 <configuration>"
        echo ""
        echo "Where configuration has following format <dalmanager_load_location>_<powerup_load_location>"
        echo "List of supported configurations"
        echo " - nfs     - start powerup-launcher from NFS without DALManager (~ run-powerup.sh)"
        echo " - http    - start build from DAL (~ run-supervisor.sh)"
        echo " - oob     - start build from DAL"
        echo " - nfs_dal - start powerup-launcher from NFS with DALManager"
        echo ""
        echo "Exit status is set to non zero if any errors occur."
        echo ""
        echo "Example:"
        echo " $ ${0##*/} nfs_dal"
        exit 0
}

check_arch()
{
arch=`uname -m`

for i in i686 x86_64 ; do
   if [ $arch == $i ]; then
      echo "arch $arch is not premitted"
      exit 1
   fi
done
}

check()
{
check_arch

if [ -z "$configuration" -o -z "`echo $supported_configs | grep $configuration -`" ]; then
   help
fi
}
