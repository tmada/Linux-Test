#!/usr/bin/env bash
# fail if any commands fails
set -e
# make pipelines' return status equal the last command to exit with a non-zero status, or zero if all commands exit successfully
set -o pipefail
# debug log
# set -x
OS=$( uname -s )
[ "$OS" == "Darwin" ] && brew install sysbench >/dev/null || { wget -qO - https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash ; sudo apt-get -y install sysbench >/dev/null ; } 
[ "$OS" == "Darwin" ] && CPUS=$(sysctl -n hw.ncpu) || CPUS=$( getconf _NPROCESSORS_ONLN )
MAX_PRIME=20000
echo "Found ${CPUS} CPUS"
echo "==CPUBenchmark_SingleCore"

sysbench cpu run --cpu-max-prime=20000 --time=20 |grep "events per second:"
echo "==CPUBenchmark_MultiCore($CPUS)"
sysbench cpu run --threads=$CPUS --cpu-max-prime=20000 --time=20 |grep "events per second:"
# if [[ "$(sysctl -n machdep.cpu.brand_string)" =~ "Apple M1 Max" ]]; then
#   echo "==CPUBenchmark_MultiCore(8)"
#   [ $CPUS -eq 10 ] &&  sysbench cpu run --threads=8 --cpu-max-prime=20000 --time=20 |grep "events per second:" || echo " events per second: 0"
#   echo "==CPUBenchmark_MultiCore(4)"
#   sysbench cpu run --threads=4 --cpu-max-prime=20000 --time=20 |grep "events per second:"
# fi

echo "==MemBenchmark_SingleCore"
sysbench memory run --threads=1 | grep "MiB transferred"
echo "==MemBenchmark_MultiCore($CPUS)"
sysbench memory run --threads=$CPUS | grep "MiB transferred"
# if [[ "$(sysctl -n machdep.cpu.brand_string )" =~ "Apple M1 Max" ]]; then
#   echo "==MemBenchmark_MultiCore(8)"
#   [ $CPUS -eq 10 ] && sysbench memory run --threads=8 | grep "MiB transferred" || echo "0.0 MiB transferred (0.0 MiB/sec)"
#   echo "==MemBenchmark_MultiCore(4)"
#   sysbench memory run --threads=4 | grep "MiB transferred"
# fi
echo "==FileIOBenchmark_SingleCoreCacheDriven"
sysbench fileio prepare >/dev/null
sysbench fileio run --threads=1 --file-test-mode=seqrewr | grep "written, MiB/s:"  # --max-time=300 --file-num=2 --file-total-size=128G
sysbench fileio cleanup >/dev/null

echo "==FileIOBenchmark_MultiCoreCacheDriven($CPUS)"
#sysbench fileio prepare --file-total-size=128G --file-num=2 >/dev/null
sysbench fileio prepare >/dev/null
sysbench fileio run --threads=$CPUS --file-test-mode=seqrewr | grep "written, MiB/s:"  # --max-time=300 --file-num=2 --file-total-size=128G
# sysbench fileio cleanup >/dev/null
# sysbench fileio prepare >/dev/null
# if [[ "$(sysctl -n machdep.cpu.brand_string)" =~ "Apple M1 Max" ]]; then
#   echo "==FileIOBenchmark_MultiCoreCacheDriven(8)"
#   [ $CPUS -eq 10 ] && sysbench fileio run --threads=8 --file-test-mode=seqrewr | grep "written, MiB/s:" || echo "written, MiB/s:               0.0"
#   sysbench fileio cleanup >/dev/null
#   sysbench fileio prepare >/dev/null
#   echo "==FileIOBenchmark_MultiCoreCacheDriven(4)"
#   sysbench fileio run --threads=4 --file-test-mode=seqrewr | grep "written, MiB/s:"
# fi
