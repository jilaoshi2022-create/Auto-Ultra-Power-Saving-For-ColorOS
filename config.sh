#!/system/bin/sh
# ============ 配置 ============
# 息屏多少秒后开启超级省电 (默认 1800 = 30 分钟; 快速测试可改 5)
DELAY_SEC=1800
# 轮询间隔(秒), 影响响应速度与耗电
POLL_INTERVAL=5
# 开启/关闭超级省电时是否自动临时关闭SELinux(真我ColorOS不认ksu域, 必须=1)
SELINUX_HANDLE=1
# 开关省电时是否备份/恢复显示设置(电池百分比/样式), 防ColorOS退出省电恢复不完整
RESTORE_DISPLAY=1
# 充电时是否重置息屏计时(1=充电期间重新计时, 0=充电暂停但保留已计时)
CHARGE_RESET=1
# 日志文件 (MODDIR 由 daemon.sh 传入)
LOG_FILE="$MODDIR/log.txt"
