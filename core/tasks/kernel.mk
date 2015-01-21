# Copyright (C) 2012 The CyanogenMod Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Android makefile to build kernel as a part of Android Build

TARGET_AUTO_KDIR := $(shell echo $(TARGET_DEVICE_DIR) | sed -e 's/^device/kernel/g')

## Externally influenced variables
# kernel location - optional, defaults to kernel/<vendor>/<device>
TARGET_KERNEL_SOURCE := $(strip $(TARGET_KERNEL_SOURCE))
ifeq ($(TARGET_KERNEL_SOURCE),)
    KERNEL_SRC := $(TARGET_AUTO_KDIR)
else
    KERNEL_SRC := $(TARGET_KERNEL_SOURCE)
endif

# kernel configuration - mandatory
KERNEL_DEFCONFIG := $(TARGET_KERNEL_CONFIG)
OVERRIDE_DEFCONFIGS := $(TARGET_KERNEL_OVERRIDE_CONFIGS)
VARIANT_DEFCONFIG := $(TARGET_KERNEL_VARIANT_CONFIG)
SELINUX_DEFCONFIG := $(TARGET_KERNEL_SELINUX_CONFIG)

## Internal variables
KERNEL_OUT := $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ
KERNEL_CONFIG := $(KERNEL_OUT)/.config

TARGET_KERNEL_ARCH := $(strip $(TARGET_KERNEL_ARCH))
ifeq ($(TARGET_KERNEL_ARCH),)
    KERNEL_ARCH := $(TARGET_ARCH)
else
    KERNEL_ARCH := $(TARGET_KERNEL_ARCH)
endif

TARGET_KERNEL_HEADER_ARCH := $(strip $(TARGET_KERNEL_HEADER_ARCH))
ifeq ($(TARGET_KERNEL_HEADER_ARCH),)
    KERNEL_HEADER_ARCH := $(KERNEL_ARCH)
else
    KERNEL_HEADER_ARCH := $(TARGET_KERNEL_HEADER_ARCH)
endif

KERNEL_HEADER_DEFCONFIG := $(strip $(KERNEL_HEADER_DEFCONFIG))
ifeq ($(KERNEL_HEADER_DEFCONFIG),)
    KERNEL_HEADER_DEFCONFIG := $(KERNEL_DEFCONFIG)
endif


ifneq ($(BOARD_KERNEL_IMAGE_NAME),)
    TARGET_PREBUILT_INT_KERNEL_TYPE := $(BOARD_KERNEL_IMAGE_NAME)
else
    ifeq ($(TARGET_USES_UNCOMPRESSED_KERNEL),true)
        TARGET_PREBUILT_INT_KERNEL_TYPE := Image
    else
        TARGET_PREBUILT_INT_KERNEL_TYPE := zImage
    endif
endif

TARGET_PREBUILT_INT_KERNEL := $(KERNEL_OUT)/arch/$(KERNEL_ARCH)/boot/$(TARGET_PREBUILT_INT_KERNEL_TYPE)

# Clear this first to prevent accidental poisoning from env
MAKE_FLAGS :=

ifeq ($(KERNEL_ARCH),arm64)
    # Avoid "unsupported RELA relocation: 311" errors (R_AARCH64_ADR_GOT_PAGE)
    MAKE_FLAGS += CFLAGS_MODULE="-fno-pic"
    ifeq ($(TARGET_ARCH),arm)
        KERNEL_CONFIG_OVERRIDE := CONFIG_ANDROID_BINDER_IPC_32BIT=y
    endif
endif


## To be discontinued in a future version. Notify builder about target kernel format requirement
ifeq ($(BOARD_KERNEL_IMAGE_NAME),)
    ifeq ($(BOARD_USES_UBOOT),true)
        $(error "Please set BOARD_KERNEL_IMAGE_NAME to uImage")
    endif
    ifeq ($(BOARD_USES_UNCOMPRESSED_BOOT),true)
        $(error "Please set BOARD_KERNEL_IMAGE_NAME to Image")
    endif
endif

ifeq ($(wildcard $(KERNEL_SRC)),)
    ifneq ($(TARGET_PREBUILT_KERNEL),)
        HAS_PREBUILT_KERNEL := true
        NEEDS_KERNEL_COPY := true
    else
        $(foreach cf,$(PRODUCT_COPY_FILES), \
            $(eval _src := $(call word-colon,1,$(cf))) \
            $(eval _dest := $(call word-colon,2,$(cf))) \
            $(ifeq kernel,$(_dest), \
            $(eval HAS_PREBUILT_KERNEL := true)))
    endif

    ifneq ($(HAS_PREBUILT_KERNEL),)
        $(warning *********************************************************************)
        $(warning * Using prebuilt kernel binary instead of source                    *)
        $(warning * THIS IS DEPRECATED, AND WILL BE DISCONTINUED                      *)
        $(warning * Please configure your device to download the kernel               *)
        $(warning * source repository to $(KERNEL_SRC)                                *)
        $(warning * See http://wiki.cyanogenmod.org/w/Doc:_integrated_kernel_building *)
        $(warning * for more information                                              *)
        $(warning *********************************************************************)
        FULL_KERNEL_BUILD := false
        KERNEL_BIN := $(TARGET_PREBUILT_KERNEL)
    else
        $(warning ***************************************************************)
        $(warning *                                                             *)
        $(warning * No kernel source found, and no fallback prebuilt defined.   *)
        $(warning * Please make sure your device is properly configured to      *)
        $(warning * download the kernel repository to $(KERNEL_SRC)             *)
        $(warning * and add the TARGET_KERNEL_CONFIG variable to BoardConfig.mk *)
        $(warning *                                                             *)
        $(warning * As an alternative, define the TARGET_PREBUILT_KERNEL        *)
        $(warning * variable with the path to the prebuilt binary kernel image  *)
        $(warning * in your BoardConfig.mk file                                 *)
        $(warning *                                                             *)
        $(warning ***************************************************************)
        $(error "NO KERNEL")
    endif
else
    NEEDS_KERNEL_COPY := true
    ifeq ($(TARGET_KERNEL_CONFIG),)
        ifneq ($(KERNEL_HEADER_DEFCONFIG),)
            $(warning **********************************************************)
            $(warning * Kernel source found, but no configuration was defined. *)
            $(warning * Header config found. Building in Header Only Mode.     *)
            $(warning *                                                        *)
            $(warning * Please add the TARGET_KERNEL_CONFIG Variable to your   *)
            $(warning * BoardConfig.mk file to stop using Header Only Mode.    *)
            $(warning **********************************************************)
            FULL_KERNEL_BUILD := true
            KERNEL_CONFIG := $(KERNEL_HEADER_DEFCONFIG)
            ifneq ($(TARGET_PREBUILT_KERNEL),)
                KERNEL_BIN := $(TARGET_PREBUILT_KERNEL)
            else
                $(warning **********************************************************)
                $(warning * When in Header Only Mode, a Prebuilt kernel must be    *)
                $(warning * defined. Set TARGET_PREBUILT_KERNEL with the path to   *)
                $(warning * the prebuilt binary kernel image in your BoardConfig   *)
                $(warning **********************************************************)
                $(error "NO KERNEL")
            endif
        else
            $(warning **********************************************************)
            $(warning * Kernel source found, but no configuration was defined. *)
            $(warning * Please add the TARGET_KERNEL_CONFIG variable to your   *)
            $(warning * BoardConfig.mk file                                    *)
            $(warning **********************************************************)
            # $(error "NO KERNEL CONFIG")
        endif
    else
        #$(info Kernel source found, building it)
        FULL_KERNEL_BUILD := true
        KERNEL_BIN := $(TARGET_PREBUILT_INT_KERNEL)
    endif
endif

ifeq ($(FULL_KERNEL_BUILD),true)
    KERNEL_HEADERS_INSTALL := $(KERNEL_OUT)/usr
    KERNEL_MODULES_INSTALL := system
    KERNEL_MODULES_OUT := $(TARGET_OUT)/lib/modules
    TARGET_KERNEL_CROSS_COMPILE_PREFIX := $(strip $(TARGET_KERNEL_CROSS_COMPILE_PREFIX))
        ifeq ($(TARGET_KERNEL_CROSS_COMPILE_PREFIX),)
            ifeq ($(KERNEL_TOOLCHAIN_PREFIX),)
                KERNEL_TOOLCHAIN_PREFIX := arm-eabi-
            endif
        else
            KERNEL_TOOLCHAIN_PREFIX := $(TARGET_KERNEL_CROSS_COMPILE_PREFIX)
        endif
    ifeq ($(KERNEL_TOOLCHAIN),)
        KERNEL_TOOLCHAIN_PATH := $(KERNEL_TOOLCHAIN_PREFIX)
    else
        ifneq ($(KERNEL_TOOLCHAIN_PREFIX),)
            KERNEL_TOOLCHAIN_PATH := $(KERNEL_TOOLCHAIN)/$(KERNEL_TOOLCHAIN_PREFIX)
        endif
    endif
    ifneq ($(USE_CCACHE),)
        ccache := $(ANDROID_BUILD_TOP)/prebuilts/misc/$(HOST_PREBUILT_TAG)/ccache/ccache
        # Check that the executable is here.
        ccache := $(strip $(wildcard $(ccache)))
    endif
    KERNEL_CROSS_COMPILE := CROSS_COMPILE="$(ccache) $(KERNEL_TOOLCHAIN_PATH)"
    ccache =

    define mv-modules
        mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.order`;\
            if [ "$$mdpath" != "" ];then\
                mpath=`dirname $$mdpath`;\
                ko=`find $$mpath/kernel -type f -name *.ko`;\
                for i in $$ko; do $(KERNEL_TOOLCHAIN_PATH)strip --strip-unneeded $$i;\
                mv $$i $(KERNEL_MODULES_OUT)/; done;\
            fi
    endef

    define clean-module-folder
        mdpath=`find $(KERNEL_MODULES_OUT) -type f -name modules.order`;\
        if [ "$$mdpath" != "" ];then\
            mpath=`dirname $$mdpath`; rm -rf $$mpath;\
        fi
    endef

    define override-defconfig
        if [ "$(OVERRIDE_DEFCONFIGS)" ]; then\
            python -c 'print("Overriding kernel config with contents of:\n##\t%s" % "\n##\t".join("$(OVERRIDE_DEFCONFIGS)".split()))'\
            for defconfig in $(OVERRIDE_DEFCONFIGS); do\
                if [ -f $(KERNEL_SRC)/arch/$(KERNEL_ARCH)/$defconfig ]; then\
                    cat $(KERNEL_SRC)/arch/$(KERNEL_ARCH)/$defconfig >> $(KERNEL_CONFIG);\
                fi;\
            done;\
            $(KERNEL_MAKE) oldconfig;\
        fi
    endef

    define override-config
        $(call override-defconfig)
        if [ ! -z "$(KERNEL_CONFIG_OVERRIDE)" ]; then\
            echo "Overriding kernel config with '$(KERNEL_CONFIG_OVERRIDE)'";\
            echo $(KERNEL_CONFIG_OVERRIDE) >> $(KERNEL_CONFIG);\
            $(KERNEL_MAKE) oldconfig;\
        fi
    endef

    ifeq ($(HOST_OS),darwin)
        MAKE_FLAGS += C_INCLUDE_PATH=$(ANDROID_BUILD_TOP)/external/elfutils/0.153/libelf/
    endif

    ifeq ($(TARGET_KERNEL_MODULES),)
        TARGET_KERNEL_MODULES := no-external-modules
    endif

    KERNEL_MAKE := $(MAKE) $(MAKE_FLAGS) -C $(KERNEL_SRC) O=$(KERNEL_OUT) ARCH=$(KERNEL_ARCH) $(KERNEL_CROSS_COMPILE)

    $(KERNEL_OUT):
	    mkdir -p $(KERNEL_OUT)
	    mkdir -p $(KERNEL_MODULES_OUT)

    $(KERNEL_CONFIG): $(KERNEL_OUT)
	    $(KERNEL_MAKE) VARIANT_DEFCONFIG=$(VARIANT_DEFCONFIG) SELINUX_DEFCONFIG=$(SELINUX_DEFCONFIG) $(KERNEL_DEFCONFIG)
	    $(hide) $(override-config)

    TARGET_KERNEL_BINARIES: $(KERNEL_OUT) $(KERNEL_CONFIG) $(KERNEL_HEADERS_INSTALL)
	$(KERNEL_MAKE) $(TARGET_PREBUILT_INT_KERNEL_TYPE)
	-$(KERNEL_MAKE) dtbs
	-$(KERNEL_MAKE) modules
	-$(KERNEL_MAKE) INSTALL_MOD_PATH=../../$(KERNEL_MODULES_INSTALL) modules_install
	$(mv-modules)
	$(clean-module-folder)

    $(TARGET_KERNEL_MODULES): TARGET_KERNEL_BINARIES

    # This is never called on Header Only builds, so safe to leave unflagged
    $(TARGET_PREBUILT_INT_KERNEL): $(TARGET_KERNEL_MODULES)
	$(mv-modules)
	$(clean-module-folder)

    # This is called on full builds, but it's safe to leave unflagged
    $(KERNEL_BIN): $(KERNEL_HEADERS_INSTALL)

    $(KERNEL_HEADERS_INSTALL): $(KERNEL_OUT) $(KERNEL_CONFIG)
    ifneq ($(KERNEL_HEADER_DEFCONFIG),$(KERNEL_DEFCONFIG))
        ifneq ($(KERNEL_HEADER_DEFCONFIG),)
	        $(eval header_changed_config=1)
	        $(KERNEL_MAKE) VARIANT_DEFCONFIG=$(VARIANT_DEFCONFIG) SELINUX_DEFCONFIG=$(SELINUX_DEFCONFIG) $(KERNEL_HEADER_DEFCONFIG)
	        $(override-config)
        endif
    endif
	$(KERNEL_MAKE) headers_install
    ifeq ($(header_changed_config),1)
	    $(hide) echo "Used a different defconfig for header generation"
	    $(KERNEL_MAKE) VARIANT_DEFCONFIG=$(VARIANT_DEFCONFIG) SELINUX_DEFCONFIG=$(SELINUX_DEFCONFIG) $(KERNEL_DEFCONFIG)
	    $(override-config)
    endif


    kerneltags: $(KERNEL_OUT) $(KERNEL_CONFIG)
	$(KERNEL_MAKE) tags

    kernelconfig: $(KERNEL_OUT) $(KERNEL_CONFIG)
	env KCONFIG_NOTIMESTAMP=true \
	    $(KERNEL_MAKE) menuconfig
	env KCONFIG_NOTIMESTAMP=true \
	    $(KERNEL_MAKE) savedefconfig
	cp $(KERNEL_OUT)/defconfig kernel/arch/$(KERNEL_ARCH)/configs/$(KERNEL_DEFCONFIG)

endif # FULL_KERNEL_BUILD

## Install it

ifeq ($(NEEDS_KERNEL_COPY),true)
    file := $(INSTALLED_KERNEL_TARGET)
    ALL_PREBUILT += $(file)
    $(file) : $(KERNEL_BIN) | $(ACP)
	$(transform-prebuilt-to-target)
    ALL_PREBUILT += $(INSTALLED_KERNEL_TARGET)
endif
