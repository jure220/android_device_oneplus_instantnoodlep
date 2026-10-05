#
# Halium 14.0 product configuration for OnePlus 8 Pro (instantnoodlep)
#
# THIS FILE REPLACES the stock LineageOS lineage_instantnoodlep.mk.
# Restore the original at any time with:
#     git -C device/oneplus/instantnoodlep checkout lineage_instantnoodlep.mk
#
# It must be named lineage_instantnoodlep.mk: AOSP validates that each entry in
# COMMON_LUNCH_CHOICES matches a product defined by the correspondingly-named
# makefile in PRODUCT_MAKEFILES, and PRODUCT_NAME must carry the lineage_
# prefix (see the LINEAGE_BUILD note further down). Naming the file
# halium_instantnoodlep.mk while declaring PRODUCT_NAME := lineage_instantnoodlep
# fails with:
#   AndroidProducts.mk: error: COMMON_LUNCH_CHOICES contains products(s) not
#   defined in this file: lineage_instantnoodlep
#
# Modelled on Halium's own reference device tree:
#   Halium/android_device_halium_halium_arm64 @ halium-14.0 -> lineage_halium_arm64.mk
#
# The important difference from lineage_instantnoodlep.mk is that Halium
# inherits vendor/halium/config/halium.mk INSTEAD OF
# vendor/lineage/config/common_full_phone.mk. Halium does not want the full
# Android UI/Java stack -- it only builds the HAL layer that libhybris will
# later expose to Ubuntu Touch. Inheriting both would drag in the whole
# framework and defeat the point.
#
# SPDX-License-Identifier: Apache-2.0
#

# 64-bit with 32-bit compat, matching TARGET_ARCH/TARGET_2ND_ARCH in
# device/oneplus/sm8250-common/BoardConfigCommon.mk
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)

# The Halium package set (HALs, libhybris support libs, droidmedia, stubs).
$(call inherit-product, vendor/halium/config/halium.mk)

# The OnePlus 8 Pro device itself. This chains to
# device/oneplus/sm8250-common/common.mk and then to
# vendor/oneplus/{instantnoodlep,sm8250-common} for the blobs.
$(call inherit-product, $(LOCAL_PATH)/device.mk)

# Fonts, if present. if-exists because the Halium manifest trims some
# frameworks/base content and this must not hard-fail.
$(call inherit-product-if-exists, frameworks/base/data/fonts/fonts.mk)

# NOTE: PRODUCT_SHIPPING_API_LEVEL is already set to 29 by device.mk:46,
# so no product_launched_with_*.mk is inherited here.

# PRODUCT_NAME MUST start with "lineage_".
# build/make/envsetup.sh:214 sets LINEAGE_BUILD only for lineage_* products,
# and build/make/core/config.mk:446 gates the ENTIRE LineageOS board config
# behind it:
#     ifneq ($(LINEAGE_BUILD),)
#         include vendor/lineage/config/BoardConfigLineage.mk
#     endif
# Without it, BoardConfigKernel.mk / BoardConfigSoong.mk never run, the
# lineageVarsPlugin soong namespace is never created, and the kernel build
# fails with: unknown variable '$(PATH_OVERRIDE_SOONG)'.
# This is why Halium's own reference device is lineage_halium_arm64, not
# halium_halium_arm64. The file keeps the halium_ name to mark it as the
# Halium config; only the product NAME has to carry the lineage_ prefix.
PRODUCT_NAME := lineage_instantnoodlep
PRODUCT_DEVICE := instantnoodlep
PRODUCT_MANUFACTURER := OnePlus
PRODUCT_BRAND := OnePlus
PRODUCT_MODEL := IN2025

# ---------------------------------------------------------------------------
# Strip Android-only Java apps.
#
# device/oneplus/sm8250-common/common.mk adds these to PRODUCT_PACKAGES. They
# are LineageOS Settings UI components (alert-slider handler, ambient-display
# settings) that depend on org.lineageos.settings.resources, SettingsLibDefaults
# and androidx -- i.e. the Java framework stack that the Halium manifest
# deliberately trims ("(halium) manifest: trim Java-only LineageOS projects").
#
# Under Ubuntu Touch there is no Android UI and no LineageOS Settings app, so
# none of these can ever run. Dropping them is correct, not a workaround;
# adding packages/resources/devicesettings back would drag the whole Java
# framework into a build that has no use for it.
#
# Filtering here rather than editing common.mk keeps the LineageOS tree clean
# for future repo syncs.
# ---------------------------------------------------------------------------
PRODUCT_PACKAGES := $(filter-out KeyHandler OplusDoze Euicc,$(PRODUCT_PACKAGES))

# ---------------------------------------------------------------------------
# Android init reads /vendor/etc/selinux/plat_sepolicy_vers.txt very early in
# SelinuxGetVendorAndroidVersion(); if it is missing init aborts with
#   "Could not read vendor SELinux version" -> InitFatalReboot (signal 6)
#
# Halium's hybris-patches disable SELinux policy generation ("(halium) disable
# SELinux parts" + libselinux_stubs), so the build emits NO vendor/etc/selinux
# directory at all. Supply the version file explicitly.
#
# 202404 = PLATFORM_SEPOLICY_VERSION, which build/make/core/config.mk:881
# defines as $(BOARD_API_LEVEL); our vendor reports ro.board.api_level=202404.
# This is accurate, not a fudge: this vendor really is built from Android 14.
# ---------------------------------------------------------------------------
# NOTE: PRODUCT_EXTRA_VNDK_VERSIONS := 30 was tried here and is a NO-OP.
# The stock vendor declares ro.vndk.version=30, so linkerconfig aborts looking
# for /apex/com.android.vndk.v30, which leaves no vendor linker namespaces and
# breaks vendor EGL (eglSubDriverAndroid.so not found). But prebuilts/vndk/v30
# defines no apex_vndk module in an Android 14 tree, so no APEX is produced and
# the setting changes nothing. Left documented rather than set, so nobody
# re-tries it expecting a fix.

# VINTF enforcement is ON (default). It was briefly disabled with
#     PRODUCT_ENFORCE_VINTF_MANIFEST_OVERRIDE := false
# while the device manifest came back empty. That turned out to be a SYMLINK
# LOOP, not a Treble incompatibility: /odm/etc -> /vendor/odm/etc with the stock
# vendor linking back, so libvintf could not read /odm/etc/vintf/manifest.xml
# and failed the WHOLE fetch (-40). halium-dynparts.sh now shadows /odm with an
# empty tmpfs and hwservicemanager reports
#     getDeviceHalManifest: Successfully processed VINTF information
#
# The override is deliberately NOT restored: with enforcement off, libhidl warns
#     getService: Potential race detected. The VINTF manifest is not being
#     enforced. If a HAL server has a delay in starting and it is not in the
#     manifest, it will not be retrieved.
# ...which weakens HAL retrieval for no benefit now that the manifest loads.

# plat_sepolicy_vers.txt: see the SELinux version note above.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/plat_sepolicy_vers.txt:$(TARGET_COPY_OUT_VENDOR)/etc/selinux/plat_sepolicy_vers.txt

# The vendor SELinux policy must actually be INSTALLED into the vendor image.
#
# halium.mk asks for selinux_policy_system (the /system half) but nothing for
# the vendor half, so the files were BUILT (they sit in
# obj/ETC/vendor_file_contexts_intermediates/) and then never packaged. The
# result: /vendor/etc/selinux contained only plat_sepolicy_vers.txt, and Android
# init SEGFAULTED right after
#     selinux: Loaded file context from: /system/etc/selinux/plat_file_contexts
# because /vendor/etc/selinux/vendor_file_contexts was absent. With the stock
# OxygenOS vendor init loads BOTH files and survives.
#
# selinux_policy_nonsystem pulls in the whole missing set: vendor_sepolicy.cil,
# vendor_file_contexts, vendor_hwservice_contexts, vendor_property_contexts,
# vendor_seapp_contexts, vendor_service_contexts, vndservice_contexts,
# vendor_mac_permissions.xml plus the odm equivalents.
PRODUCT_PACKAGES += \
    selinux_policy_nonsystem

# libminisf is the fake-SurfaceFlinger shim libhybris needs. Without it:
#     library "libminisf.so" not found
#     android/server: Device does not have libminisf ... not starting fake
#         SurfaceFlinger service
# It exists in vendor/halium/droidmedia but was never built. With it the
# compositor logs "Started fake SurfaceFlinger service".
PRODUCT_PACKAGES += \
    libminisf

# NOT SHIPPED: $(LOCAL_PATH)/ld.config.txt -> system/etc/ld.config.txt
# Adding a static linker config here BROKE THE BOOT (device never came back:
# no RNDIS, adb or fastboot). The assumption behind it -- that
# /system/etc/ld.config.txt is read only by libhybris -- is WRONG: the Android
# linker inside the container reads it too, as do Ubuntu-side services that use
# libhybris during early boot. The file is kept in the device tree for
# reference, but must be validated against a single process at runtime (write
# it to a tmpfs and point one process at it) before ever being baked into the
# system image again.
