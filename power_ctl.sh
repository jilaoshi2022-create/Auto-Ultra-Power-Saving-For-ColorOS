#!/system/bin/sh
# SPDX-License-Identifier: MPL-2.0
# 超级省电控制层 (realme UI / ColorOS)
# 诊断确认: 超级省电由 settings system 键 super_powersave_mode_state 控制 (0=关, 1=开)
# 配套键: super_powersave_launcher_enter(省电桌面进入标记), super_power_save_desktop_app_list(省电桌面允许应用)
# 注意: 与普通省电(low_power)相互独立, 本模块只操作超级省电
# 仅在真我gt5上通过测试 如果无效可以运行diag.sh获取相关配置

MODDIR=$(cd "$(dirname "$0")" && pwd)

# 检测超级省电模式是否开启: 返回 0=已开启, 1=未开启
is_super_saver_on() {
    [ "$(settings get system super_powersave_mode_state 2>/dev/null)" = "1" ]
}

# 开启超级省电
enable_super_saver() {
    settings put system super_powersave_mode_state 1
}

# 关闭超级省电
disable_super_saver() {
    settings put system super_powersave_mode_state 0
}
