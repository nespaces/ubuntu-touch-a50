#!/bin/sh
# Halium bring-up: log memory/slab growth to /userdata/live/mem.txt every 3 s
D=/userdata/live
mkdir -p $D
[ -f $D/mem.txt ] && mv -f $D/mem.txt $D/mem.prev.txt
echo -1000 > /proc/self/oom_score_adj 2>/dev/null
mount -t debugfs none /sys/kernel/debug 2>/dev/null
T=/sys/kernel/debug/tracing
arm_trace() {
  # Android init (in the container) switches tracing off around 9-10 s: re-assert every cycle
  [ -d $T ] || return
  for e in kmalloc kmalloc_node; do
    echo 'bytes_req > 1024 && bytes_req <= 2048' > $T/events/kmem/$e/filter
    echo 1 > $T/events/kmem/$e/enable
  done
  echo stacktrace > $T/trace_options
  echo 1 > $T/tracing_on
}
[ -d $T ] && { echo 3072 > $T/buffer_size_kb; : > $T/trace; }
arm_trace
SAVED=0
while true; do
  [ $SAVED = 0 ] && arm_trace
  if [ $SAVED = 0 ] && [ -d $T ] && [ $(cut -d. -f1 /proc/uptime) -ge 24 ]; then
    echo 0 > $T/tracing_on; cp $T/trace $D/trace-kmalloc2048.txt; sync -f $D; SAVED=1
  fi
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
    echo "alloc_calls kmalloc-2048:"; sort -rn /sys/kernel/slab/kmalloc-2048/alloc_calls 2>&1 | head -6 | cut -c1-170; grep -E '^kmalloc-2048 ' /proc/slabinfo
    ps -eo pid,rss,comm --sort=-rss | head -4 | tr '\n' '|'; echo
  } >> $D/mem.txt 2>&1
  sync -f $D
  sleep 3
done
