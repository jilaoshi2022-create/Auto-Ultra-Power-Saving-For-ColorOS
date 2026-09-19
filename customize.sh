#!/system/bin/sh
# 安装时执行: 补全脚本执行权限 (KSU 刷入可能重置为 644)
MODDIR=${0%/*}
chmod 755 "$MODDIR"/*.sh 2>/dev/null
# 兼容 Magisk: 部分版本以 MODDIR 环境变量传入
[ -n "$MODDIR" ] && chmod 755 "$MODDIR"/*.sh 2>/dev/null
exit 0
