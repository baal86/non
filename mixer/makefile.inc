# -*- mode: makefile; -*-

VERSION := 1.1.0
PACKAGE := MIXER
BIN_NAME := non-mixer

all: Mixer

SRCS := $(wildcard src/*.C src/*.fl src/Engine/*.C)

SRCS:=$(SRCS:.fl=.C)
SRCS:=$(sort $(SRCS))
OBJS:=$(SRCS:.C=.o)

LIBS := $(FLTK_LIBS) $(JACK_LIBS) $(LASH_LIBS) $(LRDF_LIBS) $(LIBLO_LIBS) $(SIGCPP_LIBS) $(XPM_LIBS)

CFLAGS := $(FLTK_CFLAGS) $(JACK_CFLAGS) $(LIBLO_CFLAGS) $(SIGCPP_CFLAGS) $(XPM_CFLAGS)

src/mixer: $(OBJS) FL/libfl_widgets.a nonlib/libnonlib.a
	@ echo -n Linking mixer...
	@ $(CXX) $(CXXFLAGS) $(LIBS) $(OBJS) -o $@ -LFL -lfl_widgets -Lnonlib -lnonlib -ldl && echo $(DONE)

Mixer: src/mixer

clean:
	rm -f $(OBJS) src/mixer

install: all
	@ echo -n "Installing..."
	@ install src/mixer "$(DESTDIR)$(prefix)"/bin/non-mixer
	@ mkdir -p "$(DESTDIR)$(SYSTEM_PATH)"/non-mixer
	@ $(MAKE) -s -C doc install
	@ install -d "$(DESTDIR)$(PIXMAP_PATH)/non-mixer"
	@ install -m 644 icons/hicolor/256x256/apps/non-mixer.png "$(DESTDIR)$(PIXMAP_PATH)"/non-mixer/icon-256x256.png
	@ install -d "$(DESTDIR)$(ICON_PATH)/hicolor"
	@ cp -au icons/hicolor/ "$(DESTDIR)$(ICON_PATH)"
	@ install -d "$(DESTDIR)$(DESKTOP_PATH)"
	@ sed 's:@BIN_PATH@:$(prefix)/bin:' non-mixer.desktop.in > "$(DESTDIR)$(DESKTOP_PATH)/non-mixer.desktop"
	@ echo "$(DONE)"
ifneq ($(USE_DEBUG),yes)
	@ echo -n "Stripping..."
	@ strip $(DESTDIR)$(prefix)/bin/non-mixer
	@ echo "$(DONE)"
endif