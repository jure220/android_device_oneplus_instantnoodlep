#
# Copyright (C) 2018 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Include the common OEM chipset BoardConfig.
include device/oneplus/sm8250-common/BoardConfigCommon.mk

DEVICE_PATH := device/oneplus/instantnoodlep

# Display
TARGET_SCREEN_DENSITY := 450

# HIDL
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/manifest.xml

# Properties
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Partitions
BOARD_ONEPLUS_DYNAMIC_PARTITIONS_SIZE := 7511998464
BOARD_SUPER_PARTITION_SIZE := 15032385536

# Recovery
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/init/fstab.qcom
TARGET_RECOVERY_UI_MARGIN_HEIGHT := 103

# Include the proprietary files BoardConfig.
include vendor/oneplus/instantnoodlep/BoardConfigVendor.mk

# Halium / Ubuntu Touch kernel options, merged on top of the LineageOS
# defconfig. sm8250-common/BoardConfigCommon.mk sets:
#   TARGET_KERNEL_CONFIG := vendor/kona-perf_defconfig vendor/debugfs.config
# and the LineageOS kernel build merges every fragment listed, so appending is
# enough -- no need to edit the stock defconfig.
# Revert: git -C device/oneplus/instantnoodlep checkout BoardConfig.mk
#         rm kernel/oneplus/sm8250/arch/arm64/configs/vendor/halium.config
TARGET_KERNEL_CONFIG += vendor/halium.config

# Use a locally-provided Halium initramfs instead of downloading it during the
# build. Android 14 sandboxes PATH for build hermeticity and BLOCKS curl:
#   "Disallowed PATH tool \"curl\" used"
#   (https://android.googlesource.com/platform/build/+/main/Changes.md#PATH_Tools)
# so halium-boot's get-initrd.sh cannot run. BOARD_USE_LOCAL_INITRD is
# halium-boot's own documented alternative (see its README).
#
# The file was fetched outside the build from:
#   https://github.com/halium/initramfs-tools-halium/releases/download/continuous/initrd.img-touch-arm64
# Refresh it with that same URL if the initramfs is ever updated upstream.
# Revert: rm device/oneplus/instantnoodlep/initramfs.gz and drop this flag.
BOARD_USE_LOCAL_INITRD := true

# ---------------------------------------------------------------------------
# Merge system_ext and product INTO system.
#
# Halium ships ONE system image. sm8250-common/BoardConfigCommon.mk sets
#   TARGET_COPY_OUT_SYSTEM_EXT := system_ext
#   TARGET_COPY_OUT_PRODUCT    := product
# i.e. separate partitions, which we never build or mount. The consequence is
# subtle and fatal: hwservicemanager is system_ext_specific, so the build
# emitted only the compat SYMLINK at /system/bin/hwservicemanager pointing to
# /system/system_ext/bin/hwservicemanager, and the real binary went nowhere.
#
# A dangling hwservicemanager means no HIDL service registry, so the QTI
# display composer HAL can never register, so Mir gets
#   "failed to get hwcomposer service"
# and aborts (SIGABRT), lightdm restart-loops, and there is no display.
#
# Pointing these inside system/ is the standard AOSP arrangement for devices
# without separate partitions, and puts the binaries in our image.
# Revert: git -C device/oneplus/instantnoodlep checkout BoardConfig.mk
# ---------------------------------------------------------------------------
TARGET_COPY_OUT_SYSTEM_EXT := system/system_ext
TARGET_COPY_OUT_PRODUCT := system/product

# 'system/product' and 'system/system_ext' are only permitted when no separate
# product / system_ext IMAGE is being built. board_config.mk gates on the
# filesystem-type vars, so clear the ones sm8250-common sets, otherwise:
#   board_config.mk:718: error: TARGET_COPY_OUT_PRODUCT must be set to
#   'product' to use a product image.
BOARD_PRODUCTIMAGE_FILE_SYSTEM_TYPE :=
BOARD_SYSTEM_EXTIMAGE_FILE_SYSTEM_TYPE :=

# and drop them from the dynamic partition list, since we no longer emit them
BOARD_ONEPLUS_DYNAMIC_PARTITIONS_PARTITION_LIST := odm system vendor

# The LineageOS shell_and_utilities_system module lists fsck.exfat / mkfs.exfat
# as required, but neither is present in this tree. The check is unrelated to
# anything we build; bypass it so single targets (e.g. bootctl) can be built.
BUILD_BROKEN_MISSING_REQUIRED_MODULES := true

# Builder shown in the kernel version string (uname -a, Settings > About):
#   Linux version ... (Z3PHYR@instantnoodlep)
# The build system strips KBUILD_BUILD_USER/HOST from the environment, so pass
# them as make arguments.
TARGET_KERNEL_ADDITIONAL_FLAGS += KBUILD_BUILD_USER=Z3PHYR KBUILD_BUILD_HOST=instantnoodlep
