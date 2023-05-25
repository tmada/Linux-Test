#!/usr/bin/env bash

os_setup() {
    local OSTYPE="$( uname -s )"

    case "$OSTYPE" in
        "Darwin"*)
            which fio >/dev/null || brew install fio || exit 1
            CPUS=$(sysctl -n hw.ncpu)
            : "posixaio"
            ;;
        "Linux"*)
            CPUS=$( getconf _NPROCESSORS_ONLN )
            : "libaio"
            ;;
        *)
            echo "$OSTYPE not supported"
            exit 1
            ;;
    esac

    AIO_ENGINE="$_"
    # fio --enghelp | grep "aio" | head -n 1 | sed 's/ //g;s/\t//g;'
}
os_setup

# Fucking apple and not accepting GNU... associative arrays would have been nicer...
declare -a FIO_TESTS
# FIO_SYNC_BASE="fio --size=10G --ioengine=sync --fsync=1024 --ramp_time=2s --verify=0 --bs=4k --iodepth=32 --iodepth_batch_submit=64 --iodepth_batch_complete_max=64 --group_reporting --time_based --runtime=30"
# FIO_TESTS[1]="${FIO_SYNC_BASE} --name=fio_read_seq --rw=read"
# FIO_TESTS[2]="${FIO_SYNC_BASE} --name=fio_read_seqrand --rw=randread"
# FIO_TESTS[3]="${FIO_SYNC_BASE} --name=fio_write_seq --rw=write"
# FIO_TESTS[4]="${FIO_SYNC_BASE} --name=fio_write_seqrand --rw=randwrite"
if [[ $AIO_ENGINE =~ "aio" ]]; then
    FIO_AIO_BASE="fio --direct=1 --ioengine=${AIO_ENGINE} --size=10G --ramp_time=2s --verify=0 --bs=4k --iodepth=32 --iodepth_batch_submit=64 --iodepth_batch_complete_max=64 --group_reporting --time_based --runtime=30"
    FIO_TESTS[5]="${FIO_AIO_BASE} --name=fio_aio_read_seq --rw=read"
    FIO_TESTS[6]="${FIO_AIO_BASE} --name=fio_aio__read_seqrand --rw=randread"
    FIO_TESTS[7]="${FIO_AIO_BASE} --name=fio_aio__write_seq --rw=write"
    FIO_TESTS[8]="${FIO_AIO_BASE} --name=fio_aio__write_seqrand --rw=randwrite"
fi

# Loop FIO_TESTS
for test in "${FIO_TESTS[@]}"; do
    # let i=numjobs which is essentially iodepth, where iodepth is not avail in sync mode
    for i in {1..2}; do
        #printf "Running: \n%s --numjobs=%s\n\n" "$test" "$i"
        jobname=$(echo $test | sed 's/.* --name=\(.*\) --rw=.*/\1/')
        result=$( $test "--numjobs=${i} --output=" | grep iops | cut -d : -f 2 )
        echo "test=${jobname}, jobs=${i}, $result, $test"

        # cleanup
        rm "${jobname}"*
    done
done

exit 0