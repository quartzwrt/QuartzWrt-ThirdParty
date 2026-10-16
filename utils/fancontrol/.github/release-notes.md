# Fan Control for OpenWrt

## 中文说明

本 Release 提供适用于 OpenWrt snapshot 的 APK 软件包。请下载文件名末尾与
路由器软件包架构相同的三个文件：

- `fancontrol-<架构>.apk`：风扇控制服务
- `luci-app-fancontrol-<架构>.apk`：LuCI 管理界面
- `luci-i18n-fancontrol-zh-cn-<架构>.apk`：LuCI 简体中文翻译

可在路由器上运行以下命令查看软件包架构：

```sh
apk --print-arch
```

将下载的文件上传到路由器并安装：

```sh
scp *.apk root@192.168.1.1:/tmp/
ssh root@192.168.1.1
apk add --allow-untrusted /tmp/fancontrol-*.apk \
  /tmp/luci-app-fancontrol-*.apk \
  /tmp/luci-i18n-fancontrol-zh-cn-*.apk
```

安装完成后先刷新 LuCI 后端，再进入“服务 -> 风扇控制”页面完成硬件检测和温控
曲线配置，启用并保存设置即可：

```sh
/etc/init.d/rpcd restart
```

也可以通过命令行启用风扇控制服务：

```sh
uci set fancontrol.settings.enabled='1'
uci commit fancontrol
/etc/init.d/fancontrol enable
/etc/init.d/fancontrol restart
```

> 这些 APK 使用当前 OpenWrt snapshot SDK 构建，只适用于软件包 ABI 兼容的
> snapshot 固件，不适用于仍使用 `opkg`/IPK 的稳定版固件。

## English

This release contains APK packages built for OpenWrt snapshots. Download the
three files whose filename suffix matches your router's package architecture:

- `fancontrol-<architecture>.apk`: fan control service
- `luci-app-fancontrol-<architecture>.apk`: LuCI management interface
- `luci-i18n-fancontrol-zh-cn-<architecture>.apk`: Simplified Chinese translation

Check the package architecture on the router with:

```sh
apk --print-arch
```

Upload and install the downloaded packages:

```sh
scp *.apk root@192.168.1.1:/tmp/
ssh root@192.168.1.1
apk add --allow-untrusted /tmp/fancontrol-*.apk \
  /tmp/luci-app-fancontrol-*.apk \
  /tmp/luci-i18n-fancontrol-zh-cn-*.apk
```

After installation, refresh the LuCI backend, then open
**Services -> Fan Control** in LuCI to detect the hardware, configure the
temperature curve, and enable the service:

```sh
/etc/init.d/rpcd restart
```

The fan control service can also be enabled from the command line:

```sh
uci set fancontrol.settings.enabled='1'
uci commit fancontrol
/etc/init.d/fancontrol enable
/etc/init.d/fancontrol restart
```

> These APKs are built with the current OpenWrt snapshot SDK. They require a
> snapshot firmware with a compatible package ABI and cannot be installed on
> stable releases that still use `opkg`/IPK.
