# 息屏自动超级省电 (KSU/Magisk 模块)

息屏满配置时长（默认1800s）后自动开启「超级省电模式」(非省电模式)，亮屏自动关闭；充电时不进入；手动开启的超级省电亮屏不会自动关闭。

## 功能规则
| 场景 | 行为 |
| --- | --- |
| 息屏满 `DELAY_SEC` 且未充电 | 自动开启超级省电 |
| 亮屏 | 关闭由模块开启的超级省电 |
| 充电中 | 不进入（重置计时） |
| 用户手动开启超级省电 | 亮屏不会自动关闭 |

## 安装
1. 我们推荐您采用KernelSU 对Magisk的适配十分潦草
2. 重启（KSU 开机自启 推荐），或终端执行: `sh /data/adb/modules/super_saver_auto/service.sh`
*请注意执行渠道，例如mt管理器会导致重复激活造成部分功能失效，可以深度重启系统解决（非软重启）
3. 查看日志: `cat /data/adb/modules/super_saver_auto/log.txt`

## 配置
编辑 `config.sh`:
- `DELAY_SEC`: 息屏多少秒后开启 (默认 1800s)
- `POLL_INTERVAL`: 轮询间隔秒数 (默认 5s)
- `CHARGE_RESET`: 充电是否重置计时 (1/0)
- `SELINUX_HANDLE`: 开关超级省电时是否自动临时关闭 SELinux (默认 1)

## 说明
- 开启/关闭超级省电由 `settings put system super_powersave_mode_state 1/0` 控制。
- **SELinux 处理**: ColorOS 的 SELinux 策略不认 KernelSU 的 `ksu:s0` 域，导致守护进程写 settings 被拒。模块会在「开启超级省电前」临时切 Permissive，解锁SELinux，亮屏后自动关闭
- 若系统版本不同导致无效, 重新运行诊断:
```
sh /data/adb/modules/super_saver_auto/diag.sh
```
把 `/sdcard/super_saver_diag.txt` 内容转移即可定制 `power_ctl.sh`。

## 已验证 (真我 GT5 / 2026-09-15 诊断)
- `super_powersave_mode_state` = 超级省电状态键 (0=关/1=开), 与普通省电 `low_power` 相互独立
- `super_powersave_launcher_enter` = 省电桌面进入标记
- `super_power_save_desktop_app_list` = 省电桌面允许应用列表
