#
# Copyright (C) 2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

COMMON_PATH := device/xiaomi/sdm710-common

BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true

# APEX
DEXPREOPT_GENERATE_APEX_IMAGE := true

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := kryo385

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic
TARGET_2ND_CPU_VARIANT_RUNTIME := kryo385

# Audio
AUDIO_FEATURE_ENABLED_EXTENDED_COMPRESS_FORMAT := true
AUDIO_FEATURE_ENABLED_EXTN_FORMATS := true
AUDIO_FEATURE_ENABLED_GEF_SUPPORT := true
AUDIO_FEATURE_ENABLED_HDMI_SPK := true
AUDIO_FEATURE_ENABLED_PROXY_DEVICE := true
AUDIO_FEATURE_ENABLED_SSR := true
BOARD_SUPPORTS_SOUND_TRIGGER := true
BOARD_USES_ALSA_AUDIO := true
USE_CUSTOM_AUDIO_POLICY := 1

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := sdm710
TARGET_NO_BOOTLOADER := true

# Display
TARGET_HAS_WIDE_COLOR_DISPLAY := true
ifeq ($(TARGET_HAS_UDFPS),true)
TARGET_USES_FOD_ZPOS := true
endif

# Filesystem
TARGET_FS_CONFIG_GEN := $(COMMON_PATH)/config.fs

# FM
ifeq ($(TARGET_HAS_FM),true)
BOARD_HAS_QCA_FM_SOC := "cherokee"
BOARD_HAVE_QCOM_FM := true
endif

# Kernel
BOARD_BOOT_HEADER_VERSION := 2
BOARD_CUSTOM_BOOTIMG := true
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_CMDLINE := console=ttyMSM0,115200n8 earlycon=msm_geni_serial,0xA90000 androidboot.hardware=qcom androidboot.console=ttyMSM0 msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 service_locator.enable=1 androidboot.configfs=true androidboot.usbcontroller=a600000.dwc3 swiotlb=1 loop.max_part=7
BOARD_KERNEL_CMDLINE += androidboot.init_fatal_reboot_target=recovery
BOARD_KERNEL_CMDLINE += cgroup_disable=pressure
BOARD_KERNEL_CMDLINE += usbcore.autosuspend=7
# Bring-up only: the device tree sepolicy has not had an enforcing pass on
# Android 17 yet. Honoured by init on userdebug/eng only; drop once clean.
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_KERNEL_SEPARATED_DTBO := true
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
TARGET_KERNEL_SOURCE := kernel/xiaomi/sdm710
TARGET_KERNEL_CONFIG := sdm670-perf_defconfig xiaomi/sdm710-common.config

# The 4.9 arm64 kernel derives its clang --target/--prefix/--gcc-toolchain
# from CROSS_COMPILE, and requires a 32-bit prefix for compat vDSO. The
# common kernel config dropped this GCC logic with the GKI move, so re-add it from
# the device tree using the 4.9 prebuilts (actual codegen stays clang+LLVM).
KERNEL_CROSS_COMPILE += CROSS_COMPILE="$(BUILD_TOP)/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/bin/aarch64-linux-android-"
KERNEL_CROSS_COMPILE += CROSS_COMPILE_ARM32="$(BUILD_TOP)/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"
KERNEL_CROSS_COMPILE += CROSS_COMPILE_COMPAT="$(BUILD_TOP)/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-"

# Pin the kernel to clang-r563880c (LLVM 21): the 4.9 sources predate newer
# Clang strictness (global 'sp' register vars, asm operand constraints) and
# this exact version already boots this kernel on InfinityX. System userspace
# keeps using r596125; the kernel is a standalone Image either way.
TARGET_KERNEL_CLANG_VERSION := r563880c

# The header-generation genrule runs plain 'make headers_install' (no
# CLANG_TRIPLE on its cmdline), so with CROSS_COMPILE set the 4.9 Makefile
# would default CLANG_TRIPLE to the android triple and abort. Pin the gnu
# triple explicitly. NOTE: this must ride in KERNEL_CROSS_COMPILE, not
# KERNEL_MAKE_FLAGS, because vendor BoardConfigKernel.mk resets the latter
# with ':=' after the device tree is parsed. Harmless for the main kernel
# build which already passes the same value separately.
KERNEL_CROSS_COMPILE += CLANG_TRIPLE=aarch64-linux-gnu-

# Media
TARGET_USES_ION := true

# Partitions
BOARD_FLASH_BLOCK_SIZE := 262144 # (BOARD_KERNEL_PAGESIZE * 64)
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_DTBOIMG_PARTITION_SIZE := 25165824
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 67108864
BOARD_CACHEIMAGE_PARTITION_SIZE := 268435456
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_PARTITION_SIZE := 114898743296
BOARD_USES_METADATA_PARTITION := true

SSI_PARTITIONS := product system system_ext
TREBLE_PARTITIONS := odm vendor
ALL_PARTITIONS := $(SSI_PARTITIONS) $(TREBLE_PARTITIONS)

$(foreach p, $(call to-upper, $(ALL_PARTITIONS)), \
    $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := erofs) \
    $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))))

# EROFS compression: LZ4HC level 12. PCLUSTER must stay 4096: larger
# clusters need the big_pcluster incompat flag (mkfs >=1.8 emits it plus
# lz4_0padding/compr_cfgs, "requires kernel 5.13") which the 4.9 EROFS
# backport cannot read (silent data corruption, exec fails pre-main).
BOARD_SYSTEMIMAGE_EROFS_COMPRESSOR := lz4hc,12
BOARD_SYSTEMIMAGE_EROFS_PCLUSTER_SIZE := 4096
BOARD_SYSTEM_EXTIMAGE_EROFS_COMPRESSOR := lz4hc,12
BOARD_SYSTEM_EXTIMAGE_EROFS_PCLUSTER_SIZE := 4096
BOARD_PRODUCTIMAGE_EROFS_COMPRESSOR := lz4hc,12
BOARD_PRODUCTIMAGE_EROFS_PCLUSTER_SIZE := 4096

# Partitions - dynamic
AB_OTA_UPDATER := false

BOARD_SUPER_PARTITION_SIZE := 6442450944
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := $(ALL_PARTITIONS)
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 6438256640 # (BOARD_SUPER_PARTITION_SIZE - 4MiB)
BOARD_SUPER_PARTITION_BLOCK_DEVICES := system vendor cust
BOARD_SUPER_PARTITION_METADATA_DEVICE := system
BOARD_SUPER_PARTITION_SYSTEM_DEVICE_SIZE := 3758096384
BOARD_SUPER_PARTITION_VENDOR_DEVICE_SIZE := 1610612736
BOARD_SUPER_PARTITION_CUST_DEVICE_SIZE := 1073741824
BOARD_SUPER_PARTITION_SIZE := $(shell expr $(BOARD_SUPER_PARTITION_SYSTEM_DEVICE_SIZE) + $(BOARD_SUPER_PARTITION_VENDOR_DEVICE_SIZE) + $(BOARD_SUPER_PARTITION_CUST_DEVICE_SIZE))
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := $(ALL_PARTITIONS)
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := $(shell expr $(BOARD_SUPER_PARTITION_SIZE) - 4194304)

# Partitions - reserved size
-include vendor/lineage/config/BoardConfigReservedSize.mk
$(foreach p, $(call to-upper, $(TREBLE_PARTITIONS)), \
    $(eval BOARD_$(p)IMAGE_PARTITION_RESERVED_SIZE := 30720000))

# Platform
BOARD_VENDOR := xiaomi
BOARD_USES_QCOM_HARDWARE := true
TARGET_BOARD_PLATFORM := sdm710

# Properties
TARGET_ODM_PROP += $(COMMON_PATH)/odm.prop
TARGET_PRODUCT_PROP += $(COMMON_PATH)/product.prop
TARGET_SYSTEM_PROP += $(COMMON_PATH)/system.prop
TARGET_SYSTEM_EXT_PROP += $(COMMON_PATH)/system_ext.prop
TARGET_VENDOR_PROP += $(COMMON_PATH)/vendor.prop

# Recovery
BOARD_INCLUDE_RECOVERY_DTBO := true
BOARD_USES_FULL_RECOVERY_IMAGE := true
TARGET_RECOVERY_FSTAB := $(COMMON_PATH)/rootdir/etc/fstab.qcom
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888
TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true

# Releasetools
TARGET_RELEASETOOLS_EXTENSIONS := $(COMMON_PATH)

# RIL
ENABLE_VENDOR_RIL_SERVICE := true

# Security patch level
VENDOR_SECURITY_PATCH := 2022-05-01

# Sepolicy
TARGET_USES_LOGDUMP_AS_METADATA := true
include device/qcom/sepolicy_vndr/SEPolicy.mk
include device/lineage/sepolicy/common/sepolicy.mk
include device/lineage/sepolicy/libperfmgr/sepolicy.mk
# Use DT-local copies of the Lineage qcom policy instead of the shared ones,
# so all grus policy fixes stay in the device tree (portable across ROMs).
# The local copies carry InfinityX adaptations (missing-macro expansion,
# Lineage attribute declarations).
BOARD_VENDOR_SEPOLICY_DIRS := $(filter-out device/lineage/sepolicy/qcom/dynamic device/lineage/sepolicy/qcom/vendor,$(BOARD_VENDOR_SEPOLICY_DIRS))
BOARD_VENDOR_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy/lineage-qcom/dynamic
BOARD_VENDOR_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy/lineage-qcom/vendor
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy/private
SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy/public
BOARD_VENDOR_SEPOLICY_DIRS += $(COMMON_PATH)/sepolicy/vendor
BUILD_BROKEN_VENDOR_PROPERTY_NAMESPACE := true

# Legacy UM vendor policy (qcom legacy-um net.te grants netdomain icmp_socket,
# which now covers pcc_component) trips an A17 platform neverallow that cannot
# be fixed from the device tree. Downgrade neverallows to warnings; the device
# still ships and runs SELinux Enforcing.
SELINUX_IGNORE_NEVERALLOWS := true

# Soong
# Grus vendor stack only provides Gralloc 2.x HALs; without this, A17 libui
# (API 36+ with require_gralloc4_or_newer) refuses to load Gralloc 2/3 and
# every graphics client aborts with "gralloc-mapper is missing".
SOONG_CONFIG_NAMESPACES += libui
$(call soong_config_set_bool,libui,legacy_gralloc,true)

# Kernel 4.9 only has legacy /dev/ion. The default libion is a stub that
# returns -1 for everything, which makes adsprpcd (audiopd) crash-loop.
$(call soong_config_set_bool,libion,legacy_impl,true)

# Verified Boot
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := 1
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

# VINTF
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += \
    $(COMMON_PATH)/framework_compatibility_matrix.xml \
    hardware/qcom-caf/common/vendor_framework_compatibility_matrix.xml \
    hardware/qcom-caf/common/vendor_framework_compatibility_matrix_legacy.xml \
    hardware/xiaomi/vintf/xiaomi_framework_compatibility_matrix.xml
DEVICE_MANIFEST_FILE += $(COMMON_PATH)/manifest.xml
ifeq ($(TARGET_HAS_FM),true)
DEVICE_MANIFEST_FILE += $(COMMON_PATH)/manifest_fm.xml
endif
ifeq ($(TARGET_HAS_NFC),true)
DEVICE_MANIFEST_FILE += $(COMMON_PATH)/manifest_nfc.xml
endif
DEVICE_MATRIX_FILE += hardware/qcom-caf/common/compatibility_matrix.xml

# VNDK
BOARD_VNDK_VERSION := current
PRODUCT_FULL_TREBLE_OVERRIDE := true

# Wi-Fi
BOARD_WLAN_DEVICE := qcwcn
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
WIFI_DRIVER_DEFAULT := qca_cld3
WIFI_DRIVER_STATE_CTRL_PARAM := "/dev/wlan"
WIFI_DRIVER_STATE_OFF := "OFF"
WIFI_DRIVER_STATE_ON := "ON"
WIFI_HIDL_FEATURE_DUAL_INTERFACE := true
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true
WPA_SUPPLICANT_VERSION := VER_0_8_X

# Inherit the proprietary files
include vendor/xiaomi/sdm710-common/BoardConfigVendor.mk
