#!/bin/bash

echo "# begin build properties"
echo "# autogenerated by vendor_buildinfo.sh"

echo "ro.vendor.build.id=$BUILD_ID"
echo "ro.vendor.build.version.incremental=$BUILD_NUMBER"
echo "ro.vendor.build.version.sdk=$PLATFORM_SDK_VERSION"
echo "ro.vendor.build.version.release=$PLATFORM_VERSION"
echo "ro.vendor.build.type=$TARGET_BUILD_TYPE"
echo "ro.vendor.build.tags=$BUILD_VERSION_TAGS"

echo "ro.product.board=$TARGET_BOOTLOADER_BOARD_NAME"
echo "ro.board.platform=$TARGET_BOARD_PLATFORM"

echo "ro.product.vendor.manufacturer=$PRODUCT_MANUFACTURER"
echo "ro.product.vendor.model=$PRODUCT_MODEL"
echo "ro.product.vendor.brand=$PRODUCT_BRAND"
echo "ro.product.vendor.name=$PRODUCT_NAME"
echo "ro.product.vendor.device=$TARGET_DEVICE"

echo "# end build properties"
