# Deployment routine for Frescolino CMake scripts
#
# Usage (relative paths also supportded):
#   make install /path/to/project
#
# If not using a GNU make v3.8+ compatible, remove the parameter hack below and
# instead use:
#   make install DESTDIR=/path/to/project


TARGETS_WITH_PARAMS = install softinstall
################################################################################
# GNU make parameter hack (instead of using env vars to pass parameters).
# If the first argument is in the TARGETS_WITH_PARAMS list, extract the list
# CDR, store it in PARAMS and turn it into dummy targets (name:;@:).
# Since GNU make delimits by whitespace regardless of quotes, to properly handle
#  "a b" c  and  a\ b c  as two parameters, one MUST pass  a\\ b c  on the
# command line (no quotes, double backslash spaces).
# Alternatively comment in the ONE_PARAM_TOGGLE_HACK and use  "a b c"  or
#  a\ b\ c  to pass everything after the first target as one string.
empty :=
space := $(empty) $(empty)
e_spc := \$(space)
bslas := \$(empty)
ifneq ($(filter $(firstword $(MAKECMDGOALS)),$(TARGETS_WITH_PARAMS)),)
    PARAMS := $(wordlist 2, $(words $(MAKECMDGOALS)), $(MAKECMDGOALS))

    ONE_PARAM_TOGGLE_HACK = 1
    ifeq ($(ONE_PARAM_TOGGLE_HACK),1)
        PARAMS := $(subst $(space),$(e_spc),$(PARAMS))
        bslas := $(empty)
    endif

    PARAMS := $(subst $(e_spc),{},$(strip $(PARAMS)))
    $(foreach elem, $(PARAMS),\
        $(eval $(subst {},$(bslas)$(e_spc),$(elem)):;@:)\
    )
    PARAMS := $(subst {},$(bslas)$(e_spc),$(PARAMS))
endif
################################################################################

ifdef PARAMS
    DESTDIR = $(PARAMS)
endif
DESTDIR ?= /usr/local/include
dest = $(DESTDIR)/fsc

.PHONY: all
all: what

.PHONY: install
install:
	@echo mkdir -p "$(dest)"
	@echo cp *.cmake "$(dest)"

.PHONY: softinstall
softinstall:
	@echo mkdir -p "$(dest)"
	@echo ln -s *.cmake "$(dest)"

.PHONY: what
what:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) :::dummy 2>/dev/null \
		| awk -vRS= -F: '{if ($$1 !~ "^[#.]") {print $$1}}' \
		| grep -v -e '^$@$$' -e '^$$' -e $(lastword $(MAKEFILE_LIST)) \
		| sort
