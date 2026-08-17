obj-m += panasonic-laptop.o

KVER ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVER)/build
MODULE_NAME := panasonic_laptop
VERSION := 1.0

KBUILD_AUTOCONF := /lib/modules/$(KVER)/build/include/config/auto.conf

ifneq ($(wildcard $(KBUILD_AUTOCONF)),)
    include $(KBUILD_AUTOCONF)
endif

ifeq ($(CONFIG_CC_IS_CLANG),y)
    LLVM_FLAG := LLVM=1
endif

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) $(LLVM_FLAG) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean

install:
	$(MAKE) dkms-remove
	$(MAKE) dkms-add
	$(MAKE) dkms-build
	$(MAKE) dkms-install

load:
	-/sbin/rmmod $(MODULE_NAME)
	/sbin/insmod $(MODULE_NAME).ko

dkms-add: dkms.conf
	/usr/sbin/dkms add $(CURDIR)

dkms-build: dkms.conf
	/usr/sbin/dkms build $(MODULE_NAME)/$(VERSION)

dkms-install: dkms.conf
	/usr/sbin/dkms install -m $(MODULE_NAME) -v $(VERSION)

dkms-remove: dkms.conf
	-/usr/sbin/dkms remove -m $(MODULE_NAME) -v $(VERSION) --all

modprobe-install:
	modprobe $(MODULE_NAME)

modprobe-remove:
	modprobe -r $(MODULE_NAME)

dev: modprobe-remove dkms-remove dkms-add dkms-build dkms-install modprobe-install
