#!/system/bin/sh
# 启动守护进程 (开机自启 & 手动启动均可)
# 手动启动: su -c "sh /data/adb/modules/super_saver_auto/service.sh"
MODDIR=$(cd "$(dirname "$0")" && pwd)
LOG="$MODDIR/log.txt"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] service.sh 被调用, 启动守护进程..." >> "$LOG"

# 等待系统就绪 (KSU/Magisk 在 late_start 阶段执行 service.sh, 系统已就绪, 无需等待)
# 注意: 这里不要加长 sleep, 否则手动启动时终端会长时间无响应(易被误中断)

# 防重复: 若已有 daemon 在跑则跳过
if [ -f "$MODDIR/state/.pid" ]; then
    old_pid=$(cat "$MODDIR/state/.pid" 2>/dev/null)
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 守护进程已在运行 (PID=$old_pid), 跳过启动" >> "$LOG"
        exit 0
    fi
fi

# 显式用 sh 调用 daemon.sh (不依赖可执行位, 防 KSU 刷入后权限被重置为 644)
nohup sh "$MODDIR/daemon.sh" >> "$LOG" 2>&1 &
sleep 1
if kill -0 $! 2>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 守护进程已启动 (PID=$!)" >> "$LOG"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 守护进程启动失败!" >> "$LOG"
fi
