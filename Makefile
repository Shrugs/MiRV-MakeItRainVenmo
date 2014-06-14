export THEOS_DEVICE_IP=localhost
export THEOS_DEVICE_PORT=2222
export ARCHS = armv7 armv7s arm64
export TARGET = iphone:clang:7.1
include theos/makefiles/common.mk

TWEAK_NAME = MiRV
MiRV_FILES = Tweak.xm
MiRV_FRAMEWORKS = UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
