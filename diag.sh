#!/system/bin/sh
# 超级省电 诊断脚本 - root终端执行: sh diag.sh
# 结果写入 /sdcard/super_saver_diag.txt
OUT=/sdcard/super_saver_diag.txt
{
echo "===== 设备信息 ====="
getprop ro.product.model
getprop ro.build.version.release
getprop ro.build.version.oplusrom 2>/dev/null
getprop ro.build.version.realmeui 2>/dev/null
getprop ro.build.display.id
echo ""
echo "===== 1. 电池/省电相关包 ====="
pm list packages | grep -iE "battery|power|save|safecenter|guard|energy"
echo ""
echo "===== 2. 电池管理包的全部 Activity(搜 super/power/save/extreme) ====="
for pkg in com.oplus.battery com.coloros.batterysaving com.coloros.safecenter com.oplus.safecenter; do
  echo "--- $pkg ---"
  dumpsys package $pkg 2>/dev/null | grep -E "^\s+[0-9a-f]+ .*Activity|Activity Resolver" | head -5
  dumpsys package $pkg 2>/dev/null | grep -iE "class=.*(super|power|save|extreme|mode)" | head -40
done
echo ""
echo "===== 3. settings global (power/save/battery) ====="
settings list global | grep -iE "power|save|battery|low_"
echo ""
echo "===== 4. settings system (power/save/battery) ====="
settings list system | grep -iE "power|save|battery|low_"
echo ""
echo "===== 5. settings secure (power/save/battery) ====="
settings list secure | grep -iE "power|save|battery|low_"
echo ""
echo "===== 6. 系统服务(battery/power/save) ====="
service list 2>/dev/null | grep -iE "battery|power|save"
echo ""
echo "===== 7. 当前电池状态 ====="
dumpsys battery | grep -iE "powered|level|status"
echo ""
echo "===== 8. 当前屏幕状态 ====="
dumpsys power | grep -iE "mWakefulness|mScreenOn|Display Power" | head -5
echo ""
echo "===== 9. 当前前台 Activity ====="
dumpsys activity activities | grep -iE "mResumedActivity|topResumedActivity" | head -3
} > $OUT 2>&1
echo "完成! 结果已写入: $OUT"
