#!/system/bin/sh
# 真我息屏自动超级省电 - 守护进程
# 状态机:
#   息屏 & 未充电 & 满 DELAY_SEC 秒      -> 临时宽松SELinux, 开启超级省电(打 auto 标记)
#   亮屏 & 有 auto 标记                -> 关闭超级省电, 恢复SELinux(清标记)
#   充电中                             -> 不进入, 重置计时
#   手动开启(无 auto 标记)             -> 亮屏不关闭
# 说明: 真我 ColorOS 的 SELinux 策略不认 KernelSU 的 ksu:s0 域, 导致 settings 写入被拒,
#       故开启/关闭超级省电的瞬间临时切 Permissive, 完成后再恢复 Enforcing。

MODDIR=$(cd "$(dirname "$0")" && pwd)
. "$MODDIR/config.sh"
. "$MODDIR/power_ctl.sh"

# 兼容旧配置: 未定义 DELAY_SEC 时由 DELAY_MIN(分钟) 换算
if [ -z "$DELAY_SEC" ]; then
    DELAY_SEC=$((DELAY_MIN * 60))
fi
# 兼容旧配置: 默认启用SELinux自动处理
[ -z "$SELINUX_HANDLE" ] && SELINUX_HANDLE=1

STATE_DIR="$MODDIR/state"
mkdir -p "$STATE_DIR"
AUTO_FLAG="$STATE_DIR/.auto_on"
OFF_TS="$STATE_DIR/.screen_off_ts"
PID_FILE="$STATE_DIR/.pid"
BACKUP_FILE="$STATE_DIR/.display_backup"

# 防多实例
if [ -f "$PID_FILE" ]; then
    old_pid=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null; then
        echo "已有一个守护进程在运行 (PID=$old_pid), 退出"
        exit 0
    fi
fi
echo $$ > "$PID_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

now_s() {
    date +%s
}

# 屏幕是否亮着: 0=亮, 1=息屏
is_screen_on() {
    case "$(dumpsys power 2>/dev/null | grep -m1 'mWakefulness=')" in
        *Awake*) return 0 ;;
        *)       return 1 ;;
    esac
}

# 是否在充电: 0=是, 1=否
is_charging() {
    dumpsys battery 2>/dev/null | grep -E 'AC powered|USB powered|Wireless powered' | grep -q 'true'
}

# 进入省电前备份显示设置 (ColorOS 退出省电时恢复不完整, 模块自行备份恢复)
backup_display() {
    if [ "$RESTORE_DISPLAY" = "1" ]; then
        {
            echo "display_power_percent=$(settings get system display_power_percent 2>/dev/null)"
            echo "status_bar_show_battery_percent=$(settings get system status_bar_show_battery_percent 2>/dev/null)"
            echo "display_battery_style=$(settings get system display_battery_style 2>/dev/null)"
            echo "oplus_default_display_power_percent=$(settings get system oplus_default_display_power_percent 2>/dev/null)"
        } > "$BACKUP_FILE" 2>/dev/null
        log "已备份显示设置(电池百分比/样式)"
    fi
}

# 退出省电后恢复显示设置
restore_display() {
    if [ "$RESTORE_DISPLAY" = "1" ] && [ -f "$BACKUP_FILE" ]; then
        while IFS='=' read -r k v; do
            [ -n "$k" ] && settings put system "$k" "$v" >/dev/null 2>&1
        done < "$BACKUP_FILE"
        rm -f "$BACKUP_FILE"
        log "已恢复显示设置(电池百分比/样式)"
    fi
}

# 退出兜底: 关闭超级省电并恢复SELinux, 防止残留宽松模式
cleanup() {
    if [ "$SELINUX_HANDLE" = "1" ]; then
        setenforce 0 2>/dev/null
        settings put system super_powersave_mode_state 0 >/dev/null 2>&1
        restore_display
        setenforce 1 2>/dev/null
    fi
    rm -f "$PID_FILE" 2>/dev/null
}
trap cleanup EXIT TERM INT

log "========== 守护进程启动 (PID=$$) =========="
log "配置: 息屏${DELAY_SEC}秒开启超级省电, 轮询${POLL_INTERVAL}s, 充电重置计时=${CHARGE_RESET}, SELinux自动处理=${SELINUX_HANDLE}"

# 等待 settings 服务就绪 (开机早期 SettingsProvider 可能未启动)
WAIT_T=0
while [ "$WAIT_T" -lt 60 ]; do
    if settings get system super_powersave_mode_state >/dev/null 2>&1; then
        break
    fi
    WAIT_T=$((WAIT_T + 2))
    sleep 2
done
log "settings 服务就绪 (开机等待${WAIT_T}s)"

# 启动兜底: 若没有正在进行的自动省电会话, 确保SELinux恢复Enforcing
if [ "$SELINUX_HANDLE" = "1" ] && [ ! -f "$AUTO_FLAG" ] && [ "$(getenforce 2>/dev/null)" != "Enforcing" ]; then
    setenforce 1 2>/dev/null
    log "启动兜底: 恢复SELinux Enforcing"
fi

LOOP_N=0
while true; do
    if is_screen_on; then
        # ===== 亮屏 =====
        if [ -f "$AUTO_FLAG" ]; then
            if [ "$SELINUX_HANDLE" = "1" ]; then
                setenforce 0 2>/dev/null
            fi
            if settings put system super_powersave_mode_state 0; then
                restore_display
                if [ "$SELINUX_HANDLE" = "1" ]; then
                    setenforce 1 2>/dev/null
                fi
                log "亮屏: 已关闭超级省电并恢复SELinux"
            else
                log "亮屏: 关闭超级省电失败, 保持当前SELinux状态"
            fi
            rm -f "$AUTO_FLAG"
        fi
        rm -f "$OFF_TS"
    else
        # ===== 息屏 =====
        if is_charging; then
            # 充电中: 不进入; 按配置重置计时
            if [ "$CHARGE_RESET" = "1" ]; then
                rm -f "$OFF_TS"
            fi
        else
            if [ ! -f "$AUTO_FLAG" ]; then
                if [ ! -f "$OFF_TS" ]; then
                    echo "$(now_s)" > "$OFF_TS"
                    log "息屏计时开始"
                fi
                start=$(cat "$OFF_TS")
                elapsed=$(( $(now_s) - start ))
                if [ "$elapsed" -ge "$DELAY_SEC" ]; then
                    if [ "$SELINUX_HANDLE" = "1" ]; then
                        setenforce 0 2>/dev/null
                    fi
                    backup_display
                    if settings put system super_powersave_mode_state 1; then
                        touch "$AUTO_FLAG"
                        log "息屏满${DELAY_SEC}秒, 已开启超级省电(自动), SELinux临时宽松"
                    else
                        log "息屏满${DELAY_SEC}秒, 开启超级省电失败"
                        if [ "$SELINUX_HANDLE" = "1" ]; then
                            setenforce 1 2>/dev/null
                        fi
                    fi
                fi
            fi
        fi
    fi
    LOOP_N=$((LOOP_N + 1))
    if [ -n "$MAX_LOOPS" ] && [ "$LOOP_N" -ge "$MAX_LOOPS" ]; then
        break
    fi
    sleep "$POLL_INTERVAL"
done
