#!/bin/sh
# Halium bring-up: log memory/slab growth to /userdata/live/mem.txt every 3 s
D=/userdata/live
mkdir -p $D
[ -f $D/mem.txt ] && mv -f $D/mem.txt $D/mem.prev.txt
echo -1000 > /proc/self/oom_score_adj 2>/dev/null
while true; do
  {
    echo "== up $(cut -d' ' -f1 /proc/uptime)"
    grep -E "MemFree|MemAvailable|^Slab|SUnreclaim|KernelStack|PageTables|VmallocUsed|Shmem:" /proc/meminfo | tr '\n' ' '; echo
    if [ -r /proc/slabinfo ]; then
      sort -k3 -n -r /proc/slabinfo 2>/dev/null | awk 'NR<=8{printf "%s:%s*%s ", $1,$3,$4}'; echo
    fi
    for d in /sys/kernel/slab/*/; do
      s=$(cut -d' ' -f1 $d/slabs 2>/dev/null); o=$(cat $d/order 2>/dev/null)
      [ -n "$s" ] && [ -n "$o" ] && echo "$((s*(1<<o))) $(basename $d)"
    done | sort -rn | head -6 | tr '\n' ' '; echo
    echo "alloc_calls kmalloc-2048:"; head -8 /sys/kernel/slab/kmalloc-2048/alloc_calls 2>&1 | cut -c1-200
    ps -eo pid,rss,comm --sort=-rss | head -4 | tr '\n' '|'; echo
  } >> $D/mem.txt 2>&1
  sync -f $D
  sleep 3
done
