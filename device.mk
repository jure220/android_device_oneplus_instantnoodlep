#
# Copyright (C) 2018 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# AAPT
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := xxxhdpi

# Audio
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/audio/audio_platform_info_intcodec.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_platform_info_intcodec.xml \
    $(LOCAL_PATH)/audio/mixer_paths.xml:$(TARGET_COPY_OUT_VENDOR)/etc/mixer_paths.xml \
    $(LOCAL_PATH)/audio/sound_trigger_mixer_paths.xml:$(TARGET_COPY_OUT_ODM)/etc/sound_trigger_mixer_paths.xml \
    $(LOCAL_PATH)/audio/sound_trigger_platform_info.xml:$(TARGET_COPY_OUT_ODM)/etc/sound_trigger_platform_info.xml

# Boot animation
TARGET_SCREEN_HEIGHT := 2376
TARGET_SCREEN_WIDTH := 1080

# Configstore
PRODUCT_PACKAGES += \
    disable_configstore

# Device init scripts
PRODUCT_PACKAGES += \
    fstab.qcom \
    fstab.qcom.ramdisk

# Overlays
DEVICE_PACKAGE_OVERLAYS += \
    $(LOCAL_PATH)/overlay-lineage

PRODUCT_PACKAGES += \
    OPlusFrameworksResTarget \
    OPlusSettingsProviderResTarget \
    OPlusSettingsResTarget \
    OPlusSystemUIResTarget

# PowerShare
PRODUCT_PACKAGES += \
    vendor.lineage.powershare@1.0-service.oplus

# Shipping API
PRODUCT_SHIPPING_API_LEVEL := 29

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += \
    $(LOCAL_PATH)

# Touch
$(call soong_config_set,OPLUS_LINEAGE_TOUCH_HAL,INCLUDE_DIR,$(LOCAL_PATH)/touch/include)

# Inherit from the common OEM chipset makefile.
$(call inherit-product, device/oneplus/sm8250-common/common.mk)

# Inherit from the proprietary files makefile.
$(call inherit-product, vendor/oneplus/instantnoodlep/instantnoodlep-vendor.mk)

# Software (codec2) codec list, for processes that cannot see the swcodec APEX.
#
# Codec2InfoBuilder parses /apex/com.android.media.swcodec/etc/media_codecs.xml
# for the c2.android.* components. APEX mounts are per-mount-namespace, and
# Ubuntu-side processes live in the HOST namespace where that path does not
# exist -- so every software codec was listed by the codec2 store and then
# dropped with "component 'c2.android.aac.encoder' not found in xml", leaving
# video recording with no audio encoder. The hardware OMX codecs were fine
# because /vendor is a symlink into the container rootfs and IS visible.
#
# media_codecs_c2.xml is an alternate name the same parser already looks for in
# the default search dirs (/product/etc, /odm/etc, /vendor/etc, /system/etc).
# /odm is a tmpfs here, so it goes in /system/etc, which is part of this image.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/media/media_codecs_c2.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/media_codecs_c2.xml

# dispcfg -- sets the panel's refresh-rate config through the QTI vendor
# IDisplayConfig interface. See halium-display-mode.service.
PRODUCT_PACKAGES += \
    dispcfg
