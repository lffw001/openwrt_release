#!/usr/bin/env bash

install_custom_banner() {
    local banner_source=$1
    local build_root=$2
    local banner_target="$build_root/package/base-files/files/etc/banner"

    if [[ ! -f $banner_source ]]; then
        echo "未提供自定义 banner 文件，保持 OpenWrt 默认配置"
        return 0
    fi

    if ! install -Dm644 "$banner_source" "$banner_target"; then
        echo "错误：无法安装自定义 banner 到 $banner_target" >&2
        return 1
    fi

    echo "已应用自定义 banner：$banner_target"
}
