#!/bin/mbaikov/bin/bash

boxno=`ifconfig eth0 | grep inet | awk -F'192.168.1.' '{print $2}' | awk '{print $1}'`;
path="/mnt/nfs/mbaikov/massif_reports";
vgdb="/mnt/nfs/mbaikov/valgrind/bin/vgdb"

frequency=$1;
workdir=$path/box$boxno;

if [ -z $1 ]; then
    echo "Frequency time is not set";
    echo "Usage: dump.sh <freqency in seconds>";
    exit 1;
fi

mkdir -p $workdir;
if [ ! -d $workdir ]; then
    echo "Unable to create working directory";
    exit 1;
fi

# TODO On script restart we need to find old counters

while true; do
    sleep $frequency;

    if [ -n $($vgdb -l) ] 2>/dev/null; then
        echo "no valgrind processes left. exiting";
        exit 0;
    fi

    for pid in `$vgdb -l | awk -F"--pid=" '{print $2}' | awk '{print $1}'`; do
        report=$workdir/massif.once_a_halfanhour.$pid;

        if [ ! -e $report -o ! -s $report ]; then
            counter[pid]=0;
            touch $report;
            chmod 666 $report;
        fi
        $vgdb --pid=$pid -c "detailed_snapshot $report.tmp"
        if [ ${counter[pid]} -eq 0 ]; then
            head -n 3 $report.tmp > $report;
        fi

        sed -i '1,3d' $report.tmp;
        sed -i "/snapshot=/c\snapshot=${counter[pid]}" $report.tmp;
        cat $report.tmp >> $report;
        rm $report.tmp;
        counter[pid]=$((${counter[pid]}+1));
    done

done