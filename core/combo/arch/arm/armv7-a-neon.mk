# Configuration for Linux on ARM.
# Generating binaries for the ARMv7-a architecture and higher with NEON
#
ARCH_ARM_HAVE_ARMV7A            := true
ARCH_ARM_HAVE_VFP               := true
ARCH_ARM_HAVE_VFP_D32           := true
ARCH_ARM_HAVE_NEON              := true

ifeq ($(strip $(TARGET_$(combo_2nd_arch_prefix)CPU_VARIANT)),cortex-a53)
	arch_variant_cflags := -mcpu=cortex-a15 -mfpu=neon-vfpv4

	arch_variant_ldflags := \
		-Wl,--no-fix-cortex-a8
else
ifneq (,$(filter cortex-a15 denver krait,$(TARGET_$(combo_2nd_arch_prefix)CPU_VARIANT)))
	arch_variant_cflags := -mcpu=cortex-a15 -mfpu=neon-vfpv4

	# Fake an ARM compiler flag as these processors support LPAE which GCC/clang
	# don't advertise.
	arch_variant_cflags += -D__ARM_FEATURE_LPAE=1
	arch_variant_ldflags := \
		-Wl,--no-fix-cortex-a8
else
ifeq ($(strip $(TARGET_$(combo_2nd_arch_prefix)CPU_VARIANT)),cortex-a9)
	arch_variant_cflags := -mcpu=cortex-a9 -mfpu=neon
	arch_variant_ldflags := \
		-Wl,--no-fix-cortex-a8
else
ifneq (,$(filter cortex-a8 scorpion,$(TARGET_$(combo_2nd_arch_prefix)CPU_VARIANT)))
	arch_variant_cflags := -mcpu=cortex-a8 -mfpu=neon
	arch_variant_ldflags := \
		-Wl,--fix-cortex-a8
else
ifeq ($(strip $(TARGET_$(combo_2nd_arch_prefix)CPU_VARIANT)),cortex-a7)
	arch_variant_cflags := -mcpu=cortex-a7 -mfpu=neon-vfpv4
	arch_variant_ldflags := \
		-Wl,--no-fix-cortex-a8
else
ifeq ($(strip $(TARGET_$(combo_2nd_arch_prefix)CPU_VARIANT)),cortex-a5)
	arch_variant_cflags := -mcpu=cortex-a7 -mfpu=neon-vfpv4
	arch_variant_ldflags := \
		-Wl,--no-fix-cortex-a8
else
	arch_variant_cflags := -march=armv7-a -mfpu=neon
	# Generic ARM might be a Cortex A8 -- better safe than sorry
	arch_variant_ldflags := \
		-Wl,--fix-cortex-a8
endif
endif
endif
endif
endif
endif

arch_variant_cflags += \
    -mfloat-abi=softfp

ifeq ($(TARGET_CPU_CORTEX_A53),true)
arch_variant_ldflags := -Wl,--fix-cortex-a53-843419 \
                        -Wl,--fix-cortex-a53-835769
endif
